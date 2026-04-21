"""Build script for creating a standalone Windows executable."""

from __future__ import annotations

import os
import shutil
from pathlib import Path

import customtkinter
import PyInstaller.__main__

PROJECT_ROOT = Path(__file__).resolve().parent
DIST_DIR = PROJECT_ROOT / "dist"
BUILD_DIR = PROJECT_ROOT / "build"
SCRIPTS_SRC = PROJECT_ROOT / "scripts"


def clean() -> None:
    for folder in (DIST_DIR, BUILD_DIR):
        if folder.exists():
            shutil.rmtree(folder)


def build() -> None:
    print("Building Script Launcher executable...")
    ctk_path = os.path.dirname(customtkinter.__file__)
    sep = ";" if os.name == "nt" else ":"

    args = [
        str(PROJECT_ROOT / "script_launcher.py"),
        "--name=ScriptLauncher",
        "--onefile",
        "--windowed",
        f"--distpath={DIST_DIR}",
        f"--workpath={BUILD_DIR}",
        "--clean",
        "--noconfirm",
        f"--add-data={ctk_path}{sep}customtkinter/",
        "--hidden-import=loguru",
        "--hidden-import=watchdog",
        "--hidden-import=watchdog.observers",
        "--hidden-import=watchdog.events",
        "--hidden-import=customtkinter",
        "--hidden-import=PIL",
        "--hidden-import=PIL._tkinter_finder",
        "--hidden-import=packaging",
    ]
    PyInstaller.__main__.run(args)


def stage_scripts() -> None:
    target = DIST_DIR / "scripts"
    if target.exists():
        shutil.rmtree(target)
    if SCRIPTS_SRC.exists():
        shutil.copytree(SCRIPTS_SRC, target)
        print(f"Copied scripts folder to {target}")
    else:
        target.mkdir(parents=True, exist_ok=True)
        print(f"Created empty scripts folder at {target}")


def main() -> None:
    clean()
    build()
    stage_scripts()
    print("\nBuild complete. Executable:", DIST_DIR / "ScriptLauncher.exe")


if __name__ == "__main__":
    main()
