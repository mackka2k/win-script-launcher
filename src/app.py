"""Main application class coordinating all components."""

import sys
import tkinter as tk
import customtkinter as ctk
from pathlib import Path
from tkinter import messagebox

from loguru import logger

from .config import AppConfig
from .logger import setup_logging
from .script_executor import ScriptExecutor
from .script_manager import ScriptManager
from .ui.main_window import MainWindow
from .utils.admin import elevate_privileges, is_admin
from .utils.file_watcher import ScriptFolderWatcher


class Application:
    """Main application class."""

    def __init__(self) -> None:
        """Initialize the application."""
        # Determine base directory
        if getattr(sys, "frozen", False):
            # Running as compiled exe
            self.base_dir = Path(sys.executable).parent
        else:
            # Running as script
            self.base_dir = Path(__file__).parent.parent

        self.scripts_dir = self.base_dir / "scripts"
        self.config_path = self.base_dir / "config.json"
        self.log_dir = self.base_dir / "logs"

        # Initialize components
        self.config: AppConfig
        self.script_manager: ScriptManager
        self.script_executor: ScriptExecutor
        self.main_window: MainWindow
        self.file_watcher: ScriptFolderWatcher | None = None

    def run(self) -> None:
        """Run the application."""
        # Load configuration first
        self.config = AppConfig.load(self.config_path)
        
        # Setup logging with config level
        setup_logging(self.log_dir, log_level=self.config.log_level)
        logger.info("=" * 60)
        logger.info("Script Launcher starting...")
        logger.info(f"Base directory: {self.base_dir}")
        logger.info(f"Scripts directory: {self.scripts_dir}")
        logger.info("Configuration loaded")

        # Check admin privileges
        if self.config.check_admin_on_startup:
            self._check_admin_privileges()

        # Initialize components with config for caching
        self.script_manager = ScriptManager(self.scripts_dir, config=self.config)
        self.script_executor = ScriptExecutor(timeout_seconds=self.config.execution.timeout_seconds)

        # Create UI
        ctk.set_appearance_mode("Dark")
        ctk.set_default_color_theme("dark-blue")
        
        root = ctk.CTk()
        self.main_window = MainWindow(root, self.config, self.script_manager, self.script_executor)

        # Setup file watcher only if enabled (lazy loading)
        if self.config.enable_file_watcher:
            self._setup_file_watcher()

        # Run main loop
        logger.info("Starting main loop")
        try:
            root.mainloop()
        except KeyboardInterrupt:
            logger.info("Keyboard interrupt received")
        except Exception as e:
            logger.exception(f"Unexpected error: {e}")
            messagebox.showerror("Error", f"An unexpected error occurred:\n{e}")
        finally:
            self._cleanup()

    def _check_admin_privileges(self) -> None:
        """Check and request admin privileges if needed."""
        if not is_admin():
            logger.warning("Not running with administrator privileges")

            # Create temporary root for dialog
            temp_root = tk.Tk()
            temp_root.withdraw()

            if messagebox.askyesno(
                "Administrator Required",
                "This application needs administrator privileges to run scripts.\n\n"
                "Would you like to restart as Administrator?",
            ):
                logger.info("Attempting to elevate privileges")
                if elevate_privileges():
                    temp_root.destroy()
                    sys.exit(0)
                else:
                    messagebox.showwarning(
                        "Elevation Failed",
                        "Failed to elevate privileges. Some scripts may not work correctly.",
                    )

            temp_root.destroy()
        else:
            logger.info("Running with administrator privileges")

    def _setup_file_watcher(self) -> None:
        """Setup file system watcher for auto-refresh."""
        try:
            self.file_watcher = ScriptFolderWatcher(
                self.scripts_dir, callback=self.main_window.refresh_scripts
            )
            self.file_watcher.start()
            logger.info("File watcher started")
        except Exception as e:
            logger.warning(f"Failed to start file watcher: {e}")

    def _cleanup(self) -> None:
        """Cleanup resources."""
        logger.info("Cleaning up...")

        # Stop file watcher
        if self.file_watcher:
            self.file_watcher.stop()

        # Cancel running scripts
        count = self.script_executor.cancel_all()
        if count > 0:
            logger.info(f"Cancelled {count} running script(s)")

        # Save configuration
        try:
            self.config.save(self.config_path)
            logger.info("Configuration saved")
        except Exception as e:
            logger.error(f"Failed to save configuration: {e}")

        logger.info("Application shutdown complete")


def main() -> None:
    """Main entry point."""
    app = Application()
    app.run()


if __name__ == "__main__":
    main()
