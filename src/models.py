"""Data models for the Script Launcher application."""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from threading import Lock


class ScriptType(Enum):
    """Supported script types."""

    PYTHON = "python"
    BATCH = "batch"
    POWERSHELL = "powershell"
    UNKNOWN = "unknown"

    @classmethod
    def from_extension(cls, ext: str) -> ScriptType:
        """Get script type from file extension."""
        ext = ext.lower()
        if ext == ".py":
            return cls.PYTHON
        if ext in (".bat", ".cmd"):
            return cls.BATCH
        if ext == ".ps1":
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
    last_run: datetime | None = None
    run_count: int = 0

    @classmethod
    def from_path(cls, path: Path) -> Script:
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
        return hash(self.path)

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Script):
            return NotImplemented
        return self.path == other.path


DEFAULT_MAX_OUTPUT_LINES = 10_000


@dataclass
class ScriptExecution:
    """Represents a script execution instance.

    Output is bounded by ``max_output_lines`` to prevent unbounded memory
    growth for long-running or chatty scripts. Oldest lines are dropped.
    """

    script: Script
    status: ExecutionStatus = ExecutionStatus.PENDING
    start_time: datetime | None = None
    end_time: datetime | None = None
    return_code: int | None = None
    error_message: str | None = None
    max_output_lines: int = DEFAULT_MAX_OUTPUT_LINES
    cancel_requested: bool = False
    _output: deque[str] = field(init=False, repr=False)
    _output_lock: Lock = field(init=False, repr=False, compare=False)

    def __post_init__(self) -> None:
        self._output = deque(maxlen=self.max_output_lines)
        self._output_lock = Lock()

    @property
    def output(self) -> list[str]:
        """Snapshot of output as a list (thread-safe)."""
        with self._output_lock:
            return list(self._output)

    @property
    def duration(self) -> float | None:
        """Get execution duration in seconds."""
        if self.start_time and self.end_time:
            return (self.end_time - self.start_time).total_seconds()
        return None

    def add_output(self, line: str) -> None:
        """Add a line of output (thread-safe, bounded)."""
        with self._output_lock:
            self._output.append(line)

    @property
    def full_output(self) -> str:
        """Get full output as a single string."""
        return "".join(self.output)

    @property
    def is_terminal(self) -> bool:
        """True if the execution has reached a terminal state."""
        return self.status in {
            ExecutionStatus.SUCCESS,
            ExecutionStatus.FAILED,
            ExecutionStatus.TIMEOUT,
            ExecutionStatus.CANCELLED,
        }
