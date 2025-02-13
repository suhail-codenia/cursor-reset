#!/bin/bash

# Check if Cursor is installed
check_cursor_installed() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if [ ! -d "/Applications/Cursor.app" ]; then
            echo "❌ Cursor editor not detected, please install Cursor first!"
            echo "Download link: https://www.cursor.com/downloads"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux"* ]]; then
        # Linux
        if [ ! -d "/usr/share/cursor" ] && [ ! -d "/opt/cursor" ] && [ ! -d "$HOME/.local/share/cursor" ]; then
            echo "❌ Cursor editor not detected, please install Cursor first!"
            echo "Download link: https://www.cursor.com/downloads"
            exit 1
        fi
    fi
    echo "✅ Cursor editor is installed"
}

# Check if Cursor is running
check_cursor_running() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        pgrep -x "Cursor" > /dev/null || pgrep -x "Cursor Helper" > /dev/null
    elif [[ "$OSTYPE" == "linux"* ]]; then
        pgrep -x "cursor" > /dev/null || pgrep -x "Cursor" > /dev/null
    fi
}

# Kill Cursor process
kill_cursor_process() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        pkill -9 "Cursor"
    elif [[ "$OSTYPE" == "linux"* ]]; then
        pkill -9 "cursor"
    fi
    sleep 1.5
}

# Get config directory path
get_config_dir() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "$HOME/Library/Application Support/Cursor"
    elif [[ "$OSTYPE" == "linux"* ]]; then
        echo "$HOME/.config/Cursor"
    else
        echo "❌ Unsupported operating system"
        exit 1
    fi
}

# Generate random device ID
generate_device_id() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo $(uuidgen)
    else
        echo $(cat /proc/sys/kernel/random/uuid)
    fi
}

# Backup config file
backup_config() {
    local config_file="$1"
    local timestamp=$(date +"%Y%m%d%H%M%S%3N")
    local backup_file="${config_file}.${timestamp}.bak"
    cp "$config_file" "$backup_file"
    echo "$backup_file"
}

# Disable auto-update
disable_cursor_update() {
    local updater_path=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        updater_path="$HOME/Library/Application Support/Caches/cursor-updater"
    elif [[ "$OSTYPE" == "linux"* ]]; then
        updater_path="$HOME/.config/cursor-updater"
    else
        echo "❌ Unsupported operating system"
        return 1
    fi

    # If the directory or file exists, delete it first
    if [ -e "$updater_path" ]; then
        rm -rf "$updater_path"
    fi

    # Create an empty file to prevent updates
    touch "$updater_path"
    if [ $? -eq 0; then
        return 0
    else
        return 1
    fi
}

# Main program
main() {
    echo "🔍 Checking Cursor editor..."
    check_cursor_installed
    echo

    echo "🔍 Checking if Cursor is running..."
    if check_cursor_running; then
        echo "Cursor is running, do you want to close it automatically? (y/N): "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo "Closing Cursor..."
            kill_cursor_process
            if check_cursor_running; then
                echo "❌ Unable to close Cursor automatically, please close it manually and try again!"
                exit 1
            fi
            echo "✅ Cursor closed successfully"
        else
            echo "❌ Please close the Cursor editor first and then run this tool!"
            exit 1
        fi
    else
        echo "✅ Cursor editor is closed"
    fi
    echo

    CONFIG_DIR=$(get_config_dir)
    STORAGE_FILE="$CONFIG_DIR/User/globalStorage/storage.json"
    
    echo "📂 Preparing config file..."
    mkdir -p "$(dirname "$STORAGE_FILE")"
    echo "✅ Config directory created successfully"
    echo

    if [ -f "$STORAGE_FILE" ]; then
        echo "💾 Backing up original config..."
        BACKUP_FILE=$(backup_config "$STORAGE_FILE")
        echo "✅ Config backup completed, backup file path: $(basename "$BACKUP_FILE")"
        echo
    fi

    echo "🎲 Generating new device ID..."
    MACHINE_ID=$(generate_device_id)
    MAC_MACHINE_ID=$(generate_device_id)
    DEV_DEVICE_ID=$(generate_device_id)

    # Create or update config file
    cat > "$STORAGE_FILE" << EOF
{
  "telemetry.machineId": "${MACHINE_ID}",
  "telemetry.macMachineId": "${MAC_MACHINE_ID}",
  "telemetry.devDeviceId": "${DEV_DEVICE_ID}"
}
EOF

    echo "✅ New device ID generated successfully"
    echo
    echo "💾 Saving new config..."
    echo "✅ New config saved successfully"
    echo
    echo "🎉 Device ID reset successfully! New device ID is:"
    echo
    cat "$STORAGE_FILE"
    echo
    echo "📝 Config file path: $STORAGE_FILE"
    echo

    # Automatically disable updates without asking
    echo "🔄 Disabling auto-update..."
    if disable_cursor_update; then
        echo "✅ Auto-update disabled successfully"
    else
        echo "❌ Failed to disable auto-update"
    fi

    echo
    echo "✨ You can now start the Cursor editor"
    echo "⚠️ Note: Auto-update is disabled, please download the new version manually if needed"
}

main
