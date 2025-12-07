# Contributing to Script Launcher

Thank you for your interest in contributing to Script Launcher!

## Development Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd script-launcher
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Run tests**
   ```bash
   pytest
   ```

## Code Style

We use the following tools to maintain code quality:

- **Black** for code formatting (line length: 100)
- **Ruff** for linting
- **MyPy** for type checking

Before submitting a PR, please run:

```bash
# Format code
black src/ tests/

# Check linting
ruff check src/ tests/

# Type check
mypy src/
```

## Code Standards

1. **Type Hints**: All functions should have type hints
2. **Docstrings**: Public functions and classes should have docstrings
3. **Tests**: New features should include tests
4. **Logging**: Use loguru for logging, not print statements
5. **Error Handling**: Handle exceptions appropriately

## Testing

- Write unit tests for new functionality
- Ensure all tests pass before submitting PR
- Aim for >80% code coverage

```bash
# Run tests with coverage
pytest --cov=src --cov-report=html
```

## Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Format and lint your code
7. Commit your changes (`git commit -m 'Add amazing feature'`)
8. Push to the branch (`git push origin feature/amazing-feature`)
9. Open a Pull Request

## Commit Messages

Use clear, descriptive commit messages:

- `feat: Add dark theme support`
- `fix: Resolve script execution timeout issue`
- `docs: Update README with new features`
- `test: Add tests for ScriptManager`
- `refactor: Simplify process management code`

## Questions?

Feel free to open an issue for any questions or concerns!
