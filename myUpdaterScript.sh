#!/bin/bash
# update_system.sh
# This script automatically detects the Linux distribution, desktop environment,
# and various package managers (system, Snap, and programming language specific),
# then offers to check for and apply system and application updates.
# Now includes an option to opt out of programming language package updates.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Variables ---
DISTRO_NAME="Unknown"
DISTRO_ID="unknown"
PACKAGE_MANAGER="unknown"
DESKTOP_ENVIRONMENT="Unknown"
SUDO_CMD=""
HAS_SNAP=false
HAS_NPM=false
HAS_YARN=false
HAS_BUN=false
HAS_NVM=false # Node Version Manager
YARN_VERSION="" # To store Yarn version

# --- Helper Functions ---

# Function to display a message box (simple alternative to alert/confirm)
display_message() {
    local title="$1"
    local message="$2"
    echo "--- $title ---"
    echo "$message"
    echo "-----------------"
}

# Function to prompt for Y/N confirmation
prompt_for_confirmation() {
    local question="$1"
    while true; do
        read -rp "$question (Y/N): " response
        case "$response" in
            [Yy]* ) return 0 ;; # User said Yes
            [Nn]* ) return 1 ;; # User said No
            * ) echo "Please answer Y or N." ;;
        esac
    done
}

# --- Detection Functions ---

# Function to detect the Linux distribution
detect_distro() {
    display_message "Detection" "Detecting Linux distribution..."
    if [ -f "/etc/os-release" ]; then
        # Most modern Linux distributions use /etc/os-release
        source "/etc/os-release"
        DISTRO_NAME="${PRETTY_NAME:-$NAME}"
        DISTRO_ID="${ID}"
        echo "Detected Distribution: ${DISTRO_NAME} (ID: ${DISTRO_ID})"
    elif [ -f "/etc/lsb-release" ]; then
        # For older Debian/Ubuntu-based systems
        source "/etc/lsb-release"
        DISTRO_NAME="${DISTRIB_DESCRIPTION:-Ubuntu/Debian-based}"
        DISTRO_ID="ubuntu_debian_legacy"
        echo "Detected Distribution: ${DISTRO_NAME}"
    elif [ -f "/etc/redhat-release" ]; then
        # For RHEL/CentOS/Fedora
        DISTRO_NAME=$(cat /etc/redhat-release)
        DISTRO_ID="redhat_based"
        echo "Detected Distribution: ${DISTRO_NAME}"
    elif [ -f "/etc/debian_version" ]; then
        # Generic Debian check
        DISTRO_NAME="Debian"
        DISTRO_ID="debian"
        echo "Detected Distribution: Debian"
    else
        DISTRO_NAME="Generic Linux"
        DISTRO_ID="generic_linux"
        echo "Could not precisely detect distribution. Assuming generic Linux."
    fi
}

# Function to detect the package manager
detect_package_manager() {
    display_message "Detection" "Detecting system package manager..."
    case "$DISTRO_ID" in
        ubuntu|debian|linuxmint)
            if command -v apt &> /dev/null; then
                PACKAGE_MANAGER="apt"
            fi
            ;;
        fedora|centos|rhel|redhat_based)
            if command -v dnf &> /dev/null; then
                PACKAGE_MANAGER="dnf"
            elif command -v yum &> /dev/null; then
                PACKAGE_MANAGER="yum"
            fi
            ;;
        arch|manjaro)
            if command -v pacman &> /dev/null; then
                PACKAGE_MANAGER="pacman"
            fi
            ;;
        opensuse-leap|opensuse-tumbleweed|sles)
            if command -v zypper &> /dev/null; then
                PACKAGE_MANAGER="zypper"
            fi
            ;;
        *)
            # Fallback for unknown distros: check common package managers
            if command -v apt &> /dev/null; then
                PACKAGE_MANAGER="apt"
            elif command -v dnf &> /dev/null; then
                PACKAGE_MANAGER="dnf"
            elif command -v yum &> /dev/null; then
                PACKAGE_MANAGER="yum"
            elif command -v pacman &> /dev/null; then
                PACKAGE_MANAGER="pacman"
            elif command -v zypper &> /dev/null; then
                PACKAGE_MANAGER="zypper"
            fi
            ;;
    esac

    if [ "$PACKAGE_MANAGER" = "unknown" ]; then
        echo "Error: Could not detect a supported system package manager for core system updates."
        # Do not exit here, as Snap/programming updates might still be possible
    else
        echo "Detected System Package Manager: ${PACKAGE_MANAGER}"
    fi
}

# Function to detect the desktop environment
detect_desktop_environment() {
    display_message "Detection" "Detecting desktop environment..."
    if [ -n "$XDG_CURRENT_DESKTOP" ]; then
        DESKTOP_ENVIRONMENT="$XDG_CURRENT_DESKTOP"
    elif [ -n "$DESKTOP_SESSION" ]; then
        DESKTOP_ENVIRONMENT="$DESKTOP_SESSION"
    else
        # Try to guess based on common processes/executables
        if pgrep -x "gnome-shell" > /dev/null || pgrep -x "gnome-session" > /dev/null; then
            DESKTOP_ENVIRONMENT="GNOME"
        elif pgrep -x "kdeinit5" > /dev/null || pgrep -x "plasmashell" > /dev/null; then
            DESKTOP_ENVIRONMENT="KDE Plasma"
        elif pgrep -x "xfce4-session" > /dev/null; then
            DESKTOP_ENVIRONMENT="XFCE"
        elif pgrep -x "mate-session" > /dev/null; then
            DESKTOP_ENVIRONMENT="MATE"
        elif pgrep -x "cinnamon" > /dev/null; then
            DESKTOP_ENVIRONMENT="Cinnamon"
        elif pgrep -x "lxsession" > /dev/null; then
            DESKTOP_ENVIRONMENT="LXDE/LXQt"
        fi
    fi
    echo "Detected Desktop Environment: ${DESKTOP_ENVIRONMENT}"
}

# Function to check for Snap presence
check_snap() {
    display_message "Detection" "Checking for Snap support..."
    if command -v snap &> /dev/null; then
        HAS_SNAP=true
        echo "Snap (snapd) detected."
    else
        echo "Snap (snapd) not found."
    fi
}

# Function to check for NVM (Node Version Manager) presence
# This also sources NVM so npm/yarn commands are available if managed by NVM
check_nvm() {
    display_message "Detection" "Checking for NVM (Node Version Manager) presence..."
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        export NVM_DIR="$HOME/.nvm"
        # Source nvm.sh to make 'nvm' and nvm-managed node/npm/yarn available in this script's context
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        if command -v nvm &> /dev/null; then
            HAS_NVM=true
            echo "NVM (Node Version Manager) detected."
            echo "Note: NVM manages Node.js versions. To update NVM itself, you typically re-run its install script."
            echo "This script will focus on updating global npm/Yarn packages managed by NVM."
        fi
    fi
    if [ "$HAS_NVM" = false ]; then
        echo "NVM not found."
    fi
}

# Function to check for npm presence
check_npm() {
    display_message "Detection" "Checking for npm (Node Package Manager) presence..."
    if command -v npm &> /dev/null; then
        HAS_NPM=true
        echo "npm detected."
        if [ "$HAS_NVM" = true ]; then
            echo " (npm is likely managed by NVM)"
        fi
    else
        echo "npm not found."
    fi
}

# Function to check for Yarn presence
check_yarn() {
    display_message "Detection" "Checking for Yarn presence..."
    if command -v yarn &> /dev/null; then
        HAS_YARN=true
        YARN_VERSION=$(yarn --version 2>/dev/null | cut -d'.' -f1)
        echo "Yarn detected (Version: ${YARN_VERSION})."
        if [ "$HAS_NVM" = true ]; then
            echo " (Yarn is likely managed by NVM)"
        fi
    else
        echo "Yarn not found."
    fi
}

# Function to check for Bun presence
check_bun() {
    display_message "Detection" "Checking for Bun presence..."
    if command -v bun &> /dev/null; then
        HAS_BUN=true
        echo "Bun detected."
    else
        echo "Bun not found."
    fi
}


# --- Update Check Functions ---

# Function to check for system package updates
check_system_updates() {
    if [ "$PACKAGE_MANAGER" != "unknown" ]; then
        echo "Checking for system package updates using ${PACKAGE_MANAGER}..."
        case "$PACKAGE_MANAGER" in
            apt)
                ${SUDO_CMD} apt update
                apt list --upgradable
                ;;
            dnf)
                ${SUDO_CMD} dnf check-update
                ;;
            yum)
                ${SUDO_CMD} yum check-update
                ;;
            pacman)
                ${SUDO_CMD} pacman -Sy
                pacman -Qu
                ;;
            zypper)
                ${SUDO_CMD} zypper refresh
                zypper lu
                ;;
            *)
                echo "Warning: Unsupported system package manager for checking updates: ${PACKAGE_MANAGER}"
                ;;
        esac
    else
        echo "Skipping system package update check as no supported package manager was detected."
    fi
}

# Function to check for Snap package updates
check_snap_updates() {
    if [ "$HAS_SNAP" = true ]; then
        echo ""
        echo "Checking for Snap package updates..."
        ${SUDO_CMD} snap refresh --list
    fi
}

# Function to check for npm global package updates
check_npm_global_updates() {
    if [ "$HAS_NPM" = true ]; then
        echo ""
        echo "Checking for npm global package updates..."
        # Running without sudo, as global npm packages are often managed by the user or NVM
        npm outdated -g || true # `|| true` prevents `set -e` from exiting if no outdated packages
        echo "Note: To update npm itself, the command is 'npm install -g npm@latest'."
        echo "This will be attempted during the 'Apply Updates' phase."
    fi
}

# Function to check for Yarn global package updates
check_yarn_global_updates() {
    if [ "$HAS_YARN" = true ]; then
        echo ""
        echo "Checking for Yarn global package updates..."
        if [[ "$YARN_VERSION" -eq 1 ]]; then
            # For Yarn Classic (v1), 'outdated' subcommand for global packages is not standard/reliable
            # Use 'yarn global upgrade --json --dry-run' to show what would be upgraded
            echo "Using 'yarn global upgrade --json --dry-run' for Yarn Classic (v1) update check."
            yarn global upgrade --json --dry-run || true
            echo "Note: The above output shows packages that *would* be upgraded."
        else
            # For Yarn Modern (Berry) or future versions, 'yarn outdated' should work
            # yarn global outdated (or 'yarn outdated --immutable' for Yarn 2+)
            # However, Yarn 2+ discourages global installs. We'll stick to 'global upgrade --dry-run' for consistency.
            echo "Checking for Yarn global package updates using 'yarn global upgrade --dry-run'..."
            yarn global upgrade --dry-run || true
        fi
        echo "Note: To update Yarn itself, you might need 'npm install -g yarn' if installed via npm."
    fi
}

# Function to check for Bun updates (Bun self-updates)
check_bun_self_update() {
    if [ "$HAS_BUN" = true ]; then
        echo ""
        echo "Checking for Bun self-update..."
        # Bun's upgrade command itself checks for and applies updates
        bun upgrade --dry-run || true # --dry-run for check, || true to prevent exit on no update
        echo "Note: 'bun upgrade' updates Bun itself and its internal dependencies."
    fi
}

# Main function to check for all types of updates
check_for_all_updates() {
    echo ""
    display_message "Update Check" "Checking for all available updates..."

    check_system_updates
    check_snap_updates
    check_npm_global_updates
    check_yarn_global_updates
    check_bun_self_update

    echo ""
    display_message "Update Check" "All update checks complete."
    return 0
}


# --- Perform Update Functions ---

# Function to perform system package updates
perform_system_update() {
    if [ "$PACKAGE_MANAGER" != "unknown" ]; then
        echo "Applying system package updates using ${PACKAGE_MANAGER}..."
        case "$PACKAGE_MANAGER" in
            apt)
                ${SUDO_CMD} apt upgrade -y
                ${SUDO_CMD} apt autoremove -y # Clean up old packages
                ${SUDO_CMD} apt autoclean -y  # Clean up downloaded archives
                ;;
            dnf)
                ${SUDO_CMD} dnf upgrade -y
                ${SUDO_CMD} dnf autoremove -y
                ;;
            yum)
                ${SUDO_CMD} yum update -y
                ${SUDO_CMD} yum autoremove -y
                ;;
            pacman)
                ${SUDO_CMD} pacman -Syu --noconfirm
                ;;
            zypper)
                ${SUDO_CMD} zypper update -y
                ${SUDO_CMD} zypper clean
                ;;
            *)
                echo "Warning: Unsupported system package manager for performing updates: ${PACKAGE_MANAGER}"
                ;;
        esac
    else
        echo "Skipping system package update as no supported package manager was detected."
    fi
}

# Function to perform Snap package updates
perform_snap_update() {
    if [ "$HAS_SNAP" = true ]; then
        echo ""
        echo "Applying Snap package updates..."
        ${SUDO_CMD} snap refresh
    fi
}

# Function to perform npm global package updates
perform_npm_global_update() {
    if [ "$HAS_NPM" = true ]; then
        echo ""
        echo "Applying npm global package updates..."
        # Update npm itself first
        echo "Attempting to update npm itself..."
        npm install -g npm@latest || true # `|| true` prevents exit on non-zero, allowing subsequent updates
        echo "Updating other global npm packages..."
        npm update -g || true
        echo "Note: Some global npm packages may require 'sudo' if installed system-wide."
    fi
}

# Function to perform Yarn global package updates
perform_yarn_global_update() {
    if [ "$HAS_YARN" = true ]; then
        echo ""
        echo "Applying Yarn global package updates..."
        # For yarn itself, if it was installed via npm, update it with npm
        if npm list -g yarn &> /dev/null; then
            echo "Attempting to update Yarn itself (if installed via npm)..."
            npm install -g yarn@latest || true
        fi
        # Perform the actual global upgrade
        yarn global upgrade || true
        echo "Note: Some global Yarn packages may require 'sudo' if installed system-wide."
    fi
}

# Function to perform Bun self-update
perform_bun_self_update() {
    if [ "$HAS_BUN" = true ]; then
        echo ""
        echo "Applying Bun self-update..."
        bun upgrade || true # Bun's upgrade command updates itself and its internal dependencies
    fi
}

# Main function to perform all types of updates
perform_all_updates() {
    echo ""
    display_message "Update Action" "Performing all requested system and application updates..."

    perform_system_update
    perform_snap_update

    # Check if any programming package managers were detected before asking
    if [ "$HAS_NPM" = true ] || [ "$HAS_YARN" = true ] || [ "$HAS_BUN" = true ]; then
        echo ""
        if prompt_for_confirmation "Do you want to apply programming package updates (npm, Yarn, Bun)?"; then
            perform_npm_global_update
            perform_yarn_global_update
            perform_bun_self_update
        else
            display_message "Action Skipped" "Programming package updates skipped by user."
        fi
    else
        echo "No programming package managers (npm, Yarn, Bun) detected, skipping their update."
    fi

    echo ""
    display_message "Update Action" "All requested updates complete."
    return 0
}

# --- Main Script Execution ---

# Check if sudo is available
if command -v sudo &> /dev/null; then
    SUDO_CMD="sudo"
else
    echo "Warning: 'sudo' command not found. Some update commands might require root privileges."
    echo "Please run this script with 'sudo ./update_system.sh' or ensure you have root permissions."
fi

echo "--- Starting System Update Script ---"

# Step 1: Detect system information and package managers (order matters for NVM)
detect_distro
detect_desktop_environment
check_snap
check_nvm # Check and source NVM first
detect_package_manager # System package manager
check_npm # Checks for npm after NVM is sourced
check_yarn # Checks for Yarn after NVM is sourced
check_bun

# Step 2: Display detected information
echo ""
display_message "System Information" "
Distribution: ${DISTRO_NAME}
Package Manager: ${PACKAGE_MANAGER}
Desktop Environment: ${DESKTOP_ENVIRONMENT}
Snap Support: $([ "$HAS_SNAP" = true ] && echo "Yes" || echo "No")
npm detected: $([ "$HAS_NPM" = true ] && echo "Yes" || echo "No")
Yarn detected: $([ "$HAS_YARN" = true ] && echo "Yes" || echo "No")
Bun detected: $([ "$HAS_BUN" = true ] && echo "Yes" || echo "No")
NVM detected: $([ "$HAS_NVM" = true ] && echo "Yes" || echo "No")
"

# Step 3: Prompt to check for updates
if prompt_for_confirmation "Do you want to check for all available package updates (system, Snap, and programming managers)?"; then
    check_for_all_updates

    # Step 4: Prompt to perform updates if check was successful
    if prompt_for_confirmation "Do you want to apply all available updates (system, Snap, and programming managers)?"; then
        perform_all_updates
    else
        display_message "Action Skipped" "Update application skipped by user."
    fi
else
    display_message "Action Skipped" "Update check skipped by user."
fi

echo ""
echo "--- Script Finished ---"
