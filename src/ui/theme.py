"""Theme configuration for CustomTkinter UI."""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Colors:
    """Application color palette (simple retro white theme)."""

    bg_primary: str = "#ffffff"
    bg_secondary: str = "#f4f4f4"
    bg_tertiary: str = "#e6e6e6"
    bg_hover: str = "#dcdcdc"

    text_primary: str = "#111111"
    text_secondary: str = "#333333"
    text_tertiary: str = "#666666"

    accent: str = "#000080"
    accent_hover: str = "#000060"

    success: str = "#008000"
    warning: str = "#8a5a00"
    error: str = "#a00000"
    info: str = "#000080"

    border: str = "#a0a0a0"


@dataclass(frozen=True)
class Fonts:
    """Font configuration."""

    family: str = "Tahoma"
    family_mono: str = "Consolas"

    size_small: int = 11
    size_normal: int = 12
    size_large: int = 14
    size_title: int = 18


class Theme:
    """Static theme provider."""

    colors = Colors()
    fonts = Fonts()
