"""Comprehensive tests for ScriptExecutor."""

import time
from pathlib import Path
from unittest.mock import Mock, patch

import pytest

from src.exceptions import ScriptNotFoundError, ScriptTimeoutError
from src.models import ExecutionStatus, Script, ScriptType
from src.script_executor import ScriptExecutor


class TestScriptExecutor:
    """Test suite for ScriptExecutor class."""

    @pytest.fixture
    def executor(self):
        """Create a ScriptExecutor instance for testing."""
        return ScriptExecutor(timeout_seconds=10)

    @pytest.fixture
    def mock_script(self, tmp_path):
        """Create a mock script file for testing."""
        script_file = tmp_path / "test.bat"
        script_file.write_text("@echo off\necho Test Output\n")
        return Script.from_path(script_file)

    @pytest.fixture
    def long_running_script(self, tmp_path):
        """Create a script that runs for a long time."""
        script_file = tmp_path / "long.bat"
        script_file.write_text("@echo off\ntimeout /t 30 /nobreak\n")
        return Script.from_path(script_file)

    def test_executor_initialization(self, executor):
        """Test ScriptExecutor initializes correctly."""
        assert executor.timeout_seconds == 10
        assert len(executor.active_executions) == 0
        assert len(executor.processes) == 0

    def test_execute_script_success(self, executor, mock_script):
        """Test successful script execution."""
        output_lines = []
        completion_called = []

        def on_output(line: str):
            output_lines.append(line)

        def on_completion(execution):
            completion_called.append(execution)

        execution = executor.execute_script(
            mock_script, output_callback=on_output, completion_callback=on_completion
        )

        assert execution.status == ExecutionStatus.PENDING
        assert execution.script == mock_script

        # Wait for completion
        time.sleep(2)

        assert execution.status == ExecutionStatus.SUCCESS
        assert execution.return_code == 0
        assert len(output_lines) > 0
        assert len(completion_called) == 1

    def test_execute_nonexistent_script(self, executor):
        """Test executing a script that doesn't exist."""
        fake_script = Script(
            path=Path("/nonexistent/script.bat"), name="fake.bat", script_type=ScriptType.BATCH
        )

        with pytest.raises(ScriptNotFoundError):
            executor.execute_script(fake_script)

    def test_script_timeout(self, executor, long_running_script):
        """Test script execution timeout."""
        executor.timeout_seconds = 2

        execution = executor.execute_script(long_running_script)

        # Wait for timeout
        time.sleep(4)

        assert execution.status == ExecutionStatus.TIMEOUT

    def test_cancel_execution(self, executor, long_running_script):
        """Test cancelling a running script."""
        execution = executor.execute_script(long_running_script)

        # Give it time to start
        time.sleep(0.5)

        success = executor.cancel_execution(long_running_script)

        assert success
        assert execution.status == ExecutionStatus.CANCELLED

    def test_cancel_nonexistent_execution(self, executor, mock_script):
        """Test cancelling a script that isn't running."""
        success = executor.cancel_execution(mock_script)
        assert not success

    def test_is_running(self, executor, long_running_script):
        """Test checking if a script is running."""
        assert not executor.is_running(long_running_script)

        executor.execute_script(long_running_script)
        time.sleep(0.5)

        assert executor.is_running(long_running_script)

        executor.cancel_execution(long_running_script)
        time.sleep(0.5)

        assert not executor.is_running(long_running_script)

    def test_get_active_count(self, executor, long_running_script, tmp_path):
        """Test getting count of active executions."""
        assert executor.get_active_count() == 0

        # Start multiple scripts
        script1 = long_running_script
        script2_file = tmp_path / "test2.bat"
        script2_file.write_text("@echo off\ntimeout /t 30 /nobreak\n")
        script2 = Script.from_path(script2_file)

        executor.execute_script(script1)
        executor.execute_script(script2)

        time.sleep(0.5)

        assert executor.get_active_count() == 2

        executor.cancel_all()
        time.sleep(0.5)

        assert executor.get_active_count() == 0

    def test_cancel_all(self, executor, long_running_script, tmp_path):
        """Test cancelling all running scripts."""
        # Start multiple scripts
        script1 = long_running_script
        script2_file = tmp_path / "test2.bat"
        script2_file.write_text("@echo off\ntimeout /t 30 /nobreak\n")
        script2 = Script.from_path(script2_file)

        executor.execute_script(script1)
        executor.execute_script(script2)

        time.sleep(0.5)

        cancelled_count = executor.cancel_all()

        assert cancelled_count == 2
        assert executor.get_active_count() == 0

    def test_output_callback_receives_all_output(self, executor, mock_script):
        """Test that output callback receives all script output."""
        output_lines = []

        def on_output(line: str):
            output_lines.append(line)

        executor.execute_script(mock_script, output_callback=on_output)

        time.sleep(2)

        assert len(output_lines) > 0
        assert any("Test Output" in line for line in output_lines)

    def test_execution_tracks_duration(self, executor, mock_script):
        """Test that execution tracks start and end times."""
        execution = executor.execute_script(mock_script)

        time.sleep(2)

        assert execution.start_time is not None
        assert execution.end_time is not None
        assert execution.duration is not None
        assert execution.duration > 0

    def test_script_run_count_increments(self, executor, mock_script):
        """Test that script run count increments after execution."""
        initial_count = mock_script.run_count

        executor.execute_script(mock_script)
        time.sleep(2)

        assert mock_script.run_count == initial_count + 1

    def test_script_last_run_updates(self, executor, mock_script):
        """Test that script last_run timestamp updates."""
        assert mock_script.last_run is None

        executor.execute_script(mock_script)
        time.sleep(2)

        assert mock_script.last_run is not None
