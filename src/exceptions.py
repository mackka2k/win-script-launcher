"""Custom exceptions for Script Launcher."""

from pathlib import Path
from typing import Optional

from .models import Script


class ScriptLauncherError(Exception):
    """Base exception for all Script Launcher errors."""

    pass


class ScriptNotFoundError(ScriptLauncherError):
    """Raised when a script file cannot be found."""

    def __init__(self, path: Path):
        self.path = path
        super().__init__(f"Script not found: {path}")


class ScriptExecutionError(ScriptLauncherError):
    """Raised when script execution fails."""

    def __init__(self, script: Script, return_code: int, message: str):
        self.script = script
        self.return_code = return_code
        super().__init__(f"Script '{script.name}' failed with code {return_code}: {message}")


class ScriptTimeoutError(ScriptLauncherError):
    """Raised when script execution times out."""

    def __init__(self, script: Script, timeout: int):
        self.script = script
        self.timeout = timeout
        super().__init__(f"Script '{script.name}' timed out after {timeout} seconds")


class ConfigurationError(ScriptLauncherError):
    """Raised when configuration is invalid or cannot be loaded."""

    def __init__(self, message: str, path: Optional[Path] = None):
        self.path = path
        super().__init__(f"Configuration error: {message}" + (f" ({path})" if path else ""))


class ValidationError(ScriptLauncherError):
    """Raised when input validation fails."""

    def __init__(self, field: str, value: any, message: str):
        self.field = field
        self.value = value
        super().__init__(f"Validation error for '{field}': {message}")


class PermissionError(ScriptLauncherError):
    """Raised when operation requires elevated privileges."""

    def __init__(self, operation: str):
        self.operation = operation
        super().__init__(f"Administrator privileges required for: {operation}")


class FileWatcherError(ScriptLauncherError):
    """Raised when file watcher encounters an error."""

    def __init__(self, path: Path, message: str):
        self.path = path
        super().__init__(f"File watcher error for {path}: {message}")
