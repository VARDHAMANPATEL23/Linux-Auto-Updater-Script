# Linux System & App Updater Script

A comprehensive Bash script designed to automate the process of checking for and applying updates on a Linux system.

This script intelligently detects your distribution, system package manager, and a wide array of application and programming toolchains to provide a single, unified update command.

## ✨ Key Features

- **Smart Detection**: Automatically discovers your Linux distribution (Ubuntu, Fedora, Arch, openSUSE, etc.) and the correct system package manager (apt, dnf, pacman, zypper, etc.)
- **Comprehensive Updates**: Handles updates for system packages and app packages
- **Developer-Friendly**: Detects and offers to update a wide range of programming toolchains
- **Interactive**: Prompts for confirmation before checking and applying updates
- **Responsive**: Includes a text-based spinner animation for long-running update tasks
- **Selective**: Allows opting out of programming toolchain updates
- **Safe**: Uses `set -e` to exit immediately if any command fails

## 💻 Supported Software

### System Package Managers
- apt (Debian, Ubuntu, Mint)
- dnf (Fedora, RHEL)
- yum (CentOS, older RHEL)
- pacman (Arch, Manjaro)
- zypper (openSUSE)

### Application Package Managers
- snap
- flatpak
- brew (Homebrew)

### Programming Language Managers
- npm (global packages)
- yarn (global packages)
- bun (self-update)
- rustup (Rust toolchain)
- pip (Python package manager)
- pipx (Python application installer)
- gem (RubyGems)
- asdf (Multi-language version manager)

## 🚀 Installation

### Easy Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/VARDHAMANPATEL23/Linux-Auto-Updater-Script.git
   cd Linux-Auto-Updater-Script
   ```

2. Make the scripts executable:
   ```bash
   chmod +x install.sh uninstall.sh myUpdaterScriptV2.sh
   ```

3. Run the installer:
   ```bash
   ./install.sh
   ```
   **Note**: Make sure to add your `icon.png` to the project directory before installation.

That's it! You can now find "System Updater" in your system's application menu.

### Uninstallation

To remove the script and its launcher:
```bash
./uninstall.sh
```

## 🤝 Contributing

Contributions are welcome! If you find a bug or have a suggestion, please feel free to:
- Open an issue
- Submit a pull request

## 📄 License

This project is open-source under the MIT License.

```text
MIT License

Copyright (c) 2025 Vardhaman Patel

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```