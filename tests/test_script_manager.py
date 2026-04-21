"""Tests for ScriptManager."""

from __future__ import annotations

import json
from pathlib import Path

from src.models import Script, ScriptType
from src.script_manager import ScriptManager


class TestScriptManager:
    def test_initialization(self, script_manager: ScriptManager, scripts_dir: Path) -> None:
        assert script_manager.scripts_dir == scripts_dir
        assert len(script_manager.scripts) == 0

    def test_discover_empty(self, script_manager: ScriptManager) -> None:
        assert script_manager.discover_scripts() == []

    def test_discover_all_types(self, script_manager: ScriptManager, scripts_dir: Path) -> None:
        (scripts_dir / "a.bat").write_text("@echo off\n")
        (scripts_dir / "b.py").write_text("print(1)\n")
        (scripts_dir / "c.ps1").write_text("Write-Host 'ok'\n")

        scripts = script_manager.discover_scripts()
        assert len(scripts) == 3
        types = {s.script_type for s in scripts}
        assert types == {ScriptType.BATCH, ScriptType.PYTHON, ScriptType.POWERSHELL}

    def test_ignore_non_script_files(self, script_manager: ScriptManager, scripts_dir: Path) -> None:
        (scripts_dir / "readme.txt").write_text("hello")
        (scripts_dir / "data.json").write_text("{}")
        (scripts_dir / "keep.bat").write_text("@echo off\n")

        scripts = script_manager.discover_scripts()
        assert len(scripts) == 1
        assert scripts[0].name == "keep.bat"

    def test_get_script(self, script_manager: ScriptManager, scripts_dir: Path) -> None:
        path = scripts_dir / "k.py"
        path.write_text("print(1)\n")
        script_manager.discover_scripts()
        found = script_manager.get_script(path)
        assert found is not None
        assert found.path == path

    def test_filter_by_name(self, script_manager: ScriptManager, scripts_dir: Path) -> None:
        (scripts_dir / "cleaner.bat").write_text("@echo off\n")
        (scripts_dir / "setup.bat").write_text("@echo off\n")
        script_manager.discover_scripts()

        filtered = script_manager.filter_scripts(query="clean")
        assert len(filtered) == 1
        assert filtered[0].name == "cleaner.bat"

    def test_filter_case_insensitive(self, script_manager: ScriptManager, scripts_dir: Path) -> None:
        (scripts_dir / "Alpha.bat").write_text("@echo off\n")
        script_manager.discover_scripts()
        assert len(script_manager.filter_scripts(query="ALPHA")) == 1

    def test_metadata_file_loaded(self, scripts_dir: Path, cache_path: Path) -> None:
        (scripts_dir / "x.bat").write_text("@echo off\n")
        (scripts_dir / "script_metadata.json").write_text(
            json.dumps({"x.bat": {"category": "Tools", "description": "Does X"}})
        )
        manager = ScriptManager(scripts_dir, cache_path=cache_path)
        scripts = manager.discover_scripts()
        assert scripts[0].category == "Tools"
        assert scripts[0].description == "Does X"

    def test_cache_roundtrip(self, scripts_dir: Path, cache_path: Path) -> None:
        (scripts_dir / "a.bat").write_text("@echo off\n")
        m1 = ScriptManager(scripts_dir, cache_path=cache_path)
        m1.discover_scripts()
        assert cache_path.exists()

        # Fresh manager should hydrate from cache on disk.
        m2 = ScriptManager(scripts_dir, cache_path=cache_path)
        scripts = m2.discover_scripts()
        assert len(scripts) == 1
        assert scripts[0].name == "a.bat"

    def test_cache_invalidates_on_new_file(
        self, scripts_dir: Path, cache_path: Path
    ) -> None:
        (scripts_dir / "a.bat").write_text("@echo off\n")
        manager = ScriptManager(scripts_dir, cache_path=cache_path)
        manager.discover_scripts()

        (scripts_dir / "b.bat").write_text("@echo off\n")
        scripts = ScriptManager(scripts_dir, cache_path=cache_path).discover_scripts()
        assert len(scripts) == 2

    def test_cache_invalidates_on_rename(
        self, scripts_dir: Path, cache_path: Path
    ) -> None:
        original = scripts_dir / "a.bat"
        original.write_text("@echo off\n")
        ScriptManager(scripts_dir, cache_path=cache_path).discover_scripts()

        original.rename(scripts_dir / "renamed.bat")
        scripts = ScriptManager(scripts_dir, cache_path=cache_path).discover_scripts()
        names = {s.name for s in scripts}
        assert names == {"renamed.bat"}

    def test_metadata_persists_across_discoveries(
        self, script_manager: ScriptManager, scripts_dir: Path
    ) -> None:
        path = scripts_dir / "a.bat"
        path.write_text("@echo off\n")
        scripts = script_manager.discover_scripts()
        scripts[0].description = "Custom"
        scripts[0].run_count = 5
        script_manager.update_script_metadata(path, description="Custom", category="T")

        # Re-scan forces rediscovery; metadata should stick via cache.
        refreshed = script_manager.discover_scripts(force_refresh=True)
        s = refreshed[0]
        assert s.description == "Custom"
        assert s.run_count == 5

    def test_delete_script(
        self, script_manager: ScriptManager, scripts_dir: Path
    ) -> None:
        path = scripts_dir / "doomed.bat"
        path.write_text("@echo off\n")
        script_manager.discover_scripts()

        assert script_manager.delete_script(path) is True
        assert not path.exists()
        assert path not in script_manager.scripts

    def test_delete_refuses_outside_scripts_dir(
        self, script_manager: ScriptManager, tmp_path: Path
    ) -> None:
        outside = tmp_path / "outside.bat"
        outside.write_text("@echo off\n")
        assert script_manager.delete_script(outside) is False
        assert outside.exists()

    def test_validate_script_raises_for_outside(
        self, script_manager: ScriptManager, tmp_path: Path
    ) -> None:
        outside = tmp_path / "outside.bat"
        outside.write_text("@echo off\n")
        script = Script.from_path(outside)
        import pytest

        from src.exceptions import ValidationError

        with pytest.raises(ValidationError):
            script_manager.validate_script(script)
