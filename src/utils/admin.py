"""Admin privilege utilities (Windows primary, best-effort elsewhere)."""

from __future__ import annotations

import os
import subprocess
import sys
from collections.abc import Sequence

from loguru import logger


def is_admin() -> bool:
    """Return True if running with administrator/root privileges."""
    if os.name == "nt":
        try:
            import ctypes

            return bool(ctypes.windll.shell32.IsUserAnAdmin())
        except Exception as e:  # noqa: BLE001
            logger.warning(f"Failed to check admin status: {e}")
            return False
    try:
        return os.geteuid() == 0  # type: ignore[attr-defined]
    except AttributeError:
        return False


def _quote_windows_args(args: Sequence[str]) -> str:
    """Quote arguments for Windows ``ShellExecuteW`` / ``CreateProcess``."""
    parts = []
    for arg in args:
        if not arg:
            parts.append('""')
            continue
        if any(c in arg for c in ' \t"'):
            escaped = arg.replace("\\", "\\\\").replace('"', '\\"')
            parts.append(f'"{escaped}"')
        else:
            parts.append(arg)
    return " ".join(parts)


def elevate_privileges() -> bool:
    """Restart the current process with elevated privileges.

    Returns:
        True if the elevation request was dispatched successfully. The
        caller should exit after a True return; the original (unelevated)
        process does not continue running.
    """
    if is_admin():
        return True

    if os.name != "nt":
        logger.warning("Privilege elevation not supported on this platform")
        return False

    try:
        import ctypes

        frozen = bool(getattr(sys, "frozen", False))
        if frozen:
            executable = sys.executable
            params = _quote_windows_args(sys.argv[1:])
        else:
            executable = sys.executable
            script = os.path.abspath(sys.argv[0])
            params = _quote_windows_args([script, *sys.argv[1:]])

        sw_shownormal = 1
        # ShellExecuteW returns an HINSTANCE > 32 on success.
        hinstance = ctypes.windll.shell32.ShellExecuteW(
            None, "runas", executable, params, None, sw_shownormal
        )
        if int(hinstance) <= 32:
            logger.error(f"ShellExecuteW failed (code {hinstance})")
            return False
        return True
    except Exception as e:  # noqa: BLE001
        logger.error(f"Failed to elevate privileges: {e}")
        return False


def require_admin() -> bool:
    """Log whether admin privileges are present. Returns True if they are."""
    if is_admin():
        logger.info("Running with administrator privileges")
        return True
    logger.warning("Administrator privileges not detected")
    return False


# Keep ``subprocess`` importable-from-here for tests/back-compat.
__all__ = ["is_admin", "elevate_privileges", "require_admin", "subprocess"]
