# Windows Script Launcher

A modern, keyboard-friendly GUI for discovering and running Windows scripts
(`.py`, `.bat`, `.cmd`, `.ps1`) from a single dark-themed window. Built with
CustomTkinter.

[![Python](https://img.shields.io/badge/Python-3.10%2B-blue.svg)](https://www.python.org/downloads/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- **Auto-discovery** of scripts in the `scripts/` folder with content-aware
  cache invalidation (detects rename, edit, add, delete).
- **Live output console** streaming stdout/stderr of running scripts with
  colored status tags.
- **Per-script cancel** and **Stop All** controls with thread-safe process
  termination (graceful → force kill fallback).
- **Debounced search** across script name, category, and description.
- **Configurable execution timeout** with automatic process termination.
- **Optional file watcher** that reloads the script list when the folder
  changes (debounced).
- **Path-traversal protection** — every script is validated against the
  scripts directory before execution.
- **Admin elevation** prompt on startup with clean re-launch.

## Requirements

- Python **3.10+**
- Windows 10 / 11 (Python scripts and batch scripts are tested; PowerShell
  scripts are launched via `powershell.exe`)

## Installation

```bash
git clone https://github.com/yourusername/win-script-launcher.git
cd win-script-launcher
pip install -r requirements.txt
python script_launcher.py
```

## Usage

1. Put your scripts in `scripts/` (supported: `.py`, `.bat`, `.cmd`, `.ps1`).
2. Optionally add a `scripts/script_metadata.json` with human-friendly
   descriptions and categories:

   ```json
   {
     "cleanup.bat": {
       "category": "Maintenance",
       "description": "Clears temp folders and caches.",
       "risk_level": "moderate",
       "requires_admin": true,
       "requires_reboot": false,
       "expected_changes": [
         "Deletes temporary files and cache folders."
       ],
       "backup_targets": ["files"],
       "preview_command": "cleanup.bat --dry-run"
     }
   }
   ```

3. Launch the app, select a script, click **Run**. Output streams into the
   embedded console; a per-card **Cancel** button appears while running.

Script cards show category and risk badges (`Safe`, `Moderate`,
`Destructive`, `Requires admin`, `Requires reboot`) so risky actions are
visible before execution. If metadata omits these fields, the launcher infers
reasonable defaults from the script content.

Risky scripts require confirmation before execution. The confirmation dialog
shows expected changes and backup targets, and each run writes an audit log to
`logs/scripts/<script-name>/<timestamp>.log`.

## Configuration

`config.json` is created next to the app on first run. Key fields:

| Field                               | Default | Description                                   |
| ----------------------------------- | ------- | --------------------------------------------- |
| `execution.timeout_seconds`         | `300`   | Kill scripts that exceed this runtime.        |
| `execution.max_output_lines`        | `10000` | Bounded, thread-safe output buffer per run.   |
| `execution.run_batch_in_new_window` | `false` | If `true`, `.bat`/`.cmd` launch detached.     |
| `enable_file_watcher`               | `true`  | Auto-refresh when `scripts/` changes.         |
| `check_admin_on_startup`            | `true`  | Prompt to relaunch as admin if not elevated.  |
| `log_level`                         | `INFO`  | `DEBUG` / `INFO` / `WARNING` / `ERROR`.       |

Discovery cache is persisted separately in `cache.json` to keep user
settings untouched by scan churn.

## Project layout

```
win-script-launcher/
├── src/
│   ├── app.py              # Orchestrator
│   ├── config.py           # AppConfig + ScriptCache (atomic save)
│   ├── exceptions.py       # Typed exception hierarchy
│   ├── logger.py           # Loguru setup (console + rotated files)
│   ├── models.py           # Script / ScriptExecution / enums
│   ├── script_manager.py   # Discovery, filtering, metadata, cache
│   ├── script_executor.py  # Threaded execution with cancel + timeout
│   ├── validators.py       # Path + config validation
│   ├── ui/                 # CustomTkinter components + main window
│   └── utils/              # process, admin, file_watcher
├── scripts/                # User scripts (drop-in)
├── tests/                  # pytest suite (executor, manager, config, ...)
├── build_exe.py            # PyInstaller one-file build
└── script_launcher.py      # Entry point
```

## Development

```bash
pip install -e ".[dev]"
pytest                    # run the test suite
ruff check src tests      # lint
mypy src                  # type check
```

### Building a Windows executable

```bash
pip install -e ".[build]"
python build_exe.py       # produces dist/ScriptLauncher.exe + dist/scripts/
```

## Security notes

- Scripts are executed with the current user's privileges (elevated to
  Administrator if the user agreed at startup). Do **not** drop untrusted
  scripts into `scripts/` — this is an execution harness, not a sandbox.
- Path traversal is blocked via `PathValidator.validate_script_path`
  before each run; symlinks leaving `scripts/` are rejected.
- `.exe` and other non-script files are intentionally ignored during
  discovery.

## License

MIT — see [LICENSE](LICENSE).
