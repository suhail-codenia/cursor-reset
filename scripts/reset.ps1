# 获取用户配置目录
$configDir = "$env:APPDATA\Cursor"

# 检查目录是否存在
if (-not (Test-Path $configDir)) {
    Write-Host "Cursor 配置目录不存在"
    exit 1
}

# 删除试用相关文件
Remove-Item -Path "$configDir\Local Storage" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$configDir\Session Storage" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "✨ Cursor 试用期已重置"
Write-Host "🎉 重启 Cursor 编辑器即可开始新的试用期"
