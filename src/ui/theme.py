"""Theme configuration for CustomTkinter UI."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Colors:
    """Application color palette (dark theme)."""

    bg_primary: str = "#1a1a1a"
    bg_secondary: str = "#242424"
    bg_tertiary: str = "#2f2f2f"
    bg_hover: str = "#3a3a3a"

    text_primary: str = "#ffffff"
    text_secondary: str = "#b3b3b3"
    text_tertiary: str = "#6e6e6e"

    accent: str = "#1f6aa5"
    accent_hover: str = "#2b7fc0"

    success: str = "#2ea043"
    warning: str = "#d29922"
    error: str = "#f85149"
    info: str = "#58a6ff"

    border: str = "#3a3a3a"


@dataclass(frozen=True)
class Fonts:
    """Font configuration."""

    family: str = "Segoe UI"
    family_mono: str = "Cascadia Mono"

    size_small: int = 11
    size_normal: int = 13
    size_large: int = 15
    size_title: int = 22


class Theme:
    """Static theme provider."""

    colors = Colors()
    fonts = Fonts()
