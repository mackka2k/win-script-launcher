"""Configuration management for Script Launcher.

Design:
    * ``AppConfig`` holds user-facing settings only (theme, window,
      execution, toggles). It is persisted to ``config.json``.
    * ``ScriptCache`` holds discovery cache and is persisted **separately**
      to ``cache.json`` so cache churn never corrupts user settings.
    * All datetime values are serialized via ISO 8601 strings.
"""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any

from loguru import logger

from .exceptions import ConfigurationError
from .validators import ConfigValidator


def _json_default(obj: Any) -> Any:
    """JSON encoder fallback for datetime and Path."""
    if isinstance(obj, datetime):
        return obj.isoformat()
    if isinstance(obj, Path):
        return str(obj)
    raise TypeError(f"Object of type {type(obj).__name__} is not JSON serializable")


@dataclass
class ThemeConfig:
    """Theme configuration."""

    mode: str = "dark"
    accent_color: str = "#1f6aa5"

    def __post_init__(self) -> None:
        ConfigValidator.validate_theme_mode(self.mode)
        ConfigValidator.validate_color(self.accent_color)


@dataclass
class WindowConfig:
    """Window configuration."""

    width: int = 1100
    height: int = 750
    remember_size: bool = True
    remember_position: bool = True
    last_x: int | None = None
    last_y: int | None = None

    def __post_init__(self) -> None:
        ConfigValidator.validate_window_size(self.width, self.height)


@dataclass
class ExecutionConfig:
    """Script execution configuration."""

    timeout_seconds: int = 300
    show_output_realtime: bool = True
    auto_scroll_output: bool = True
    max_output_lines: int = 10_000
    run_batch_in_new_window: bool = False
    """If True, .bat/.cmd scripts are launched in a detached cmd window
    (no output capture, no cancel). If False, they run in-process and
    their output is streamed into the embedded console."""

    def __post_init__(self) -> None:
        ConfigValidator.validate_timeout(self.timeout_seconds)
        ConfigValidator.validate_max_output_lines(self.max_output_lines)


@dataclass
class AppConfig:
    """Application configuration."""

    theme: ThemeConfig = field(default_factory=ThemeConfig)
    window: WindowConfig = field(default_factory=WindowConfig)
    execution: ExecutionConfig = field(default_factory=ExecutionConfig)
    enable_file_watcher: bool = True
    check_admin_on_startup: bool = True
    log_level: str = "INFO"

    def __post_init__(self) -> None:
        ConfigValidator.validate_log_level(self.log_level)

    @classmethod
    def load(cls, config_path: Path) -> AppConfig:
        """Load configuration from JSON file, falling back to defaults."""
        if not config_path.exists():
            logger.info("Config file not found, using defaults")
            return cls()

        try:
            with open(config_path, encoding="utf-8") as f:
                data = json.load(f)

            theme_data = data.pop("theme", {})
            window_data = data.pop("window", {})
            execution_data = data.pop("execution", {})
            # Drop legacy/unknown keys rather than crash.
            data.pop("script_cache", None)

            return cls(
                theme=ThemeConfig(**theme_data),
                window=WindowConfig(**window_data),
                execution=ExecutionConfig(**execution_data),
                **data,
            )
        except json.JSONDecodeError as e:
            raise ConfigurationError(f"Invalid JSON: {e}", config_path) from e
        except TypeError as e:
            raise ConfigurationError(
                f"Invalid config structure: {e}", config_path
            ) from e
        except Exception as e:  # noqa: BLE001 - never let config break startup
            logger.warning(f"Error loading config: {e}. Using defaults.")
            return cls()

    def save(self, config_path: Path) -> None:
        """Save configuration to JSON file atomically."""
        try:
            config_path.parent.mkdir(parents=True, exist_ok=True)
            tmp_path = config_path.with_suffix(config_path.suffix + ".tmp")
            with open(tmp_path, "w", encoding="utf-8") as f:
                json.dump(asdict(self), f, indent=2, default=_json_default)
            tmp_path.replace(config_path)
        except OSError as e:
            raise ConfigurationError(
                f"Failed to save config: {e}", config_path
            ) from e

    def to_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass
class CachedScript:
    """Serializable snapshot of a script's persistent metadata."""

    path: str
    name: str
    description: str = ""
    category: str = "General"
    last_run: str | None = None  # ISO 8601
    run_count: int = 0


@dataclass
class ScriptCache:
    """Disk-backed cache of discovered scripts."""

    last_scan: str = ""
    directory_signature: str = ""
    scripts: list[CachedScript] = field(default_factory=list)

    @classmethod
    def load(cls, cache_path: Path) -> ScriptCache:
        if not cache_path.exists():
            return cls()
        try:
            with open(cache_path, encoding="utf-8") as f:
                data = json.load(f)
            scripts = [CachedScript(**s) for s in data.pop("scripts", [])]
            return cls(scripts=scripts, **data)
        except Exception as e:  # noqa: BLE001 - cache is best-effort
            logger.warning(f"Failed to load cache: {e}. Rebuilding.")
            return cls()

    def save(self, cache_path: Path) -> None:
        try:
            cache_path.parent.mkdir(parents=True, exist_ok=True)
            tmp_path = cache_path.with_suffix(cache_path.suffix + ".tmp")
            with open(tmp_path, "w", encoding="utf-8") as f:
                json.dump(asdict(self), f, indent=2, default=_json_default)
            tmp_path.replace(cache_path)
        except OSError as e:
            logger.warning(f"Failed to save cache: {e}")
