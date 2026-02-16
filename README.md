# 🚀 Windows Script Launcher

> A modern, minimalistic GUI tool for organizing and executing Windows scripts with a sleek dark interface.

[![Python](https://img.shields.io/badge/Python-3.8+-blue.svg)](https://www.python.org/downloads/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## ✨ Features

- 🎨 Modern dark-themed UI built with CustomTkinter
- 📁 Auto-discovery of scripts (`.bat`, `.ps1`, `.py`)
- 🏷️ Category-based organization
- ⚡ One-click script execution
- 📝 Detailed logging and error handling
- 🔍 Search and filter capabilities

## 🚀 Quick Start

### Prerequisites
- Python 3.8+
- Windows 10/11

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/win-script-launcher.git
cd win-script-launcher

# Install dependencies
pip install -r requirements.txt

# Run the application
python script_launcher.py
```

### Usage

1. Place your scripts in the `scripts/` directory
2. Launch the application
3. Select a script from the list
4. Click **Run** to execute

## 📁 Project Structure

```
win-script-launcher/
├── src/                    # Source code
│   ├── ui/                # UI components
│   ├── utils/             # Utility functions
│   └── app.py             # Main application
├── scripts/               # Your scripts go here
├── tests/                 # Unit tests
├── docs/                  # Documentation
├── requirements.txt       # Python dependencies
└── README.md
```

## 🛠️ Development

```bash
# Install dev dependencies
pip install -r requirements.txt

# Run tests
pytest tests/

# Build executable
python build_exe.py
```

## 📚 Documentation

- [Contributing Guide](docs/CONTRIBUTING.md)
- [Release Guide](docs/RELEASE_GUIDE.md)
- [Release Notes](docs/RELEASE_NOTES.md)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Made with ❤️ for Windows power users**
