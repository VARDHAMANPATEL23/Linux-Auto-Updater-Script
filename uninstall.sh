#!/bin/bash
# uninstall.sh
# Removes the system updater script and .desktop launcher.

set -e

echo "--- System Updater Uninstaller ---"

# 1. Define paths (MUST match install.sh)
INSTALL_SCRIPT_DIR="$HOME/.local/bin"
INSTALL_ICON_DIR="$HOME/.local/share/icons/hicolor/scalable/apps"
INSTALL_DESKTOP_DIR="$HOME/.local/share/applications"

SCRIPT_NAME="myUpdaterScript.sh"
INSTALLED_ICON_NAME="system-updater-icon.png"
DESKTOP_FILE_NAME="system-updater.desktop"

# 2. Remove the installed files
echo "Removing script..."
rm -f "$INSTALL_SCRIPT_DIR/$SCRIPT_NAME"

echo "Removing icon..."
rm -f "$INSTALL_ICON_DIR/$INSTALLED_ICON_NAME"

echo "Removing .desktop file..."
rm -f "$INSTALL_DESKTOP_DIR/$DESKTOP_FILE_NAME"

# 3. Update the application database
echo "Updating application database..."
update-desktop-database "$INSTALL_DESKTOP_DIR"

echo ""
echo "🗑️ Uninstallation Complete."