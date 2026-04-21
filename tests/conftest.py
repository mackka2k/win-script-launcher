"""Test configuration and fixtures."""

from __future__ import annotations

import os
from pathlib import Path

import pytest

from src.config import AppConfig
from src.script_executor import ScriptExecutor
from src.script_manager import ScriptManager

IS_WINDOWS = os.name == "nt"


@pytest.fixture
def scripts_dir(tmp_path: Path) -> Path:
    folder = tmp_path / "scripts"
    folder.mkdir()
    return folder


@pytest.fixture
def cache_path(tmp_path: Path) -> Path:
    return tmp_path / "cache.json"


@pytest.fixture
def app_config() -> AppConfig:
    return AppConfig()


@pytest.fixture
def script_manager(scripts_dir: Path, cache_path: Path) -> ScriptManager:
    return ScriptManager(scripts_dir, cache_path=cache_path)


@pytest.fixture
def script_executor() -> ScriptExecutor:
    return ScriptExecutor(timeout_seconds=10)


@pytest.fixture
def python_script_factory(scripts_dir: Path):
    """Factory that creates a Python script returning the given exit code."""

    def make(name: str = "hello.py", body: str = "print('hello')") -> Path:
        path = scripts_dir / name
        path.write_text(body, encoding="utf-8")
        return path

    return make


@pytest.fixture
def batch_script_factory(scripts_dir: Path):
    """Factory that creates a batch script (Windows only)."""

    def make(name: str = "hello.bat", body: str = "@echo off\necho hello\n") -> Path:
        path = scripts_dir / name
        path.write_text(body, encoding="utf-8")
        return path

    return make


def pytest_collection_modifyitems(config, items):  # noqa: ARG001
    """Skip Windows-only tests on non-Windows platforms."""
    skip_non_windows = pytest.mark.skip(reason="Windows-only")
    for item in items:
        if "windows" in item.keywords and not IS_WINDOWS:
            item.add_marker(skip_non_windows)


__all__ = ["IS_WINDOWS"]
