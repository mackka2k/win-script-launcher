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
) -> subprocess.Popen[str]:
    """Spawn a subprocess with stdout/stderr capture and no console flash."""
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
        stdin=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        errors="replace",
        bufsize=1,
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
    process: subprocess.Popen[str], timeout: float = 2.0
) -> bool:
    """Gracefully terminate a process, falling back to force kill."""
    if process.poll() is not None:
        return True

    try:
        process.terminate()
        try:
            process.wait(timeout=timeout)
            logger.debug("Process terminated gracefully")
            return True
        except subprocess.TimeoutExpired:
            logger.warning("Graceful termination timed out, force killing process")
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
