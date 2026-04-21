"""Reusable UI components for Script Launcher."""

from __future__ import annotations

from collections.abc import Callable

import customtkinter as ctk

from ..models import Script, ScriptType
from .theme import Theme


class ModernButton(ctk.CTkButton):
    """Button with consistent typography and sizing."""

    def __init__(
        self,
        parent: ctk.CTkBaseClass,
        text: str,
        command: Callable[[], None] | None = None,
        **kwargs: object,
    ) -> None:
        super().__init__(
            parent,
            text=text,
            command=command,
            font=(Theme.fonts.family, Theme.fonts.size_normal),
            height=34,
            corner_radius=6,
            **kwargs,
        )


class ScriptCard(ctk.CTkFrame):
    """A compact row that shows a script and its run/cancel controls."""

    def __init__(
        self,
        parent: ctk.CTkBaseClass,
        script: Script,
        on_run: Callable[[Script], None],
        on_cancel: Callable[[Script], None] | None = None,
        **kwargs: object,
    ) -> None:
        super().__init__(
            parent,
            fg_color=Theme.colors.bg_secondary,
            corner_radius=8,
            border_width=1,
            border_color=Theme.colors.border,
            **kwargs,
        )
        self.script = script
        self._on_run = on_run
        self._on_cancel = on_cancel

        self.grid_columnconfigure(1, weight=1)

        self._icon = ctk.CTkLabel(
            self,
            text=self._icon_for(script.script_type),
            font=(Theme.fonts.family, 16, "bold"),
            text_color=Theme.colors.accent,
            width=36,
        )
        self._icon.grid(row=0, column=0, padx=(12, 6), pady=10)

        self._name = ctk.CTkLabel(
            self,
            text=script.name,
            font=(Theme.fonts.family, Theme.fonts.size_normal, "bold"),
            text_color=Theme.colors.text_primary,
            anchor="w",
        )
        self._name.grid(row=0, column=1, sticky="w", padx=4)

        if script.description:
            self._desc = ctk.CTkLabel(
                self,
                text=script.description,
                font=(Theme.fonts.family, Theme.fonts.size_small),
                text_color=Theme.colors.text_secondary,
                anchor="w",
                justify="left",
            )
            self._desc.grid(row=1, column=1, sticky="w", padx=4, pady=(0, 6))

        if script.category and script.category != "General":
            self._category = ctk.CTkLabel(
                self,
                text=script.category,
                font=(Theme.fonts.family, Theme.fonts.size_small),
                fg_color=Theme.colors.bg_tertiary,
                text_color=Theme.colors.text_secondary,
                corner_radius=4,
                padx=8,
                pady=2,
            )
            self._category.grid(row=0, column=2, padx=8)

        self._run_btn = ctk.CTkButton(
            self,
            text="Run",
            command=self._run_clicked,
            width=72,
            height=28,
            font=(Theme.fonts.family, Theme.fonts.size_small, "bold"),
            fg_color=Theme.colors.accent,
            hover_color=Theme.colors.accent_hover,
        )
        self._run_btn.grid(row=0, column=3, padx=(6, 12))

    def _run_clicked(self) -> None:
        self._on_run(self.script)

    def set_running(self, running: bool) -> None:
        """Toggle between ``Run`` and ``Cancel`` states."""
        if running and self._on_cancel is not None:
            self._run_btn.configure(
                text="Cancel",
                command=self._cancel_clicked,
                fg_color=Theme.colors.error,
                hover_color="#c0392b",
            )
        else:
            self._run_btn.configure(
                text="Run",
                command=self._run_clicked,
                fg_color=Theme.colors.accent,
                hover_color=Theme.colors.accent_hover,
            )

    def _cancel_clicked(self) -> None:
        if self._on_cancel is not None:
            self._on_cancel(self.script)

    @staticmethod
    def _icon_for(script_type: ScriptType) -> str:
        return {
            ScriptType.PYTHON: "PY",
            ScriptType.BATCH: "BAT",
            ScriptType.POWERSHELL: "PS",
            ScriptType.UNKNOWN: "?",
        }.get(script_type, "?")


class OutputConsole(ctk.CTkTextbox):
    """Read-only console with colored status tags."""

    def __init__(self, parent: ctk.CTkBaseClass, **kwargs: object) -> None:
        super().__init__(
            parent,
            font=(Theme.fonts.family_mono, Theme.fonts.size_small),
            text_color=Theme.colors.text_primary,
            fg_color=Theme.colors.bg_primary,
            border_width=1,
            border_color=Theme.colors.border,
            activate_scrollbars=True,
            **kwargs,
        )
        self.configure(state="disabled")
        self._textbox.tag_config("error", foreground=Theme.colors.error)
        self._textbox.tag_config("success", foreground=Theme.colors.success)
        self._textbox.tag_config("warning", foreground=Theme.colors.warning)
        self._textbox.tag_config("info", foreground=Theme.colors.info)
        self._textbox.tag_config("muted", foreground=Theme.colors.text_tertiary)

    def append(self, text: str, tag: str | None = None) -> None:
        self.configure(state="normal")
        if tag:
            self.insert("end", text, tag)
        else:
            self.insert("end", text)
        self.see("end")
        self.configure(state="disabled")

    def clear(self) -> None:
        self.configure(state="normal")
        self.delete("1.0", "end")
        self.configure(state="disabled")


class SearchBar(ctk.CTkEntry):
    """Debounced search input."""

    def __init__(
        self,
        parent: ctk.CTkBaseClass,
        on_search: Callable[[str], None],
        placeholder: str = "Search scripts...",
        debounce_ms: int = 180,
        **kwargs: object,
    ) -> None:
        super().__init__(
            parent,
            placeholder_text=placeholder,
            font=(Theme.fonts.family, Theme.fonts.size_normal),
            height=36,
            fg_color=Theme.colors.bg_secondary,
            border_width=1,
            border_color=Theme.colors.border,
            **kwargs,
        )
        self._on_search = on_search
        self._debounce_ms = debounce_ms
        self._after_id: str | None = None
        self.bind("<KeyRelease>", self._schedule)

    def _schedule(self, _event: object) -> None:
        if self._after_id is not None:
            self.after_cancel(self._after_id)
        self._after_id = self.after(self._debounce_ms, self._fire)

    def _fire(self) -> None:
        self._after_id = None
        self._on_search(self.get())


class StatusBar(ctk.CTkFrame):
    """Status bar pinned to the bottom of the window."""

    def __init__(self, parent: ctk.CTkBaseClass, **kwargs: object) -> None:
        super().__init__(
            parent,
            height=28,
            fg_color=Theme.colors.bg_tertiary,
            corner_radius=0,
            **kwargs,
        )
        self.pack_propagate(False)

        self._label = ctk.CTkLabel(
            self,
            text="Ready",
            font=(Theme.fonts.family, Theme.fonts.size_small),
            text_color=Theme.colors.text_secondary,
        )
        self._label.pack(side="left", padx=12)

        self._right = ctk.CTkLabel(
            self,
            text="",
            font=(Theme.fonts.family, Theme.fonts.size_small),
            text_color=Theme.colors.text_tertiary,
        )
        self._right.pack(side="right", padx=12)

    def set_status(self, text: str, color: str | None = None) -> None:
        self._label.configure(
            text=text, text_color=color or Theme.colors.text_secondary
        )

    def set_right(self, text: str) -> None:
        self._right.configure(text=text)


__all__ = [
    "ModernButton",
    "ScriptCard",
    "OutputConsole",
    "SearchBar",
    "StatusBar",
]
