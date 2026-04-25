"""Tests for risk-aware UI safety decisions and UI smoke paths."""

from __future__ import annotations

import contextlib
from pathlib import Path

import pytest

from src.models import RiskLevel, Script, ScriptType
from src.ui.main_window import MainWindow

pytest.importorskip("tkinter")


def _script(**overrides: object) -> Script:
    values = {
        "path": Path("x.bat"),
        "name": "x.bat",
        "script_type": ScriptType.BATCH,
    }
    values.update(overrides)
    return Script(**values)


def test_safe_script_does_not_require_confirmation() -> None:
    script = _script(risk_level=RiskLevel.SAFE)

    assert MainWindow._requires_confirmation(script) is False


def test_risky_script_requires_confirmation() -> None:
    destructive = _script(risk_level=RiskLevel.DESTRUCTIVE)
    admin = _script(requires_admin=True)
    reboot = _script(requires_reboot=True)

    assert MainWindow._requires_confirmation(destructive) is True
    assert MainWindow._requires_confirmation(admin) is True
    assert MainWindow._requires_confirmation(reboot) is True


def test_script_summary_counts_destructive_and_admin() -> None:
    scripts = [
        _script(name="a.bat", risk_level=RiskLevel.SAFE),
        _script(name="b.bat", risk_level=RiskLevel.DESTRUCTIVE, requires_admin=True),
        _script(name="c.bat", risk_level=RiskLevel.MODERATE, requires_admin=True),
    ]

    summary = MainWindow._script_summary(scripts)

    assert "3 scripts" in summary
    assert "1 destructive" in summary
    assert "2 admin" in summary


# --- Tk-dependent smoke tests -----------------------------------------------


@pytest.fixture
def ctk_root():
    """Create a CTk root, or skip when no display / no Tk is available."""
    try:
        import customtkinter as ctk
    except Exception as e:  # noqa: BLE001
        pytest.skip(f"customtkinter unavailable: {e}")

    try:
        root = ctk.CTk()
    except Exception as e:  # noqa: BLE001 - Tcl/Tk init can fail headlessly
        pytest.skip(f"Tk display unavailable: {e}")

    try:
        root.withdraw()
        yield root
    finally:
        with contextlib.suppress(Exception):
            root.destroy()


def _make_main_window(ctk_root, tmp_path: Path):
    from src.config import AppConfig
    from src.script_executor import ScriptExecutor
    from src.script_manager import ScriptManager

    scripts_dir = tmp_path / "scripts"
    scripts_dir.mkdir()
    (scripts_dir / "one.py").write_text("print('one')", encoding="utf-8")
    (scripts_dir / "two.py").write_text("print('two')", encoding="utf-8")

    manager = ScriptManager(scripts_dir, cache_path=tmp_path / "cache.json")
    executor = ScriptExecutor(timeout_seconds=5, log_dir=tmp_path / "logs")
    config = AppConfig()

    return MainWindow(ctk_root, config, manager, executor), manager, executor


def test_main_window_refresh_populates_cards(ctk_root, tmp_path: Path) -> None:
    window, _, _ = _make_main_window(ctk_root, tmp_path)

    assert len(window._cards) == 2
    assert {p.name for p in window._cards} == {"one.py", "two.py"}


def test_main_window_empty_search_shows_label(ctk_root, tmp_path: Path) -> None:
    window, _, _ = _make_main_window(ctk_root, tmp_path)

    window._on_search("definitely-not-a-real-script-name")

    assert window._empty_label is not None
    # grid_info is non-empty when the widget is currently mapped.
    assert window._empty_label.grid_info() != {}


def test_main_window_snapshot_geometry_updates_config(
    ctk_root, tmp_path: Path
) -> None:
    window, _, _ = _make_main_window(ctk_root, tmp_path)

    window.snapshot_geometry()

    assert window.config.window.width > 0
    assert window.config.window.height > 0
    assert window.config.window.last_x is not None
    assert window.config.window.last_y is not None
