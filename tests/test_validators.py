"""Tests for validators module."""

import pytest
from pathlib import Path

from src.validators import PathValidator, ConfigValidator
from src.exceptions import ValidationError


class TestPathValidator:
    """Test suite for PathValidator."""

    def test_is_safe_path_within_base(self, tmp_path):
        """Test that paths within base directory are safe."""
        base_dir = tmp_path / "base"
        base_dir.mkdir()
        
        safe_path = base_dir / "script.bat"
        safe_path.touch()
        
        assert PathValidator.is_safe_path(safe_path, base_dir)

    def test_is_safe_path_escapes_base(self, tmp_path):
        """Test that paths escaping base directory are unsafe."""
        base_dir = tmp_path / "base"
        base_dir.mkdir()
        
        unsafe_path = tmp_path / "outside.bat"
        unsafe_path.touch()
        
        assert not PathValidator.is_safe_path(unsafe_path, base_dir)

    def test_sanitize_filename_removes_dangerous_chars(self):
        """Test filename sanitization removes dangerous characters."""
        dangerous = "test<>:\"/\\|?*.bat"
        safe = PathValidator.sanitize_filename(dangerous)
        
        assert "<" not in safe
        assert ">" not in safe
        assert ":" not in safe
        assert '"' not in safe
        assert "/" not in safe
        assert "\\" not in safe
        assert "|" not in safe
        assert "?" not in safe
        assert "*" not in safe

    def test_sanitize_filename_limits_length(self):
        """Test filename sanitization limits length."""
        long_name = "a" * 300
        safe = PathValidator.sanitize_filename(long_name, max_length=255)
        
        assert len(safe) == 255

    def test_validate_script_path_success(self, tmp_path):
        """Test successful script path validation."""
        scripts_dir = tmp_path / "scripts"
        scripts_dir.mkdir()
        
        script_path = scripts_dir / "test.bat"
        script_path.touch()
        
        # Should not raise
        PathValidator.validate_script_path(script_path, scripts_dir)

    def test_validate_script_path_nonexistent(self, tmp_path):
        """Test validation fails for nonexistent path."""
        scripts_dir = tmp_path / "scripts"
        scripts_dir.mkdir()
        
        script_path = scripts_dir / "nonexistent.bat"
        
        with pytest.raises(ValidationError) as exc_info:
            PathValidator.validate_script_path(script_path, scripts_dir)
        
        assert "does not exist" in str(exc_info.value)

    def test_validate_script_path_is_directory(self, tmp_path):
        """Test validation fails for directory."""
        scripts_dir = tmp_path / "scripts"
        scripts_dir.mkdir()
        
        dir_path = scripts_dir / "subdir"
        dir_path.mkdir()
        
        with pytest.raises(ValidationError) as exc_info:
            PathValidator.validate_script_path(dir_path, scripts_dir)
        
        assert "not a file" in str(exc_info.value)


class TestConfigValidator:
    """Test suite for ConfigValidator."""

    def test_validate_timeout_valid(self):
        """Test valid timeout values."""
        ConfigValidator.validate_timeout(60)  # Should not raise
        ConfigValidator.validate_timeout(300)  # Should not raise

    def test_validate_timeout_too_small(self):
        """Test timeout validation fails for values too small."""
        with pytest.raises(ValidationError) as exc_info:
            ConfigValidator.validate_timeout(0)
        
        assert "at least 1 second" in str(exc_info.value)

    def test_validate_timeout_too_large(self):
        """Test timeout validation fails for values too large."""
        with pytest.raises(ValidationError) as exc_info:
            ConfigValidator.validate_timeout(4000)
        
        assert "3600 seconds" in str(exc_info.value)

    def test_validate_window_size_valid(self):
        """Test valid window dimensions."""
        ConfigValidator.validate_window_size(900, 700)  # Should not raise

    def test_validate_window_size_width_invalid(self):
        """Test window validation fails for invalid width."""
        with pytest.raises(ValidationError) as exc_info:
            ConfigValidator.validate_window_size(200, 700)
        
        assert "width" in str(exc_info.value).lower()

    def test_validate_window_size_height_invalid(self):
        """Test window validation fails for invalid height."""
        with pytest.raises(ValidationError) as exc_info:
            ConfigValidator.validate_window_size(900, 100)
        
        assert "height" in str(exc_info.value).lower()

    def test_validate_log_level_valid(self):
        """Test valid log levels."""
        for level in ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]:
            ConfigValidator.validate_log_level(level)  # Should not raise

    def test_validate_log_level_case_insensitive(self):
        """Test log level validation is case insensitive."""
        ConfigValidator.validate_log_level("debug")  # Should not raise
        ConfigValidator.validate_log_level("WaRnInG")  # Should not raise

    def test_validate_log_level_invalid(self):
        """Test log level validation fails for invalid values."""
        with pytest.raises(ValidationError) as exc_info:
            ConfigValidator.validate_log_level("INVALID")
        
        assert "Must be one of" in str(exc_info.value)

    def test_validate_theme_mode_valid(self):
        """Test valid theme modes."""
        ConfigValidator.validate_theme_mode("light")  # Should not raise
        ConfigValidator.validate_theme_mode("dark")  # Should not raise

    def test_validate_theme_mode_invalid(self):
        """Test theme mode validation fails for invalid values."""
        with pytest.raises(ValidationError) as exc_info:
            ConfigValidator.validate_theme_mode("blue")
        
        assert "light" in str(exc_info.value) or "dark" in str(exc_info.value)

    def test_validate_color_valid(self):
        """Test valid hex colors."""
        ConfigValidator.validate_color("#0078d4")  # Should not raise
        ConfigValidator.validate_color("#FFFFFF")  # Should not raise
        ConfigValidator.validate_color("#000000")  # Should not raise

    def test_validate_color_invalid_format(self):
        """Test color validation fails for invalid format."""
        with pytest.raises(ValidationError):
            ConfigValidator.validate_color("0078d4")  # Missing #
        
        with pytest.raises(ValidationError):
            ConfigValidator.validate_color("#0078d")  # Too short
        
        with pytest.raises(ValidationError):
            ConfigValidator.validate_color("#GGGGGG")  # Invalid hex
