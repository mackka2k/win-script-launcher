"""Integration tests for complete workflows."""

import time
from pathlib import Path

import pytest

from src.config import AppConfig
from src.models import ExecutionStatus, ScriptType
from src.script_executor import ScriptExecutor
from src.script_manager import ScriptManager


class TestIntegration:
    """Integration tests for complete workflows."""

    @pytest.fixture
    def test_environment(self, tmp_path):
        """Set up complete test environment."""
        scripts_dir = tmp_path / "scripts"
        scripts_dir.mkdir()

        # Create test scripts
        batch_script = scripts_dir / "test.bat"
        batch_script.write_text("@echo off\necho Integration Test\n")

        python_script = scripts_dir / "test.py"
        python_script.write_text("print('Python Integration Test')\n")

        config = AppConfig()
        manager = ScriptManager(scripts_dir, config=config)
        executor = ScriptExecutor(timeout_seconds=10)

        return {
            "scripts_dir": scripts_dir,
            "config": config,
            "manager": manager,
            "executor": executor,
        }

    def test_complete_workflow_discovery_to_execution(self, test_environment):
        """Test complete workflow from discovery to execution."""
        manager = test_environment["manager"]
        executor = test_environment["executor"]

        # Discover scripts
        scripts = manager.discover_scripts()
        assert len(scripts) == 2

        # Execute batch script
        batch_script = next(s for s in scripts if s.script_type == ScriptType.BATCH)
        execution = executor.execute_script(batch_script)

        # Wait for completion
        time.sleep(2)

        # Verify execution
        assert execution.status == ExecutionStatus.SUCCESS
        assert execution.return_code == 0
        assert "Integration Test" in execution.full_output

    def test_multiple_concurrent_executions(self, test_environment):
        """Test executing multiple scripts concurrently."""
        manager = test_environment["manager"]
        executor = test_environment["executor"]

        scripts = manager.discover_scripts()

        # Execute all scripts
        executions = []
        for script in scripts:
            execution = executor.execute_script(script)
            executions.append(execution)

        # Wait for all to complete
        time.sleep(3)

        # Verify all completed
        for execution in executions:
            assert execution.status == ExecutionStatus.SUCCESS

    def test_script_metadata_persistence(self, test_environment):
        """Test that script metadata persists across operations."""
        manager = test_environment["manager"]
        executor = test_environment["executor"]
        config = test_environment["config"]

        # First discovery
        scripts1 = manager.discover_scripts()
        script = scripts1[0]

        # Execute script
        executor.execute_script(script)
        time.sleep(2)

        # Verify metadata updated
        assert script.run_count == 1
        assert script.last_run is not None

        # Second discovery should preserve metadata
        scripts2 = manager.discover_scripts()
        script2 = next(s for s in scripts2 if s.path == script.path)

        assert script2.run_count == 1
        assert script2.last_run is not None

    def test_config_save_and_load(self, test_environment, tmp_path):
        """Test configuration persistence."""
        config = test_environment["config"]
        config_path = tmp_path / "config.json"

        # Modify config
        config.theme.mode = "dark"
        config.window.width = 1200

        # Save config
        config.save(config_path)

        # Load config
        loaded_config = AppConfig.load(config_path)

        # Verify
        assert loaded_config.theme.mode == "dark"
        assert loaded_config.window.width == 1200

    def test_error_recovery(self, test_environment):
        """Test system recovers from errors gracefully."""
        manager = test_environment["manager"]
        executor = test_environment["executor"]
        scripts_dir = test_environment["scripts_dir"]

        # Create failing script
        failing_script = scripts_dir / "fail.bat"
        failing_script.write_text("@echo off\nexit /b 1\n")

        scripts = manager.discover_scripts()
        fail_script = next(s for s in scripts if s.name == "fail.bat")

        # Execute failing script
        execution = executor.execute_script(fail_script)
        time.sleep(2)

        # System should handle failure gracefully
        assert execution.status == ExecutionStatus.FAILED
        assert execution.return_code == 1

        # System should still be able to execute other scripts
        good_script = next(s for s in scripts if s.name == "test.bat")
        execution2 = executor.execute_script(good_script)
        time.sleep(2)

        assert execution2.status == ExecutionStatus.SUCCESS
