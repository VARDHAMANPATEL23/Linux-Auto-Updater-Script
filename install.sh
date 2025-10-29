#!/bin/bash
# install.sh
# Installs the system updater script and creates a .desktop launcher
# with correct paths for the current user.

set -e

echo "--- System Updater Installer ---"

# 1. Get the absolute path to the directory this script is in
# This allows the script to be run from anywhere.
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

# 2. Define standard installation paths in the user's home directory
# These do not require sudo to write to.
INSTALL_SCRIPT_DIR="$HOME/.local/bin"
INSTALL_ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
INSTALL_DESKTOP_DIR="$HOME/.local/share/applications"

# 3. Define the file names
SCRIPT_NAME="myUpdaterScript.sh"
# Assumes your icon is named "icon.png" in the same directory
SOURCE_ICON_NAME="icon.png" 
INSTALLED_ICON_NAME="system-updater-icon.png"
DESKTOP_FILE_NAME="system-updater.desktop"

# 4. Create the target directories if they don't exist
echo "Creating directories..."
mkdir -p "$INSTALL_SCRIPT_DIR"
mkdir -p "$INSTALL_ICON_DIR"
mkdir -p "$INSTALL_DESKTOP_DIR"

# 5. Install the script and icon
echo "Installing script to $INSTALL_SCRIPT_DIR"
cp "$SCRIPT_DIR/$SCRIPT_NAME" "$INSTALL_SCRIPT_DIR/$SCRIPT_NAME"
chmod +x "$INSTALL_SCRIPT_DIR/$SCRIPT_NAME"

echo "Installing icon to $INSTALL_ICON_DIR"
cp "$SCRIPT_DIR/$SOURCE_ICON_NAME" "$INSTALL_ICON_DIR/$INSTALLED_ICON_NAME"

# 6. Dynamically create the .desktop file
# This is the most important part.
# It uses variables to build the file with the user's correct paths.
echo "Creating .desktop file in $INSTALL_DESKTOP_DIR"

cat << EOF > "$INSTALL_DESKTOP_DIR/$DESKTOP_FILE_NAME"
[Desktop Entry]
Name=System Updater
Comment=Check and apply system updates automatically
Exec=gnome-terminal -- /bin/zsh -c "sudo $INSTALL_SCRIPT_DIR/$SCRIPT_NAME; echo; echo 'Script finished. Press Enter to close.'; read -n 1 -s"
Icon=$INSTALL_ICON_DIR/$INSTALLED_ICON_NAME
Terminal=false
Type=Application
Categories=System;Utility;
EOF

# 7. Update the application database so the icon appears
echo "Updating application database..."
update-desktop-database "$INSTALL_DESKTOP_DIR"

echo ""
echo "✅ Installation Complete!"
echo "You can now find 'System Updater' in your application menu."