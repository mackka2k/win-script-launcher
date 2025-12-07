"""Reusable UI components for Script Launcher using CustomTkinter."""

import customtkinter as ctk
from typing import Callable, Optional
import tkinter as tk # for some constants if needed, or specific mixins

from ..models import Script, ScriptType
from .theme import Theme

class ModernButton(ctk.CTkButton):
    """Standard textured button."""
    
    def __init__(self, parent, text: str, command: Optional[Callable[[], None]] = None, **kwargs):
        super().__init__(
            parent,
            text=text,
            command=command,
            font=(Theme.fonts.family, Theme.fonts.size_normal),
            height=32,
            **kwargs
        )

class ScriptCard(ctk.CTkFrame):
    """A compact list row widget for displaying a script."""

    def __init__(
        self,
        parent,
        script: Script,
        on_run: Callable[[Script], None],
        **kwargs,
    ):
        super().__init__(parent, fg_color=Theme.colors.bg_secondary, corner_radius=6, **kwargs)

        self.script = script
        self.on_run = on_run

        # Layout
        self.grid_columnconfigure(1, weight=1) # Name expands
        
        # Icon
        icon = self._get_icon(script.script_type)
        self.icon_label = ctk.CTkLabel(
            self, 
            text=icon, 
            font=(Theme.fonts.family, 16),
            text_color=Theme.colors.accent,
            width=30
        )
        self.icon_label.grid(row=0, column=0, padx=(10, 5), pady=8)

        # Name
        self.name_label = ctk.CTkLabel(
            self,
            text=script.name,
            font=(Theme.fonts.family, Theme.fonts.size_normal, "bold"),
            text_color=Theme.colors.text_primary,
            anchor="w"
        )
        self.name_label.grid(row=0, column=1, sticky="w", padx=5)
        
        # Category Badge (if applicable)
        if script.category and script.category != "General":
            self.cat_label = ctk.CTkLabel(
                self,
                text=script.category,
                font=(Theme.fonts.family, 10),
                fg_color=Theme.colors.bg_tertiary,
                text_color=Theme.colors.text_secondary,
                corner_radius=4,
                padx=6,
                pady=2
            )
            self.cat_label.grid(row=0, column=2, padx=10)

        # Run Button
        self.run_btn = ctk.CTkButton(
            self,
            text="Run",
            command=lambda: on_run(script),
            width=60,
            height=24,
            font=(Theme.fonts.family, 12),
            fg_color=Theme.colors.accent,
            hover_color=Theme.colors.accent_hover
        )
        self.run_btn.grid(row=0, column=3, padx=(5, 10))

    def _get_icon(self, script_type: ScriptType) -> str:
        icons = {
            ScriptType.PYTHON: "🐍",
            ScriptType.BATCH: "bat",  # Win10 emojis or text
            ScriptType.POWERSHELL: "PS",
            ScriptType.UNKNOWN: "📄",
        }
        return icons.get(script_type, "📄")

class OutputConsole(ctk.CTkTextbox):
    """ReadOnly console output."""
    
    def __init__(self, parent, **kwargs):
        super().__init__(
            parent,
            font=(Theme.fonts.family_mono, Theme.fonts.size_normal),
            text_color=Theme.colors.text_primary,
            fg_color=Theme.colors.bg_primary,
            activate_scrollbars=True,
            **kwargs
        )
        self.configure(state="disabled")
        
        # Tag configuration is different in CTk/Tk
        # CTkTextbox underlying widget is a tk.Text
        self._textbox.tag_config("error", foreground=Theme.colors.error)
        self._textbox.tag_config("success", foreground=Theme.colors.success)
        self._textbox.tag_config("warning", foreground=Theme.colors.warning)
        self._textbox.tag_config("info", foreground=Theme.colors.info)

    def append(self, text: str, tag: Optional[str] = None) -> None:
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
    """Search input field."""
    
    def __init__(self, parent, on_search: Callable[[str], None], placeholder="Search...", **kwargs):
        self.on_search = on_search
        super().__init__(
            parent,
            placeholder_text=placeholder,
            font=(Theme.fonts.family, Theme.fonts.size_normal),
            height=35,
            fg_color=Theme.colors.bg_secondary,
            border_width=1,
            border_color=Theme.colors.bg_tertiary,
            **kwargs
        )
        
        # Bind
        self.bind("<KeyRelease>", self._on_key_release)
        
    def _on_key_release(self, event):
        self.on_search(self.get())

class StatusBar(ctk.CTkFrame):
    """Status bar at bottom."""
    
    def __init__(self, parent, **kwargs):
        super().__init__(parent, height=28, fg_color=Theme.colors.accent, corner_radius=0, **kwargs)
        self.pack_propagate(False) # Fix height
        
        self.label = ctk.CTkLabel(
            self,
            text="Ready",
            font=(Theme.fonts.family, 12),
            text_color="#ffffff"
        )
        self.label.pack(side="left", padx=10)
        
    def set_status(self, text: str, color: str = None) -> None:
        self.label.configure(text=text)
        # Verify if we want to change bar color or text color
        if color:
             # If color is passed (like success/error), maybe change bg of status bar?
             # For now, let's keep it simple or implement specific logic
             if color == Theme.colors.error:
                 self.configure(fg_color=Theme.colors.error)
             elif color == Theme.colors.success:
                 self.configure(fg_color=Theme.colors.success)
             else:
                 self.configure(fg_color=Theme.colors.accent)
