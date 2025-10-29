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

## 🚀 Usage

1.  **Clone or Download**
    ```sh
    # Clone the repository (Recommended)
    git clone [https://github.com/YOUR_USERNAME/YOUR_REPOSITORY_NAME.git](https://github.com/YOUR_USERNAME/YOUR_REPOSITORY_NAME.git)
    cd YOUR_REPOSITORY_NAME

    # Or just download the script
    curl -O [https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPOSITORY_NAME/main/myUpdaterScript.sh](https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPOSITORY_NAME/main/myUpdaterScript.sh)
    ```

2.  **Make the Script Executable**
    ```sh
    chmod +x myUpdaterScript.sh
    ```

3.  **Run the Script**
    ```sh
    ./myUpdaterScript.sh
    ```

The script will first perform its detection, show you what it found, and then ask for permission to check for updates. If updates are found, it will ask for a final confirmation before applying them.


## 🔧 How It Works

1.  **Detection Phase:**
    * Reads `/etc/os-release` to find the distribution ID.
    * Selects the appropriate system package manager based on the ID.
    * Checks for the `snap` command.
    * Sources `nvm.sh` to initialize the NVM environment.
    * Checks for `npm`, `yarn`, and `bun` commands.

2.  **Check Phase (Optional):**
    * Runs the "check" or "list" command for each detected package manager (e.g., `apt list --upgradable`, `snap refresh --list`, `npm outdated -g`).
    * This phase is read-only and makes no changes.

3.  **Apply Phase (Optional):**
    * Runs the "upgrade" or "update" command for each detected package manager (e.g., `sudo apt upgrade -y`, `sudo snap refresh`, `npm update -g`).
    * Prompts the user to optionally skip programming package updates.

## 🤝 Contributing

Contributions are welcome! If you find a bug, have a suggestion, or want to add support for another package manager (like Flatpak or Homebrew), please feel free to open an issue or submit a pull request.

## 📄 License

This project is open-source. Please consider adding a `LICENSE` file (e.g., [MIT License](https://opensource.org/licenses/MIT)).