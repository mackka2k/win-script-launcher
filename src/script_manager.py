"""Script management for discovering and organizing scripts."""

import hashlib
import os
from datetime import datetime
from pathlib import Path
from typing import Optional

from loguru import logger

from .models import Script, ScriptType


class ScriptManager:
    """Manages script discovery and organization."""

    def __init__(self, scripts_dir: Path, config=None):
        """
        Initialize the script manager.

        Args:
            scripts_dir: Directory containing scripts
            config: App configuration for caching
        """
        self.scripts_dir = scripts_dir
        self.scripts: dict[Path, Script] = {}
        self.config = config
        self._ensure_scripts_dir()

    def _ensure_scripts_dir(self) -> None:
        """Ensure the scripts directory exists."""
        self.scripts_dir.mkdir(parents=True, exist_ok=True)
        logger.info(f"Scripts directory: {self.scripts_dir}")

    def _get_directory_hash(self) -> str:
        """Get hash of scripts directory state for cache validation."""
        try:
            # Use directory mtime and file count as hash
            mtime = os.path.getmtime(self.scripts_dir)
            file_count = len(list(self.scripts_dir.glob("*.*")))
            hash_str = f"{mtime}_{file_count}"
            return hashlib.md5(hash_str.encode()).hexdigest()
        except Exception:
            return ""

    def _is_cache_valid(self) -> bool:
        """Check if cached scripts are still valid."""
        if not self.config or not self.config.script_cache:
            return False
        
        cache = self.config.script_cache
        if not cache.directory_hash or not cache.scripts:
            return False
        
        # Compare directory hash
        current_hash = self._get_directory_hash()
        return current_hash == cache.directory_hash

    def _load_from_cache(self) -> list[Script]:
        """Load scripts from cache."""
        try:
            scripts_data = self.config.script_cache.scripts
            self.scripts = {}
            
            for script_data in scripts_data:
                script_path = Path(script_data["path"])
                if script_path.exists():
                    script = Script.from_path(script_path)
                    # Restore metadata
                    script.description = script_data.get("description", "")
                    script.category = script_data.get("category", "General")
                    script.last_run = script_data.get("last_run")
                    script.run_count = script_data.get("run_count", 0)
                    self.scripts[script_path] = script
            
            logger.info(f"Loaded {len(self.scripts)} scripts from cache")
            return list(self.scripts.values())
        except Exception as e:
            logger.warning(f"Failed to load cache: {e}")
            return []

    def _save_to_cache(self) -> None:
        """Save scripts to cache."""
        try:
            scripts_data = []
            for script in self.scripts.values():
                scripts_data.append({
                    "path": str(script.path),
                    "name": script.name,
                    "description": script.description,
                    "category": script.category,
                    "last_run": script.last_run,
                    "run_count": script.run_count,
                })
            
            self.config.script_cache.scripts = scripts_data
            self.config.script_cache.directory_hash = self._get_directory_hash()
            self.config.script_cache.last_scan = datetime.now().isoformat()
            logger.info("Saved scripts to cache")
        except Exception as e:
            logger.warning(f"Failed to save cache: {e}")

    def discover_scripts(self, force_refresh: bool = False) -> list[Script]:
        """
        Discover all scripts with caching for performance.

        Args:
            force_refresh: Force rescan even if cache is valid

        Returns:
            List of discovered scripts
        """
        # Try to load from cache if available
        if not force_refresh and self.config and self._is_cache_valid():
            logger.info("Loading scripts from cache")
            return self._load_from_cache()

        # Scan directory
        discovered: dict[Path, Script] = {}

        if not self.scripts_dir.exists():
            logger.warning(f"Scripts directory does not exist: {self.scripts_dir}")
            return []

        # Supported extensions
        extensions = ["*.py", "*.bat", "*.cmd", "*.ps1"]

        for pattern in extensions:
            for script_path in self.scripts_dir.glob(pattern):
                if script_path.is_file():
                    script = Script.from_path(script_path)

                    # Preserve metadata if script was already known
                    if script_path in self.scripts:
                        old_script = self.scripts[script_path]
                        script.description = old_script.description
                        script.category = old_script.category
                        script.last_run = old_script.last_run
                        script.run_count = old_script.run_count

                    discovered[script_path] = script

        self.scripts = discovered
        
        # Load metadata from JSON file
        self._load_metadata()
        
        logger.info(f"Discovered {len(self.scripts)} scripts")
        
        # Save to cache
        if self.config:
            self._save_to_cache()
        
        return list(self.scripts.values())
    
    def _load_metadata(self) -> None:
        """Load script metadata from JSON file."""
        import json
        
        metadata_file = self.scripts_dir / "script_metadata.json"
        if not metadata_file.exists():
            return
        
        try:
            with open(metadata_file, "r", encoding="utf-8") as f:
                metadata = json.load(f)
            
            for script in self.scripts.values():
                script_name = script.path.name
                if script_name in metadata:
                    meta = metadata[script_name]
                    script.category = meta.get("category", "General")
                    script.description = meta.get("description", "")
            
            logger.info("Loaded script metadata")
        except Exception as e:
            logger.warning(f"Failed to load metadata: {e}")


    def get_script(self, path: Path) -> Optional[Script]:
        """
        Get a script by path.

        Args:
            path: Path to the script

        Returns:
            Script object or None if not found
        """
        return self.scripts.get(path)

    def get_all_scripts(self) -> list[Script]:
        """
        Get all managed scripts.

        Returns:
            List of all scripts
        """
        return list(self.scripts.values())

    def filter_scripts(
        self,
        query: Optional[str] = None,
        category: Optional[str] = None,
        script_type: Optional[ScriptType] = None,
    ) -> list[Script]:
        """
        Filter scripts based on criteria.

        Args:
            query: Search query for script name
            category: Filter by category
            script_type: Filter by script type

        Returns:
            Filtered list of scripts
        """
        results = list(self.scripts.values())

        if query:
            query_lower = query.lower()
            results = [s for s in results if query_lower in s.name.lower()]

        if category:
            results = [s for s in results if s.category == category]

        if script_type:
            results = [s for s in results if s.script_type == script_type]

        return results

    def get_categories(self) -> list[str]:
        """
        Get all unique categories.

        Returns:
            List of category names
        """
        categories = {script.category for script in self.scripts.values()}
        return sorted(categories)

    def update_script_metadata(
        self,
        script_path: Path,
        description: Optional[str] = None,
        category: Optional[str] = None,
    ) -> bool:
        """
        Update script metadata.

        Args:
            script_path: Path to the script
            description: New description
            category: New category

        Returns:
            True if updated successfully
        """
        script = self.scripts.get(script_path)
        if not script:
            logger.warning(f"Script not found: {script_path}")
            return False

        if description is not None:
            script.description = description
        if category is not None:
            script.category = category

        logger.info(f"Updated metadata for {script.name}")
        
        # Update cache
        if self.config:
            self._save_to_cache()
        
        return True

    def delete_script(self, script_path: Path) -> bool:
        """
        Delete a script file.

        Args:
            script_path: Path to the script

        Returns:
            True if deleted successfully
        """
        try:
            if script_path.exists():
                script_path.unlink()
                if script_path in self.scripts:
                    del self.scripts[script_path]
                logger.info(f"Deleted script: {script_path}")
                
                # Update cache
                if self.config:
                    self._save_to_cache()
                
                return True
            return False
        except Exception as e:
            logger.error(f"Failed to delete script {script_path}: {e}")
            return False
