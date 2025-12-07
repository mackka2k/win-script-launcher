"""Centralized logging configuration using loguru."""

import sys
from pathlib import Path
from typing import Optional

from loguru import logger


def setup_logging(
    log_dir: Optional[Path] = None,
    log_level: str = "INFO",
    rotation: str = "10 MB",
    retention: str = "1 week",
) -> None:
    """
    Configure application logging.

    Args:
        log_dir: Directory to store log files (optional)
        log_level: Minimum log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        rotation: When to rotate log files
        retention: How long to keep old log files
    """
    # Remove default handler
    logger.remove()

    # Add console handler with colors (only if stderr is available)
    # In windowed executables, sys.stderr is None
    if sys.stderr is not None:
        logger.add(
            sys.stderr,
            format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> - <level>{message}</level>",
            level=log_level,
            colorize=True,
        )

    # Add file handler with rotation (only if log_dir is provided)
    if log_dir is not None:
        try:
            # Create log directory
            log_dir.mkdir(parents=True, exist_ok=True)

            # Add file handler with rotation
            logger.add(
                log_dir / "script_launcher_{time:YYYY-MM-DD}.log",
                format="{time:YYYY-MM-DD HH:mm:ss} | {level: <8} | {name}:{function}:{line} - {message}",
                level=log_level,
                rotation=rotation,
                retention=retention,
                compression="zip",
            )
            logger.info(f"File logging enabled: {log_dir}")
        except Exception as e:
            # If file logging fails, we still have console logging (if available)
            if sys.stderr is not None:
                logger.warning(f"Failed to setup file logging: {e}")

    logger.info(f"Logging initialized at level {log_level}")


def get_logger(name: Optional[str] = None) -> "logger":  # type: ignore
    """
    Get a logger instance.

    Args:
        name: Optional name for the logger

    Returns:
        Logger instance
    """
    if name:
        return logger.bind(name=name)
    return logger
