"""Tests for configuration and cache persistence."""

from __future__ import annotations

from datetime import datetime
from pathlib import Path

import pytest

from src.config import AppConfig, CachedScript, ScriptCache
from src.exceptions import ConfigurationError, ValidationError


class TestAppConfig:
    def test_defaults_are_valid(self) -> None:
        cfg = AppConfig()
        assert cfg.theme.mode == "dark"
        assert cfg.window.width >= 400
        assert cfg.execution.timeout_seconds >= 1

    def test_invalid_theme_rejected(self) -> None:
        with pytest.raises(ValidationError):
            AppConfig().theme.__class__(mode="neon", accent_color="#1f6aa5")

    def test_invalid_color_rejected(self) -> None:
        with pytest.raises(ValidationError):
            AppConfig().theme.__class__(mode="dark", accent_color="notacolor")

    def test_save_load_roundtrip(self, tmp_path: Path) -> None:
        path = tmp_path / "config.json"
        cfg = AppConfig()
        cfg.execution.timeout_seconds = 123
        cfg.save(path)

        loaded = AppConfig.load(path)
        assert loaded.execution.timeout_seconds == 123

    def test_load_invalid_json_raises(self, tmp_path: Path) -> None:
        path = tmp_path / "config.json"
        path.write_text("{not-json")
        with pytest.raises(ConfigurationError):
            AppConfig.load(path)

    def test_load_missing_returns_defaults(self, tmp_path: Path) -> None:
        cfg = AppConfig.load(tmp_path / "nope.json")
        assert isinstance(cfg, AppConfig)

    def test_save_is_atomic(self, tmp_path: Path) -> None:
        path = tmp_path / "config.json"
        AppConfig().save(path)
        assert path.exists()
        assert not path.with_suffix(".json.tmp").exists()


class TestScriptCache:
    def test_cache_save_load_with_datetime(self, tmp_path: Path) -> None:
        """Regression: datetime values must serialize via ISO strings."""
        cache_path = tmp_path / "cache.json"
        cache = ScriptCache(
            last_scan="2026-01-01T00:00:00",
            directory_signature="abc",
            scripts=[
                CachedScript(
                    path="/tmp/a.bat",
                    name="a.bat",
                    description="",
                    category="General",
                    last_run=datetime.now().isoformat(),
                    run_count=3,
                )
            ],
        )
        cache.save(cache_path)
        assert cache_path.exists()

        loaded = ScriptCache.load(cache_path)
        assert loaded.directory_signature == "abc"
        assert len(loaded.scripts) == 1
        assert loaded.scripts[0].run_count == 3

    def test_missing_cache_returns_empty(self, tmp_path: Path) -> None:
        cache = ScriptCache.load(tmp_path / "missing.json")
        assert cache.scripts == []

    def test_corrupt_cache_returns_empty(self, tmp_path: Path) -> None:
        path = tmp_path / "cache.json"
        path.write_text("corrupted{{")
        cache = ScriptCache.load(path)
        assert cache.scripts == []
