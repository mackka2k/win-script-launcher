"""Script execution engine with real-time output streaming.

Contract:
    * ``execute_script`` raises ``ScriptNotFoundError`` synchronously if the
      script file does not exist.
    * Execution always runs in a background thread. The returned
      ``ScriptExecution`` moves from ``PENDING`` -> ``RUNNING`` -> terminal.
    * Callbacks (``output_callback``, ``completion_callback``) are invoked
      from the worker thread. UI consumers must marshal to the main thread.
    * Batch scripts are captured by default via ``cmd.exe /c``. Set
      ``run_batch_in_new_window=True`` (via config) to launch them detached
      in a new console window with no output capture.
"""

from __future__ import annotations

import subprocess
import threading
import time
from collections.abc import Callable
from datetime import datetime

from loguru import logger

from .exceptions import ScriptNotFoundError
from .models import ExecutionStatus, Script, ScriptExecution, ScriptType
from .utils.process import (
    create_process,
    get_script_command,
    launch_detached,
    terminate_process,
)

OutputCallback = Callable[[str], None]
CompletionCallback = Callable[[ScriptExecution], None]


class ScriptExecutor:
    """Executes scripts and manages their lifecycle."""

    def __init__(
        self,
        timeout_seconds: int = 300,
        max_output_lines: int = 10_000,
        run_batch_in_new_window: bool = False,
    ) -> None:
        self.timeout_seconds = timeout_seconds
        self.max_output_lines = max_output_lines
        self.run_batch_in_new_window = run_batch_in_new_window

        self._active: dict[str, ScriptExecution] = {}
        self._processes: dict[str, subprocess.Popen[str]] = {}
        self._lock = threading.Lock()

    # --- Public API ----------------------------------------------------

    def execute_script(
        self,
        script: Script,
        output_callback: OutputCallback | None = None,
        completion_callback: CompletionCallback | None = None,
    ) -> ScriptExecution:
        """Execute a script asynchronously.

        Raises:
            ScriptNotFoundError: If the script file does not exist.
        """
        if not script.path.exists():
            raise ScriptNotFoundError(script.path)

        execution_id = self._key(script)

        with self._lock:
            existing = self._active.get(execution_id)
            if existing is not None:
                logger.warning(f"Script already running: {script.name}")
                return existing

            execution = ScriptExecution(
                script=script,
                status=ExecutionStatus.PENDING,
                max_output_lines=self.max_output_lines,
            )
            self._active[execution_id] = execution

        thread = threading.Thread(
            target=self._run,
            args=(execution, output_callback, completion_callback),
            name=f"script-exec:{script.name}",
            daemon=True,
        )
        thread.start()
        return execution

    def cancel_execution(self, script: Script, wait_for_process: float = 2.0) -> bool:
        """Request cancellation of a running script.

        Returns True if cancellation was successfully issued (either the
        subprocess was terminated, or a cancel flag was registered on a
        detached run). Returns False when there is no active execution or
        when a subprocess could not be terminated.
        """
        execution_id = self._key(script)
        with self._lock:
            execution = self._active.get(execution_id)
            if execution is None:
                logger.debug(f"No active execution for: {script.name}")
                return False
            execution.cancel_requested = True
            process = self._processes.get(execution_id)

        # The worker thread may not have spawned the subprocess yet; wait
        # briefly for it to appear before giving up.
        if process is None and wait_for_process > 0:
            deadline = time.monotonic() + wait_for_process
            while process is None and time.monotonic() < deadline:
                time.sleep(0.02)
                with self._lock:
                    # Bail out if the execution already finished.
                    if execution_id not in self._active:
                        return True
                    process = self._processes.get(execution_id)

        if process is None:
            # No subprocess to kill (detached batch, or worker failed
            # to start one). The cancel flag is recorded, so this counts
            # as a successful cancellation request.
            logger.info(f"Cancel registered without subprocess: {script.name}")
            return True

        return terminate_process(process)

    def cancel_all(self) -> int:
        """Cancel every running script. Returns number of cancellations issued."""
        with self._lock:
            scripts = [e.script for e in self._active.values()]

        count = 0
        for script in scripts:
            if self.cancel_execution(script):
                count += 1
        return count

    def is_running(self, script: Script) -> bool:
        with self._lock:
            return self._key(script) in self._active

    def get_active_count(self) -> int:
        with self._lock:
            return len(self._active)

    def get_active_executions(self) -> list[ScriptExecution]:
        with self._lock:
            return list(self._active.values())

    # --- Internal ------------------------------------------------------

    @staticmethod
    def _key(script: Script) -> str:
        return str(script.path.resolve())

    def _run(
        self,
        execution: ScriptExecution,
        output_callback: OutputCallback | None,
        completion_callback: CompletionCallback | None,
    ) -> None:
        execution_id = self._key(execution.script)
        script = execution.script

        try:
            execution.status = ExecutionStatus.RUNNING
            execution.start_time = datetime.now()
            logger.info(f"Starting execution: {script.name}")

            if (
                script.script_type == ScriptType.BATCH
                and self.run_batch_in_new_window
            ):
                self._run_detached(execution, output_callback)
                return

            self._run_captured(execution, execution_id, output_callback)

        except Exception as e:  # noqa: BLE001
            logger.exception(f"Error executing {script.name}")
            execution.status = ExecutionStatus.FAILED
            execution.error_message = str(e)

        finally:
            execution.end_time = datetime.now()
            with self._lock:
                self._processes.pop(execution_id, None)
                self._active.pop(execution_id, None)

            script.last_run = execution.end_time
            script.run_count += 1

            if completion_callback is not None:
                try:
                    completion_callback(execution)
                except Exception:  # noqa: BLE001
                    logger.exception("Completion callback raised")

    def _run_detached(
        self,
        execution: ScriptExecution,
        output_callback: OutputCallback | None,
    ) -> None:
        script = execution.script
        launch_detached(script.path)
        msg1 = f"Script launched in separate window: {script.name}\n"
        msg2 = "Check the CMD window for output and interaction.\n"
        execution.add_output(msg1)
        execution.add_output(msg2)
        if output_callback:
            output_callback(msg1)
            output_callback(msg2)
        execution.status = ExecutionStatus.SUCCESS
        execution.return_code = 0
        logger.info(f"Launched detached: {script.name}")

    def _run_captured(
        self,
        execution: ScriptExecution,
        execution_id: str,
        output_callback: OutputCallback | None,
    ) -> None:
        script = execution.script
        command = get_script_command(script.path, script.script_type)
        process = create_process(command, cwd=script.path.parent)

        with self._lock:
            self._processes[execution_id] = process

        stdout_thread = threading.Thread(
            target=self._pump_stream,
            args=(process.stdout, "", execution, output_callback),
            name=f"stdout:{script.name}",
            daemon=True,
        )
        stderr_thread = threading.Thread(
            target=self._pump_stream,
            args=(process.stderr, "[stderr] ", execution, output_callback),
            name=f"stderr:{script.name}",
            daemon=True,
        )
        stdout_thread.start()
        stderr_thread.start()

        try:
            return_code = process.wait(timeout=self.timeout_seconds)
        except subprocess.TimeoutExpired:
            logger.warning(f"Script timed out: {script.name}")
            terminate_process(process)
            execution.status = ExecutionStatus.TIMEOUT
            execution.error_message = (
                f"Execution timed out after {self.timeout_seconds}s"
            )
            stdout_thread.join(timeout=1.0)
            stderr_thread.join(timeout=1.0)
            return

        stdout_thread.join(timeout=2.0)
        stderr_thread.join(timeout=2.0)

        execution.return_code = return_code
        if execution.cancel_requested:
            execution.status = ExecutionStatus.CANCELLED
            execution.error_message = "Cancelled by user"
            logger.info(f"Script cancelled: {script.name}")
        elif return_code == 0:
            execution.status = ExecutionStatus.SUCCESS
            logger.info(f"Script completed: {script.name}")
        else:
            execution.status = ExecutionStatus.FAILED
            execution.error_message = f"Exited with code {return_code}"
            logger.warning(
                f"Script failed with code {return_code}: {script.name}"
            )

    @staticmethod
    def _pump_stream(
        stream: object | None,
        prefix: str,
        execution: ScriptExecution,
        output_callback: OutputCallback | None,
    ) -> None:
        if stream is None:
            return
        try:
            for line in iter(stream.readline, ""):  # type: ignore[union-attr]
                if not line:
                    break
                chunk = f"{prefix}{line}"
                execution.add_output(chunk)
                if output_callback is not None:
                    try:
                        output_callback(chunk)
                    except Exception:  # noqa: BLE001
                        logger.exception("Output callback raised")
        except (OSError, ValueError) as e:
            logger.debug(f"Stream closed: {e}")
