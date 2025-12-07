"""Build script for creating executable."""

import PyInstaller.__main__
import shutil
from pathlib import Path
import customtkinter
import os

# Get project root
PROJECT_ROOT = Path(__file__).parent
SRC_DIR = PROJECT_ROOT / "src"
DIST_DIR = PROJECT_ROOT / "dist"
BUILD_DIR = PROJECT_ROOT / "build"

# Clean previous builds
if DIST_DIR.exists():
    shutil.rmtree(DIST_DIR)
if BUILD_DIR.exists():
    shutil.rmtree(BUILD_DIR)

print("Building Script Launcher executable...")

# Get CustomTkinter path for data files
ctk_path = os.path.dirname(customtkinter.__file__)

# PyInstaller arguments
args = [
    str(PROJECT_ROOT / "script_launcher.py"),  # Entry point
    "--name=ScriptLauncher",  # Executable name
    "--onefile",  # Single file
    "--windowed",  # No console window
    f"--distpath={DIST_DIR}",  # Output directory
    f"--workpath={BUILD_DIR}",  # Build directory
    "--clean",  # Clean cache
    # Add data files for CustomTkinter
    f"--add-data={ctk_path};customtkinter/",
    # Add hidden imports
    "--hidden-import=loguru",
    "--hidden-import=pydantic",
    "--hidden-import=watchdog",
    "--hidden-import=watchdog.observers",
    "--hidden-import=watchdog.events",
    "--hidden-import=customtkinter",
    "--hidden-import=PIL",
    "--hidden-import=PIL._tkinter_finder",
    "--hidden-import=packaging",
]

# Run PyInstaller
PyInstaller.__main__.run(args)

print("\n" + "=" * 60)
print("Build complete!")
print(f"Executable location: {DIST_DIR / 'ScriptLauncher.exe'}")
print("=" * 60)

# Create scripts folder next to executable
scripts_folder = DIST_DIR / "scripts"
scripts_folder.mkdir(exist_ok=True)
print(f"\nCreated scripts folder: {scripts_folder}")

# Copy system_cleanup.bat to scripts folder
source_script = PROJECT_ROOT / "scripts" / "system_cleanup.bat"
if source_script.exists():
    shutil.copy(source_script, scripts_folder / "system_cleanup.bat")
    print(f"Copied system_cleanup.bat to scripts folder")

print("\nYou can now run the executable from the dist folder!")
