"""Test configuration and fixtures."""

import pytest
from pathlib import Path
import tempfile
import shutil

from src.config import AppConfig
from src.script_manager import ScriptManager
from src.script_executor import ScriptExecutor


@pytest.fixture
def temp_dir():
    """Create a temporary directory for tests."""
    temp = Path(tempfile.mkdtemp())
    yield temp
    shutil.rmtree(temp)


@pytest.fixture
def scripts_dir(temp_dir):
    """Create a temporary scripts directory."""
    scripts = temp_dir / "scripts"
    scripts.mkdir()
    return scripts


@pytest.fixture
def sample_python_script(scripts_dir):
    """Create a sample Python script."""
    script = scripts_dir / "test_script.py"
    script.write_text('print("Hello from test script!")')
    return script


@pytest.fixture
def sample_batch_script(scripts_dir):
    """Create a sample batch script."""
    script = scripts_dir / "test_script.bat"
    script.write_text('@echo off\necho Hello from batch script!')
    return script


@pytest.fixture
def app_config():
    """Create a test app configuration."""
    return AppConfig()


@pytest.fixture
def script_manager(scripts_dir):
    """Create a script manager instance."""
    return ScriptManager(scripts_dir)


@pytest.fixture
def script_executor():
    """Create a script executor instance."""
    return ScriptExecutor(timeout_seconds=30)
