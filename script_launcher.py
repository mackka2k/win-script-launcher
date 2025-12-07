"""Script Launcher entry point."""

import sys
from pathlib import Path

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from src.app import main

if __name__ == "__main__":
    main()
