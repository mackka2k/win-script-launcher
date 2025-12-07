"""Process management utilities for script execution."""

import os
import subprocess
import sys
from pathlib import Path
from typing import Optional

from loguru import logger

from ..models import ScriptType


def get_script_command(script_path: Path, script_type: ScriptType) -> list[str]:
    """
    Get the command to execute a script based on its type.

    Args:
        script_path: Path to the script file
        script_type: Type of the script

    Returns:
        Command as a list of strings
    """
    if script_type == ScriptType.PYTHON:
        return [sys.executable, str(script_path)]
    elif script_type == ScriptType.BATCH:
        return [str(script_path)]
    elif script_type == ScriptType.POWERSHELL:
        return ["powershell.exe", "-ExecutionPolicy", "Bypass", "-File", str(script_path)]
    else:
        raise ValueError(f"Unsupported script type: {script_type}")


def create_process(
    command: list[str], cwd: Optional[Path] = None, shell: bool = False
) -> subprocess.Popen:  # type: ignore
    """
    Create a subprocess for script execution.

    Args:
        command: Command to execute
        cwd: Working directory for the process
        shell: Whether to use shell execution

    Returns:
        Popen process object
    """
    creation_flags = 0
    if os.name == "nt":
        # Prevent console window from appearing on Windows
        creation_flags = subprocess.CREATE_NO_WINDOW

    process = subprocess.Popen(
        command,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        stdin=subprocess.PIPE,
        text=True,
        bufsize=1,
        universal_newlines=True,
        cwd=str(cwd) if cwd else None,
        shell=shell,
        creationflags=creation_flags,
    )

    return process


def terminate_process(process: subprocess.Popen, timeout: float = 2.0) -> bool:  # type: ignore
    """
    Gracefully terminate a process with fallback to force kill.

    Args:
        process: Process to terminate
        timeout: Seconds to wait before force killing

    Returns:
        True if process was terminated successfully
    """
    if process.poll() is not None:
        # Process already terminated
        return True

    try:
        # Try graceful termination first
        process.terminate()

        try:
            process.wait(timeout=timeout)
            logger.info("Process terminated gracefully")
            return True
        except subprocess.TimeoutExpired:
            # Force kill if graceful termination fails
            logger.warning("Graceful termination timed out, force killing process")
            process.kill()
            process.wait(timeout=1.0)
            return True
    except Exception as e:
        logger.error(f"Failed to terminate process: {e}")
        return False
