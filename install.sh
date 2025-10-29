#!/bin/bash
# install.sh
# Installs the system updater script and creates a .desktop launcher
# with correct, universal paths for the current user.

set -e

echo "--- System Updater Installer ---"

# 1. Get the absolute path to the directory this script is in
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# 2. Define standard installation paths
INSTALL_SCRIPT_DIR="$HOME/.local/bin"
INSTALL_ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
INSTALL_DESKTOP_DIR="$HOME/.local/share/applications"

# 3. Define the file names
SCRIPT_NAME="myUpdaterScript.sh"
SOURCE_ICON_NAME="icon.png" # Assumes your icon is in the same directory
INSTALLED_ICON_NAME="system-updater-icon.png"
DESKTOP_FILE_NAME="system-updater.desktop"

# 4. Create the target directories
echo "Creating directories..."
mkdir -p "$INSTALL_SCRIPT_DIR"
mkdir -p "$INSTALL_ICON_DIR"
mkdir -p "$INSTALL_DESKTOP_DIR"

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

# 6. Dynamically create the UNIVERSAL .desktop file
echo "Creating universal .desktop file in $INSTALL_DESKTOP_DIR"

# --- THIS BLOCK IS UPDATED ---
cat << EOF > "$INSTALL_DESKTOP_DIR/$DESKTOP_FILE_NAME"
[Desktop Entry]
Name=System Updater
Comment=Check and apply system updates automatically
Exec=sudo $INSTALL_SCRIPT_DIR/$SCRIPT_NAME
Icon=$INSTALL_ICON_DIR/$INSTALLED_ICON_NAME
Terminal=true
Type=Application
Categories=System;Utility;
EOF
# --- END OF UPDATED BLOCK ---

# 7. Update the application database
echo "Updating application database..."
update-desktop-database "$INSTALL_DESKTOP_DIR"

echo ""
echo "✅ Installation Complete!"
echo "You can now find 'System Updater' in your application menu."
