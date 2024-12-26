#!/bin/bash

# 获取用户主目录
HOME_DIR="$HOME"

# 定义 Cursor 配置目录
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    CONFIG_DIR="$HOME_DIR/Library/Application Support/Cursor"
elif [[ "$OSTYPE" == "linux"* ]]; then
    # Linux
    CONFIG_DIR="$HOME_DIR/.config/Cursor"
else
    echo "不支持的操作系统"
    exit 1
fi

# 检查目录是否存在
if [ ! -d "$CONFIG_DIR" ]; then
    echo "Cursor 配置目录不存在"
    exit 1
fi

# 删除试用相关文件
rm -rf "$CONFIG_DIR/Local Storage"
rm -rf "$CONFIG_DIR/Session Storage"

echo "✨ Cursor 试用期已重置"
echo "🎉 重启 Cursor 编辑器即可开始新的试用期"
