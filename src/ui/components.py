"""Reusable UI components for Script Launcher."""

import tkinter as tk
from tkinter import scrolledtext
from typing import Callable, Optional

from ..models import Script, ScriptType


class ModernButton(tk.Button):
    """A modern styled button with hover effects."""

    def __init__(
        self,
        parent: tk.Widget,
        text: str,
        command: Optional[Callable[[], None]] = None,
        style_dict: Optional[dict[str, str]] = None,
        hover_bg: Optional[str] = None,
        hover_fg: Optional[str] = None,
        **kwargs,
    ):
        """
        Initialize modern button.

        Args:
            parent: Parent widget
            text: Button text
            command: Command to execute on click
            style_dict: Style dictionary
            hover_bg: Background color on hover
            hover_fg: Foreground color on hover
            **kwargs: Additional button arguments
        """
        # Apply style
        if style_dict:
            kwargs.update(style_dict)

        super().__init__(parent, text=text, command=command, **kwargs)

        # Store original and hover colors
        self.normal_bg = kwargs.get("bg", "#ffffff")
        self.normal_fg = kwargs.get("fg", "#000000")
        self.hover_bg = hover_bg or kwargs.get("activebackground", "#f0f0f0")
        self.hover_fg = hover_fg or kwargs.get("activeforeground", "#000000")

        # Bind hover events
        self.bind("<Enter>", self._on_enter)
        self.bind("<Leave>", self._on_leave)

    def _on_enter(self, event: tk.Event) -> None:  # type: ignore
        """Handle mouse enter."""
        if self["state"] == tk.NORMAL:
            self.config(bg=self.hover_bg, fg=self.hover_fg)

    def _on_leave(self, event: tk.Event) -> None:  # type: ignore
        """Handle mouse leave."""
        if self["state"] == tk.NORMAL:
            self.config(bg=self.normal_bg, fg=self.normal_fg)


class ScriptCard(tk.Frame):
    """A compact list row widget for displaying a script."""

    def __init__(
        self,
        parent: tk.Widget,
        script: Script,
        on_run: Callable[[Script], None],
        on_delete: Optional[Callable[[Script], None]] = None,
        theme_colors: Optional[dict[str, str]] = None,
        **kwargs,
    ):
        """
        Initialize script card as compact list row.

        Args:
            parent: Parent widget
            script: Script to display
            on_run: Callback when run button is clicked
            on_delete: Optional callback when delete is requested
            theme_colors: Theme color dictionary
            **kwargs: Additional frame arguments
        """
        super().__init__(parent, **kwargs)

        self.script = script
        self.on_run = on_run
        self.on_delete = on_delete

        # Default colors
        colors = theme_colors or {}
        bg = colors.get("bg", "#ffffff")
        fg = colors.get("fg", "#333333")
        accent = colors.get("accent", "#0078d4")

        # Compact list row style
        self.config(bg=bg, relief=tk.FLAT, bd=0, height=24)

        # Icon (small)
        icon = self._get_icon(script.script_type)
        icon_label = tk.Label(self, text=icon, font=("Segoe UI", 9), bg=bg, fg=accent, width=2)
        icon_label.pack(side=tk.LEFT, padx=(5, 3))

        # Script name (truncated if needed)
        name_text = script.name if len(script.name) <= 30 else script.name[:27] + "..."
        name_label = tk.Label(
            self, text=name_text, font=("Segoe UI", 9), bg=bg, fg=fg, anchor=tk.W, width=35
        )
        name_label.pack(side=tk.LEFT, padx=2)

        # Category badge (small)
        if script.category and script.category != "General":
            category_text = script.category.split()[-1][:10]  # Last word, max 10 chars
            category_label = tk.Label(
                self, text=category_text, font=("Segoe UI", 8), bg="#f0f0f0", fg="#666", 
                padx=4, pady=1, relief=tk.FLAT
            )
            category_label.pack(side=tk.LEFT, padx=5)

        # Run button (small, right-aligned)
        run_btn = tk.Button(
            self,
            text="▶ Run",
            command=lambda: on_run(script),
            bg=accent,
            fg="#ffffff",
            font=("Segoe UI", 8),
            relief=tk.FLAT,
            cursor="hand2",
            padx=8,
            pady=1,
        )
        run_btn.pack(side=tk.RIGHT, padx=5)

        # Hover effect
        self.bind("<Enter>", lambda e: self.config(bg="#f5f5f5"))
        self.bind("<Leave>", lambda e: self.config(bg=bg))
        for child in self.winfo_children():
            if isinstance(child, tk.Label):
                child.bind("<Enter>", lambda e: self.config(bg="#f5f5f5"))
                child.bind("<Leave>", lambda e: self.config(bg=bg))

    def _get_icon(self, script_type: ScriptType) -> str:
        """Get icon for script type."""
        icons = {
            ScriptType.PYTHON: "🐍",
            ScriptType.BATCH: "⚙️",
            ScriptType.POWERSHELL: "💻",
            ScriptType.UNKNOWN: "📄",
        }
        return icons.get(script_type, "📄")


class OutputConsole(scrolledtext.ScrolledText):
    """Enhanced output console with syntax highlighting."""

    def __init__(self, parent: tk.Widget, theme_colors: Optional[dict[str, str]] = None, **kwargs):
        """
        Initialize output console.

        Args:
            parent: Parent widget
            theme_colors: Theme color dictionary
            **kwargs: Additional ScrolledText arguments
        """
        colors = theme_colors or {}

        # Apply theme colors with better readability
        kwargs.setdefault("bg", colors.get("bg", "#1e1e1e"))
        kwargs.setdefault("fg", colors.get("fg", "#d4d4d4"))
        kwargs.setdefault("insertbackground", colors.get("fg", "#d4d4d4"))
        kwargs.setdefault("selectbackground", colors.get("accent", "#264f78"))
        kwargs.setdefault("selectforeground", "#ffffff")
        kwargs.setdefault("font", ("Consolas", 10))  # Larger, more readable font
        kwargs.setdefault("wrap", tk.WORD)
        kwargs.setdefault("state", tk.DISABLED)
        kwargs.setdefault("padx", 10)
        kwargs.setdefault("pady", 10)

        super().__init__(parent, **kwargs)

        # Configure tags for colored output with better contrast
        self.tag_config("error", foreground="#f48771", font=("Consolas", 10, "bold"))
        self.tag_config("success", foreground="#89d185", font=("Consolas", 10, "bold"))
        self.tag_config("warning", foreground="#dcdcaa", font=("Consolas", 10, "bold"))
        self.tag_config("info", foreground="#4fc1ff", font=("Consolas", 10, "bold"))
        self.tag_config("header", foreground="#c586c0", font=("Consolas", 11, "bold"))

    def append(self, text: str, tag: Optional[str] = None) -> None:
        """
        Append text to the console.

        Args:
            text: Text to append
            tag: Optional tag for styling
        """
        self.config(state=tk.NORMAL)
        if tag:
            self.insert(tk.END, text, tag)
        else:
            self.insert(tk.END, text)
        self.see(tk.END)
        self.config(state=tk.DISABLED)

    def clear(self) -> None:
        """Clear the console."""
        self.config(state=tk.NORMAL)
        self.delete(1.0, tk.END)
        self.config(state=tk.DISABLED)


class SearchBar(tk.Frame):
    """Search bar with filter functionality."""

    def __init__(
        self,
        parent: tk.Widget,
        on_search: Callable[[str], None],
        placeholder: str = "Search scripts...",
        **kwargs,
    ):
        """
        Initialize search bar.

        Args:
            parent: Parent widget
            on_search: Callback when search text changes
            placeholder: Placeholder text
            **kwargs: Additional frame arguments
        """
        super().__init__(parent, **kwargs)

        self.on_search = on_search
        self.placeholder = placeholder

        # Search icon
        icon_label = tk.Label(self, text="🔍", font=("Segoe UI", 12))
        icon_label.pack(side=tk.LEFT, padx=(5, 0))

        # Search entry
        self.entry = tk.Entry(
            self, font=("Segoe UI", 10), relief=tk.FLAT, bg="#ffffff", fg="#333333"
        )
        self.entry.pack(side=tk.LEFT, fill=tk.BOTH, expand=True, padx=5, pady=5)

        # Bind events
        self.entry.bind("<KeyRelease>", self._on_key_release)

        # Set placeholder
        self._show_placeholder()
        self.entry.bind("<FocusIn>", self._on_focus_in)
        self.entry.bind("<FocusOut>", self._on_focus_out)

    def _on_key_release(self, event: tk.Event) -> None:  # type: ignore
        """Handle key release."""
        text = self.entry.get()
        if text != self.placeholder:
            self.on_search(text)

    def _show_placeholder(self) -> None:
        """Show placeholder text."""
        self.entry.delete(0, tk.END)
        self.entry.insert(0, self.placeholder)
        self.entry.config(fg="#999999")

    def _on_focus_in(self, event: tk.Event) -> None:  # type: ignore
        """Handle focus in."""
        if self.entry.get() == self.placeholder:
            self.entry.delete(0, tk.END)
            self.entry.config(fg="#333333")

    def _on_focus_out(self, event: tk.Event) -> None:  # type: ignore
        """Handle focus out."""
        if not self.entry.get():
            self._show_placeholder()

    def get_text(self) -> str:
        """Get search text."""
        text = self.entry.get()
        return "" if text == self.placeholder else text


class StatusBar(tk.Frame):
    """Modern status bar."""

    def __init__(self, parent: tk.Widget, **kwargs):
        """
        Initialize status bar.

        Args:
            parent: Parent widget
            **kwargs: Additional frame arguments
        """
        super().__init__(parent, **kwargs)

        self.config(relief=tk.SUNKEN, bd=1)

        # Status label
        self.label = tk.Label(
            self, text="Ready", font=("Segoe UI", 9), anchor=tk.W, padx=10, pady=2
        )
        self.label.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

    def set_status(self, text: str, color: str = "#107c10") -> None:
        """
        Set status text.

        Args:
            text: Status text
            color: Text color
        """
        self.label.config(text=text, fg=color)
