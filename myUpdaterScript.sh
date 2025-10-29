#!/bin/bash
# update_system.sh
# This script automatically detects the Linux distribution, desktop environment,
# and various package managers (system, Snap, and programming language specific),
# then offers to check for and apply system and application updates.
# Now includes an option to opt out of programming language package updates.
# Now includes a spinner animation for update tasks.

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

# Function to display a message box
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

# --- NEW: Spinner Function ---
# $1: The command to run (as a string)
# $2: The message to display while spinning
run_with_spinner() {
    local cmd="$1"
    local msg="$2"
    local spinner_chars="/-\|"
    local i=0

    # Start the spinner animation in the background
    (
        while true; do
            # Use printf for better cursor control
            printf "\r[${spinner_chars:i++%${#spinner_chars}:1}] $msg"
            sleep 0.1
        done
    ) &
    SPINNER_PID=$!

    # Trap ensures the spinner is killed if the script exits (e.g., Ctrl+C)
    trap "kill $SPINNER_PID 2>/dev/null; printf '\r'; exit" SIGINT SIGTERM

    # Run the actual command, redirecting its output to /dev/null
    # We add `|| true` to prevent `set -e` from exiting on non-zero,
    # as we want to handle the result ourselves.
    local cmd_output
    cmd_output=$(eval "$cmd" 2>&1)
    local cmd_exit_code=$?

    # Stop the spinner
    kill $SPINNER_PID 2>/dev/null
    wait $SPINNER_PID 2>/dev/null # Wait to clean up the process

    # Clear the spinner line
    printf "\r%-80s\n" " "
    
    # Check the command's exit code
    if [ $cmd_exit_code -eq 0 ]; then
        printf "✅ $msg ... Done\n"
    else
        printf "❌ $msg ... Failed\n"
        echo "Error details:"
        echo "$cmd_output"
    fi
    
    # Return the original exit code
    return $cmd_exit_code
}

# --- Detection Functions ---

# Function to detect the Linux distribution
detect_distro() {
    display_message "Detection" "Detecting Linux distribution..."
    if [ -f "/etc/os-release" ]; then
        source "/etc/os-release"
        DISTRO_NAME="${PRETTY_NAME:-$NAME}"
        DISTRO_ID="${ID}"
        echo "Detected Distribution: ${DISTRO_NAME} (ID: ${DISTRO_ID})"
    elif [ -f "/etc/lsb-release" ]; then
        source "/etc/lsb-release"
        DISTRO_NAME="${DISTRIB_DESCRIPTION:-Ubuntu/Debian-based}"
        DISTRO_ID="ubuntu_debian_legacy"
        echo "Detected Distribution: ${DISTRO_NAME}"
    elif [ -f "/etc/redhat-release" ]; then
        DISTRO_NAME=$(cat /etc/redhat-release)
        DISTRO_ID="redhat_based"
        echo "Detected Distribution: ${DISTRO_NAME}"
    elif [ -f "/etc/debian_version" ]; then
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
        echo "Error: Could not detect a supported system package manager."
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

# Function to check for NVM presence
check_nvm() {
    display_message "Detection" "Checking for NVM (Node Version Manager)..."
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        if command -v nvm &> /dev/null; then
            HAS_NVM=true
            echo "NVM (Node Version Manager) detected."
        fi
    fi
    if [ "$HAS_NVM" = false ]; then
        echo "NVM not found."
    fi
}

# Function to check for npm presence
check_npm() {
    display_message "Detection" "Checking for npm..."
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
    display_message "Detection" "Checking for Yarn..."
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
    display_message "Detection" "Checking for Bun..."
    if command -v bun &> /dev/null; then
        HAS_BUN=true
        echo "Bun detected."
    else
        echo "Bun not found."
    fi
}


# --- Update Check Functions ---
# (These functions print output, so we DON'T use a spinner here)

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
        echo "Skipping system package update check."
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
        npm outdated -g || true
    fi
}

# Function to check for Yarn global package updates
check_yarn_global_updates() {
    if [ "$HAS_YARN" = true ]; then
        echo ""
        echo "Checking for Yarn global package updates..."
        if [[ "$YARN_VERSION" -eq 1 ]]; then
            echo "Using 'yarn global upgrade --json --dry-run' for Yarn Classic (v1)."
            yarn global upgrade --json --dry-run || true
        else
            echo "Checking for Yarn global package updates using 'yarn global upgrade --dry-run'..."
            yarn global upgrade --dry-run || true
        fi
    fi
}

# Function to check for Bun updates
check_bun_self_update() {
    if [ "$HAS_BUN" = true ]; then
        echo ""
        echo "Checking for Bun self-update..."
        bun upgrade --dry-run || true
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


# --- Perform Update Functions (WITH SPINNERS) ---

# Function to perform system package updates
perform_system_update() {
    if [ "$PACKAGE_MANAGER" != "unknown" ]; then
        echo "Applying system package updates using ${PACKAGE_MANAGER}..."
        case "$PACKAGE_MANAGER" in
            apt)
                run_with_spinner "${SUDO_CMD} apt upgrade -y" "Applying apt upgrades"
                run_with_spinner "${SUDO_CMD} apt autoremove -y" "Cleaning up old packages"
                run_with_spinner "${SUDO_CMD} apt autoclean -y" "Cleaning up downloaded archives"
                ;;
            dnf)
                run_with_spinner "${SUDO_CMD} dnf upgrade -y" "Applying dnf upgrades"
                run_with_spinner "${SUDO_CMD} dnf autoremove -y" "Cleaning up old packages"
                ;;
            yum)
                run_with_spinner "${SUDO_CMD} yum update -y" "Applying yum updates"
                run_with_spinner "${SUDO_CMD} yum autoremove -y" "Cleaning up old packages"
                ;;
            pacman)
                run_with_spinner "${SUDO_CMD} pacman -Syu --noconfirm" "Applying pacman updates"
                ;;
            zypper)
                run_with_spinner "${SUDO_CMD} zypper update -y" "Applying zypper updates"
                run_with_spinner "${SUDO_CMD} zypper clean" "Cleaning up zypper cache"
                ;;
            *)
                echo "Warning: Unsupported system package manager for performing updates: ${PACKAGE_MANAGER}"
                ;;
        esac
    else
        echo "Skipping system package update."
    fi
}

# Function to perform Snap package updates
perform_snap_update() {
    if [ "$HAS_SNAP" = true ]; then
        echo ""
        run_with_spinner "${SUDO_CMD} snap refresh" "Applying Snap package updates"
    fi
}

# Function to perform npm global package updates
perform_npm_global_update() {
    if [ "$HAS_NPM" = true ]; then
        echo ""
        run_with_spinner "npm install -g npm@latest" "Updating npm itself" || true
        run_with_spinner "npm update -g" "Updating other global npm packages" || true
    fi
}

# Function to perform Yarn global package updates
perform_yarn_global_update() {
    if [ "$HAS_YARN" = true ]; then
        echo ""
        if npm list -g yarn &> /dev/null; then
            run_with_spinner "npm install -g yarn@latest" "Updating Yarn itself (via npm)" || true
        fi
        run_with_spinner "yarn global upgrade" "Applying Yarn global package updates" || true
    fi
}

# Function to perform Bun self-update
perform_bun_self_update() {
    if [ "$HAS_BUN" = true ]; then
        echo ""
        run_with_spinner "bun upgrade" "Applying Bun self-update" || true
    fi
}

# Main function to perform all types of updates
perform_all_updates() {
    echo ""
    display_message "Update Action" "Performing all requested updates..."

    perform_system_update
    perform_snap_update

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
        echo "No programming package managers detected, skipping."
    fi

    echo ""
    display_message "Update Action" "All requested updates complete."
    return 0
}

# --- Main Script Execution ---

if command -v sudo &> /dev/null; then
    SUDO_CMD="sudo"
else
    echo "Warning: 'sudo' not found. Some commands may fail."
fi

echo "--- Starting System Update Script ---"

# Step 1: Detections
detect_distro
detect_desktop_environment
check_snap
check_nvm
detect_package_manager
check_npm
check_yarn
check_bun

# Step 2: Display info
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

# Step 3: Prompt to check
if prompt_for_confirmation "Do you want to check for all available package updates?"; then
    check_for_all_updates

    # Step 4: Prompt to perform
    if prompt_for_confirmation "Do you want to apply all available updates?"; then
        perform_all_updates
    else
        display_message "Action Skipped" "Update application skipped by user."
    fi
else
    display_message "Action Skipped" "Update check skipped by user."
fi

echo ""
echo "--- Script Finished ---"

# This keeps the terminal window open
echo ""
echo "Script finished. Press any key to close."
read -n 1 -s -r