"""File system watcher for automatic script refresh (debounced)."""

from __future__ import annotations

import threading
from collections.abc import Callable
from pathlib import Path

from loguru import logger
from watchdog.events import FileSystemEvent, FileSystemEventHandler
from watchdog.observers import Observer
from watchdog.observers.api import BaseObserver

SCRIPT_EXTENSIONS = frozenset({".py", ".bat", ".cmd", ".ps1"})


class _DebouncedCallback:
    """Schedule ``callback`` at most once per ``delay`` seconds."""

    def __init__(self, callback: Callable[[], None], delay: float) -> None:
        self._callback = callback
        self._delay = delay
        self._timer: threading.Timer | None = None
        self._lock = threading.Lock()

    def trigger(self) -> None:
        with self._lock:
            if self._timer is not None:
                self._timer.cancel()
            self._timer = threading.Timer(self._delay, self._fire)
            self._timer.daemon = True
            self._timer.start()

    def _fire(self) -> None:
        try:
            self._callback()
        except Exception:  # noqa: BLE001
            logger.exception("File watcher callback raised")

    def cancel(self) -> None:
        with self._lock:
            if self._timer is not None:
                self._timer.cancel()
                self._timer = None


class ScriptFolderHandler(FileSystemEventHandler):
    """Handler that filters for script files and debounces the callback."""

    def __init__(self, debounced: _DebouncedCallback) -> None:
        super().__init__()
        self._debounced = debounced

    @staticmethod
    def _is_script(event: FileSystemEvent) -> bool:
        if event.is_directory:
            return False
        return Path(event.src_path).suffix.lower() in SCRIPT_EXTENSIONS

    def on_created(self, event: FileSystemEvent) -> None:
        if self._is_script(event):
            logger.info(f"Script added: {event.src_path}")
            self._debounced.trigger()

    def on_deleted(self, event: FileSystemEvent) -> None:
        if self._is_script(event):
            logger.info(f"Script removed: {event.src_path}")
            self._debounced.trigger()

    def on_moved(self, event: FileSystemEvent) -> None:
        dest = getattr(event, "dest_path", None)
        if self._is_script(event) or (
            dest is not None and Path(dest).suffix.lower() in SCRIPT_EXTENSIONS
        ):
            logger.info(f"Script moved: {event.src_path} -> {dest}")
            self._debounced.trigger()


class ScriptFolderWatcher:
    """Watches a folder for script file changes."""

    def __init__(
        self,
        folder_path: Path,
        callback: Callable[[], None],
        debounce_seconds: float = 0.5,
    ) -> None:
        self.folder_path = folder_path
        self._debounced = _DebouncedCallback(callback, debounce_seconds)
        self._handler = ScriptFolderHandler(self._debounced)
        self._observer: BaseObserver | None = None

    def start(self) -> None:
        if self._observer is not None:
            logger.warning("Watcher already started")
            return
        if not self.folder_path.exists():
            logger.warning(f"Folder does not exist: {self.folder_path}")
            return

        self._observer = Observer()
        self._observer.schedule(
            self._handler, str(self.folder_path), recursive=False
        )
        self._observer.start()
        logger.info(f"Watching folder: {self.folder_path}")

    def stop(self) -> None:
        self._debounced.cancel()
        if self._observer is None:
            return
        self._observer.stop()
        self._observer.join(timeout=2.0)
        self._observer = None
        logger.debug("File watcher stopped")

    def __enter__(self) -> ScriptFolderWatcher:
        self.start()
        return self

    def __exit__(self, exc_type: object, exc_val: object, exc_tb: object) -> None:
        self.stop()


__all__ = ["ScriptFolderWatcher", "SCRIPT_EXTENSIONS"]
