# Contributing to IoT Fleet Management

Thank you for your interest in contributing! This document provides guidelines for contributing to the project.

---

## Ways to Contribute

- 🐛 Report bugs
- 💡 Suggest new features
- 📝 Improve documentation
- 🔧 Submit code improvements
- 🧪 Add test coverage
- 📦 Create example applications

---

## Getting Started

### 1. Fork the Repository

```bash
# Fork on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/IoT-Fleet-Management.git
cd IoT-Fleet-Management
```

### 2. Create a Branch

```bash
git checkout -b feature/your-feature-name
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `test/` - Test additions/improvements

### 3. Make Your Changes

- Follow existing code style
- Add comments where needed
- Update documentation
- Test your changes

### 4. Commit Your Changes

```bash
git add .
git commit -m "Description of your changes"
```

Commit message format:
```
type: Short description (max 50 chars)

Longer explanation if needed (wrap at 72 chars)

- Bullet points for multiple changes
- Reference issues: Fixes #123
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### 5. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub.

---

## Code Guidelines

### Docker Compose Files

- Use version `3.8`
- Include clear comments
- Set restart policies
- Use named volumes when appropriate
- Define health checks

### Shell Scripts

- Use `#!/bin/bash` shebang
- Set `set -e` for error handling
- Add comments explaining complex logic
- Make scripts executable: `chmod +x`
- Test on Ubuntu 22.04 LTS

### Python Code

- Follow PEP 8 style guide
- Use Python 3.8+
- Add type hints where possible
- Include docstrings
- Handle exceptions gracefully

### Documentation

- Use Markdown format
- Include code examples
- Keep line length under 80 characters
- Update table of contents
- Test all commands

---

## Testing Checklist

Before submitting a PR, verify:

- [ ] Code runs without errors
- [ ] Docker containers start successfully
- [ ] Documentation is updated
- [ ] Examples work as described
- [ ] No sensitive data committed (passwords, keys)
- [ ] Scripts are executable
- [ ] YAML/JSON is valid
- [ ] Tested on clean system

---

## Pull Request Process

1. **Update Documentation**: If adding features, update relevant docs
2. **Add Examples**: Provide usage examples when appropriate
3. **Keep Changes Focused**: One feature/fix per PR
4. **Describe Changes**: Clear description of what and why
5. **Reference Issues**: Link to related issues
6. **Request Review**: Tag maintainers if needed

---

## Reporting Bugs

Use GitHub Issues with the following information:

**Template:**
```markdown
**Description**
Clear description of the bug

**Steps to Reproduce**
1. Step one
2. Step two
3. See error

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Environment**
- OS: Ubuntu 22.04
- Docker: 24.0.7
- Service: Mender/MeshCentral/etc.

**Logs**
```
Paste relevant logs here
```

**Additional Context**
Any other information
```

---

## Feature Requests

Use GitHub Issues with `enhancement` label:

**Template:**
```markdown
**Feature Description**
Clear description of the feature

**Use Case**
Why is this feature needed?

**Proposed Solution**
How should it work?

**Alternatives Considered**
Other approaches you considered

**Additional Context**
Mockups, examples, references
```

---

## Documentation Style Guide

### Headings

```markdown
# H1: Page Title
## H2: Major Section
### H3: Subsection
#### H4: Detail
```

### Code Blocks

```markdown
```bash
# Always specify language
command --flag value
```
```

### Command Examples

```markdown
# Good: Show command and expected output
$ docker ps
CONTAINER ID   IMAGE     ...

# Bad: No context
docker ps
```

### Links

```markdown
# Good: Descriptive text
See the [Installation Guide](docs/INSTALL.md)

# Bad: Raw URLs
See https://example.com/docs
```

---

## Project Structure

```
IoT-Fleet-Management/
├── README.md                   # Main documentation
├── COMPLETE_SETUP_GUIDE.md     # Installation guide
├── CONTRIBUTING.md             # This file
├── LICENSE                     # MIT License
├── .gitignore                  # Git ignore rules
│
├── docker-compose.core.yml     # Core services
├── docker-compose.iot.yml      # IoT services
│
├── config/                     # Service configurations
│   ├── meshcentral/
│   └── mosquitto/
│
├── scripts/                    # Helper scripts
│   ├── deploy-all.sh
│   └── pi-setup.sh
│
├── mender-integration/         # Mender setup
│   └── deploy-mender.sh
│
├── docs/                       # Additional documentation
│   ├── QUICK_START.md
│   └── ARCHITECTURE.md
│
└── examples/                   # Usage examples
    ├── iot-sensor-app/
    └── nodered-flows/
```

---

## Questions?

- **Documentation**: Check [docs/](docs/) folder
- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/IoT-Fleet-Management/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR_USERNAME/IoT-Fleet-Management/discussions)

---

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on the best solution
- Help others learn

---

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing!** 🎉
