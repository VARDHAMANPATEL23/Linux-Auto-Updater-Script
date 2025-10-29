#!/bin/bash
# update_system.sh
# This script automatically detects the Linux distribution, desktop environment,
# and various package managers (system, app, and programming language specific),
# then offers to check for and apply system and application updates.
# This version keeps all checks and update functions separate for clarity.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Variables ---
DISTRO_NAME="Unknown"
DISTRO_ID="unknown"
PACKAGE_MANAGER="unknown"
DESKTOP_ENVIRONMENT="Unknown"
SUDO_CMD=""

# App Package Managers
HAS_SNAP=false
HAS_FLATPAK=false
HAS_BREW=false

# Programming Toolchain Flags
HAS_NVM=false # Node Version Manager
HAS_NPM=false
HAS_YARN=false
HAS_BUN=false
HAS_RUSTUP=false
HAS_PIP=false
HAS_PIPX=false
HAS_GEM=false
HAS_ASDF=false
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

# Spinner Function
# $1: The command to run (as a string)
# $2: The message to display while spinning
run_with_spinner() {
    local cmd="$1"
    local msg="$2"
    local spinner_chars="/-\|"
    local i=0

    (
        while true; do
            printf "\r[${spinner_chars:i++%${#spinner_chars}:1}] $msg"
            sleep 0.1
        done
    ) &
    SPINNER_PID=$!
    trap "kill $SPINNER_PID 2>/dev/null; printf '\r'; exit" SIGINT SIGTERM

    local cmd_output
    cmd_output=$(eval "$cmd" 2>&1)
    local cmd_exit_code=$?

    kill $SPINNER_PID 2>/dev/null
    wait $SPINNER_PID 2>/dev/null

    printf "\r%-80s\n" " "
    if [ $cmd_exit_code -eq 0 ]; then
        printf "✅ $msg ... Done\n"
    else
        printf "❌ $msg ... Failed\n"
        if ! echo "$cmd_output" | grep -q -e "No packages to update" -e "nothing to upgrade"; then
            echo "Error details:"
            echo "$cmd_output"
        fi
    fi
    return $cmd_exit_code
}

# --- Sourcing Function ---

# Source common toolchain environments
source_toolchains() {
    display_message "Detection" "Sourcing toolchain environments..."

    # Source NVM (Node)
    if [ -s "$HOME/.nvm/nvm.sh" ]; then
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        if command -v nvm &> /dev/null; then
            HAS_NVM=true
            echo "Sourced NVM (Node Version Manager)."
        fi
    fi
    
    # Source ASDF (Multi-language)
    if [ -s "$HOME/.asdf/asdf.sh" ]; then
        . "$HOME/.asdf/asdf.sh"
        if command -v asdf &> /dev/null; then
            HAS_ASDF=true
            echo "Sourced asdf (Multi-language Version Manager)."
        fi
    fi

    # Source RUSTUP (Rust)
    if [ -s "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
        if command -v rustup &> /dev/null; then
            HAS_RUSTUP=true
            echo "Sourced Cargo (Rust)."
        fi
    fi
}


# --- Detection Functions ---

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
    else
        DISTRO_NAME="Generic Linux"
        DISTRO_ID="generic_linux"
        echo "Could not precisely detect distribution."
    fi
}

detect_package_manager() {
    display_message "Detection" "Detecting system package manager..."
    case "$DISTRO_ID" in
        ubuntu|debian|linuxmint)
            [ -x "$(command -v apt)" ] && PACKAGE_MANAGER="apt"
            ;;
        fedora|centos|rhel|redhat_based)
            [ -x "$(command -v dnf)" ] && PACKAGE_MANAGER="dnf"
            [ -x "$(command -v yum)" ] && PACKAGE_MANAGER="yum"
            ;;
        arch|manjaro)
            [ -x "$(command -v pacman)" ] && PACKAGE_MANAGER="pacman"
            ;;
        opensuse-leap|opensuse-tumbleweed|sles)
            [ -x "$(command -v zypper)" ] && PACKAGE_MANAGER="zypper"
            ;;
        *)
            [ -x "$(command -v apt)" ] && PACKAGE_MANAGER="apt" || \
            [ -x "$(command -v dnf)" ] && PACKAGE_MANAGER="dnf" || \
            [ -x "$(command -v yum)" ] && PACKAGE_MANAGER="yum" || \
            [ -x "$(command -v pacman)" ] && PACKAGE_MANAGER="pacman" || \
            [ -x "$(command -v zypper)" ] && PACKAGE_MANAGER="zypper"
            ;;
    esac

    if [ "$PACKAGE_MANAGER" = "unknown" ]; then
        echo "Error: Could not detect a supported system package manager."
    else
        echo "Detected System Package Manager: ${PACKAGE_MANAGER}"
    fi
}

detect_desktop_environment() {
    display_message "Detection" "Detecting desktop environment..."
    if [ -n "$XDG_CURRENT_DESKTOP" ]; then
        DESKTOP_ENVIRONMENT="$XDG_CURRENT_DESKTOP"
    elif [ -n "$DESKTOP_SESSION" ]; then
        DESKTOP_ENVIRONMENT="$DESKTOP_SESSION"
    fi
    echo "Detected Desktop Environment: ${DESKTOP_ENVIRONMENT}"
}

# --- App Package Manager Detections ---

check_snap() {
    display_message "Detection" "Checking for Snap..."
    [ -x "$(command -v snap)" ] && HAS_SNAP=true && echo "Snap detected."
}

check_flatpak() {
    display_message "Detection" "Checking for Flatpak..."
    [ -x "$(command -v flatpak)" ] && HAS_FLATPAK=true && echo "Flatpak detected."
}

check_brew() {
    display_message "Detection" "Checking for Homebrew..."
    [ -x "$(command -v brew)" ] && HAS_BREW=true && echo "Homebrew detected."
}

# --- Programming Toolchain Detections ---

check_npm() {
    display_message "Detection" "Checking for npm..."
    if [ -x "$(command -v npm)" ]; then
        HAS_NPM=true && echo "npm detected."
        [ "$HAS_NVM" = true ] && echo " (Managed by NVM)"
    fi
}

check_yarn() {
    display_message "Detection" "Checking for Yarn..."
    if [ -x "$(command -v yarn)" ]; then
        HAS_YARN=true
        YARN_VERSION=$(yarn --version 2>/dev/null | cut -d'.' -f1)
        echo "Yarn detected (Version: ${YARN_VERSION})."
        [ "$HAS_NVM" = true ] && echo " (Managed by NVM)"
    fi
}

check_bun() {
    display_message "Detection" "Checking for Bun..."
    [ -x "$(command -v bun)" ] && HAS_BUN=true && echo "Bun detected."
}

check_rustup() {
    display_message "Detection" "Checking for Rust (rustup)..."
    [ "$HAS_RUSTUP" = true ] && echo "Rust (rustup) detected."
}

check_pip() {
    display_message "Detection" "Checking for Python (pip)..."
    [ -x "$(command -v pip3)" ] && HAS_PIP=true && echo "pip3 detected."
}

check_pipx() {
    display_message "Detection" "Checking for pipx..."
    [ -x "$(command -v pipx)" ] && HAS_PIPX=true && echo "pipx detected."
}

check_gem() {
    display_message "Detection" "Checking for Ruby (gem)..."
    [ -x "$(command -v gem)" ] && HAS_GEM=true && echo "RubyGems detected."
}

check_asdf() {
    display_message "Detection" "Checking for asdf..."
    [ "$HAS_ASDF" = true ] && echo "asdf detected."
}


# --- Update Check Functions ---

check_system_updates() {
    if [ "$PACKAGE_MANAGER" != "unknown" ]; then
        echo ""
        echo "Checking for system package updates (${PACKAGE_MANAGER})..."
        case "$PACKAGE_MANAGER" in
            apt) ${SUDO_CMD} apt update; apt list --upgradable ;;
            dnf) ${SUDO_CMD} dnf check-update ;;
            yum) ${SUDO_CMD} yum check-update ;;
            pacman) ${SUDO_CMD} pacman -Sy; pacman -Qu ;;
            zypper) ${SUDO_CMD} zypper refresh; zypper lu ;;
        esac
    fi
}

check_snap_updates() {
    [ "$HAS_SNAP" = true ] && echo "" && echo "Checking for Snap updates..." && ${SUDO_CMD} snap refresh --list
}

check_flatpak_updates() {
    [ "$HAS_FLATPAK" = true ] && echo "" && echo "Checking for Flatpak updates..." && flatpak remote-ls --updates
}

check_brew_updates() {
    [ "$HAS_BREW" = true ] && echo "" && echo "Checking for Homebrew updates..." && brew outdated
}

check_npm_global_updates() {
    [ "$HAS_NPM" = true ] && echo "" && echo "Checking for npm global updates..." && npm outdated -g || true
}

check_yarn_global_updates() {
    [ "$HAS_YARN" = true ] && echo "" && echo "Checking for Yarn global updates..." && (yarn global upgrade --dry-run || true)
}

check_bun_self_update() {
    [ "$HAS_BUN" = true ] && echo "" && echo "Checking for Bun self-update..." && bun upgrade --dry-run || true
}

check_rust_updates() {
    [ "$HAS_RUSTUP" = true ] && echo "" && echo "Checking for Rust toolchain updates..." && rustup check
}

check_pip_updates() {
    [ "$HAS_PIP" = true ] && echo "" && echo "Checking for pip updates..." && pip3 list --outdated
}

check_pipx_updates() {
    [ "$HAS_PIPX" = true ] && echo "" && echo "Checking for pipx package updates..." && pipx list --outdated
}

check_gem_updates() {
    [ "$HAS_GEM" = true ] && echo "" && echo "Checking for Ruby Gem updates..." && gem outdated
}

check_asdf_updates() {
    [ "$HAS_ASDF" = true ] && echo "" && echo "Checking for asdf plugin updates..." && asdf plugin list all
}

check_for_all_updates() {
    echo ""
    display_message "Update Check" "Checking for all available updates..."
    
    # System & App Checks
    check_system_updates
    check_snap_updates
    check_flatpak_updates
    check_brew_updates

    # Programming Toolchain Checks
    check_npm_global_updates
    check_yarn_global_updates
    check_bun_self_update
    check_rust_updates
    check_pip_updates
    check_pipx_updates
    check_gem_updates
    check_asdf_updates

    echo ""
    display_message "Update Check" "All update checks complete."
    return 0
}


# --- Perform Update Functions ---

perform_system_update() {
    if [ "$PACKAGE_MANAGER" != "unknown" ]; then
        echo "Applying system package updates (${PACKAGE_MANAGER})..."
        case "$PACKAGE_MANAGER" in
            apt)
                run_with_spinner "${SUDO_CMD} apt upgrade -y" "Applying apt upgrades"
                run_with_spinner "${SUDO_CMD} apt autoremove -y" "Cleaning up old packages"
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
                ;;
        esac
    fi
}

perform_snap_update() {
    [ "$HAS_SNAP" = true ] && echo "" && run_with_spinner "${SUDO_CMD} snap refresh" "Applying Snap updates"
}

perform_flatpak_update() {
    [ "$HAS_FLATPAK" = true ] && echo "" && run_with_spinner "flatpak update -y" "Applying Flatpak updates"
}

perform_brew_update() {
    [ "$HAS_BREW" = true ] && echo "" && run_with_spinner "brew update && brew upgrade" "Applying Homebrew updates"
}

perform_npm_global_update() {
    if [ "$HAS_NPM" = true ]; then
        echo ""
        run_with_spinner "npm install -g npm@latest" "Updating npm itself" || true
        run_with_spinner "npm update -g" "Updating global npm packages" || true
    fi
}

perform_yarn_global_update() {
    if [ "$HAS_YARN" = true ]; then
        echo ""
        [ "$(npm list -g yarn)" ] && run_with_spinner "npm install -g yarn@latest" "Updating Yarn (via npm)" || true
        run_with_spinner "yarn global upgrade" "Applying Yarn global updates" || true
    fi
}

perform_bun_self_update() {
    [ "$HAS_BUN" = true ] && echo "" && run_with_spinner "bun upgrade" "Applying Bun self-update" || true
}

perform_rust_update() {
    [ "$HAS_RUSTUP" = true ] && echo "" && run_with_spinner "rustup update" "Updating Rust toolchain" || true
}

perform_pip_update() {
    [ "$HAS_PIP" = true ] && echo "" && run_with_spinner "pip3 install --upgrade pip" "Updating pip" || true
}

perform_pipx_update() {
    [ "$HAS_PIPX" = true ] && echo "" && run_with_spinner "pipx upgrade-all" "Updating all pipx packages" || true
}

perform_gem_update() {
    if [ "$HAS_GEM" = true ]; then
        echo ""
        run_with_spinner "gem update --system" "Updating RubyGems system" || true
        run_with_spinner "gem update" "Updating all gems" || true
    fi
}

perform_asdf_update() {
    if [ "$HAS_ASDF" = true ]; then
        echo ""
        run_with_spinner "asdf update" "Updating asdf" || true
        run_with_spinner "asdf plugin update --all" "Updating all asdf plugins" || true
    fi
}

# Main function to perform all types of updates
perform_all_updates() {
    echo ""
    display_message "Update Action" "Performing System and App updates..."

    perform_system_update
    perform_snap_update
    perform_flatpak_update
    perform_brew_update

    # Check if any programming toolchains were detected
    if [ "$HAS_NPM" = true ] || [ "$HAS_YARN" = true ] || [ "$HAS_BUN" = true ] || \
       [ "$HAS_RUSTUP" = true ] || [ "$HAS_PIP" = true ] || [ "$HAS_PIPX" = true ] || \
       [ "$HAS_GEM" = true ] || [ "$HAS_ASDF" = true ]; then
        
        echo ""
        if prompt_for_confirmation "Do you want to apply programming toolchain updates (npm, Rust, pip, etc)?"; then
            display_message "Update Action" "Performing Programming Toolchain updates..."
            perform_npm_global_update
            perform_yarn_global_update
            perform_bun_self_update
            perform_rust_update
            perform_pip_update
            perform_pipx_update
            perform_gem_update
            perform_asdf_update
        else
            display_message "Action Skipped" "Programming toolchain updates skipped by user."
        fi
    else
        echo "No programming toolchains detected, skipping."
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
source_toolchains # Source NVM, ASDF, Rust FIRST
detect_package_manager

# App Detections
check_snap
check_flatpak
check_brew

# Programming Detections
check_npm
check_yarn
check_bun
check_rustup
check_pip
check_pipx
check_gem
check_asdf

# Step 2: Display info
echo ""
display_message "System Information" "
Distribution: ${DISTRO_NAME}
Package Manager: ${PACKAGE_MANAGER}
Desktop Environment: ${DESKTOP_ENVIRONMENT}
---
Snap: $([ "$HAS_SNAP" = true ] && echo "Yes" || echo "No")
Flatpak: $([ "$HAS_FLATPAK" = true ] && echo "Yes" || echo "No")
Homebrew: $([ "$HAS_BREW" = true ] && echo "Yes" || echo "No")
---
NVM: $([ "$HAS_NVM" = true ] && echo "Yes" || echo "No")
asdf: $([ "$HAS_ASDF" = true ] && echo "Yes" || echo "No")
Rustup: $([ "$HAS_RUSTUP" = true ] && echo "Yes" || echo "No")
npm: $([ "$HAS_NPM" = true ] && echo "Yes" || echo "No")
Yarn: $([ "$HAS_YARN" = true ] && echo "Yes" || echo "No")
Bun: $([ "$HAS_BUN" = true ] && echo "Yes" || echo "No")
pip: $([ "$HAS_PIP" = true ] && echo "Yes" || echo "No")
pipx: $([ "$HAS_PIPX" = true ] && echo "Yes" || echo "No")
RubyGems: $([ "$HAS_GEM" = true ] && echo "Yes" || echo "No")
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

# --- NEW UNIVERSAL PAUSE ---
# This keeps the terminal window open
echo ""
echo "Script finished. Press any key to close."
read -n 1 -s -r

