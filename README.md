# Linux System & App Updater Script

![Shell Script](https://img.shields.io/badge/language-Shell%20Script-green.svg)

A comprehensive Bash script designed to automate the process of checking for and applying updates on a Linux system.

This script intelligently detects your distribution, system package manager, desktop environment, and various application package managers (like Snap, npm, Yarn, and Bun) to provide a single, unified update command.

## ✨ Key Features

* **Smart Detection:** Automatically discovers your Linux distribution (Ubuntu, Fedora, Arch, openSUSE, etc.) and the correct system package manager (`apt`, `dnf`, `pacman`, `zypper`, etc.).
* **Comprehensive Updates:** Handles updates for:
    * System packages (via `apt`, `dnf`, etc.)
    * Snap packages (`snap refresh`)
* **Developer-Friendly:** Detects and offers to update global packages for:
    * `npm` (Node Package Manager)
    * `yarn` (detects v1 vs. modern)
    * `bun`
* **NVM Aware:** Correctly sources `~/.nvm/nvm.sh` if it exists, ensuring it can find and update Node-managed packages.
* **Interactive:** Prompts for confirmation before checking for updates and again before applying them.
* **Responsive:** Includes a text-based spinner animation to show that long-running update tasks are in progress.
* **Selective:** Allows you to opt-out of updating programming language packages (npm, Yarn, Bun) if you only want to run system updates.
* **Safe:** Uses `set -e` to exit immediately if any command fails, preventing potential issues.

## 💻 Supported Software

This script actively detects and supports updates for the following:

* **System Package Managers:**
    * `apt` (Debian, Ubuntu, Mint)
    * `dnf` (Fedora, RHEL)
    * `yum` (CentOS, older RHEL)
    * `pacman` (Arch, Manjaro)
    * `zypper` (openSUSE)
* **Application Package Managers:**
    * `snap`
* **Programming Language Managers:**
    * `npm` (global packages)
    * `yarn` (global packages)
    * `bun` (self-update)

## 🚀 Installation (Easy Setup)

This project includes an installer that automatically sets up the script and creates an application launcher for you.

1.  **Clone the repository:**
    ```sh
    git clone [https://github.com/VARDHAMANPATEL23/Linux-Auto-Updater-Script.git](https://github.com/VARDHAMANPATEL23/Linux-Auto-Updater-Script.git)
    cd Linux-Auto-Updater-Script
    ```

2.  **Make the scripts executable:**
    ```sh
    chmod +x install.sh uninstall.sh myUpdaterScript.sh
    ```

3.  **Run the installer:**
    ```sh
    ./install.sh
    ```

That's it! You can now find "System Updater" in your system's application menu.

### Uninstallation

To remove the script and its launcher, simply run the uninstaller:
```sh
./uninstall.sh