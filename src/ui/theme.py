"""Theme configuration for CustomTkinter UI."""

from dataclasses import dataclass

@dataclass
class Colors:
    """Application color palette (Dark Theme)."""
    
    # Backgrounds
    bg_primary: str = "#1e1e1e"  # Main window bg (though CTk handles this mostly)
    bg_secondary: str = "#2b2b2b" # Cards/Containers
    bg_tertiary: str = "#333333" # Hover states
    
    # Text
    text_primary: str = "#ffffff"
    text_secondary: str = "#a0a0a0"
    text_tertiary: str = "#666666"
    
    # Accents
    accent: str = "#1f6aa5"      # Standard CTk blue-ish
    accent_hover: str = "#144870"
    
    # Semantic
    success: str = "#2ea043"     # GitHub-like green
    warning: str = "#d29922"     # GitHub-like orange
    error: str = "#f85149"       # GitHub-like red
    info: str = "#58a6ff"        # GitHub-like blue

@dataclass
class Fonts:
    """Font configuration."""
    family: str = "Roboto Medium"  # CTk default is usually good, but we can be specific
    family_mono: str = "Roboto Mono"
    
    size_small: int = 12
    size_normal: int = 14
    size_large: int = 16
    size_title: int = 24

class Theme:
    """Static theme provider."""
    colors = Colors()
    fonts = Fonts()
