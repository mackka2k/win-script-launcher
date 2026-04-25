"""Main application class coordinating all components."""

from __future__ import annotations

import sys
import tkinter as tk
from pathlib import Path
from tkinter import messagebox

import customtkinter as ctk
from loguru import logger

from .config import AppConfig
from .logger import setup_logging
from .script_executor import ScriptExecutor
from .script_manager import ScriptManager
from .ui.main_window import MainWindow
from .ui.theme import Theme
from .utils.admin import elevate_privileges, is_admin
from .utils.file_watcher import ScriptFolderWatcher


class Application:
    """Main application class."""

    def __init__(self) -> None:
        if getattr(sys, "frozen", False):
            self.base_dir = Path(sys.executable).parent
        else:
            self.base_dir = Path(__file__).resolve().parent.parent

        self.scripts_dir = self.base_dir / "scripts"
        self.config_path = self.base_dir / "config.json"
        self.cache_path = self.base_dir / "cache.json"
        self.log_dir = self.base_dir / "logs"

        self.config: AppConfig = AppConfig()
        self.script_manager: ScriptManager | None = None
        self.script_executor: ScriptExecutor | None = None
        self.main_window: MainWindow | None = None
        self.file_watcher: ScriptFolderWatcher | None = None

    # --- Public --------------------------------------------------------

    def run(self) -> None:
        """Run the application main loop."""
        self._stabilize_windows_dpi()
        self.config = AppConfig.load(self.config_path)
        setup_logging(self.log_dir, log_level=self.config.log_level)
        logger.info("=" * 60)
        logger.info("Script Launcher starting")
        logger.info(f"Base directory: {self.base_dir}")
        logger.info(f"Scripts directory: {self.scripts_dir}")

        if self.config.check_admin_on_startup and not self._maybe_elevate():
            return

        self.script_manager = ScriptManager(
            self.scripts_dir, cache_path=self.cache_path
        )
        self.script_executor = ScriptExecutor(
            timeout_seconds=self.config.execution.timeout_seconds,
            max_output_lines=self.config.execution.max_output_lines,
            run_batch_in_new_window=self.config.execution.run_batch_in_new_window,
            log_dir=self.log_dir / "scripts",
        )

        ctk.set_appearance_mode(self.config.theme.mode.capitalize())
        ctk.set_default_color_theme("blue")

        root = ctk.CTk()
        root.configure(fg_color=Theme.colors.bg_primary)
        self.main_window = MainWindow(
            root,
            self.config,
            self.script_manager,
            self.script_executor,
            on_close=self._persist_state,
        )

        if self.config.enable_file_watcher:
            self._setup_file_watcher()

        logger.info("Entering main loop")
        try:
            root.mainloop()
        except KeyboardInterrupt:
            logger.info("Keyboard interrupt received")
        except Exception:  # noqa: BLE001
            logger.exception("Unexpected error in main loop")
            messagebox.showerror(
                "Error", "An unexpected error occurred. See logs for details."
            )
        finally:
            self._cleanup()

    # --- Internal ------------------------------------------------------

    def _maybe_elevate(self) -> bool:
        """Prompt for admin elevation. Returns False if the app should exit."""
        if is_admin():
            logger.info("Running with administrator privileges")
            return True

        logger.warning("Not running with administrator privileges")

        temp_root = tk.Tk()
        temp_root.withdraw()
        try:
            wants_elevate = messagebox.askyesno(
                "Administrator required",
                "Some scripts need administrator privileges to run correctly.\n\n"
                "Restart as Administrator?",
            )
        finally:
            temp_root.destroy()

        if not wants_elevate:
            return True

        logger.info("Attempting to elevate privileges")
        if elevate_privileges():
            sys.exit(0)
        messagebox.showwarning(
            "Elevation failed",
            "Failed to elevate privileges. Some scripts may not work correctly.",
        )
        return True

    def _setup_file_watcher(self) -> None:
        try:
            assert self.main_window is not None
            self.file_watcher = ScriptFolderWatcher(
                self.scripts_dir,
                callback=self.main_window.refresh_scripts,
            )
            self.file_watcher.start()
        except Exception as e:  # noqa: BLE001
            logger.warning(f"Failed to start file watcher: {e}")

    def _persist_state(self) -> None:
        """Persist config and cancel running scripts on close."""
        if self.main_window is not None:
            try:
                self.main_window.snapshot_geometry()
            except Exception:  # noqa: BLE001
                logger.exception("Failed to snapshot window geometry")

        try:
            self.config.save(self.config_path)
            logger.info("Configuration saved")
        except Exception:  # noqa: BLE001
            logger.exception("Failed to save configuration")

        if self.script_executor is not None:
            count = self.script_executor.cancel_all()
            if count:
                logger.info(f"Cancelled {count} running script(s)")

    def _cleanup(self) -> None:
        logger.info("Cleaning up")
        if self.file_watcher is not None:
            self.file_watcher.stop()
        logger.info("Shutdown complete")

    @staticmethod
    def _stabilize_windows_dpi() -> None:
        """Avoid expensive per-monitor Tk rescaling while dragging windows.

        Tk/CustomTkinter can stutter badly when crossing monitors with
        different DPI scales. System-DPI awareness keeps the app at one stable
        scale for the session instead of rebuilding metrics during the drag.
        """
        if sys.platform != "win32":
            return
        try:
            import ctypes

            try:
                # PROCESS_SYSTEM_DPI_AWARE
                ctypes.windll.shcore.SetProcessDpiAwareness(1)
            except Exception:  # noqa: BLE001 - fallback for older Windows
                ctypes.windll.user32.SetProcessDPIAware()
            ctk.set_widget_scaling(1.0)
            ctk.set_window_scaling(1.0)
        except Exception as e:  # noqa: BLE001 - DPI setup must not block startup
            logger.debug(f"DPI stabilization skipped: {e}")


def main() -> None:
    """Main entry point."""
    Application().run()


if __name__ == "__main__":
    main()
