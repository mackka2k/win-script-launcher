"""Main application window."""

import tkinter as tk
from pathlib import Path
from tkinter import messagebox, ttk

from loguru import logger

from ..config import AppConfig
from ..models import Script, ScriptExecution
from ..script_executor import ScriptExecutor
from ..script_manager import ScriptManager
from .components import ModernButton, OutputConsole, ScriptCard, SearchBar, StatusBar
from .theme import Theme


class MainWindow:
    """Main application window."""

    def __init__(
        self,
        root: tk.Tk,
        config: AppConfig,
        script_manager: ScriptManager,
        script_executor: ScriptExecutor,
    ):
        """
        Initialize main window.

        Args:
            root: Root Tk window
            config: Application configuration
            script_manager: Script manager instance
            script_executor: Script executor instance
        """
        self.root = root
        self.config = config
        self.script_manager = script_manager
        self.script_executor = script_executor

        # Initialize theme
        self.theme = Theme(mode=config.theme.mode)

        # Setup window
        self._setup_window()
        self._create_ui()

        # Load scripts
        self.refresh_scripts()

        logger.info("Main window initialized")

    def _setup_window(self) -> None:
        """Setup window properties."""
        self.root.title("Script Launcher")

        # Set window size
        width = self.config.window.width
        height = self.config.window.height

        # Center window
        screen_width = self.root.winfo_screenwidth()
        screen_height = self.root.winfo_screenheight()
        x = (screen_width - width) // 2
        y = (screen_height - height) // 2

        self.root.geometry(f"{width}x{height}+{x}+{y}")
        self.root.minsize(700, 500)

        # Configure colors
        self.root.configure(bg=self.theme.colors.bg_secondary)

        # Handle window close
        self.root.protocol("WM_DELETE_WINDOW", self._on_closing)

    def _create_ui(self) -> None:
        """Create the user interface."""
        # Main container
        main_frame = tk.Frame(self.root, bg=self.theme.colors.bg_secondary)
        main_frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        # Header
        self._create_header(main_frame)

        # Search bar
        self._create_search_bar(main_frame)

        # Scripts area
        self._create_scripts_area(main_frame)

        # Output area
        self._create_output_area(main_frame)

        # Control buttons
        self._create_controls(main_frame)

        # Status bar
        self.status_bar = StatusBar(self.root, bg=self.theme.colors.bg_secondary)
        self.status_bar.pack(side=tk.BOTTOM, fill=tk.X)

    def _create_header(self, parent: tk.Frame) -> None:
        """Create header section."""
        header_frame = tk.Frame(parent, bg=self.theme.colors.bg_secondary)
        header_frame.pack(fill=tk.X, pady=(0, 10))

        # Title
        title = tk.Label(
            header_frame,
            text="Script Launcher",
            font=(self.theme.fonts.family, self.theme.fonts.size_title, "bold"),
            bg=self.theme.colors.bg_secondary,
            fg=self.theme.colors.text_primary,
        )
        title.pack(side=tk.LEFT)

    def _create_search_bar(self, parent: tk.Frame) -> None:
        """Create search bar."""
        self.search_bar = SearchBar(
            parent,
            on_search=self._on_search,
            bg=self.theme.colors.bg_primary,
            relief=tk.SOLID,
            bd=1,
        )
        self.search_bar.pack(fill=tk.X, pady=(0, 10))

    def _create_scripts_area(self, parent: tk.Frame) -> None:
        """Create scripts display area."""
        # Frame
        scripts_frame = tk.LabelFrame(
            parent,
            text="Available Scripts",
            font=(self.theme.fonts.family, self.theme.fonts.size_normal, "bold"),
            bg=self.theme.colors.bg_secondary,
            fg=self.theme.colors.text_primary,
            relief=tk.SOLID,
            bd=1,
        )
        scripts_frame.pack(fill=tk.BOTH, expand=False, pady=(0, 10))

        # Scrollable canvas
        canvas = tk.Canvas(
            scripts_frame,
            height=200,
            bg=self.theme.colors.bg_secondary,
            highlightthickness=0,
            bd=0,
        )
        scrollbar = ttk.Scrollbar(scripts_frame, orient=tk.VERTICAL, command=canvas.yview)

        self.scripts_container = tk.Frame(canvas, bg=self.theme.colors.bg_secondary)

        self.scripts_container.bind(
            "<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all"))
        )

        canvas.create_window((0, 0), window=self.scripts_container, anchor=tk.NW)
        canvas.configure(yscrollcommand=scrollbar.set)

        canvas.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=5, pady=5)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        # Mouse wheel scrolling
        canvas.bind_all("<MouseWheel>", lambda e: canvas.yview_scroll(-1 * (e.delta // 120), "units"))

    def _create_output_area(self, parent: tk.Frame) -> None:
        """Create output console area."""
        output_frame = tk.LabelFrame(
            parent,
            text="Output",
            font=(self.theme.fonts.family, self.theme.fonts.size_normal, "bold"),
            bg=self.theme.colors.bg_secondary,
            fg=self.theme.colors.text_primary,
            relief=tk.SOLID,
            bd=1,
        )
        output_frame.pack(fill=tk.BOTH, expand=True, pady=(0, 10))

        # Output console
        self.output_console = OutputConsole(
            output_frame, theme_colors=self.theme.get_output_style(), height=12
        )
        self.output_console.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

    def _create_controls(self, parent: tk.Frame) -> None:
        """Create control buttons."""
        control_frame = tk.Frame(parent, bg=self.theme.colors.bg_secondary)
        control_frame.pack(fill=tk.X)

        # Refresh button
        refresh_btn = ModernButton(
            control_frame,
            text="🔄 Refresh",
            command=self.refresh_scripts,
            style_dict=self.theme.get_button_style(),
            padx=10,
            pady=5,
        )
        refresh_btn.pack(side=tk.LEFT, padx=2)

        # Clear output button
        clear_btn = ModernButton(
            control_frame,
            text="🗑️ Clear Output",
            command=self._clear_output,
            style_dict=self.theme.get_button_style(),
            padx=10,
            pady=5,
        )
        clear_btn.pack(side=tk.LEFT, padx=2)

        # Copy output button
        copy_btn = ModernButton(
            control_frame,
            text="📋 Copy Output",
            command=self._copy_output,
            style_dict=self.theme.get_button_style(),
            padx=10,
            pady=5,
        )
        copy_btn.pack(side=tk.LEFT, padx=2)

        # Open folder button
        open_btn = ModernButton(
            control_frame,
            text="📁 Open Folder",
            command=self._open_scripts_folder,
            style_dict=self.theme.get_button_style(),
            padx=10,
            pady=5,
        )
        open_btn.pack(side=tk.LEFT, padx=2)

        # Stop button
        self.stop_btn = ModernButton(
            control_frame,
            text="⏹️ Stop All",
            command=self._stop_all_scripts,
            style_dict=self.theme.get_button_style(),
            padx=10,
            pady=5,
            state=tk.DISABLED,
        )
        self.stop_btn.pack(side=tk.LEFT, padx=2)

    def refresh_scripts(self) -> None:
        """Refresh the scripts list."""
        logger.info("Refreshing scripts")

        # Clear existing cards
        for widget in self.scripts_container.winfo_children():
            widget.destroy()

        # Discover scripts
        scripts = self.script_manager.discover_scripts()

        if not scripts:
            # Show empty state
            empty_label = tk.Label(
                self.scripts_container,
                text="No scripts found. Add .py, .bat, .ps1, or .cmd files to the scripts folder.",
                font=(self.theme.fonts.family, self.theme.fonts.size_normal),
                bg=self.theme.colors.bg_secondary,
                fg=self.theme.colors.text_tertiary,
            )
            empty_label.pack(pady=20)
        else:
            # Display scripts as vertical list (Details view style)
            for script in sorted(scripts, key=lambda s: (s.category, s.name)):
                card = ScriptCard(
                    self.scripts_container,
                    script=script,
                    on_run=self._run_script,
                    theme_colors={
                        "bg": self.theme.colors.bg_primary,
                        "fg": self.theme.colors.text_secondary,
                        "accent": self.theme.colors.accent,
                    },
                )
                card.pack(fill=tk.X, padx=2, pady=1)

        self.status_bar.set_status(f"Found {len(scripts)} script(s)", self.theme.colors.success)


    def _run_script(self, script: Script) -> None:
        """Run a script."""
        logger.info(f"Running script: {script.name}")

        # Check if already running
        if self.script_executor.is_running(script):
            messagebox.showinfo("Already Running", f"'{script.name}' is already running!")
            return

        # Update UI
        self.output_console.append(f"\n{'=' * 60}\n")
        self.output_console.append(f"Running: {script.name}\n", "info")
        self.output_console.append(f"{'=' * 60}\n")

        # Execute script
        self.script_executor.execute_script(
            script, output_callback=self._on_output, completion_callback=self._on_completion
        )

        # Update status
        self._update_execution_status()

    def _on_output(self, line: str) -> None:
        """Handle script output."""
        # Determine tag based on content
        tag = None
        if "[STDERR]" in line or "error" in line.lower():
            tag = "error"
        elif "success" in line.lower() or "✓" in line:
            tag = "success"
        elif "warning" in line.lower() or "⚠" in line:
            tag = "warning"

        self.output_console.append(line, tag)

    def _on_completion(self, execution: ScriptExecution) -> None:
        """Handle script completion."""
        logger.info(f"Script completed: {execution.script.name} - {execution.status.value}")

        # Show completion message
        if execution.status.name == "SUCCESS":
            self.output_console.append("\n✓ Script completed successfully!\n", "success")
        elif execution.status.name == "FAILED":
            self.output_console.append(
                f"\n✗ Script failed: {execution.error_message}\n", "error"
            )
        elif execution.status.name == "TIMEOUT":
            self.output_console.append("\n⏱️ Script timed out!\n", "warning")
        elif execution.status.name == "CANCELLED":
            self.output_console.append("\n⏹️ Script cancelled!\n", "warning")

        # Update status
        self._update_execution_status()

    def _update_execution_status(self) -> None:
        """Update execution status in UI."""
        count = self.script_executor.get_active_count()

        if count > 0:
            self.status_bar.set_status(f"Running {count} script(s)...", self.theme.colors.warning)
            self.stop_btn.config(state=tk.NORMAL)
        else:
            self.status_bar.set_status("Ready", self.theme.colors.success)
            self.stop_btn.config(state=tk.DISABLED)

    def _stop_all_scripts(self) -> None:
        """Stop all running scripts."""
        count = self.script_executor.get_active_count()

        if count == 0:
            return

        if messagebox.askyesno("Stop Scripts", f"Stop {count} running script(s)?"):
            stopped = self.script_executor.cancel_all()
            logger.info(f"Stopped {stopped} script(s)")
            self.output_console.append(f"\n⏹️ Stopped {stopped} script(s)\n", "warning")

    def _clear_output(self) -> None:
        """Clear output console."""
        self.output_console.clear()

    def _copy_output(self) -> None:
        """Copy output console content to clipboard."""
        try:
            # Get all text from the output console
            output_text = self.output_console.get("1.0", tk.END)
            
            # Copy to clipboard
            self.root.clipboard_clear()
            self.root.clipboard_append(output_text)
            self.root.update()  # Required for clipboard to work
            
            # Show confirmation in status bar
            self.status_bar.set_status("Output copied to clipboard!", self.theme.colors.success)
            logger.info("Output copied to clipboard")
        except Exception as e:
            logger.error(f"Failed to copy output: {e}")
            messagebox.showerror("Error", f"Failed to copy output:\n{e}")

    def _open_scripts_folder(self) -> None:
        """Open scripts folder in file explorer."""
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
            messagebox.showerror("Error", f"Failed to open folder:\n{e}")

    def _on_search(self, query: str) -> None:
        """Handle search query."""
        logger.debug(f"Search query: {query}")

        # Clear existing cards
        for widget in self.scripts_container.winfo_children():
            widget.destroy()

        # Filter scripts
        if query:
            scripts = self.script_manager.filter_scripts(query=query)
        else:
            scripts = self.script_manager.get_all_scripts()

        # Display filtered scripts
        for script in sorted(scripts, key=lambda s: s.name):
            card = ScriptCard(
                self.scripts_container,
                script=script,
                on_run=self._run_script,
                theme_colors={
                    "bg": self.theme.colors.bg_primary,
                    "fg": self.theme.colors.text_secondary,
                    "accent": self.theme.colors.accent,
                },
            )
            card.pack(fill=tk.X, padx=5, pady=3)

    def _on_closing(self) -> None:
        """Handle window closing."""
        # Check for running scripts
        if self.script_executor.get_active_count() > 0:
            if not messagebox.askyesno(
                "Scripts Running", "Scripts are still running. Exit anyway?"
            ):
                return

        # Save config
        try:
            config_path = Path(self.script_manager.scripts_dir).parent / "config.json"
            self.config.save(config_path)
        except Exception as e:
            logger.error(f"Failed to save config: {e}")

        # Stop all scripts
        self.script_executor.cancel_all()

        # Close window
        self.root.destroy()
