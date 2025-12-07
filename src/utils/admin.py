"""Admin privilege utilities for cross-platform support."""

import os
import sys
from typing import Callable, Optional

from loguru import logger


def is_admin() -> bool:
    """
    Check if the current process has administrator/root privileges.

    Returns:
        True if running with admin privileges, False otherwise
    """
    if os.name == "nt":  # Windows
        try:
            import ctypes

            return bool(ctypes.windll.shell32.IsUserAnAdmin())
        except Exception as e:
            logger.warning(f"Failed to check admin status: {e}")
            return False
    else:  # Unix-like (Linux, macOS)
        return os.geteuid() == 0


def elevate_privileges(callback: Optional[Callable[[], None]] = None) -> bool:
    """
    Attempt to elevate privileges by restarting the application as admin.

    Args:
        callback: Optional callback to execute before restarting

    Returns:
        True if elevation was attempted, False otherwise
    """
    if is_admin():
        return True

    if os.name == "nt":  # Windows
        try:
            import ctypes

            if callback:
                callback()

            # Get the script or executable path
            if getattr(sys, "frozen", False):
                # Running as compiled exe
                script = sys.executable
            else:
                # Running as script
                script = os.path.abspath(sys.argv[0])

            # Prepare arguments
            params = " ".join([f'"{arg}"' for arg in sys.argv[1:]])

            # Request elevation
            ctypes.windll.shell32.ShellExecuteW(
                None,
                "runas",  # Verb to run as admin
                sys.executable if getattr(sys, "frozen", False) else sys.executable,
                f'"{script}" {params}' if not getattr(sys, "frozen", False) else params,
                None,
                1,  # SW_SHOWNORMAL
            )

            return True
        except Exception as e:
            logger.error(f"Failed to elevate privileges: {e}")
            return False
    else:
        # On Unix, we can't easily elevate - user needs to run with sudo
        logger.warning("Privilege elevation not supported on this platform")
        return False


def require_admin(app_name: str = "This application") -> bool:
    """
    Check for admin privileges and prompt user to elevate if needed.

    Args:
        app_name: Name of the application for user messages

    Returns:
        True if admin privileges are available, False otherwise
    """
    if is_admin():
        logger.info("Running with administrator privileges")
        return True

    logger.warning("Administrator privileges not detected")
    return False
