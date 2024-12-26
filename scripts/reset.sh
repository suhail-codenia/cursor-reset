#!/bin/bash

# 检查 Cursor 是否已安装
check_cursor_installed() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if [ ! -d "/Applications/Cursor.app" ]; then
            echo "❌ 未检测到 Cursor 编辑器，请先安装 Cursor！"
            echo "下载地址：https://www.cursor.com/downloads"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux"* ]]; then
        # Linux
        if [ ! -d "/usr/share/cursor" ] && [ ! -d "/opt/cursor" ] && [ ! -d "$HOME/.local/share/cursor" ]; then
            echo "❌ 未检测到 Cursor 编辑器，请先安装 Cursor！"
            echo "下载地址：https://www.cursor.com/downloads"
            exit 1
        fi
    fi
    echo "✅ Cursor 编辑器已安装"
}

# 检查 Cursor 是否在运行
check_cursor_running() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        pgrep -x "Cursor" > /dev/null || pgrep -x "Cursor Helper" > /dev/null
    elif [[ "$OSTYPE" == "linux"* ]]; then
        pgrep -x "cursor" > /dev/null || pgrep -x "Cursor" > /dev/null
    fi
}

# 关闭 Cursor 进程
kill_cursor_process() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        pkill -9 "Cursor"
    elif [[ "$OSTYPE" == "linux"* ]]; then
        pkill -9 "cursor"
    fi
    sleep 1.5
}

# 获取配置文件路径
get_config_dir() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "$HOME/Library/Application Support/Cursor"
    elif [[ "$OSTYPE" == "linux"* ]]; then
        echo "$HOME/.config/Cursor"
    else
        echo "❌ 不支持的操作系统"
        exit 1
    fi
}

# 生成随机设备 ID
generate_device_id() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo $(uuidgen)
    else
        echo $(cat /proc/sys/kernel/random/uuid)
    fi
}

# 备份配置文件
backup_config() {
    local config_file="$1"
    local timestamp=$(date +"%Y%m%d%H%M%S%3N")
    local backup_file="${config_file}.${timestamp}.bak"
    cp "$config_file" "$backup_file"
    echo "$backup_file"
}

# 主程序
main() {
    echo "🔍 正在检查 Cursor 编辑器..."
    check_cursor_installed
    echo

    echo "🔍 检查 Cursor 是否在运行..."
    if check_cursor_running; then
        echo "检测到 Cursor 正在运行，是否自动关闭？ (y/N): "
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            echo "正在关闭 Cursor..."
            kill_cursor_process
            if check_cursor_running; then
                echo "❌ 无法自动关闭 Cursor，请手动关闭后重试！"
                exit 1
            fi
            echo "✅ Cursor 已成功关闭"
        else
            echo "❌ 请先关闭 Cursor 编辑器后再运行此工具！"
            exit 1
        fi
    else
        echo "✅ Cursor 编辑器已关闭"
    fi
    echo

    CONFIG_DIR=$(get_config_dir)
    STORAGE_FILE="$CONFIG_DIR/User/globalStorage/storage.json"
    
    echo "📂 正在准备配置文件..."
    mkdir -p "$(dirname "$STORAGE_FILE")"
    echo "✅ 配置目录创建成功"
    echo

    if [ -f "$STORAGE_FILE" ]; then
        echo "💾 正在备份原配置..."
        BACKUP_FILE=$(backup_config "$STORAGE_FILE")
        echo "✅ 配置备份完成，备份文件路径：$(basename "$BACKUP_FILE")"
        echo
    fi

    echo "🎲 正在生成新的设备 ID..."
    MACHINE_ID=$(generate_device_id)
    MAC_MACHINE_ID=$(generate_device_id)
    DEV_DEVICE_ID=$(generate_device_id)

    # 创建或更新配置文件
    cat > "$STORAGE_FILE" << EOF
{
  "telemetry.machineId": "${MACHINE_ID}",
  "telemetry.macMachineId": "${MAC_MACHINE_ID}",
  "telemetry.devDeviceId": "${DEV_DEVICE_ID}"
}
EOF

    echo "✅ 新设备 ID 生成成功"
    echo
    echo "💾 正在保存新配置..."
    echo "✅ 新配置保存成功"
    echo
    echo "🎉 设备 ID 重置成功！新的设备 ID 为："
    echo
    cat "$STORAGE_FILE"
    echo
    echo "📝 配置文件路径：$STORAGE_FILE"
    echo
    echo "✨ 现在可以启动 Cursor 编辑器了"
}

main
