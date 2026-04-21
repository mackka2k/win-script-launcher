"""Custom exceptions for Script Launcher.

Exception hierarchy:

    ScriptLauncherError
        ScriptNotFoundError
        ScriptExecutionError
        ScriptTimeoutError
        ConfigurationError
        ValidationError
        AdminPrivilegeError
        FileWatcherError
"""

from __future__ import annotations

from pathlib import Path
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from .models import Script


class ScriptLauncherError(Exception):
    """Base exception for all Script Launcher errors."""


class ScriptNotFoundError(ScriptLauncherError):
    """Raised when a script file cannot be found."""

    def __init__(self, path: Path) -> None:
        self.path = path
        super().__init__(f"Script not found: {path}")


class ScriptExecutionError(ScriptLauncherError):
    """Raised when script execution fails."""

    def __init__(self, script: Script, return_code: int, message: str) -> None:
        self.script = script
        self.return_code = return_code
        super().__init__(
            f"Script '{script.name}' failed with code {return_code}: {message}"
        )


class ScriptTimeoutError(ScriptLauncherError):
    """Raised when script execution times out."""

    def __init__(self, script: Script, timeout: int) -> None:
        self.script = script
        self.timeout = timeout
        super().__init__(
            f"Script '{script.name}' timed out after {timeout} seconds"
        )


class ConfigurationError(ScriptLauncherError):
    """Raised when configuration is invalid or cannot be loaded."""

    def __init__(self, message: str, path: Path | None = None) -> None:
        self.path = path
        super().__init__(
            f"Configuration error: {message}" + (f" ({path})" if path else "")
        )


class ValidationError(ScriptLauncherError):
    """Raised when input validation fails."""

    def __init__(self, field: str, value: Any, message: str) -> None:
        self.field = field
        self.value = value
        super().__init__(f"Validation error for '{field}': {message}")


class AdminPrivilegeError(ScriptLauncherError):
    """Raised when operation requires elevated privileges.

    Note: intentionally NOT named ``PermissionError`` because the Python
    built-in ``PermissionError`` is a subclass of ``OSError`` and shadowing
    it causes subtle bugs.
    """

    def __init__(self, operation: str) -> None:
        self.operation = operation
        super().__init__(f"Administrator privileges required for: {operation}")


class FileWatcherError(ScriptLauncherError):
    """Raised when file watcher encounters an error."""

    def __init__(self, path: Path, message: str) -> None:
        self.path = path
        super().__init__(f"File watcher error for {path}: {message}")
