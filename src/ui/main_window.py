"""Main application window."""

from __future__ import annotations

import os
import subprocess
import sys
import threading
from collections.abc import Callable
from pathlib import Path
from tkinter import messagebox

import customtkinter as ctk
from loguru import logger

from ..config import AppConfig
from ..exceptions import ScriptLauncherError, ValidationError
from ..models import ExecutionStatus, RiskLevel, Script, ScriptExecution
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

    _OUTPUT_FLUSH_MS = 50

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
        self._empty_label: ctk.CTkLabel | None = None
        self._scripts: list[Script] = []
        self._selected_script: Script | None = None
        self._output_buffer: list[tuple[str, str | None]] = []
        self._output_lock = threading.Lock()
        self._output_flush_scheduled = False

        self._build_ui()
        self.refresh_scripts()
        logger.debug("Main window ready")

    # --- Public --------------------------------------------------------

    def refresh_scripts(self) -> None:
        """Re-discover scripts and rebuild the card list."""
        logger.debug("Refreshing scripts")
        self._scripts = self.script_manager.discover_scripts()
        self._render_scripts(self._scripts)
        self.status_bar.set_right(self._script_summary(self._scripts))

    def snapshot_geometry(self) -> None:
        """Copy the current window size/position into ``self.config.window``.

        Called before persisting config so ``remember_size`` /
        ``remember_position`` survive restarts. Silently no-ops if the root
        window has already been destroyed.
        """
        window_cfg = self.config.window
        try:
            self.root.update_idletasks()
            width = self.root.winfo_width()
            height = self.root.winfo_height()
            x = self.root.winfo_x()
            y = self.root.winfo_y()
        except Exception:  # noqa: BLE001 - Tk may be torn down
            return

        if window_cfg.remember_size and width > 0 and height > 0:
            window_cfg.width = width
            window_cfg.height = height
        if window_cfg.remember_position:
            window_cfg.last_x = x
            window_cfg.last_y = y

    # --- Internal: layout ---------------------------------------------

    def _build_ui(self) -> None:
        self.root.title("Script Launcher")
        width, height, x, y = self._initial_geometry()
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

    def _initial_geometry(self) -> tuple[int, int, int, int]:
        """Compute ``(width, height, x, y)`` for the initial window placement.

        Restores the saved position when ``remember_position`` is enabled and
        the saved ``(x, y)`` still lands on the current desktop. Otherwise
        the window is centered. Size always comes from ``config.window``
        (which is updated on close when ``remember_size`` is true).
        """
        window_cfg = self.config.window
        screen_w = self.root.winfo_screenwidth()
        screen_h = self.root.winfo_screenheight()

        width = window_cfg.width
        height = window_cfg.height

        saved_x = window_cfg.last_x
        saved_y = window_cfg.last_y
        if (
            window_cfg.remember_position
            and saved_x is not None
            and saved_y is not None
            and 0 <= saved_x <= max(0, screen_w - 100)
            and 0 <= saved_y <= max(0, screen_h - 100)
        ):
            return width, height, saved_x, saved_y

        x = max(0, (screen_w - width) // 2)
        y = max(0, (screen_h - height) // 2)
        return width, height, x, y

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
            corner_radius=0,
            border_width=1,
            border_color=Theme.colors.border,
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

        self.input_frame = ctk.CTkFrame(output_frame, fg_color="transparent")
        self.input_frame.grid(row=2, column=0, sticky="ew", pady=(8, 0))
        self.input_frame.grid_columnconfigure(0, weight=1)

        self.input_entry = ctk.CTkEntry(
            self.input_frame,
            placeholder_text="Type input for the running script...",
            font=(Theme.fonts.family, Theme.fonts.size_normal),
            height=34,
            fg_color=Theme.colors.bg_secondary,
            border_width=1,
            border_color=Theme.colors.border,
            corner_radius=0,
            state="disabled",
        )
        self.input_entry.grid(row=0, column=0, sticky="ew", padx=(0, 8))
        self.input_entry.bind("<Return>", self._send_input)

        self.input_send_btn = ModernButton(
            self.input_frame,
            text="Send",
            command=self._send_input,
            fg_color=Theme.colors.bg_secondary,
            hover_color=Theme.colors.bg_hover,
            width=72,
            state="disabled",
        )
        self.input_send_btn.grid(row=0, column=1)

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
            text_color="#ffffff",
            state="disabled",
        )
        self.stop_all_btn.pack(side="right")

    # --- Internal: rendering ------------------------------------------

    def _render_scripts(self, scripts: list[Script]) -> None:
        known_paths = {script.path for script in self._scripts}
        for path in list(self._cards):
            if path not in known_paths:
                self._cards[path].destroy()
                self._cards.pop(path)

        if not scripts:
            for card in self._cards.values():
                card.grid_remove()
            self._show_empty_scripts_label()
            return

        self._hide_empty_scripts_label()
        ordered = sorted(scripts, key=lambda s: (s.category.lower(), s.name.lower()))
        visible_paths = {script.path for script in ordered}
        for i, script in enumerate(ordered):
            card = self._cards.get(script.path)
            if card is None:
                card = ScriptCard(
                    self.scripts_container,
                    script=script,
                    on_run=self._run_script,
                    on_cancel=self._cancel_script,
                    on_select=self._select_script,
                )
                self._cards[script.path] = card
            else:
                card.update_script(script)
            card.grid(row=i, column=0, sticky="ew", pady=4, padx=6)
            if self.script_executor.is_running(script):
                card.set_running(True)
        for path, card in self._cards.items():
            if path not in visible_paths:
                card.grid_remove()

    def _select_script(self, script: Script) -> None:
        self._selected_script = script

    def _show_empty_scripts_label(self) -> None:
        if self._empty_label is None:
            self._empty_label = ctk.CTkLabel(
                self.scripts_container,
                text="No scripts found.\nDrop a .py, .bat, .cmd or .ps1 into the scripts/ folder.",
                text_color=Theme.colors.text_tertiary,
                justify="center",
            )
        self._empty_label.grid(row=0, column=0, pady=24)

    def _hide_empty_scripts_label(self) -> None:
        if self._empty_label is not None:
            self._empty_label.grid_remove()

    @staticmethod
    def _script_summary(scripts: list[Script]) -> str:
        destructive = sum(1 for script in scripts if script.risk_level is RiskLevel.DESTRUCTIVE)
        admin = sum(1 for script in scripts if script.requires_admin)
        return f"{len(scripts)} scripts | {destructive} destructive | {admin} admin"

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
            messagebox.showinfo("Already running", f"'{script.name}' is already running.")
            return

        if not self._confirm_risky_run(script):
            logger.info(f"Run cancelled at confirmation: {script.name}")
            return

        card = self._cards.get(script.path)
        if card is not None:
            card.set_running(True)

        self._select_script(script)
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

    def _confirm_risky_run(self, script: Script) -> bool:
        if not self._requires_confirmation(script):
            return True

        expected_changes = (
            "\n".join(f"- {change}" for change in script.expected_changes[:8])
            or "- No specific changes documented."
        )
        backup_targets = ", ".join(script.backup_targets) if script.backup_targets else "none"
        flags = [
            script.risk_level.label,
            "Requires admin" if script.requires_admin else "",
            "Requires reboot" if script.requires_reboot else "",
        ]
        flags_text = ", ".join(flag for flag in flags if flag)
        message = (
            f"Script: {script.name}\n"
            f"Risk: {flags_text}\n\n"
            "Preview / expected changes:\n"
            f"{expected_changes}\n\n"
            f"Backup targets: {backup_targets}\n\n"
            "Run this script now?"
        )
        return messagebox.askyesno("Confirm risky script", message)

    @staticmethod
    def _requires_confirmation(script: Script) -> bool:
        return (
            script.risk_level is RiskLevel.DESTRUCTIVE
            or script.requires_admin
            or script.requires_reboot
        )

    def _cancel_script(self, script: Script) -> None:
        if messagebox.askyesno("Cancel script", f"Cancel '{script.name}'?"):
            self.script_executor.cancel_execution(script)

    def _stop_all_scripts(self) -> None:
        count = self.script_executor.get_active_count()
        if count == 0:
            return
        if messagebox.askyesno("Stop scripts", f"Stop {count} running script(s)?"):
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

    def _send_input(self, _event: object | None = None) -> None:
        text = self.input_entry.get()
        if not text:
            return

        target = self._input_target_script()
        if target is None:
            messagebox.showinfo("No running script", "Start a script before sending input.")
            return

        if not self.script_executor.send_input(target, text):
            messagebox.showwarning(
                "Input not sent",
                "Could not send input. The script may have already finished.",
            )
            self._update_execution_status()
            return

        self.input_entry.delete(0, "end")
        self.output_console.append("\n[input sent]\n", tag="muted")

    def _input_target_script(self) -> Script | None:
        if (
            self._selected_script is not None
            and self.script_executor.is_running(self._selected_script)
        ):
            return self._selected_script

        active = self.script_executor.get_active_executions()
        if len(active) == 1:
            return active[0].script
        return None

    # --- Internal: callbacks ------------------------------------------

    def _on_output(self, line: str) -> None:
        # Called from worker thread; coalesce output to keep Tk responsive.
        with self._output_lock:
            self._output_buffer.append((line, None))
            if self._output_flush_scheduled:
                return
            self._output_flush_scheduled = True
        self._schedule_output_flush()

    def _on_completion(self, execution: ScriptExecution) -> None:
        self._on_main_thread(lambda: self._handle_completion(execution))

    def _handle_completion(self, execution: ScriptExecution) -> None:
        self._flush_output()
        tag, label = STATUS_TAGS.get(execution.status, ("muted", execution.status.name))
        duration = execution.duration
        summary = f"<<< {execution.script.name} [{label}]"
        if duration is not None:
            summary += f" ({duration:.2f}s)"
        if execution.error_message:
            summary += f" {execution.error_message}"
        if execution.log_path:
            summary += f" | log: {execution.log_path}"
        self.output_console.append(summary + "\n", tag=tag)

        card = self._cards.get(execution.script.path)
        if card is not None:
            card.set_running(False)
        self._update_execution_status()

    def _schedule_output_flush(self) -> None:
        try:
            self.root.after(self._OUTPUT_FLUSH_MS, self._flush_output)
        except RuntimeError:
            logger.debug("Dropped output flush after root destroyed")

    def _flush_output(self) -> None:
        with self._output_lock:
            chunks = self._output_buffer
            self._output_buffer = []
            self._output_flush_scheduled = False
        if chunks:
            self.output_console.append_many(chunks)

    def _on_search(self, query: str) -> None:
        filtered = self._scripts if not query else self.script_manager.filter_scripts(query=query)
        self._render_scripts(filtered)

    def _update_execution_status(self) -> None:
        count = self.script_executor.get_active_count()
        if count > 0:
            self.status_bar.set_status(f"Running {count} script(s)...", color=Theme.colors.warning)
            self.stop_all_btn.configure(state="normal")
        else:
            self.status_bar.set_status("Ready", color=Theme.colors.success)
            self.stop_all_btn.configure(state="disabled")
        self._set_input_enabled(count > 0)

    def _set_input_enabled(self, enabled: bool) -> None:
        state = "normal" if enabled else "disabled"
        self.input_entry.configure(state=state)
        self.input_send_btn.configure(state=state)

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
