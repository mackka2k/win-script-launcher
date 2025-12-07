"""Configuration management for Script Launcher."""

import json
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any, Optional

from loguru import logger

from .exceptions import ConfigurationError
from .validators import ConfigValidator


@dataclass
class ScriptCache:
    """Script cache for faster discovery."""
    last_scan: str = ""
    scripts: list[dict] = field(default_factory=list)
    directory_hash: str = ""


@dataclass
class ThemeConfig:
    """Theme configuration."""

    mode: str = "light"  # "light" or "dark"
    accent_color: str = "#0078d4"
    
    def __post_init__(self):
        """Validate configuration after initialization."""
        ConfigValidator.validate_theme_mode(self.mode)
        ConfigValidator.validate_color(self.accent_color)


@dataclass
class WindowConfig:
    """Window configuration."""

    width: int = 900
    height: int = 700
    remember_size: bool = True
    remember_position: bool = True
    last_x: Optional[int] = None
    last_y: Optional[int] = None
    
    def __post_init__(self):
        """Validate configuration after initialization."""
        ConfigValidator.validate_window_size(self.width, self.height)


@dataclass
class ExecutionConfig:
    """Script execution configuration."""

    timeout_seconds: int = 300  # 5 minutes
    show_output_realtime: bool = True
    auto_scroll_output: bool = True
    max_output_lines: int = 10000
    
    def __post_init__(self):
        """Validate configuration after initialization."""
        ConfigValidator.validate_timeout(self.timeout_seconds)


@dataclass
class AppConfig:
    """Application configuration."""

    theme: ThemeConfig = field(default_factory=ThemeConfig)
    window: WindowConfig = field(default_factory=WindowConfig)
    execution: ExecutionConfig = field(default_factory=ExecutionConfig)
    script_cache: ScriptCache = field(default_factory=ScriptCache)
    enable_file_watcher: bool = False  # Disabled by default for performance
    check_admin_on_startup: bool = True  # Check for admin privileges
    log_level: str = "WARNING"  # Reduced logging for performance
    
    def __post_init__(self):
        """Validate configuration after initialization."""
        ConfigValidator.validate_log_level(self.log_level)

    @classmethod
    def load(cls, config_path: Path) -> "AppConfig":
        """
        Load configuration from JSON file.
        
        Args:
            config_path: Path to configuration file
            
        Returns:
            AppConfig instance
            
        Raises:
            ConfigurationError: If config file is invalid
        """
        if not config_path.exists():
            logger.info("Config file not found, using defaults")
            return cls()

        try:
            with open(config_path, encoding="utf-8") as f:
                data = json.load(f)

            # Reconstruct nested dataclasses
            theme_data = data.pop("theme", {})
            window_data = data.pop("window", {})
            execution_data = data.pop("execution", {})
            cache_data = data.pop("script_cache", {})

            return cls(
                theme=ThemeConfig(**theme_data),
                window=WindowConfig(**window_data),
                execution=ExecutionConfig(**execution_data),
                script_cache=ScriptCache(**cache_data),
                **data,
            )
        except json.JSONDecodeError as e:
            raise ConfigurationError(f"Invalid JSON: {e}", config_path)
        except TypeError as e:
            raise ConfigurationError(f"Invalid config structure: {e}", config_path)
        except Exception as e:
            logger.warning(f"Error loading config: {e}. Using defaults.")
            return cls()

    def save(self, config_path: Path) -> None:
        """
        Save configuration to JSON file.
        
        Args:
            config_path: Path to save configuration
            
        Raises:
            ConfigurationError: If saving fails
        """
        try:
            config_path.parent.mkdir(parents=True, exist_ok=True)
            with open(config_path, "w", encoding="utf-8") as f:
                json.dump(asdict(self), f, indent=2)
        except (OSError, IOError) as e:
            raise ConfigurationError(f"Failed to save config: {e}", config_path)

    def to_dict(self) -> dict[str, Any]:
        """Convert to dictionary."""
        return asdict(self)
