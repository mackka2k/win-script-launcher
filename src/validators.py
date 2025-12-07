"""Input validation and sanitization utilities."""

import re
from pathlib import Path
from typing import Optional

from loguru import logger

from .exceptions import ValidationError


class PathValidator:
    """Validator for file system paths."""

    @staticmethod
    def is_safe_path(path: Path, base_dir: Path) -> bool:
        """
        Ensure path doesn't escape base directory (path traversal protection).

        Args:
            path: Path to validate
            base_dir: Base directory that path must be within

        Returns:
            True if path is safe, False otherwise
        """
        try:
            resolved = path.resolve()
            base_resolved = base_dir.resolve()
            return resolved.is_relative_to(base_resolved)
        except (ValueError, OSError) as e:
            logger.warning(f"Path validation failed: {e}")
            return False

    @staticmethod
    def sanitize_filename(filename: str, max_length: int = 255) -> str:
        """
        Remove dangerous characters from filename.

        Args:
            filename: Original filename
            max_length: Maximum allowed length

        Returns:
            Sanitized filename
        """
        # Remove path separators and dangerous characters
        safe = re.sub(r'[/\\:\*\?"<>\|\x00-\x1f]', '_', filename)
        # Remove leading/trailing spaces and dots
        safe = safe.strip('. ')
        # Limit length
        return safe[:max_length]

    @staticmethod
    def validate_script_path(path: Path, scripts_dir: Path) -> None:
        """
        Validate that a script path is safe and exists.

        Args:
            path: Script path to validate
            scripts_dir: Base scripts directory

        Raises:
            ValidationError: If path is invalid or unsafe
        """
        if not path.exists():
            raise ValidationError("path", str(path), "File does not exist")

        if not path.is_file():
            raise ValidationError("path", str(path), "Path is not a file")

        if not PathValidator.is_safe_path(path, scripts_dir):
            raise ValidationError(
                "path", str(path), "Path escapes scripts directory (security risk)"
            )


class ConfigValidator:
    """Validator for configuration values."""

    @staticmethod
    def validate_timeout(timeout: int) -> None:
        """
        Validate timeout value.

        Args:
            timeout: Timeout in seconds

        Raises:
            ValidationError: If timeout is invalid
        """
        if timeout < 1:
            raise ValidationError("timeout", timeout, "Must be at least 1 second")
        if timeout > 3600:
            raise ValidationError("timeout", timeout, "Must not exceed 3600 seconds (1 hour)")

    @staticmethod
    def validate_window_size(width: int, height: int) -> None:
        """
        Validate window dimensions.

        Args:
            width: Window width in pixels
            height: Window height in pixels

        Raises:
            ValidationError: If dimensions are invalid
        """
        if width < 400 or width > 7680:
            raise ValidationError("width", width, "Must be between 400 and 7680 pixels")
        if height < 300 or height > 4320:
            raise ValidationError("height", height, "Must be between 300 and 4320 pixels")

    @staticmethod
    def validate_log_level(level: str) -> None:
        """
        Validate log level.

        Args:
            level: Log level string

        Raises:
            ValidationError: If log level is invalid
        """
        valid_levels = {"DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"}
        if level.upper() not in valid_levels:
            raise ValidationError(
                "log_level", level, f"Must be one of: {', '.join(valid_levels)}"
            )

    @staticmethod
    def validate_theme_mode(mode: str) -> None:
        """
        Validate theme mode.

        Args:
            mode: Theme mode string

        Raises:
            ValidationError: If theme mode is invalid
        """
        valid_modes = {"light", "dark"}
        if mode.lower() not in valid_modes:
            raise ValidationError("theme_mode", mode, "Must be 'light' or 'dark'")

    @staticmethod
    def validate_color(color: str) -> None:
        """
        Validate hex color code.

        Args:
            color: Hex color string

        Raises:
            ValidationError: If color is invalid
        """
        if not re.match(r'^#[0-9A-Fa-f]{6}$', color):
            raise ValidationError("color", color, "Must be a valid hex color (e.g., #0078d4)")
