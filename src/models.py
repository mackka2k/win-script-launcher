"""Data models for the Script Launcher application."""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Optional


class ScriptType(Enum):
    """Supported script types."""

    PYTHON = "python"
    BATCH = "batch"
    POWERSHELL = "powershell"
    UNKNOWN = "unknown"

    @classmethod
    def from_extension(cls, ext: str) -> "ScriptType":
        """Get script type from file extension."""
        ext = ext.lower()
        if ext == ".py":
            return cls.PYTHON
        elif ext in [".bat", ".cmd"]:
            return cls.BATCH
        elif ext == ".ps1":
            return cls.POWERSHELL
        return cls.UNKNOWN


class ExecutionStatus(Enum):
    """Script execution status."""

    PENDING = "pending"
    RUNNING = "running"
    SUCCESS = "success"
    FAILED = "failed"
    TIMEOUT = "timeout"
    CANCELLED = "cancelled"


@dataclass
class Script:
    """Represents a script file."""

    path: Path
    name: str
    script_type: ScriptType
    description: str = ""
    category: str = "General"
    last_run: Optional[datetime] = None
    run_count: int = 0

    @classmethod
    def from_path(cls, path: Path) -> "Script":
        """Create a Script instance from a file path."""
        return cls(
            path=path,
            name=path.name,
            script_type=ScriptType.from_extension(path.suffix),
        )

    @property
    def display_name(self) -> str:
        """Get display name for the script."""
        return self.name

    def __hash__(self) -> int:
        """Make Script hashable for use in sets/dicts."""
        return hash(self.path)

    def __eq__(self, other: object) -> bool:
        """Compare scripts by path."""
        if not isinstance(other, Script):
            return NotImplemented
        return self.path == other.path


@dataclass
class ScriptExecution:
    """Represents a script execution instance."""

    script: Script
    status: ExecutionStatus = ExecutionStatus.PENDING
    output: list[str] = field(default_factory=list)
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    return_code: Optional[int] = None
    error_message: Optional[str] = None

    @property
    def duration(self) -> Optional[float]:
        """Get execution duration in seconds."""
        if self.start_time and self.end_time:
            return (self.end_time - self.start_time).total_seconds()
        return None

    def add_output(self, line: str) -> None:
        """Add a line of output."""
        self.output.append(line)

    @property
    def full_output(self) -> str:
        """Get full output as a single string."""
        return "".join(self.output)
