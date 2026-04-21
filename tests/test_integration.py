"""End-to-end integration tests."""

from __future__ import annotations

import time
from pathlib import Path

from src.config import AppConfig
from src.models import ExecutionStatus
from src.script_executor import ScriptExecutor
from src.script_manager import ScriptManager


def _wait_until(predicate, timeout: float = 15.0, interval: float = 0.05) -> bool:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if predicate():
            return True
        time.sleep(interval)
    return False


class TestIntegration:
    def test_discovery_to_execution_python(self, tmp_path: Path) -> None:
        scripts_dir = tmp_path / "scripts"
        scripts_dir.mkdir()
        (scripts_dir / "hello.py").write_text("print('integration')")

        manager = ScriptManager(scripts_dir, cache_path=tmp_path / "cache.json")
        executor = ScriptExecutor(timeout_seconds=10)

        scripts = manager.discover_scripts()
        assert len(scripts) == 1
        execution = executor.execute_script(scripts[0])

        assert _wait_until(lambda: execution.is_terminal)
        assert execution.status == ExecutionStatus.SUCCESS
        assert "integration" in execution.full_output

    def test_multiple_concurrent_executions(self, tmp_path: Path) -> None:
        scripts_dir = tmp_path / "scripts"
        scripts_dir.mkdir()
        (scripts_dir / "a.py").write_text("print('a')")
        (scripts_dir / "b.py").write_text("print('b')")

        manager = ScriptManager(scripts_dir, cache_path=tmp_path / "cache.json")
        executor = ScriptExecutor(timeout_seconds=10)

        executions = [executor.execute_script(s) for s in manager.discover_scripts()]
        assert _wait_until(lambda: all(e.is_terminal for e in executions))
        assert all(e.status == ExecutionStatus.SUCCESS for e in executions)

    def test_config_save_and_load_roundtrip(self, tmp_path: Path) -> None:
        cfg = AppConfig()
        cfg.theme.mode = "light"
        cfg.window.width = 1200
        cfg.execution.timeout_seconds = 120

        path = tmp_path / "config.json"
        cfg.save(path)

        loaded = AppConfig.load(path)
        assert loaded.theme.mode == "light"
        assert loaded.window.width == 1200
        assert loaded.execution.timeout_seconds == 120

    def test_config_save_with_legacy_fields_ignored(self, tmp_path: Path) -> None:
        path = tmp_path / "config.json"
        path.write_text(
            '{"theme":{"mode":"dark","accent_color":"#1f6aa5"},'
            '"window":{"width":900,"height":700},'
            '"execution":{"timeout_seconds":60},'
            '"script_cache":{"legacy":true},'
            '"log_level":"INFO"}'
        )
        cfg = AppConfig.load(path)
        assert cfg.log_level == "INFO"
        assert cfg.execution.timeout_seconds == 60

    def test_failing_script_does_not_break_executor(self, tmp_path: Path) -> None:
        scripts_dir = tmp_path / "scripts"
        scripts_dir.mkdir()
        (scripts_dir / "fail.py").write_text("import sys; sys.exit(7)")
        (scripts_dir / "ok.py").write_text("print('ok')")

        manager = ScriptManager(scripts_dir, cache_path=tmp_path / "cache.json")
        executor = ScriptExecutor(timeout_seconds=10)
        scripts = manager.discover_scripts()

        fail = next(s for s in scripts if s.name == "fail.py")
        ok = next(s for s in scripts if s.name == "ok.py")

        e1 = executor.execute_script(fail)
        assert _wait_until(lambda: e1.is_terminal)
        assert e1.status == ExecutionStatus.FAILED
        assert e1.return_code == 7

        e2 = executor.execute_script(ok)
        assert _wait_until(lambda: e2.is_terminal)
        assert e2.status == ExecutionStatus.SUCCESS
