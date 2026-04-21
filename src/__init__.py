"""Script Launcher - A modern GUI application for running scripts."""

from __future__ import annotations

__version__ = "3.0.0"
__author__ = "Script Launcher Team"

from .app import Application, main
from .config import AppConfig
from .models import ExecutionStatus, Script, ScriptExecution, ScriptType
from .script_executor import ScriptExecutor
from .script_manager import ScriptManager

__all__ = [
    "Application",
    "main",
    "AppConfig",
    "Script",
    "ScriptType",
    "ScriptExecution",
    "ExecutionStatus",
    "ScriptManager",
    "ScriptExecutor",
    "__version__",
]
