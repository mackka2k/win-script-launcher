"""Input validation and sanitization utilities."""

from __future__ import annotations

import re
from pathlib import Path

from loguru import logger

from .exceptions import ValidationError

_ALLOWED_SCRIPT_SUFFIXES = {".py", ".bat", ".cmd", ".ps1"}


class PathValidator:
    """Validator for file system paths."""

    @staticmethod
    def is_safe_path(path: Path, base_dir: Path) -> bool:
        """Ensure ``path`` doesn't escape ``base_dir`` (traversal protection)."""
        try:
            resolved = path.resolve()
            base_resolved = base_dir.resolve()
        except (ValueError, OSError) as e:
            logger.warning(f"Path validation failed: {e}")
            return False

        try:
            return resolved.is_relative_to(base_resolved)
        except AttributeError:
            # Python < 3.9 fallback (shouldn't hit since we require 3.10+)
            try:
                resolved.relative_to(base_resolved)
                return True
            except ValueError:
                return False

    @staticmethod
    def sanitize_filename(filename: str, max_length: int = 255) -> str:
        """Remove dangerous characters from filename."""
        safe = re.sub(r'[/\\:\*\?"<>\|\x00-\x1f]', "_", filename)
        safe = safe.strip(". ")
        return safe[:max_length]

    @staticmethod
    def validate_script_path(path: Path, scripts_dir: Path) -> None:
        """Validate that a script path is safe, exists, and is supported.

        Raises:
            ValidationError: If path is invalid, unsafe, or unsupported.
        """
        if not path.exists():
            raise ValidationError("path", str(path), "File does not exist")

        if not path.is_file():
            raise ValidationError("path", str(path), "Path is not a file")

        if path.suffix.lower() not in _ALLOWED_SCRIPT_SUFFIXES:
            raise ValidationError(
                "path",
                str(path),
                f"Unsupported extension '{path.suffix}'. "
                f"Allowed: {sorted(_ALLOWED_SCRIPT_SUFFIXES)}",
            )

        if not PathValidator.is_safe_path(path, scripts_dir):
            raise ValidationError(
                "path",
                str(path),
                "Path escapes scripts directory (security risk)",
            )


class ConfigValidator:
    """Validator for configuration values."""

    @staticmethod
    def validate_timeout(timeout: int) -> None:
        if timeout < 1:
            raise ValidationError("timeout", timeout, "Must be at least 1 second")
        if timeout > 3600:
            raise ValidationError(
                "timeout", timeout, "Must not exceed 3600 seconds (1 hour)"
            )

    @staticmethod
    def validate_window_size(width: int, height: int) -> None:
        if width < 400 or width > 7680:
            raise ValidationError(
                "width", width, "Must be between 400 and 7680 pixels"
            )
        if height < 300 or height > 4320:
            raise ValidationError(
                "height", height, "Must be between 300 and 4320 pixels"
            )

    @staticmethod
    def validate_log_level(level: str) -> None:
        valid_levels = {"DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"}
        if level.upper() not in valid_levels:
            raise ValidationError(
                "log_level", level, f"Must be one of: {', '.join(sorted(valid_levels))}"
            )

    @staticmethod
    def validate_theme_mode(mode: str) -> None:
        valid_modes = {"light", "dark", "system"}
        if mode.lower() not in valid_modes:
            raise ValidationError(
                "theme_mode", mode, f"Must be one of: {', '.join(sorted(valid_modes))}"
            )

    @staticmethod
    def validate_color(color: str) -> None:
        if not re.match(r"^#[0-9A-Fa-f]{6}$", color):
            raise ValidationError(
                "color", color, "Must be a valid hex color (e.g., #0078d4)"
            )

    @staticmethod
    def validate_max_output_lines(max_lines: int) -> None:
        if max_lines < 100:
            raise ValidationError(
                "max_output_lines", max_lines, "Must be at least 100"
            )
        if max_lines > 1_000_000:
            raise ValidationError(
                "max_output_lines", max_lines, "Must not exceed 1,000,000"
            )
