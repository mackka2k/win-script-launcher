# 📁 Project Structure

This document outlines the clean, minimalistic folder structure of the Windows Script Launcher project.

## Directory Layout

```
win-script-launcher/
│
├── 📄 README.md                    # Project overview and quick start
├── 📄 LICENSE                      # MIT License
├── 📄 pyproject.toml              # Python project configuration
├── 📄 requirements.txt            # Python dependencies
├── 📄 script_launcher.py          # Entry point
├── 📄 build_exe.py                # Build script for executable
├── 📄 .gitignore                  # Git ignore rules
├── 📄 .pre-commit-config.yaml     # Pre-commit hooks
│
├── 📂 src/                        # Source code
│   ├── __init__.py
│   ├── app.py                     # Main application
│   ├── config.py                  # Configuration management
│   ├── exceptions.py              # Custom exceptions
│   ├── logger.py                  # Logging utilities
│   ├── models.py                  # Data models
│   ├── script_executor.py         # Script execution logic
│   ├── script_manager.py          # Script management
│   ├── validators.py              # Input validation
│   │
│   ├── 📂 ui/                     # User interface components
│   │   ├── __init__.py
│   │   ├── main_window.py
│   │   ├── script_list.py
│   │   └── theme.py
│   │
│   └── 📂 utils/                  # Utility functions
│       ├── __init__.py
│       ├── file_utils.py
│       ├── system_utils.py
│       └── metadata_parser.py
│
├── 📂 scripts/                    # User scripts directory
│   ├── script_metadata.json      # Script metadata
│   └── *.bat, *.ps1, *.py        # User scripts (71 files)
│
├── 📂 tests/                      # Unit tests
│   ├── __init__.py
│   ├── test_config.py
│   ├── test_integration.py
│   ├── test_models.py
│   ├── test_script_executor.py
│   ├── test_script_manager.py
│   └── test_validators.py
│
├── 📂 docs/                       # Documentation
│   ├── CONTRIBUTING.md            # Contribution guidelines
│   ├── RELEASE_GUIDE.md           # Release process
│   ├── RELEASE_NOTES.md           # Version history
│   └── PROJECT_STRUCTURE.md       # This file
│
└── 📂 logs/                       # Application logs (gitignored)
    └── *.log
```

## Design Principles

### ✅ Clean & Minimalistic
- **No clutter**: Only essential files in root directory
- **Clear separation**: Code, docs, tests, and scripts are separated
- **Logical grouping**: Related files are grouped together

### 📦 Modular Architecture
- **src/**: All application code
- **src/ui/**: UI components isolated
- **src/utils/**: Reusable utilities
- **tests/**: Comprehensive test coverage

### 🔒 Security & Best Practices
- **No secrets**: All sensitive data gitignored
- **No build artifacts**: Executables and zips ignored
- **Clean git history**: Proper .gitignore configuration

### 📚 Documentation First
- **README.md**: Clear project overview
- **docs/**: All documentation in one place
- **Inline comments**: Code is self-documenting

## File Counts

| Directory | Files | Purpose |
|-----------|-------|---------|
| Root | 8 | Configuration & entry points |
| src/ | 9 | Core application code |
| src/ui/ | 4 | User interface components |
| src/utils/ | 4 | Utility functions |
| scripts/ | 71 | User batch scripts |
| tests/ | 6 | Unit tests |
| docs/ | 4 | Documentation |

**Total**: ~106 tracked files

## Ignored Files

The following are automatically ignored via `.gitignore`:

- `__pycache__/` - Python bytecode
- `*.pyc` - Compiled Python files
- `logs/` - Application logs
- `*.zip` - Build archives
- `*.exe` - Executables
- `build/`, `dist/` - Build directories
- `.venv/`, `venv/` - Virtual environments

## Notes for Developers

1. **Adding new features**: Place code in appropriate `src/` subdirectory
2. **Adding scripts**: Drop into `scripts/` directory
3. **Documentation**: Update relevant docs in `docs/`
4. **Tests**: Add tests to `tests/` directory
5. **Dependencies**: Update `requirements.txt`

---

*Last updated: 2026-02-16*
