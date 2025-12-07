"""Modern theme system for the Script Launcher UI."""

from dataclasses import dataclass
from typing import Literal

ThemeMode = Literal["light", "dark"]


@dataclass
class ColorPalette:
    """Color palette for a theme."""

    # Background colors
    bg_primary: str
    bg_secondary: str
    bg_tertiary: str
    bg_hover: str
    bg_active: str

    # Text colors
    text_primary: str
    text_secondary: str
    text_tertiary: str

    # Accent colors
    accent: str
    accent_hover: str
    accent_light: str

    # Status colors
    success: str
    warning: str
    error: str
    info: str

    # Border colors
    border: str
    border_light: str


@dataclass
class FontConfig:
    """Font configuration."""

    family: str = "Segoe UI"
    family_mono: str = "Consolas"
    size_small: int = 9
    size_normal: int = 10
    size_large: int = 12
    size_title: int = 18


# Light theme palette
LIGHT_PALETTE = ColorPalette(
    bg_primary="#ffffff",
    bg_secondary="#f5f5f5",
    bg_tertiary="#e8e8e8",
    bg_hover="#f0f0f0",
    bg_active="#e0e0e0",
    text_primary="#000000",
    text_secondary="#333333",
    text_tertiary="#666666",
    accent="#0078d4",
    accent_hover="#005a9e",
    accent_light="#e8f4fd",
    success="#107c10",
    warning="#ff8c00",
    error="#d32f2f",
    info="#0078d4",
    border="#d1d1d1",
    border_light="#e8e8e8",
)

# Dark theme palette
DARK_PALETTE = ColorPalette(
    bg_primary="#1e1e1e",
    bg_secondary="#252525",
    bg_tertiary="#2d2d2d",
    bg_hover="#2a2a2a",
    bg_active="#323232",
    text_primary="#ffffff",
    text_secondary="#e0e0e0",
    text_tertiary="#a0a0a0",
    accent="#0078d4",
    accent_hover="#1e90ff",
    accent_light="#1a3a52",
    success="#4ec9b0",
    warning="#ce9178",
    error="#f48771",
    info="#4fc1ff",
    border="#3f3f3f",
    border_light="#2d2d2d",
)


class Theme:
    """Theme manager for the application."""

    def __init__(self, mode: ThemeMode = "light"):
        """
        Initialize theme.

        Args:
            mode: Theme mode (light or dark)
        """
        self.mode = mode
        self.colors = LIGHT_PALETTE if mode == "light" else DARK_PALETTE
        self.fonts = FontConfig()

    def toggle(self) -> None:
        """Toggle between light and dark mode."""
        self.mode = "dark" if self.mode == "light" else "light"
        self.colors = LIGHT_PALETTE if self.mode == "light" else DARK_PALETTE

    def get_button_style(self) -> dict[str, str]:
        """Get standard button style."""
        return {
            "bg": self.colors.bg_primary,
            "fg": self.colors.text_secondary,
            "activebackground": self.colors.bg_active,
            "activeforeground": self.colors.text_primary,
            "relief": "solid",
            "bd": "1",
            "highlightthickness": "0",
            "cursor": "hand2",
        }

    def get_accent_button_style(self) -> dict[str, str]:
        """Get accent button style."""
        return {
            "bg": self.colors.accent,
            "fg": "#ffffff",
            "activebackground": self.colors.accent_hover,
            "activeforeground": "#ffffff",
            "relief": "flat",
            "bd": "0",
            "highlightthickness": "0",
            "cursor": "hand2",
        }

    def get_script_card_style(self) -> dict[str, str]:
        """Get script card style."""
        return {
            "bg": self.colors.bg_primary,
            "fg": self.colors.text_secondary,
            "activebackground": self.colors.bg_hover,
            "activeforeground": self.colors.text_primary,
            "relief": "solid",
            "bd": "1",
            "highlightthickness": "0",
            "cursor": "hand2",
        }

    def get_output_style(self) -> dict[str, str]:
        """Get output console style."""
        return {
            "bg": self.colors.bg_primary,
            "fg": self.colors.text_primary,
            "insertbackground": self.colors.text_primary,
            "selectbackground": self.colors.accent,
            "selectforeground": "#ffffff",
        }
