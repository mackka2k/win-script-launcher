"""Comprehensive tests for ScriptManager."""

import json
from pathlib import Path

import pytest

from src.config import AppConfig, ScriptCache
from src.models import Script, ScriptType
from src.script_manager import ScriptManager


class TestScriptManager:
    """Test suite for ScriptManager class."""

    @pytest.fixture
    def scripts_dir(self, tmp_path):
        """Create a temporary scripts directory."""
        scripts_dir = tmp_path / "scripts"
        scripts_dir.mkdir()
        return scripts_dir

    @pytest.fixture
    def manager(self, scripts_dir):
        """Create a ScriptManager instance for testing."""
        return ScriptManager(scripts_dir)

    @pytest.fixture
    def sample_scripts(self, scripts_dir):
        """Create sample script files."""
        # Create batch script
        batch_script = scripts_dir / "test.bat"
        batch_script.write_text("@echo off\necho test\n")

        # Create Python script
        python_script = scripts_dir / "test.py"
        python_script.write_text("print('test')\n")

        # Create PowerShell script
        ps_script = scripts_dir / "test.ps1"
        ps_script.write_text("Write-Host 'test'\n")

        return [batch_script, python_script, ps_script]

    def test_manager_initialization(self, manager, scripts_dir):
        """Test ScriptManager initializes correctly."""
        assert manager.scripts_dir == scripts_dir
        assert len(manager.scripts) == 0

    def test_discover_scripts(self, manager, sample_scripts):
        """Test script discovery."""
        scripts = manager.discover_scripts()

        assert len(scripts) == 3
        assert all(isinstance(s, Script) for s in scripts)

        # Check script types
        types = {s.script_type for s in scripts}
        assert ScriptType.BATCH in types
        assert ScriptType.PYTHON in types
        assert ScriptType.POWERSHELL in types

    def test_discover_scripts_empty_directory(self, manager):
        """Test discovering scripts in empty directory."""
        scripts = manager.discover_scripts()
        assert len(scripts) == 0

    def test_get_script(self, manager, sample_scripts):
        """Test getting a specific script."""
        manager.discover_scripts()

        script = manager.get_script(sample_scripts[0])
        assert script is not None
        assert script.path == sample_scripts[0]

    def test_get_nonexistent_script(self, manager):
        """Test getting a script that doesn't exist."""
        fake_path = Path("/nonexistent/script.bat")
        script = manager.get_script(fake_path)
        assert script is None

    def test_get_all_scripts(self, manager, sample_scripts):
        """Test getting all scripts."""
        manager.discover_scripts()

        all_scripts = manager.get_all_scripts()
        assert len(all_scripts) == 3

    def test_filter_scripts_by_name(self, manager, sample_scripts):
        """Test filtering scripts by name."""
        manager.discover_scripts()

        # Filter by partial name
        filtered = manager.filter_scripts(query="test.bat")
        assert len(filtered) == 1
        assert filtered[0].name == "test.bat"

    def test_filter_scripts_case_insensitive(self, manager, sample_scripts):
        """Test case-insensitive filtering."""
        manager.discover_scripts()

        filtered = manager.filter_scripts(query="TEST")
        assert len(filtered) == 3  # All scripts contain "test"

    def test_filter_scripts_no_match(self, manager, sample_scripts):
        """Test filtering with no matches."""
        manager.discover_scripts()

        filtered = manager.filter_scripts(query="nonexistent")
        assert len(filtered) == 0

    def test_caching_with_config(self, scripts_dir, sample_scripts, tmp_path):
        """Test script caching functionality."""
        config = AppConfig()
        manager = ScriptManager(scripts_dir, config=config)

        # First discovery should populate cache
        scripts1 = manager.discover_scripts()
        assert len(scripts1) == 3
        assert len(config.script_cache.scripts) == 3

        # Second discovery should use cache
        scripts2 = manager.discover_scripts()
        assert len(scripts2) == 3

    def test_cache_invalidation_on_file_change(self, scripts_dir, sample_scripts):
        """Test cache invalidates when files change."""
        config = AppConfig()
        manager = ScriptManager(scripts_dir, config=config)

        # Initial discovery
        manager.discover_scripts()
        initial_hash = config.script_cache.directory_hash

        # Add new script
        new_script = scripts_dir / "new.bat"
        new_script.write_text("echo new")

        # Discovery should detect change
        scripts = manager.discover_scripts(force_refresh=True)
        assert len(scripts) == 4
        assert config.script_cache.directory_hash != initial_hash

    def test_metadata_loading(self, scripts_dir, sample_scripts):
        """Test loading script metadata from JSON."""
        # Create metadata file
        metadata = {
            "test.bat": {"category": "Testing", "description": "Test script"},
            "test.py": {"category": "Python", "description": "Python test"},
        }
        metadata_file = scripts_dir / "script_metadata.json"
        metadata_file.write_text(json.dumps(metadata))

        manager = ScriptManager(scripts_dir)
        scripts = manager.discover_scripts()

        # Check metadata was loaded
        bat_script = next(s for s in scripts if s.name == "test.bat")
        assert bat_script.category == "Testing"
        assert bat_script.description == "Test script"

    def test_script_persistence_across_discoveries(self, manager, sample_scripts):
        """Test that script metadata persists across discoveries."""
        # First discovery
        scripts1 = manager.discover_scripts()
        scripts1[0].run_count = 5
        scripts1[0].description = "Custom description"

        # Second discovery should preserve metadata
        scripts2 = manager.discover_scripts()
        assert scripts2[0].run_count == 5
        assert scripts2[0].description == "Custom description"

    def test_ignore_non_script_files(self, scripts_dir):
        """Test that non-script files are ignored."""
        # Create non-script files
        (scripts_dir / "readme.txt").write_text("readme")
        (scripts_dir / "config.json").write_text("{}")
        (scripts_dir / "test.bat").write_text("echo test")

        manager = ScriptManager(scripts_dir)
        scripts = manager.discover_scripts()

        assert len(scripts) == 1
        assert scripts[0].name == "test.bat"
