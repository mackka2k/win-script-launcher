# Changelog

All notable changes to this project are documented here.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and this project adheres to [Semantic Versioning](https://semver.org/).

## [3.0.0] — 2026-04-21

Full rewrite for correctness, safety, and maintainability.

### Breaking

- Minimum Python version bumped to **3.10** (was 3.9). The codebase now
  uses PEP 604 union syntax throughout.
- Discovery cache is persisted to `cache.json` instead of being embedded
  inside `config.json`. Existing `script_cache` keys inside `config.json`
  are silently ignored on load.
- `exceptions.PermissionError` renamed to `AdminPrivilegeError` (the
  previous name shadowed Python's built-in `PermissionError`).
- `ScriptExecutor.execute_script` now raises `ScriptNotFoundError`
  synchronously when the target file is missing.
- Batch scripts run in-process through `cmd.exe /c` by default and have
  their output captured. Set `execution.run_batch_in_new_window = true`
  in `config.json` to restore the previous detached-window behaviour.

### Added

- Embedded output console with colored status tags wired into the main
  window.
- Per-script **Cancel** button and per-script run-state tracking.
- Debounced search (180 ms) and debounced file-watcher callbacks.
- Atomic config / cache writes via temp file + `replace`.
- Content-aware directory signature (name + size + mtime_ns, SHA-256) so
  renames and edits invalidate the cache.
- Path-traversal validation is now actually enforced before execution
  and before deletion.
- Bounded `ScriptExecution.output` using a thread-safe `deque` with a
  configurable max line count.
- `pytest-timeout` dependency and cross-platform Python-script based
  executor tests (no more Windows-only `.bat` assumptions).
- `CHANGELOG.md`.

### Fixed

- `AppConfig.save` no longer crashes when a script has a `last_run`
  datetime (JSON encoder now handles `datetime` and `Path`).
- `ValidationError.value` is typed as `Any` instead of the built-in
  `any()` function.
- `MainWindow` no longer saves the config itself and no longer guesses
  the config path; the `Application` owns persistence.
- Cancellation logic is race-free: the worker thread observes
  `cancel_requested` and reports `CANCELLED` correctly.
- `ShellExecuteW` return value is now checked; arguments are quoted
  defensively before elevation re-launch.
- File watcher debounce timer is reset cleanly on each event and
  cancelled on shutdown.
- Tk callbacks fired from worker threads are marshalled via
  `root.after(0, ...)` throughout the UI.

### Changed

- Default log level raised to `INFO` (was `WARNING`). Logging is async
  (`enqueue=True`) and rotated.
- Default window size bumped to 1100 × 750 to fit the two-pane layout.
- Theme palette refined; fonts switched to Segoe UI / Cascadia Mono.
- `ScriptCard` now shows the description and swaps to a **Cancel**
  button while running.
- `filter_scripts` also matches description and category.

### Removed

- Dead code paths inside `script_manager` (md5-based directory hash,
  inline `_load_from_cache`) replaced by the new signature-based cache.
- Unused `src.utils.admin.require_admin` `app_name` argument.
- Legacy `pydantic` dependency (no longer used).
