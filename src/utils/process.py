"""Process management utilities for script execution."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

from loguru import logger

from ..models import ScriptType


def get_script_command(script_path: Path, script_type: ScriptType) -> list[str]:
    """Get the command to execute a script based on its type.

    Batch scripts are routed through ``cmd.exe /c`` so that their exit
    code is reliably reported and ``CREATE_NO_WINDOW`` can suppress the
    console flash.

    Raises:
        ValueError: If ``script_type`` is unsupported.
    """
    path_str = str(script_path)
    if script_type == ScriptType.PYTHON:
        return [sys.executable, "-u", path_str]
    if script_type == ScriptType.BATCH:
        if os.name == "nt":
            return ["cmd.exe", "/c", path_str]
        raise ValueError("Batch scripts are only supported on Windows")
    if script_type == ScriptType.POWERSHELL:
        if os.name == "nt":
            return [
                "powershell.exe",
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                path_str,
            ]
        # pwsh (PowerShell Core) fallback on non-Windows.
        return ["pwsh", "-NoProfile", "-File", path_str]
    raise ValueError(f"Unsupported script type: {script_type}")


def create_process(
    command: list[str],
    cwd: Path | None = None,
    env: dict[str, str] | None = None,
    attach_stdin: bool = False,
) -> subprocess.Popen[bytes]:
    """Spawn a subprocess with stdout/stderr capture and no console flash.

    The process is launched in binary mode so callers decode bytes
    themselves (see :func:`ScriptExecutor._pump_stream`). Passing
    ``attach_stdin=True`` allocates an input pipe so callers can write
    to the child; otherwise stdin is closed and subsequent writes will
    fail cleanly.
    """
    creation_flags = 0
    startupinfo = None
    if os.name == "nt":
        creation_flags = getattr(subprocess, "CREATE_NO_WINDOW", 0)
        startupinfo = subprocess.STARTUPINFO()  # type: ignore[attr-defined]
        startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW  # type: ignore[attr-defined]

    return subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        stdin=subprocess.PIPE if attach_stdin else subprocess.DEVNULL,
        bufsize=0,
        cwd=str(cwd) if cwd else None,
        env=env,
        shell=False,
        creationflags=creation_flags,
        startupinfo=startupinfo,
    )


def launch_detached(script_path: Path) -> None:
    """Launch a script in a detached, user-visible window.

    Used for interactive batch scripts that require their own console.
    No output capture, no cancellation.
    """
    if os.name == "nt":
        os.startfile(str(script_path))  # type: ignore[attr-defined]
        return
    # Non-Windows best-effort fallback.
    subprocess.Popen(
        ["xdg-open", str(script_path)],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )


def terminate_process(
    process: subprocess.Popen[bytes] | subprocess.Popen[str],
    timeout: float = 2.0,
) -> bool:
    """Terminate a process and its descendants.

    On Windows we must kill the **whole tree in a single call** via
    ``taskkill /F /T``: batch scripts frequently spawn ``powershell.exe``
    or other helpers, and once ``cmd.exe`` dies those grandchildren get
    reparented and no longer appear in ``taskkill /T``'s walk. So we
    issue the tree kill first, then wait for the parent to reap.
    On other platforms we fall back to ``terminate`` -> ``kill``.
    """
    if process.poll() is not None:
        return True

    try:
        if os.name == "nt":
            killed = _tree_kill_windows(process.pid)
            try:
                process.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                logger.warning("Parent still alive after tree kill; calling kill()")
                process.kill()
                try:
                    process.wait(timeout=1.0)
                except subprocess.TimeoutExpired:
                    logger.error("Process failed to exit after tree kill + kill()")
                    return False
            return killed

        process.terminate()
        try:
            process.wait(timeout=timeout)
            logger.debug("Process terminated gracefully")
            return True
        except subprocess.TimeoutExpired:
            logger.warning("Graceful termination timed out, force killing")
            process.kill()
            try:
                process.wait(timeout=1.0)
            except subprocess.TimeoutExpired:
                logger.error("Process failed to exit after kill()")
                return False
            return True
    except Exception as e:  # noqa: BLE001
        logger.error(f"Failed to terminate process: {e}")
        return False


def _tree_kill_windows(pid: int) -> bool:
    """Force-kill ``pid`` and every descendant via ``taskkill /F /T``.

    No-op (returns True) on non-Windows. Returns True whenever the
    ``taskkill`` call itself dispatched successfully — exit codes like
    "process not found" still mean the goal (no running children) has
    been met.
    """
    if os.name != "nt":
        return True

    creation_flags = getattr(subprocess, "CREATE_NO_WINDOW", 0)
    try:
        subprocess.run(
            ["taskkill", "/F", "/T", "/PID", str(pid)],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=5.0,
            creationflags=creation_flags,
            check=False,
        )
        return True
    except (OSError, subprocess.TimeoutExpired) as e:
        logger.warning(f"taskkill failed for PID {pid}: {e}")
        return False
