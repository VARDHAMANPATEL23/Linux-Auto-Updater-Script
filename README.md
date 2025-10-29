# 🐧 Linux System & App Updater Script

A comprehensive Bash script designed to automate the process of checking for and applying updates on a Linux system.

This script intelligently detects your distribution, system package manager, and a wide array of application and programming toolchains to provide a single, unified update command.

## ✨ Key Features

- **🧠 Smart Detection:** Automatically discovers your Linux distribution (Ubuntu, Fedora, Arch, openSUSE, etc.) and the correct system package manager (`apt`, `dnf`, `pacman`, `zypper`, etc.)
- **🔄 Comprehensive Updates:** Handles updates for:
  - System packages (via `apt`, `dnf`, etc.)
  - App packages (Snap, Flatpak, Homebrew)
- **💻 Developer-Friendly:** Detects and offers to update a wide range of programming toolchains
- **🔧 Flexible Installation:** The installer lets you add the shortcut to your Application Menu, Desktop, or both
- **✅ Fixes "Untrusted" Error:** Automatically marks the desktop shortcut as trusted, bypassing the "Allow Launching" security prompt
- **👆 Interactive:** Prompts for confirmation before checking for updates and again before applying them
- **⏳ Responsive:** Includes a text-based spinner animation to show that long-running update tasks are in progress
- **🤔 Selective:** Allows you to opt-out of updating programming toolchains if you only want to run system/app updates
- **🛡️ Safe:** Uses `set -e` to exit immediately if any command fails

## 💻 Supported Software

This script actively detects and supports updates for the following:

### 📦 System Package Managers
- `apt` (Debian, Ubuntu, Mint)
- `dnf` (Fedora, RHEL)
- `yum` (CentOS, older RHEL)
- `pacman` (Arch, Manjaro)
- `zypper` (openSUSE)

### 🛍️ Application Package Managers
- `snap`
- `flatpak`
- `brew` (Homebrew)

### 🛠️ Programming Language Managers
- `npm` (global packages)
- `yarn` (global packages)
- `bun` (self-update)
- `rustup` (Rust toolchain)
- `pip` (Python package manager)
- `pipx` (Python application installer)
- `gem` (RubyGems)
- `asdf` (Multi-language version manager)

## 🚀 Installation (Easy Setup)

This project includes an installer that automatically sets up the script and creates an application launcher for you.

1. **Clone the repository:**
```bash
git clone https://github.com/VARDHAMANPATEL23/Linux-Auto-Updater-Script.git
cd Linux-Auto-Updater-Script
```

*(Note: You will also need to add your `icon.png` to this directory for the shortcut icon to work.)*

2. **Make the scripts executable:**
```bash
chmod +x install.sh uninstall.sh myUpdaterScript.sh
```

3. **Run the installer:**
```bash
./install.sh
```

4. **Choose your shortcut location:**
   The script will ask if you want the shortcut in your **Application Menu**, on your **Desktop**, or **Both**.

That's it! The launcher is now in your chosen location.

### 🗑️ Uninstallation

To remove the script and its launcher from all locations, simply run the uninstaller:
```bash
./uninstall.sh
```

## ⚙️ How It Works

1. **Detection Phase:**
   - Reads `/etc/os-release` to find the distribution ID
   - Selects the appropriate system package manager
   - Sources common environments like NVM, asdf, and Cargo
   - Checks for all other supported package managers

2. **Check Phase (Optional):**
   - Runs the "check" or "list" command for each detected package manager (e.g., `apt list --upgradable`, `flatpak remote-ls --updates`, `npm outdated -g`)
   - This phase is read-only and makes no changes

3. **Apply Phase (Optional):**
   - Runs the "upgrade" or "update" command for each detected package manager (e.g., `sudo apt upgrade -y`, `flatpak update -y`, `npm update -g`)
   - Shows a spinner animation while tasks are running
   - Prompts the user to optionally skip programming toolchain updates

## 🤝 Contributing

Contributions are welcome! If you find a bug or have a suggestion, please feel free to open an issue or submit a pull request.

## 📄 License

This project is open-source. Please consider adding a `LICENSE` file (e.g., [MIT License](https://opensource.org/licenses/MIT)).