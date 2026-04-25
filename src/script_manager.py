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
from .models import RiskLevel, Script, ScriptType
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
        self._cache: ScriptCache = ScriptCache.load(cache_path) if cache_path else ScriptCache()
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
        self._infer_missing_risk_metadata()
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
                or q in s.risk_level.label.lower()
                or any(q in change.lower() for change in s.expected_changes)
                or any(q in target.lower() for target in s.backup_targets)
                or (s.requires_admin and q in "requires admin")
                or (s.requires_reboot and q in "requires reboot")
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
        risk_level: str | RiskLevel | None = None,
        requires_admin: bool | None = None,
        requires_reboot: bool | None = None,
        expected_changes: list[str] | None = None,
        backup_targets: list[str] | None = None,
        preview_command: str | None = None,
    ) -> bool:
        script = self.scripts.get(script_path)
        if not script:
            logger.warning(f"Script not found: {script_path}")
            return False
        if description is not None:
            script.description = description
        if category is not None:
            script.category = category
        if risk_level is not None:
            script.risk_level = RiskLevel.from_value(risk_level)
        if requires_admin is not None:
            script.requires_admin = requires_admin
        if requires_reboot is not None:
            script.requires_reboot = requires_reboot
        if expected_changes is not None:
            script.expected_changes = expected_changes
        if backup_targets is not None:
            script.backup_targets = backup_targets
        if preview_command is not None:
            script.preview_command = preview_command
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
        metadata_file = self.scripts_dir / METADATA_FILENAME
        if metadata_file.exists():
            try:
                st = metadata_file.stat()
                entries.append(f"{METADATA_FILENAME}|{st.st_size}|{st.st_mtime_ns}")
            except OSError:
                pass
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
                script.risk_level = previous.risk_level
                script.requires_admin = previous.requires_admin
                script.requires_reboot = previous.requires_reboot
                script.expected_changes = previous.expected_changes
                script.backup_targets = previous.backup_targets
                script.preview_command = previous.preview_command
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
            script.risk_level = RiskLevel.from_value(cached.risk_level)
            script.requires_admin = cached.requires_admin
            script.requires_reboot = cached.requires_reboot
            script.expected_changes = cached.expected_changes
            script.backup_targets = cached.backup_targets
            script.preview_command = cached.preview_command
            script.run_count = cached.run_count
            if cached.last_run:
                try:
                    script.last_run = datetime.fromisoformat(cached.last_run)
                except ValueError:
                    script.last_run = None
            self.scripts[path] = script

    def _load_metadata_file(self) -> None:
        """Load per-script metadata from JSON."""
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
            script.risk_level = RiskLevel.from_value(meta.get("risk_level", script.risk_level))
            script.requires_admin = bool(meta.get("requires_admin", script.requires_admin))
            script.requires_reboot = bool(meta.get("requires_reboot", script.requires_reboot))
            script.expected_changes = self._string_list(
                meta.get("expected_changes", script.expected_changes)
            )
            script.backup_targets = self._string_list(
                meta.get("backup_targets", script.backup_targets)
            )
            script.preview_command = meta.get("preview_command", script.preview_command)

    def _infer_missing_risk_metadata(self) -> None:
        """Infer baseline risk badges when metadata does not specify them."""
        for script in self.scripts.values():
            content = self._safe_read_script(script.path)
            haystack = f"{script.name}\n{script.description}\n{content}".lower()
            inferred_changes: set[str] = set(script.expected_changes)
            inferred_backups: set[str] = set(script.backup_targets)

            script.requires_admin = script.requires_admin or any(
                marker in haystack
                for marker in (
                    "net session",
                    "checkpoint-computer",
                    "set-mppreference",
                    "dism /online",
                    "reg add hklm",
                    "reg delete hklm",
                    "sc config",
                    "netsh ",
                    "powercfg ",
                )
            )
            script.requires_reboot = script.requires_reboot or any(
                marker in haystack
                for marker in (
                    "shutdown /r",
                    "restart-computer",
                    "open_to_bios",
                    "reboot",
                    "perkrauti",
                    "restart computer",
                )
            )

            if any(marker in haystack for marker in ("reg add", "reg delete", "set-itemproperty")):
                inferred_changes.add("Modify Windows registry settings")
                inferred_backups.add("registry")
            if "hosts" in haystack:
                inferred_changes.add("Read or modify the Windows hosts file")
                inferred_backups.add("hosts")
            if "netsh " in haystack or "set-dnsclientserveraddress" in haystack:
                inferred_changes.add("Change network, DNS, TCP/IP, or firewall settings")
                inferred_backups.add("network")
            if "advfirewall" in haystack:
                inferred_changes.add("Change Windows Firewall rules or profile settings")
                inferred_backups.add("firewall")
            if "set-mppreference" in haystack or "defender" in haystack:
                inferred_changes.add("Change Windows Defender protection settings")
                inferred_backups.add("defender")
            if "remove-appxpackage" in haystack or "bloat_remover" in haystack:
                inferred_changes.add("Remove installed Windows app packages")
                inferred_backups.add("appx")
            if "path" in haystack and (
                "setenvironmentvariable" in haystack or "path_cleaner" in haystack
            ):
                inferred_changes.add("Change the system PATH environment variable")
                inferred_backups.add("path")
            if any(marker in haystack for marker in ("sc config", "set-service")):
                inferred_changes.add("Change Windows service startup or runtime state")
                inferred_backups.add("services")
            if any(marker in haystack for marker in ("disable-scheduledtask", "scheduledtask")):
                inferred_changes.add("Read or change Windows scheduled tasks")
                inferred_backups.add("scheduled_tasks")
            if any(marker in haystack for marker in ("rmdir /s", "rd /s", "del /s", "remove-item")):
                inferred_changes.add("Delete files, folders, caches, or application data")
                inferred_backups.add("files")
            if "powercfg" in haystack:
                inferred_changes.add("Change or report Windows power configuration")
                inferred_backups.add("power")

            if any(
                marker in haystack
                for marker in (
                    "bloat_remover",
                    "event_log_wiper",
                    "discord_stealth_cleaner",
                    "defender_toggle",
                    "cortana_edge_killer",
                    "rmdir /s",
                    "rd /s",
                    "del /s",
                    "remove-appxpackage",
                    "disable-scheduledtask",
                    "set-mppreference -disablerealtimemonitoring $true",
                    "reg delete",
                    "taskkill /f",
                )
            ):
                script.risk_level = RiskLevel.DESTRUCTIVE
            elif script.risk_level is RiskLevel.SAFE:
                continue
            elif (
                script.requires_admin
                or script.requires_reboot
                or any(
                    marker in haystack
                    for marker in (
                        "cleaner",
                        "reset",
                        "fixer",
                        "optimizer",
                        "manager",
                        "backup",
                        "restore",
                        "install",
                        "update",
                        "netsh ",
                        "reg add",
                        "set-itemproperty",
                    )
                )
            ):
                script.risk_level = RiskLevel.MODERATE
            else:
                script.risk_level = RiskLevel.SAFE

            script.expected_changes = sorted(inferred_changes)
            script.backup_targets = sorted(inferred_backups)

    @staticmethod
    def _safe_read_script(path: Path) -> str:
        try:
            return path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            return ""

    @staticmethod
    def _string_list(value: object) -> list[str]:
        if value is None:
            return []
        if isinstance(value, str):
            return [value]
        if isinstance(value, list):
            return [str(item) for item in value if str(item).strip()]
        return []

    def _persist_cache(self, signature: str | None = None, only_if_changed: bool = False) -> None:
        if self.cache_path is None:
            return
        cached_scripts = [self._to_cached(s) for s in self.scripts.values()]
        directory_signature = signature or self._directory_signature()
        if (
            only_if_changed
            and self._cache.scripts == cached_scripts
            and self._cache.directory_signature == directory_signature
        ):
            return
        self._cache.scripts = cached_scripts
        self._cache.last_scan = datetime.now().isoformat()
        self._cache.directory_signature = directory_signature
        self._cache.save(self.cache_path)

    @staticmethod
    def _to_cached(script: Script) -> CachedScript:
        return CachedScript(
            path=str(script.path),
            name=script.name,
            description=script.description,
            category=script.category,
            risk_level=script.risk_level.value,
            requires_admin=script.requires_admin,
            requires_reboot=script.requires_reboot,
            expected_changes=script.expected_changes,
            backup_targets=script.backup_targets,
            preview_command=script.preview_command,
            last_run=(script.last_run.isoformat() if script.last_run is not None else None),
            run_count=script.run_count,
        )
