"""Script execution engine with real-time output streaming."""

import subprocess
import threading
from datetime import datetime
from typing import Callable, Optional

from loguru import logger

from .models import ExecutionStatus, Script, ScriptExecution
from .utils.process import create_process, get_script_command, terminate_process


class ScriptExecutor:
    """Executes scripts and manages their lifecycle."""

    def __init__(self, timeout_seconds: int = 300):
        """
        Initialize the script executor.

        Args:
            timeout_seconds: Maximum execution time for scripts
        """
        self.timeout_seconds = timeout_seconds
        self.active_executions: dict[str, ScriptExecution] = {}
        self.processes: dict[str, subprocess.Popen] = {}  # type: ignore
        self._lock = threading.Lock()

    def execute_script(
        self,
        script: Script,
        output_callback: Optional[Callable[[str], None]] = None,
        completion_callback: Optional[Callable[[ScriptExecution], None]] = None,
    ) -> ScriptExecution:
        """
        Execute a script asynchronously.

        Args:
            script: Script to execute
            output_callback: Called for each line of output
            completion_callback: Called when execution completes

        Returns:
            ScriptExecution object tracking the execution
        """
        execution_id = str(script.path)

        # Check if already running
        with self._lock:
            if execution_id in self.active_executions:
                logger.warning(f"Script already running: {script.name}")
                return self.active_executions[execution_id]

            # Create execution object
            execution = ScriptExecution(script=script, status=ExecutionStatus.PENDING)
            self.active_executions[execution_id] = execution

        # Start execution in background thread
        thread = threading.Thread(
            target=self._execute_thread,
            args=(execution, output_callback, completion_callback),
            daemon=True,
        )
        thread.start()

        return execution

    def _execute_thread(
        self,
        execution: ScriptExecution,
        output_callback: Optional[Callable[[str], None]],
        completion_callback: Optional[Callable[[ScriptExecution], None]],
    ) -> None:
        """Execute script in a background thread."""
        execution_id = str(execution.script.path)
        script = execution.script

        try:
            # Update status
            execution.status = ExecutionStatus.RUNNING
            execution.start_time = datetime.now()
            logger.info(f"Starting execution: {script.name}")

            # Get command
            command = get_script_command(script.path, script.script_type)

            # For batch scripts, run in separate window for interactive input
            if script.script_type.value == "batch":
                # Run in new CMD window
                import os
                os.startfile(str(script.path))
                
                # Mark as success immediately since we can't track external window
                execution.status = ExecutionStatus.SUCCESS
                execution.return_code = 0
                execution.add_output(f"Script launched in separate window: {script.name}\n")
                execution.add_output("Check the CMD window for output and interaction.\n")
                logger.info(f"Launched batch script in separate window: {script.name}")
                
                if output_callback:
                    output_callback(f"Script launched in separate window: {script.name}\n")
                    output_callback("Check the CMD window for output and interaction.\n")
                
                return  # Exit early for batch scripts

            # Create process for Python/PowerShell scripts (keep original behavior)
            process = create_process(
                command, cwd=script.path.parent, shell=False
            )

            with self._lock:
                self.processes[execution_id] = process

            # Read output in real-time
            def read_stream(stream, prefix: str = "") -> None:  # type: ignore
                """Read output from a stream."""
                try:
                    for line in iter(stream.readline, ""):
                        if not line:
                            break
                        output_line = f"{prefix}{line}"
                        execution.add_output(output_line)
                        if output_callback:
                            output_callback(output_line)
                except Exception as e:
                    logger.error(f"Error reading stream: {e}")

            # Start output reading threads
            stdout_thread = threading.Thread(
                target=read_stream, args=(process.stdout, ""), daemon=True
            )
            stderr_thread = threading.Thread(
                target=read_stream, args=(process.stderr, "[STDERR] "), daemon=True
            )

            stdout_thread.start()
            stderr_thread.start()

            # Wait for process with timeout
            try:
                return_code = process.wait(timeout=self.timeout_seconds)
                execution.return_code = return_code

                # Wait for output threads to finish
                stdout_thread.join(timeout=1.0)
                stderr_thread.join(timeout=1.0)

                # Set final status
                if return_code == 0:
                    execution.status = ExecutionStatus.SUCCESS
                    logger.info(f"Script completed successfully: {script.name}")
                else:
                    execution.status = ExecutionStatus.FAILED
                    execution.error_message = f"Exited with code {return_code}"
                    logger.warning(f"Script failed with code {return_code}: {script.name}")

            except subprocess.TimeoutExpired:
                logger.warning(f"Script timed out: {script.name}")
                terminate_process(process)
                execution.status = ExecutionStatus.TIMEOUT
                execution.error_message = f"Execution timed out after {self.timeout_seconds}s"

        except Exception as e:
            logger.error(f"Error executing script {script.name}: {e}")
            execution.status = ExecutionStatus.FAILED
            execution.error_message = str(e)

        finally:
            # Clean up
            execution.end_time = datetime.now()

            with self._lock:
                if execution_id in self.processes:
                    del self.processes[execution_id]
                if execution_id in self.active_executions:
                    del self.active_executions[execution_id]

            # Update script metadata
            script.last_run = execution.end_time
            script.run_count += 1

            # Call completion callback
            if completion_callback:
                completion_callback(execution)

    def cancel_execution(self, script: Script) -> bool:
        """
        Cancel a running script execution.

        Args:
            script: Script to cancel

        Returns:
            True if cancelled successfully
        """
        execution_id = str(script.path)

        with self._lock:
            if execution_id not in self.active_executions:
                logger.warning(f"No active execution for: {script.name}")
                return False

            execution = self.active_executions[execution_id]
            process = self.processes.get(execution_id)

            if not process:
                return False

        # Terminate process
        success = terminate_process(process)

        if success:
            execution.status = ExecutionStatus.CANCELLED
            execution.end_time = datetime.now()
            execution.error_message = "Cancelled by user"
            logger.info(f"Cancelled execution: {script.name}")

        return success

    def cancel_all(self) -> int:
        """
        Cancel all running executions.

        Returns:
            Number of executions cancelled
        """
        with self._lock:
            scripts = [exec.script for exec in self.active_executions.values()]

        count = 0
        for script in scripts:
            if self.cancel_execution(script):
                count += 1

        return count

    def is_running(self, script: Script) -> bool:
        """
        Check if a script is currently running.

        Args:
            script: Script to check

        Returns:
            True if running
        """
        execution_id = str(script.path)
        with self._lock:
            return execution_id in self.active_executions

    def get_active_count(self) -> int:
        """
        Get the number of active executions.

        Returns:
            Number of running scripts
        """
        with self._lock:
            return len(self.active_executions)
