"""Static compatibility checks for bundled Windows batch scripts."""

from __future__ import annotations

from pathlib import Path

SCRIPTS_DIR = Path(__file__).resolve().parents[1] / "scripts"
BANNED_GLYPHS = set("✅❌✓→🚀🌐⚡📊🎧💎🦾📂✨🎮🛡🛠🔄💾🎯👻🎶")


def _batch_files() -> list[Path]:
    return sorted(SCRIPTS_DIR.glob("*.bat"))


def test_batch_scripts_have_consistent_headers() -> None:
    assert _batch_files(), "Expected bundled .bat scripts to be present"

    for script in _batch_files():
        lines = script.read_text(encoding="utf-8").splitlines()
        first_lines = [line.strip().lower() for line in lines[:8]]

        assert first_lines[0] == "@echo off", f"{script.name} must start with @echo off"
        assert any(
            line.startswith("setlocal") for line in first_lines
        ), f"{script.name} must isolate environment changes with setlocal"
        assert any(
            line.startswith("title ") for line in first_lines
        ), f"{script.name} should set a readable console title"


def test_batch_scripts_avoid_locale_and_console_glyph_pitfalls() -> None:
    for script in _batch_files():
        text = script.read_text(encoding="utf-8")

        used_glyphs = sorted(BANNED_GLYPHS.intersection(text))
        assert not used_glyphs, f"{script.name} uses console-fragile glyphs: {used_glyphs}"
        assert 'find "Average"' not in text
        assert 'findstr "Average"' not in text


def test_batch_scripts_use_safe_start_syntax() -> None:
    for script in _batch_files():
        text = script.read_text(encoding="utf-8").lower()

        assert "start http://" not in text
        assert "start https://" not in text
        assert 'start /wait "' not in text


def test_batch_scripts_do_not_expand_errorlevel_inside_blocks() -> None:
    for script in _batch_files():
        depth = 0
        for line_number, line in enumerate(script.read_text(encoding="utf-8").splitlines(), 1):
            stripped = line.strip()
            if "%errorlevel%" in stripped.lower() and depth > 0:
                raise AssertionError(
                    f"{script.name}:{line_number} uses parse-time %errorlevel% inside a block"
                )

            if stripped.startswith("::") or stripped.lower().startswith("rem "):
                continue
            depth += line.count("(") - line.count(")")
            depth = max(depth, 0)


def test_batch_scripts_keep_large_powershell_in_assets() -> None:
    for script in _batch_files():
        for line_number, line in enumerate(script.read_text(encoding="utf-8").splitlines(), 1):
            if "-Command" in line and len(line) > 180:
                raise AssertionError(
                    f"{script.name}:{line_number} should move large PowerShell into scripts/assets"
                )
