#!/bin/bash
# install.sh
# Installs the system updater script and creates a .desktop launcher
# with correct, universal paths for the current user.

set -e

echo "--- System Updater Installer ---"

# --- Helper Function for Choice ---
prompt_for_shortcut_location() {
    # --- MODIFIED LINES ---
    # We redirect the menu text to standard error (stderr)
    # so it prints to the terminal instead of being captured by the variable.
    echo "" >&2
    echo "Where would you like to add the shortcut?" >&2
    echo "  1) Application Menu (Recommended)" >&2
    echo "  2) Desktop" >&2
    echo "  3) Both" >&2
    echo "" >&2
    # --- END OF MODIFIED LINES ---
    
    local choice
    while true; do
        # 'read -rp' already prints its prompt to stderr, so it's fine
        read -rp "Enter your choice (1, 2, or 3): " choice
        case "$choice" in
            # This echo goes to stdout, which is what we want to capture
            1|2|3 ) echo "$choice"; return 0 ;;
            # Error messages should also go to stderr
            * ) echo "Please enter 1, 2, or 3." >&2 ;;
        esac
    done
}

# 1. Get the absolute path to the directory this script is in
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# 2. Define standard installation paths
INSTALL_SCRIPT_DIR="$HOME/.local/bin"
INSTALL_ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
APP_MENU_DIR="$HOME/.local/share/applications"
DESKTOP_DIR="$HOME/Desktop" # <-- New path added

# 3. Define the file names
SCRIPT_NAME="myUpdaterScript.sh"
SOURCE_ICON_NAME="icon.png" # Assumes your icon is in the same directory
INSTALLED_ICON_NAME="system-updater-icon.png"
DESKTOP_FILE_NAME="system-updater.desktop"

# 4. Create the target directories
echo "Creating directories..."
mkdir -p "$INSTALL_SCRIPT_DIR"
mkdir -p "$INSTALL_ICON_DIR"
mkdir -p "$APP_MENU_DIR"
mkdir -p "$DESKTOP_DIR" # Ensure Desktop directory exists

# 5. Install the script and icon
echo "Installing script to $INSTALL_SCRIPT_DIR"
cp "$SCRIPT_DIR/$SCRIPT_NAME" "$INSTALL_SCRIPT_DIR/$SCRIPT_NAME"
chmod +x "$INSTALL_SCRIPT_DIR/$SCRIPT_NAME"

echo "Installing icon to $INSTALL_ICON_DIR"
# Check if icon.png exists before copying
if [ -f "$SCRIPT_DIR/$SOURCE_ICON_NAME" ]; then
    cp "$SCRIPT_DIR/$SOURCE_ICON_NAME" "$INSTALL_ICON_DIR/$INSTALLED_ICON_NAME"
else
    echo "Warning: icon.png not found. Skipping icon installation."
fi

# 6. Define the .desktop file content
# We store it in a variable to write it to multiple places easily.
DESKTOP_ENTRY_CONTENT="[Desktop Entry]
Name=System Updater
Comment=Check and apply system updates automatically
Exec=sudo $INSTALL_SCRIPT_DIR/$SCRIPT_NAME
Icon=$INSTALL_ICON_DIR/$INSTALLED_ICON_NAME
Terminal=true
Type=Application
Categories=System;Utility;
"

# 7. Ask user and create shortcut(s)
USER_CHOICE=$(prompt_for_shortcut_location)

case "$USER_CHOICE" in
    1)
        echo "Installing shortcut to Application Menu..."
        echo "$DESKTOP_ENTRY_CONTENT" > "$APP_MENU_DIR/$DESKTOP_FILE_NAME"
        echo "Updating application database..."
        update-desktop-database "$APP_MENU_DIR"
        ;;
    2)
        echo "Installing shortcut to Desktop..."
        echo "$DESKTOP_ENTRY_CONTENT" > "$DESKTOP_DIR/$DESKTOP_FILE_NAME"
        chmod +x "$DESKTOP_DIR/$DESKTOP_FILE_NAME" # Make desktop file trusted
        ;;
    3)
        echo "Installing shortcut to Application Menu..."
        echo "$DESKTOP_ENTRY_CONTENT" > "$APP_MENU_DIR/$DESKTOP_FILE_NAME"
        echo "Updating application database..."
        update-desktop-database "$APP_MENU_DIR"
        
        echo "Installing shortcut to Desktop..."
        echo "$DESKTOP_ENTRY_CONTENT" > "$DESKTOP_DIR/$DESKTOP_FILE_NAME"
        chmod +x "$DESKTOP_DIR/$DESKTOP_FILE_NAME" # Make desktop file trusted
        ;;
esac

echo ""
echo "✅ Installation Complete!"
echo "You can now find 'System Updater' in your chosen location(s)."