"""Tests for ScriptExecutor."""

from __future__ import annotations

import time
from pathlib import Path

import pytest

from src.exceptions import ScriptNotFoundError
from src.models import ExecutionStatus, Script, ScriptType
from src.script_executor import ScriptExecutor


def _wait_until(predicate, timeout: float = 10.0, interval: float = 0.05) -> bool:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if predicate():
            return True
        time.sleep(interval)
    return False


class TestScriptExecutor:
    """Unit tests targeting the Python-script execution path (portable)."""

    def test_initialization(self, script_executor: ScriptExecutor) -> None:
        assert script_executor.timeout_seconds == 10
        assert script_executor.get_active_count() == 0

    def test_execute_nonexistent_script_raises(self, script_executor: ScriptExecutor) -> None:
        fake = Script(
            path=Path("/definitely/does/not/exist.py"),
            name="fake.py",
            script_type=ScriptType.PYTHON,
        )
        with pytest.raises(ScriptNotFoundError):
            script_executor.execute_script(fake)

    def test_execute_python_success(
        self,
        script_executor: ScriptExecutor,
        python_script_factory,
    ) -> None:
        path = python_script_factory(body="print('hello-output')")
        script = Script.from_path(path)

        output: list[str] = []
        completed: list = []

        execution = script_executor.execute_script(
            script,
            output_callback=output.append,
            completion_callback=completed.append,
        )
        assert execution.script == script

        assert _wait_until(lambda: execution.is_terminal, timeout=15)
        assert execution.status == ExecutionStatus.SUCCESS
        assert execution.return_code == 0
        assert "hello-output" in "".join(output)
        assert "hello-output" in execution.full_output
        assert len(completed) == 1

    def test_failed_script_reports_failed(
        self,
        script_executor: ScriptExecutor,
        python_script_factory,
    ) -> None:
        path = python_script_factory(body="import sys; sys.exit(3)")
        script = Script.from_path(path)

        execution = script_executor.execute_script(script)
        assert _wait_until(lambda: execution.is_terminal, timeout=15)
        assert execution.status == ExecutionStatus.FAILED
        assert execution.return_code == 3

    def test_timeout(
        self,
        python_script_factory,
    ) -> None:
        executor = ScriptExecutor(timeout_seconds=1)
        path = python_script_factory(name="sleep.py", body="import time; time.sleep(10)")
        script = Script.from_path(path)

        execution = executor.execute_script(script)
        assert _wait_until(lambda: execution.is_terminal, timeout=10)
        assert execution.status == ExecutionStatus.TIMEOUT

    def test_cancel_execution(
        self,
        script_executor: ScriptExecutor,
        python_script_factory,
    ) -> None:
        path = python_script_factory(name="longsleep.py", body="import time; time.sleep(30)")
        script = Script.from_path(path)

        execution = script_executor.execute_script(script)
        assert _wait_until(lambda: script_executor.is_running(script), timeout=5)

        assert script_executor.cancel_execution(script)
        assert _wait_until(lambda: execution.is_terminal, timeout=5)
        assert execution.status == ExecutionStatus.CANCELLED

    def test_cancel_nonexistent_execution(
        self,
        script_executor: ScriptExecutor,
        python_script_factory,
    ) -> None:
        path = python_script_factory()
        script = Script.from_path(path)
        assert script_executor.cancel_execution(script) is False

    def test_cancel_all(
        self,
        script_executor: ScriptExecutor,
        python_script_factory,
    ) -> None:
        path_a = python_script_factory(name="a.py", body="import time; time.sleep(30)")
        path_b = python_script_factory(name="b.py", body="import time; time.sleep(30)")
        script_a = Script.from_path(path_a)
        script_b = Script.from_path(path_b)

        script_executor.execute_script(script_a)
        script_executor.execute_script(script_b)
        assert _wait_until(lambda: script_executor.get_active_count() == 2, timeout=5)

        cancelled = script_executor.cancel_all()
        assert cancelled == 2
        assert _wait_until(lambda: script_executor.get_active_count() == 0, timeout=5)

    def test_is_running_lifecycle(
        self,
        script_executor: ScriptExecutor,
        python_script_factory,
    ) -> None:
        path = python_script_factory(name="mid.py", body="import time; time.sleep(15)")
        script = Script.from_path(path)

        assert not script_executor.is_running(script)
        script_executor.execute_script(script)
        assert _wait_until(lambda: script_executor.is_running(script), timeout=5)

        script_executor.cancel_execution(script)
        assert _wait_until(lambda: not script_executor.is_running(script), timeout=5)

    def test_run_count_and_last_run_updated(
        self,
        script_executor: ScriptExecutor,
        python_script_factory,
    ) -> None:
        path = python_script_factory()
        script = Script.from_path(path)
        assert script.run_count == 0
        assert script.last_run is None

        execution = script_executor.execute_script(script)
        assert _wait_until(lambda: execution.is_terminal, timeout=10)

        assert script.run_count == 1
        assert script.last_run is not None

    def test_duplicate_execution_returns_existing(
        self,
        script_executor: ScriptExecutor,
        python_script_factory,
    ) -> None:
        path = python_script_factory(name="dup.py", body="import time; time.sleep(5)")
        script = Script.from_path(path)
        e1 = script_executor.execute_script(script)
        e2 = script_executor.execute_script(script)
        assert e1 is e2
        script_executor.cancel_execution(script)
        assert _wait_until(lambda: e1.is_terminal, timeout=5)

    def test_execution_writes_audit_log(self, tmp_path: Path, python_script_factory) -> None:
        executor = ScriptExecutor(timeout_seconds=10, log_dir=tmp_path / "logs")
        path = python_script_factory(body="print('logged-output')")
        script = Script.from_path(path)

        execution = executor.execute_script(script)

        assert _wait_until(lambda: execution.is_terminal, timeout=10)
        assert execution.log_path is not None
        assert execution.log_path.exists()
        log_text = execution.log_path.read_text(encoding="utf-8")
        assert "START" in log_text
        assert "logged-output" in log_text
        assert "END success" in log_text

    def test_send_input_to_running_script(
        self, script_executor: ScriptExecutor, python_script_factory
    ) -> None:
        path = python_script_factory(
            name="input.py",
            body=(
                "name = input('Name: ')\n"
                "print(f'hello {name}')\n"
            ),
        )
        script = Script.from_path(path)

        execution = script_executor.execute_script(script)

        assert _wait_until(lambda: "Name: " in execution.full_output, timeout=10)
        assert script_executor.send_input(script, "Alice")
        assert _wait_until(lambda: execution.is_terminal, timeout=10)

        assert execution.status == ExecutionStatus.SUCCESS
        assert "hello Alice" in execution.full_output

    def test_send_input_without_active_script_returns_false(
        self, script_executor: ScriptExecutor, python_script_factory
    ) -> None:
        path = python_script_factory()
        script = Script.from_path(path)

        assert script_executor.send_input(script, "ignored") is False

    def test_chatty_output_is_delivered_in_batches(
        self, script_executor: ScriptExecutor, python_script_factory
    ) -> None:
        path = python_script_factory(
            name="chatty.py",
            body=(
                "import sys\n"
                "sys.stdout.write('x' * 10000)\n"
                "sys.stdout.flush()\n"
            ),
        )
        script = Script.from_path(path)
        output: list[str] = []

        execution = script_executor.execute_script(script, output_callback=output.append)

        assert _wait_until(lambda: execution.is_terminal, timeout=10)
        assert execution.status == ExecutionStatus.SUCCESS
        assert "x" * 10000 in execution.full_output
        assert len(output) < 20


@pytest.mark.windows
class TestBatchExecution:
    """Windows-only: in-process batch execution via cmd.exe /c."""

    def test_batch_script_success(
        self, script_executor: ScriptExecutor, batch_script_factory
    ) -> None:
        path = batch_script_factory(name="hi.bat", body="@echo off\r\necho batch-ok\r\n")
        script = Script.from_path(path)

        output: list[str] = []
        execution = script_executor.execute_script(script, output_callback=output.append)

        assert _wait_until(lambda: execution.is_terminal, timeout=15)
        assert execution.status == ExecutionStatus.SUCCESS
        assert "batch-ok" in execution.full_output
