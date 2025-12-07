"""Main application window using CustomTkinter."""

import customtkinter as ctk
from pathlib import Path
from tkinter import messagebox # CTk doesn't have a message box, standard is fine or use CTkMessagebox if available (not standard)
# Actually, sticking to tk.messagebox is the safest "standard" way even with CTk, though it looks native/os-styled.

from loguru import logger

from ..config import AppConfig
from ..models import Script, ScriptExecution
from ..script_executor import ScriptExecutor
from ..script_manager import ScriptManager
from .components import ModernButton, OutputConsole, ScriptCard, SearchBar, StatusBar
from .theme import Theme
import tkinter as tk # for mixins if needed

class MainWindow:
    """Main application window."""

    def __init__(
        self,
        root: ctk.CTk,
        config: AppConfig,
        script_manager: ScriptManager,
        script_executor: ScriptExecutor,
    ):
        self.root = root
        self.config = config
        self.script_manager = script_manager
        self.script_executor = script_executor

        # Setup window
        self._setup_window()
        self._create_ui()

        # Load scripts
        self.refresh_scripts()

        logger.info("Main window initialized")

    def _setup_window(self) -> None:
        """Setup window properties."""
        self.root.title("Script Launcher") # Senior UI title

        # Set window size
        width = self.config.window.width
        height = self.config.window.height

        # Center window
        screen_width = self.root.winfo_screenwidth()
        screen_height = self.root.winfo_screenheight()
        x = (screen_width - width) // 2
        y = (screen_height - height) // 2

        self.root.geometry(f"{width}x{height}+{x}+{y}")
        self.root.minsize(800, 600) # Slightly larger for senior feel

        # Configure background
        # CTk handles this by default for "Dark" mode, but we can enforce
        # self.root.configure(fg_color=Theme.colors.bg_primary)

        # Handle window close
        self.root.protocol("WM_DELETE_WINDOW", self._on_closing)

    def _create_ui(self) -> None:
        """Create the user interface."""
        
        # Main Grid Layout
        self.root.grid_columnconfigure(0, weight=1)
        self.root.grid_rowconfigure(2, weight=1) # Scripts area expands

        # 1. Header (Title + Controls?)
        self._create_header(row=0)

        # 2. Search Bar
        self._create_search_bar(row=1)

        # 3. Scripts Area (Scrollable)
        self._create_scripts_area(row=2)

        # 4. Controls (Bottom actions)
        self._create_controls(row=3)

        # 5. Status Bar
        self.status_bar = StatusBar(self.root)
        self.status_bar.grid(row=4, column=0, sticky="ew")

    def _create_header(self, row: int) -> None:
        """Create header section."""
        header_frame = ctk.CTkFrame(self.root, fg_color="transparent")
        header_frame.grid(row=row, column=0, sticky="ew", padx=20, pady=(20, 10))
        
        # Title
        title = ctk.CTkLabel(
            header_frame,
            text="Script Launcher",
            font=(Theme.fonts.family, Theme.fonts.size_title, "bold"),
            text_color=Theme.colors.text_primary
        )
        title.pack(side="left")

    def _create_search_bar(self, row: int) -> None:
        """Create search bar."""
        search_frame = ctk.CTkFrame(self.root, fg_color="transparent")
        search_frame.grid(row=row, column=0, sticky="ew", padx=20, pady=(0, 10))
        
        self.search_bar = SearchBar(
            search_frame,
            on_search=self._on_search,
            width=400 # Fixed width for clean look? Or expand? Let's expand
        )
        self.search_bar.pack(fill="x")

    def _create_scripts_area(self, row: int) -> None:
        """Create scrollable scripts display area."""
        
        # CTkScrollableFrame allows easy scrolling without canvas hell
        self.scripts_container = ctk.CTkScrollableFrame(
            self.root,
            label_text="Available Scripts",
            label_font=(Theme.fonts.family, Theme.fonts.size_normal, "bold"),
            fg_color=Theme.colors.bg_secondary,  # Container bg
            label_fg_color=Theme.colors.bg_primary # Match parent
        )
        self.scripts_container.grid(row=row, column=0, sticky="nsew", padx=20, pady=(0, 10))
        
        # Grid inside scrollable frame
        self.scripts_container.grid_columnconfigure(0, weight=1)

    def _create_controls(self, row: int) -> None:
        """Create control buttons."""
        control_frame = ctk.CTkFrame(self.root, fg_color="transparent")
        control_frame.grid(row=row, column=0, sticky="ew", padx=20, pady=(0, 10))
        
        # Refresh
        refresh_btn = ModernButton(
            control_frame,
            text="Refresh",
            command=self.refresh_scripts,
            fg_color=Theme.colors.bg_secondary,
            hover_color=Theme.colors.bg_tertiary
        )
        refresh_btn.pack(side="left", padx=(0, 10))

        # Open Folder
        open_btn = ModernButton(
            control_frame,
            text="Open Folder",
            command=self._open_scripts_folder,
            fg_color=Theme.colors.bg_secondary,
            hover_color=Theme.colors.bg_tertiary
        )
        open_btn.pack(side="left", padx=(0, 10))

        # Stop All
        self.stop_btn = ModernButton(
            control_frame,
            text="Stop All",
            command=self._stop_all_scripts,
            fg_color=Theme.colors.error, # Red for danger
            hover_color="#c0392b",
            state="disabled"
        )
        self.stop_btn.pack(side="right")

    def refresh_scripts(self) -> None:
        """Refresh the scripts list."""
        logger.info("Refreshing scripts")

        # Clear existing
        for widget in self.scripts_container.winfo_children():
            widget.destroy()

        # Discover
        scripts = self.script_manager.discover_scripts()

        if not scripts:
            empty_label = ctk.CTkLabel(
                self.scripts_container,
                text="No scripts found.",
                text_color=Theme.colors.text_tertiary
            )
            empty_label.pack(pady=20)
        else:
            for i, script in enumerate(sorted(scripts, key=lambda s: (s.category, s.name))):
                card = ScriptCard(
                    self.scripts_container,
                    script=script,
                    on_run=self._run_script
                )
                card.grid(row=i, column=0, sticky="ew", pady=4, padx=5)

        self.status_bar.set_status(f"Found {len(scripts)} scripts")

    def _run_script(self, script: Script) -> None:
        logger.info(f"Running script: {script.name}")

        if self.script_executor.is_running(script):
            messagebox.showinfo("Already Running", f"'{script.name}' is already running!")
            return

        self.script_executor.execute_script(
            script, output_callback=None, completion_callback=self._on_completion
        )
        self._update_execution_status()

    def _on_completion(self, execution: ScriptExecution) -> None:
        logger.info(f"Script completed: {execution.script.name}")
        # Need to schedule UI update on main thread? 
        # Tkinter is not thread safe. 
        # Usually logic calls callback from thread. 
        # CTk/Tk requires after() for thread safety.
        self.root.after(0, self._update_execution_status)

    def _update_execution_status(self) -> None:
        count = self.script_executor.get_active_count()
        if count > 0:
            self.status_bar.set_status(f"Running {count} scripts...", Theme.colors.warning)
            self.stop_btn.configure(state="normal")
        else:
            self.status_bar.set_status("Ready", Theme.colors.success)
            self.stop_btn.configure(state="disabled")

    def _stop_all_scripts(self) -> None:
        count = self.script_executor.get_active_count()
        if count == 0: return

        if messagebox.askyesno("Stop Scripts", f"Stop {count} running script(s)?"):
            self.script_executor.cancel_all()
            self._update_execution_status()

    def _open_scripts_folder(self) -> None:
        import os
        import subprocess
        import sys
        try:
            if os.name == "nt":
                os.startfile(str(self.script_manager.scripts_dir))
            elif sys.platform == "darwin":
                subprocess.run(["open", str(self.script_manager.scripts_dir)])
            else:
                subprocess.run(["xdg-open", str(self.script_manager.scripts_dir)])
        except Exception as e:
            logger.error(f"Failed to open folder: {e}")

    def _on_search(self, query: str) -> None:
        # Clear
        for widget in self.scripts_container.winfo_children():
            widget.destroy()

        if query:
            scripts = self.script_manager.filter_scripts(query=query)
        else:
            scripts = self.script_manager.get_all_scripts()

        for i, script in enumerate(sorted(scripts, key=lambda s: s.name)):
            card = ScriptCard(
                self.scripts_container,
                script=script,
                on_run=self._run_script
            )
            card.grid(row=i, column=0, sticky="ew", pady=4, padx=5)

    def _on_closing(self) -> None:
        if self.script_executor.get_active_count() > 0:
            if not messagebox.askyesno("Scripts Running", "Scripts are still running. Exit anyway?"):
                return
        
        # Save config... (omitted implementation for brevity, assuming existing logic or not strictly needed for UI task)
        # Actually I should call config save if it was there.
        # Looking at previous file: yes, it saved config.
        try:
            config_path = Path(self.script_manager.scripts_dir).parent / "config.json"
            self.config.save(config_path)
        except Exception as e:
            logger.error(f"Failed to save config: {e}")

        self.script_executor.cancel_all()
        self.root.destroy()
