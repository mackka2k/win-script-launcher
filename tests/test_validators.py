"""Tests for validators."""

from __future__ import annotations

from pathlib import Path

import pytest

from src.exceptions import ValidationError
from src.validators import ConfigValidator, PathValidator


class TestPathValidator:
    def test_is_safe_path_within_base(self, tmp_path: Path) -> None:
        base = tmp_path / "base"
        base.mkdir()
        inside = base / "script.bat"
        inside.touch()
        assert PathValidator.is_safe_path(inside, base)

    def test_is_safe_path_escapes_base(self, tmp_path: Path) -> None:
        base = tmp_path / "base"
        base.mkdir()
        outside = tmp_path / "outside.bat"
        outside.touch()
        assert not PathValidator.is_safe_path(outside, base)

    def test_sanitize_filename_removes_dangerous_chars(self) -> None:
        safe = PathValidator.sanitize_filename('te<>:"/\\|?*st.bat')
        for ch in '<>:"/\\|?*':
            assert ch not in safe

    def test_sanitize_filename_limits_length(self) -> None:
        safe = PathValidator.sanitize_filename("a" * 400, max_length=255)
        assert len(safe) == 255

    def test_validate_script_path_success(self, tmp_path: Path) -> None:
        scripts_dir = tmp_path / "s"
        scripts_dir.mkdir()
        path = scripts_dir / "t.bat"
        path.touch()
        PathValidator.validate_script_path(path, scripts_dir)

    def test_validate_script_path_nonexistent(self, tmp_path: Path) -> None:
        scripts_dir = tmp_path / "s"
        scripts_dir.mkdir()
        with pytest.raises(ValidationError, match="does not exist"):
            PathValidator.validate_script_path(
                scripts_dir / "missing.bat", scripts_dir
            )

    def test_validate_script_path_directory(self, tmp_path: Path) -> None:
        scripts_dir = tmp_path / "s"
        scripts_dir.mkdir()
        sub = scripts_dir / "sub"
        sub.mkdir()
        with pytest.raises(ValidationError, match="not a file"):
            PathValidator.validate_script_path(sub, scripts_dir)

    def test_validate_script_path_unsupported_extension(self, tmp_path: Path) -> None:
        scripts_dir = tmp_path / "s"
        scripts_dir.mkdir()
        path = scripts_dir / "evil.exe"
        path.touch()
        with pytest.raises(ValidationError, match="Unsupported"):
            PathValidator.validate_script_path(path, scripts_dir)

    def test_validate_script_path_escapes(self, tmp_path: Path) -> None:
        scripts_dir = tmp_path / "s"
        scripts_dir.mkdir()
        outside = tmp_path / "outside.bat"
        outside.touch()
        with pytest.raises(ValidationError, match="security"):
            PathValidator.validate_script_path(outside, scripts_dir)


class TestConfigValidator:
    def test_timeout_valid(self) -> None:
        ConfigValidator.validate_timeout(60)
        ConfigValidator.validate_timeout(3600)

    def test_timeout_too_small(self) -> None:
        with pytest.raises(ValidationError):
            ConfigValidator.validate_timeout(0)

    def test_timeout_too_large(self) -> None:
        with pytest.raises(ValidationError):
            ConfigValidator.validate_timeout(4000)

    def test_window_size(self) -> None:
        ConfigValidator.validate_window_size(900, 700)
        with pytest.raises(ValidationError):
            ConfigValidator.validate_window_size(100, 700)
        with pytest.raises(ValidationError):
            ConfigValidator.validate_window_size(900, 100)

    def test_log_level(self) -> None:
        for level in ("DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"):
            ConfigValidator.validate_log_level(level)
        ConfigValidator.validate_log_level("debug")
        with pytest.raises(ValidationError):
            ConfigValidator.validate_log_level("INVALID")

    def test_theme_mode(self) -> None:
        ConfigValidator.validate_theme_mode("dark")
        ConfigValidator.validate_theme_mode("light")
        ConfigValidator.validate_theme_mode("system")
        with pytest.raises(ValidationError):
            ConfigValidator.validate_theme_mode("neon")

    def test_color(self) -> None:
        ConfigValidator.validate_color("#0078d4")
        ConfigValidator.validate_color("#FFFFFF")
        with pytest.raises(ValidationError):
            ConfigValidator.validate_color("0078d4")
        with pytest.raises(ValidationError):
            ConfigValidator.validate_color("#12345")
        with pytest.raises(ValidationError):
            ConfigValidator.validate_color("#GGGGGG")

    def test_max_output_lines(self) -> None:
        ConfigValidator.validate_max_output_lines(1000)
        with pytest.raises(ValidationError):
            ConfigValidator.validate_max_output_lines(10)
        with pytest.raises(ValidationError):
            ConfigValidator.validate_max_output_lines(10_000_000)
