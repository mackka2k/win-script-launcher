"""Reusable UI components for Script Launcher."""

from __future__ import annotations

from collections.abc import Callable

import customtkinter as ctk

from ..models import RiskLevel, Script, ScriptType
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
        kwargs.setdefault("text_color", Theme.colors.text_primary)
        super().__init__(
            parent,
            text=text,
            command=command,
            font=(Theme.fonts.family, Theme.fonts.size_normal),
            height=34,
            corner_radius=0,
            border_width=1,
            border_color=Theme.colors.border,
            **kwargs,
        )


class ScriptCard(ctk.CTkFrame):
    """A compact row that shows a script and its run/cancel controls."""

    _DESC_WRAP_DEBOUNCE_MS = 120
    _DESC_MIN_WRAP = 120

    def __init__(
        self,
        parent: ctk.CTkBaseClass,
        script: Script,
        on_run: Callable[[Script], None],
        on_cancel: Callable[[Script], None] | None = None,
        on_select: Callable[[Script], None] | None = None,
        **kwargs: object,
    ) -> None:
        super().__init__(
            parent,
            fg_color=Theme.colors.bg_secondary,
            corner_radius=0,
            border_width=1,
            border_color=Theme.colors.border,
            **kwargs,
        )
        self.script = script
        self._on_run = on_run
        self._on_cancel = on_cancel
        self._on_select = on_select
        self._wrap_after_id: str | None = None

        self.grid_columnconfigure(0, weight=0)
        self.grid_columnconfigure(1, weight=1)
        self.grid_columnconfigure(2, weight=0)
        self.grid_rowconfigure(1, weight=1)

        self._icon = ctk.CTkLabel(
            self,
            text=self._icon_for(script.script_type),
            font=(Theme.fonts.family, 16, "bold"),
            text_color=Theme.colors.accent,
            width=36,
        )
        self._icon.grid(row=0, column=0, padx=(10, 6), pady=(8, 2), sticky="nw")

        self._name = ctk.CTkLabel(
            self,
            text=script.name,
            font=(Theme.fonts.family, Theme.fonts.size_normal, "bold"),
            text_color=Theme.colors.text_primary,
            anchor="w",
        )
        self._name.grid(row=0, column=1, sticky="ew", padx=4, pady=(8, 2))

        if script.description:
            self._desc = ctk.CTkLabel(
                self,
                text=script.description,
                font=(Theme.fonts.family, Theme.fonts.size_normal),
                text_color=Theme.colors.text_primary,
                anchor="w",
                justify="left",
                wraplength=900,
            )
            self._desc.grid(
                row=1,
                column=0,
                columnspan=3,
                sticky="ew",
                padx=10,
                pady=(4, 8),
            )

        self._meta_badge = ctk.CTkLabel(
            self,
            text=self._metadata_text(script),
            font=(Theme.fonts.family, Theme.fonts.size_small),
            fg_color=self._risk_color(script.risk_level),
            text_color="#ffffff",
            corner_radius=0,
            padx=8,
            pady=2,
        )
        self._meta_badge.grid(
            row=2,
            column=0,
            columnspan=2,
            padx=10,
            pady=(0, 8),
            sticky="w",
        )

        self._run_btn = ctk.CTkButton(
            self,
            text="Run",
            command=self._run_clicked,
            width=72,
            height=28,
            font=(Theme.fonts.family, Theme.fonts.size_small, "bold"),
            fg_color=Theme.colors.accent,
            hover_color=Theme.colors.accent_hover,
            text_color="#ffffff",
            corner_radius=0,
            border_width=1,
            border_color=Theme.colors.border,
        )
        self._run_btn.grid(row=2, column=2, padx=(6, 10), pady=(0, 8), sticky="e")
        if hasattr(self, "_desc"):
            self.bind("<Configure>", self._schedule_description_wrap)
        self._bind_select_handlers()

    def _bind_select_handlers(self) -> None:
        if self._on_select is None:
            return
        for widget in (self, self._icon, self._name, self._meta_badge):
            widget.bind("<Button-1>", self._select_clicked)
        if hasattr(self, "_desc"):
            self._desc.bind("<Button-1>", self._select_clicked)

    def _select_clicked(self, _event: object) -> None:
        if self._on_select is not None:
            self._on_select(self.script)

    def update_script(self, script: Script) -> None:
        """Refresh row content while reusing the existing widget tree."""
        self.script = script
        self._icon.configure(text=self._icon_for(script.script_type))
        self._name.configure(text=script.name)
        self._meta_badge.configure(
            text=self._metadata_text(script),
            fg_color=self._risk_color(script.risk_level),
        )
        if hasattr(self, "_desc"):
            self._desc.configure(text=script.description)

    def _schedule_description_wrap(self, event: object) -> None:
        width = getattr(event, "width", self.winfo_width())
        if width <= 0 or width == getattr(self, "_last_wrap_width", None):
            return
        self._last_wrap_width = width
        if self._wrap_after_id is not None:
            self.after_cancel(self._wrap_after_id)
        self._wrap_after_id = self.after(
            self._DESC_WRAP_DEBOUNCE_MS,
            lambda: self._update_description_wrap(width),
        )

    def _update_description_wrap(self, card_width: int) -> None:
        self._wrap_after_id = None
        if not hasattr(self, "_desc"):
            return
        wraplength = max(self._DESC_MIN_WRAP, card_width - 24)
        self._desc.configure(wraplength=wraplength)

    @staticmethod
    def _metadata_text(script: Script) -> str:
        parts = []
        category = script.category.replace("⚙", "").strip()
        if category and category != "General":
            parts.append(category)
        parts.append(script.risk_level.label)
        if script.requires_admin:
            parts.append("Admin")
        if script.requires_reboot:
            parts.append("Reboot")
        return " | ".join(parts)

    @staticmethod
    def _risk_color(risk_level: RiskLevel) -> str:
        return {
            RiskLevel.SAFE: Theme.colors.success,
            RiskLevel.MODERATE: Theme.colors.warning,
            RiskLevel.DESTRUCTIVE: Theme.colors.error,
        }[risk_level]

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
                text_color="#ffffff",
            )
        else:
            self._run_btn.configure(
                text="Run",
                command=self._run_clicked,
                fg_color=Theme.colors.accent,
                hover_color=Theme.colors.accent_hover,
                text_color="#ffffff",
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
            corner_radius=0,
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
        self.append_many([(text, tag)])

    def append_many(self, chunks: list[tuple[str, str | None]]) -> None:
        if not chunks:
            return
        self.configure(state="normal")
        for text, tag in chunks:
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
            corner_radius=0,
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
        self._label.configure(text=text, text_color=color or Theme.colors.text_secondary)

    def set_right(self, text: str) -> None:
        self._right.configure(text=text)


__all__ = [
    "ModernButton",
    "ScriptCard",
    "OutputConsole",
    "SearchBar",
    "StatusBar",
]
