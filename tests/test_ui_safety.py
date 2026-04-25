"""Tests for risk-aware UI safety decisions."""

from __future__ import annotations

from pathlib import Path

from src.models import RiskLevel, Script, ScriptType
from src.ui.main_window import MainWindow


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
