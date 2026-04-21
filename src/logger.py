"""Centralized logging configuration using loguru."""

from __future__ import annotations

import sys
from pathlib import Path

from loguru import logger


def setup_logging(
    log_dir: Path | None = None,
    log_level: str = "INFO",
    rotation: str = "10 MB",
    retention: str = "1 week",
) -> None:
    """Configure application logging.

    Both console and file sinks are optional and added only when viable:
    windowed executables have no ``sys.stderr``; disk-less environments
    should not crash on logging setup.
    """
    logger.remove()

    if sys.stderr is not None:
        logger.add(
            sys.stderr,
            format=(
                "<green>{time:YYYY-MM-DD HH:mm:ss}</green> | "
                "<level>{level: <8}</level> | "
                "<cyan>{name}</cyan>:<cyan>{function}</cyan>:<cyan>{line}</cyan> "
                "- <level>{message}</level>"
            ),
            level=log_level,
            colorize=True,
            enqueue=True,
        )

    if log_dir is not None:
        try:
            log_dir.mkdir(parents=True, exist_ok=True)
            logger.add(
                log_dir / "script_launcher_{time:YYYY-MM-DD}.log",
                format=(
                    "{time:YYYY-MM-DD HH:mm:ss.SSS} | {level: <8} | "
                    "{name}:{function}:{line} - {message}"
                ),
                level=log_level,
                rotation=rotation,
                retention=retention,
                compression="zip",
                enqueue=True,
            )
        except OSError as e:
            # File logging is optional; console logging (if any) continues.
            if sys.stderr is not None:
                logger.warning(f"Failed to setup file logging: {e}")

    logger.info(f"Logging initialized at level {log_level}")


def get_logger(name: str | None = None):
    """Return a loguru logger, optionally bound to ``name``."""
    return logger.bind(name=name) if name else logger
