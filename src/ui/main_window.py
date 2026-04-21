"""Main application window."""

from __future__ import annotations

import os
import subprocess
import sys
from collections.abc import Callable
from pathlib import Path
from tkinter import messagebox

import customtkinter as ctk
from loguru import logger

from ..config import AppConfig
from ..exceptions import ScriptLauncherError, ValidationError
from ..models import ExecutionStatus, Script, ScriptExecution
from ..script_executor import ScriptExecutor
from ..script_manager import ScriptManager
from .components import (
    ModernButton,
    OutputConsole,
    ScriptCard,
    SearchBar,
    StatusBar,
)
from .theme import Theme

STATUS_TAGS = {
    ExecutionStatus.SUCCESS: ("success", "OK"),
    ExecutionStatus.FAILED: ("error", "FAILED"),
    ExecutionStatus.TIMEOUT: ("warning", "TIMEOUT"),
    ExecutionStatus.CANCELLED: ("muted", "CANCELLED"),
}


class MainWindow:
    """Main application window.

    The window owns all UI state. Callbacks from background threads are
    marshalled to the Tk main loop via :meth:`_on_main_thread`.
    """

    def __init__(
        self,
        root: ctk.CTk,
        config: AppConfig,
        script_manager: ScriptManager,
        script_executor: ScriptExecutor,
        on_close: Callable[[], None] | None = None,
    ) -> None:
        self.root = root
        self.config = config
        self.script_manager = script_manager
        self.script_executor = script_executor
        self._on_close_callback = on_close

        self._cards: dict[Path, ScriptCard] = {}
        self._scripts: list[Script] = []

        self._build_ui()
        self.refresh_scripts()
        logger.debug("Main window ready")

    # --- Public --------------------------------------------------------

    def refresh_scripts(self) -> None:
        """Re-discover scripts and rebuild the card list."""
        logger.debug("Refreshing scripts")
        self._scripts = self.script_manager.discover_scripts()
        self._render_scripts(self._scripts)
        self.status_bar.set_right(f"{len(self._scripts)} scripts")

    # --- Internal: layout ---------------------------------------------

    def _build_ui(self) -> None:
        self.root.title("Script Launcher")
        width = self.config.window.width
        height = self.config.window.height
        screen_w = self.root.winfo_screenwidth()
        screen_h = self.root.winfo_screenheight()
        x = max(0, (screen_w - width) // 2)
        y = max(0, (screen_h - height) // 2)
        self.root.geometry(f"{width}x{height}+{x}+{y}")
        self.root.minsize(820, 560)
        self.root.protocol("WM_DELETE_WINDOW", self._on_closing)

        self.root.grid_columnconfigure(0, weight=1)
        self.root.grid_rowconfigure(2, weight=1)

        self._build_header(row=0)
        self._build_search(row=1)
        self._build_body(row=2)
        self._build_controls(row=3)

        self.status_bar = StatusBar(self.root)
        self.status_bar.grid(row=4, column=0, sticky="ew")

    def _build_header(self, row: int) -> None:
        frame = ctk.CTkFrame(self.root, fg_color="transparent")
        frame.grid(row=row, column=0, sticky="ew", padx=20, pady=(18, 8))
        ctk.CTkLabel(
            frame,
            text="Script Launcher",
            font=(Theme.fonts.family, Theme.fonts.size_title, "bold"),
            text_color=Theme.colors.text_primary,
        ).pack(side="left")

    def _build_search(self, row: int) -> None:
        frame = ctk.CTkFrame(self.root, fg_color="transparent")
        frame.grid(row=row, column=0, sticky="ew", padx=20, pady=(0, 10))
        self.search_bar = SearchBar(frame, on_search=self._on_search)
        self.search_bar.pack(fill="x")

    def _build_body(self, row: int) -> None:
        body = ctk.CTkFrame(self.root, fg_color="transparent")
        body.grid(row=row, column=0, sticky="nsew", padx=20, pady=(0, 10))
        body.grid_columnconfigure(0, weight=3, uniform="body")
        body.grid_columnconfigure(1, weight=2, uniform="body")
        body.grid_rowconfigure(0, weight=1)

        self.scripts_container = ctk.CTkScrollableFrame(
            body,
            label_text="Available Scripts",
            label_font=(Theme.fonts.family, Theme.fonts.size_normal, "bold"),
            fg_color=Theme.colors.bg_secondary,
            label_fg_color=Theme.colors.bg_tertiary,
        )
        self.scripts_container.grid(row=0, column=0, sticky="nsew", padx=(0, 8))
        self.scripts_container.grid_columnconfigure(0, weight=1)

        output_frame = ctk.CTkFrame(body, fg_color="transparent")
        output_frame.grid(row=0, column=1, sticky="nsew", padx=(8, 0))
        output_frame.grid_rowconfigure(1, weight=1)
        output_frame.grid_columnconfigure(0, weight=1)

        header = ctk.CTkFrame(output_frame, fg_color="transparent")
        header.grid(row=0, column=0, sticky="ew", pady=(0, 6))
        ctk.CTkLabel(
            header,
            text="Output",
            font=(Theme.fonts.family, Theme.fonts.size_normal, "bold"),
            text_color=Theme.colors.text_primary,
        ).pack(side="left")
        ModernButton(
            header,
            text="Clear",
            command=self._clear_output,
            fg_color=Theme.colors.bg_secondary,
            hover_color=Theme.colors.bg_hover,
            width=72,
        ).pack(side="right")

        self.output_console = OutputConsole(output_frame)
        self.output_console.grid(row=1, column=0, sticky="nsew")

    def _build_controls(self, row: int) -> None:
        frame = ctk.CTkFrame(self.root, fg_color="transparent")
        frame.grid(row=row, column=0, sticky="ew", padx=20, pady=(0, 10))

        ModernButton(
            frame,
            text="Refresh",
            command=self.refresh_scripts,
            fg_color=Theme.colors.bg_secondary,
            hover_color=Theme.colors.bg_hover,
        ).pack(side="left", padx=(0, 8))

        ModernButton(
            frame,
            text="Open Folder",
            command=self._open_scripts_folder,
            fg_color=Theme.colors.bg_secondary,
            hover_color=Theme.colors.bg_hover,
        ).pack(side="left", padx=(0, 8))

        self.stop_all_btn = ModernButton(
            frame,
            text="Stop All",
            command=self._stop_all_scripts,
            fg_color=Theme.colors.error,
            hover_color="#c0392b",
            state="disabled",
        )
        self.stop_all_btn.pack(side="right")

    # --- Internal: rendering ------------------------------------------

    def _render_scripts(self, scripts: list[Script]) -> None:
        for card in self._cards.values():
            card.destroy()
        self._cards.clear()

        if not scripts:
            ctk.CTkLabel(
                self.scripts_container,
                text="No scripts found.\nDrop a .py, .bat, .cmd or .ps1 into the scripts/ folder.",
                text_color=Theme.colors.text_tertiary,
                justify="center",
            ).grid(row=0, column=0, pady=24)
            return

        ordered = sorted(scripts, key=lambda s: (s.category.lower(), s.name.lower()))
        for i, script in enumerate(ordered):
            card = ScriptCard(
                self.scripts_container,
                script=script,
                on_run=self._run_script,
                on_cancel=self._cancel_script,
            )
            card.grid(row=i, column=0, sticky="ew", pady=4, padx=6)
            self._cards[script.path] = card
            if self.script_executor.is_running(script):
                card.set_running(True)

    # --- Internal: actions --------------------------------------------

    def _run_script(self, script: Script) -> None:
        logger.info(f"Running script: {script.name}")

        try:
            self.script_manager.validate_script(script)
        except ValidationError as e:
            logger.error(f"Validation failed: {e}")
            messagebox.showerror("Cannot run script", str(e))
            return

        if self.script_executor.is_running(script):
            messagebox.showinfo(
                "Already running", f"'{script.name}' is already running."
            )
            return

        card = self._cards.get(script.path)
        if card is not None:
            card.set_running(True)

        self.output_console.append(f"\n>>> {script.name}\n", tag="info")

        try:
            self.script_executor.execute_script(
                script,
                output_callback=self._on_output,
                completion_callback=self._on_completion,
            )
        except ScriptLauncherError as e:
            logger.error(f"Failed to start script: {e}")
            messagebox.showerror("Execution failed", str(e))
            if card is not None:
                card.set_running(False)
            return

        self._update_execution_status()

    def _cancel_script(self, script: Script) -> None:
        if messagebox.askyesno(
            "Cancel script", f"Cancel '{script.name}'?"
        ):
            self.script_executor.cancel_execution(script)

    def _stop_all_scripts(self) -> None:
        count = self.script_executor.get_active_count()
        if count == 0:
            return
        if messagebox.askyesno(
            "Stop scripts", f"Stop {count} running script(s)?"
        ):
            self.script_executor.cancel_all()
            self._update_execution_status()

    def _open_scripts_folder(self) -> None:
        folder = self.script_manager.scripts_dir
        try:
            if os.name == "nt":
                os.startfile(str(folder))  # type: ignore[attr-defined]
            elif sys.platform == "darwin":
                subprocess.run(["open", str(folder)], check=False)
            else:
                subprocess.run(["xdg-open", str(folder)], check=False)
        except OSError as e:
            logger.error(f"Failed to open folder: {e}")
            messagebox.showerror("Open folder", f"Could not open folder:\n{e}")

    def _clear_output(self) -> None:
        self.output_console.clear()

    # --- Internal: callbacks ------------------------------------------

    def _on_output(self, line: str) -> None:
        # Called from worker thread – marshal to Tk main loop.
        self._on_main_thread(lambda: self.output_console.append(line))

    def _on_completion(self, execution: ScriptExecution) -> None:
        self._on_main_thread(lambda: self._handle_completion(execution))

    def _handle_completion(self, execution: ScriptExecution) -> None:
        tag, label = STATUS_TAGS.get(execution.status, ("muted", execution.status.name))
        duration = execution.duration
        summary = f"<<< {execution.script.name} [{label}]"
        if duration is not None:
            summary += f" ({duration:.2f}s)"
        if execution.error_message:
            summary += f" {execution.error_message}"
        self.output_console.append(summary + "\n", tag=tag)

        card = self._cards.get(execution.script.path)
        if card is not None:
            card.set_running(False)
        self._update_execution_status()

    def _on_search(self, query: str) -> None:
        filtered = (
            self._scripts
            if not query
            else self.script_manager.filter_scripts(query=query)
        )
        self._render_scripts(filtered)

    def _update_execution_status(self) -> None:
        count = self.script_executor.get_active_count()
        if count > 0:
            self.status_bar.set_status(
                f"Running {count} script(s)...", color=Theme.colors.warning
            )
            self.stop_all_btn.configure(state="normal")
        else:
            self.status_bar.set_status("Ready", color=Theme.colors.success)
            self.stop_all_btn.configure(state="disabled")

    def _on_closing(self) -> None:
        if self.script_executor.get_active_count() > 0 and not messagebox.askyesno(
            "Scripts running",
            "Scripts are still running. Exit anyway?",
        ):
            return
        if self._on_close_callback is not None:
            try:
                self._on_close_callback()
            except Exception:  # noqa: BLE001
                logger.exception("on_close callback raised")
        self.root.destroy()

    def _on_main_thread(self, fn: Callable[[], None]) -> None:
        try:
            self.root.after(0, fn)
        except RuntimeError:
            # Tk root has been destroyed; drop the event.
            logger.debug("Dropped UI event after root destroyed")
