"""File system watcher for automatic script refresh."""

import time
from pathlib import Path
from typing import Callable, Optional

from loguru import logger
from watchdog.events import FileSystemEvent, FileSystemEventHandler
from watchdog.observers import Observer


class ScriptFolderHandler(FileSystemEventHandler):
    """Handler for script folder file system events."""

    def __init__(self, callback: Callable[[], None], debounce_seconds: float = 0.5):
        """
        Initialize the handler.

        Args:
            callback: Function to call when changes are detected
            debounce_seconds: Minimum time between callback invocations
        """
        super().__init__()
        self.callback = callback
        self.debounce_seconds = debounce_seconds
        self.last_triggered = 0.0
        self.script_extensions = {".py", ".bat", ".cmd", ".ps1"}

    def _should_process(self, event: FileSystemEvent) -> bool:
        """Check if the event should trigger a callback."""
        # Ignore directory events
        if event.is_directory:
            return False

        # Only process script files
        path = Path(event.src_path)
        if path.suffix.lower() not in self.script_extensions:
            return False

        # Debounce: don't trigger too frequently
        current_time = time.time()
        if current_time - self.last_triggered < self.debounce_seconds:
            return False

        return True

    def on_created(self, event: FileSystemEvent) -> None:
        """Handle file creation events."""
        if self._should_process(event):
            logger.info(f"Script added: {event.src_path}")
            self.last_triggered = time.time()
            self.callback()

    def on_deleted(self, event: FileSystemEvent) -> None:
        """Handle file deletion events."""
        if self._should_process(event):
            logger.info(f"Script removed: {event.src_path}")
            self.last_triggered = time.time()
            self.callback()

    def on_modified(self, event: FileSystemEvent) -> None:
        """Handle file modification events."""
        if self._should_process(event):
            logger.debug(f"Script modified: {event.src_path}")
            # Don't refresh on modification, only on add/remove


class ScriptFolderWatcher:
    """Watches a folder for script file changes."""

    def __init__(self, folder_path: Path, callback: Callable[[], None]):
        """
        Initialize the watcher.

        Args:
            folder_path: Path to the folder to watch
            callback: Function to call when changes are detected
        """
        self.folder_path = folder_path
        self.callback = callback
        self.observer: Optional[Observer] = None
        self.handler = ScriptFolderHandler(callback)

    def start(self) -> None:
        """Start watching the folder."""
        if self.observer is not None:
            logger.warning("Watcher already started")
            return

        if not self.folder_path.exists():
            logger.warning(f"Folder does not exist: {self.folder_path}")
            return

        self.observer = Observer()
        self.observer.schedule(self.handler, str(self.folder_path), recursive=False)
        self.observer.start()
        logger.info(f"Started watching folder: {self.folder_path}")

    def stop(self) -> None:
        """Stop watching the folder."""
        if self.observer is None:
            return

        self.observer.stop()
        self.observer.join(timeout=2.0)
        self.observer = None
        logger.info("Stopped watching folder")

    def __enter__(self) -> "ScriptFolderWatcher":
        """Context manager entry."""
        self.start()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:  # type: ignore
        """Context manager exit."""
        self.stop()
