"""Script management for discovering and organizing scripts.

The on-disk cache lives in ``cache.json`` (separate from user config) so
that the (potentially large) cache payload never corrupts user settings.
Cache invalidation uses a deterministic signature built from the set of
``(path, mtime, size)`` tuples so renames and content changes are caught.
"""

from __future__ import annotations

import hashlib
import json
from datetime import datetime
from pathlib import Path

from loguru import logger

from .config import CachedScript, ScriptCache
from .exceptions import ValidationError
from .models import Script, ScriptType
from .validators import PathValidator

SUPPORTED_EXTENSIONS = (".py", ".bat", ".cmd", ".ps1")
METADATA_FILENAME = "script_metadata.json"


class ScriptManager:
    """Manages script discovery and organization."""

    def __init__(
        self,
        scripts_dir: Path,
        cache_path: Path | None = None,
    ) -> None:
        self.scripts_dir = scripts_dir
        self.cache_path = cache_path
        self.scripts: dict[Path, Script] = {}
        self._cache: ScriptCache = (
            ScriptCache.load(cache_path) if cache_path else ScriptCache()
        )
        self._ensure_scripts_dir()

    # --- Public API ----------------------------------------------------

    def discover_scripts(self, force_refresh: bool = False) -> list[Script]:
        """Discover all scripts, using the on-disk cache when valid."""
        signature = self._directory_signature()

        if (
            not force_refresh
            and self.cache_path is not None
            and self._cache.directory_signature == signature
            and self._cache.scripts
        ):
            self._hydrate_from_cache()
            logger.info(f"Loaded {len(self.scripts)} scripts from cache")
            return list(self.scripts.values())

        self._scan_directory()
        self._load_metadata_file()

        self._cache = ScriptCache(
            last_scan=datetime.now().isoformat(),
            directory_signature=signature,
            scripts=[self._to_cached(s) for s in self.scripts.values()],
        )
        if self.cache_path is not None:
            self._cache.save(self.cache_path)

        logger.info(f"Discovered {len(self.scripts)} scripts")
        return list(self.scripts.values())

    def get_script(self, path: Path) -> Script | None:
        return self.scripts.get(path)

    def get_all_scripts(self) -> list[Script]:
        return list(self.scripts.values())

    def filter_scripts(
        self,
        query: str | None = None,
        category: str | None = None,
        script_type: ScriptType | None = None,
    ) -> list[Script]:
        results = list(self.scripts.values())
        if query:
            q = query.lower()
            results = [
                s
                for s in results
                if q in s.name.lower()
                or q in s.description.lower()
                or q in s.category.lower()
            ]
        if category:
            results = [s for s in results if s.category == category]
        if script_type:
            results = [s for s in results if s.script_type == script_type]
        return results

    def get_categories(self) -> list[str]:
        return sorted({s.category for s in self.scripts.values()})

    def update_script_metadata(
        self,
        script_path: Path,
        description: str | None = None,
        category: str | None = None,
    ) -> bool:
        script = self.scripts.get(script_path)
        if not script:
            logger.warning(f"Script not found: {script_path}")
            return False
        if description is not None:
            script.description = description
        if category is not None:
            script.category = category
        self._persist_cache()
        return True

    def delete_script(self, script_path: Path) -> bool:
        """Delete a script file, validating the path is within ``scripts_dir``."""
        try:
            PathValidator.validate_script_path(script_path, self.scripts_dir)
        except ValidationError as e:
            logger.error(f"Refused to delete: {e}")
            return False

        try:
            script_path.unlink()
        except OSError as e:
            logger.error(f"Failed to delete script {script_path}: {e}")
            return False

        self.scripts.pop(script_path, None)
        self._persist_cache()
        logger.info(f"Deleted script: {script_path}")
        return True

    def validate_script(self, script: Script) -> None:
        """Validate that a script is safe to execute."""
        PathValidator.validate_script_path(script.path, self.scripts_dir)

    # --- Internal ------------------------------------------------------

    def _ensure_scripts_dir(self) -> None:
        self.scripts_dir.mkdir(parents=True, exist_ok=True)
        logger.debug(f"Scripts directory: {self.scripts_dir}")

    def _directory_signature(self) -> str:
        """Content-aware signature: hashes (relpath, size, mtime_ns) tuples."""
        if not self.scripts_dir.exists():
            return ""
        entries: list[str] = []
        for path in sorted(self.scripts_dir.iterdir()):
            if not path.is_file():
                continue
            if path.suffix.lower() not in SUPPORTED_EXTENSIONS:
                continue
            try:
                st = path.stat()
            except OSError:
                continue
            entries.append(f"{path.name}|{st.st_size}|{st.st_mtime_ns}")
        digest = hashlib.sha256("\n".join(entries).encode("utf-8")).hexdigest()
        return digest

    def _scan_directory(self) -> None:
        discovered: dict[Path, Script] = {}
        for path in sorted(self.scripts_dir.iterdir()):
            if not path.is_file():
                continue
            if path.suffix.lower() not in SUPPORTED_EXTENSIONS:
                continue
            script = Script.from_path(path)

            previous = self.scripts.get(path)
            if previous is not None:
                script.description = previous.description
                script.category = previous.category
                script.last_run = previous.last_run
                script.run_count = previous.run_count
            discovered[path] = script

        self.scripts = discovered

    def _hydrate_from_cache(self) -> None:
        self.scripts = {}
        for cached in self._cache.scripts:
            path = Path(cached.path)
            if not path.exists():
                continue
            script = Script.from_path(path)
            script.description = cached.description
            script.category = cached.category
            script.run_count = cached.run_count
            if cached.last_run:
                try:
                    script.last_run = datetime.fromisoformat(cached.last_run)
                except ValueError:
                    script.last_run = None
            self.scripts[path] = script

    def _load_metadata_file(self) -> None:
        """Load per-script metadata (category, description) from JSON."""
        metadata_file = self.scripts_dir / METADATA_FILENAME
        if not metadata_file.exists():
            return
        try:
            with open(metadata_file, encoding="utf-8") as f:
                metadata = json.load(f)
        except (OSError, json.JSONDecodeError) as e:
            logger.warning(f"Failed to load metadata: {e}")
            return

        for script in self.scripts.values():
            meta = metadata.get(script.path.name)
            if not meta:
                continue
            script.category = meta.get("category", script.category or "General")
            script.description = meta.get("description", script.description)

    def _persist_cache(self) -> None:
        if self.cache_path is None:
            return
        self._cache.scripts = [self._to_cached(s) for s in self.scripts.values()]
        self._cache.last_scan = datetime.now().isoformat()
        self._cache.directory_signature = self._directory_signature()
        self._cache.save(self.cache_path)

    @staticmethod
    def _to_cached(script: Script) -> CachedScript:
        return CachedScript(
            path=str(script.path),
            name=script.name,
            description=script.description,
            category=script.category,
            last_run=(
                script.last_run.isoformat() if script.last_run is not None else None
            ),
            run_count=script.run_count,
        )
