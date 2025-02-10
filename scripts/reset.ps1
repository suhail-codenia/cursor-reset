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

# 检查 Cursor 是否已安装
function Check-CursorInstalled {
    $cursorPath = Join-Path $env:LOCALAPPDATA "Programs\Cursor\Cursor.exe"
    if (-not (Test-Path $cursorPath)) {
        Write-Host "❌ 未检测到 Cursor 编辑器，请先安装 Cursor！"
        Write-Host "下载地址：https://www.cursor.com/downloads"
        exit 1
    }
    Write-Host "✅ Cursor 编辑器已安装"
}

# 检查 Cursor 是否在运行
function Get-CursorProcess {
    $processes = Get-WmiObject -Class Win32_Process | Where-Object { 
        $_.Name -like "*cursor*" -and 
        $_.Name -notlike "*cursor-reset*" -and 
        $_.ProcessId -ne $PID 
    }
    return $processes
}

# 关闭 Cursor 进程
function Stop-CursorProcess {
    $processes = Get-CursorProcess
    if ($processes) {
        $processes | ForEach-Object {
            Stop-Process -Id $_.ProcessId -Force
        }
        Start-Sleep -Seconds 1.5
    }
}

# 生成随机设备 ID
function New-DeviceId {
    return [guid]::NewGuid().ToString()
}

# 备份配置文件
function Backup-ConfigFile {
    param (
        [string]$ConfigFile
    )
    $timestamp = Get-Date -Format "yyyyMMddHHmmssfff"
    $backupFile = "${ConfigFile}.${timestamp}.bak"
    Copy-Item -Path $ConfigFile -Destination $backupFile -Force
    return $backupFile
}

# 禁用自动更新
function Disable-CursorUpdate {
    $updaterPath = Join-Path $env:LOCALAPPDATA "cursor-updater"
    
    try {
        # 如果存在目录或文件，先删除
        if (Test-Path $updaterPath) {
            Remove-Item -Path $updaterPath -Force -Recurse -ErrorAction Stop
        }
        
        # 创建空文件来阻止更新
        New-Item -ItemType File -Path $updaterPath -Force | Out-Null
        return $true
    } catch {
        Write-Host "禁用自动更新时出错：$($_.Exception.Message)"
        return $false
    }
}

# 主程序
function Main {
    Write-Host "🔍 正在检查 Cursor 编辑器..."
    Check-CursorInstalled
    Write-Host

    Write-Host "🔍 检查 Cursor 是否在运行..."
    $cursorProcess = Get-CursorProcess
    if ($cursorProcess) {
        $response = Read-Host "检测到 Cursor 正在运行，是否自动关闭？ (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            Write-Host "正在关闭 Cursor..."
            Stop-CursorProcess
            $cursorProcess = Get-CursorProcess
            if ($cursorProcess) {
                Write-Host "❌ 无法自动关闭 Cursor，请手动关闭后重试！"
                exit 1
            }
            Write-Host "✅ Cursor 已成功关闭"
        } else {
            Write-Host "❌ 请先关闭 Cursor 编辑器后再运行此工具！"
            exit 1
        }
    } else {
        Write-Host "✅ Cursor 编辑器已关闭"
    }
    Write-Host

    $configDir = Join-Path $env:APPDATA "Cursor"
    $storageFile = Join-Path $configDir "User\globalStorage\storage.json"
    
    Write-Host "📂 正在准备配置文件..."
    New-Item -ItemType Directory -Path (Split-Path $storageFile -Parent) -Force | Out-Null
    Write-Host "✅ 配置目录创建成功"
    Write-Host

    if (Test-Path $storageFile) {
        Write-Host "💾 正在备份原配置..."
        $backupFile = Backup-ConfigFile -ConfigFile $storageFile
        Write-Host "✅ 配置备份完成，备份文件路径：$((Split-Path $backupFile -Leaf))"
        Write-Host
    }

    Write-Host "🎲 正在生成新的设备 ID..."
    $machineId = New-DeviceId
    $macMachineId = New-DeviceId
    $devDeviceId = New-DeviceId

    # 创建或更新配置文件
    $config = @{
        "telemetry.machineId" = $machineId
        "telemetry.macMachineId" = $macMachineId
        "telemetry.devDeviceId" = $devDeviceId
    }
    
    $config | ConvertTo-Json | Set-Content -Path $storageFile -Encoding UTF8

    Write-Host "✅ 新设备 ID 生成成功"
    Write-Host
    Write-Host "💾 正在保存新配置..."
    Write-Host "✅ 新配置保存成功"
    Write-Host
    Write-Host "🎉 设备 ID 重置成功！新的设备 ID 为："
    Write-Host
    Get-Content $storageFile
    Write-Host
    Write-Host "📝 配置文件路径：$storageFile"
    Write-Host

    # 自动禁用更新，无需询问
    Write-Host "🔄 正在禁用自动更新..."
    if (Disable-CursorUpdate) {
        Write-Host "✅ 自动更新已成功禁用"
    } else {
        Write-Host "❌ 禁用自动更新失败"
    }

    Write-Host
    Write-Host "✨ 现在可以启动 Cursor 编辑器了"
    Write-Host "⚠️ 提示：已禁用自动更新，如需更新请手动下载新版本"
}

# 运行主程序
Main
Write-Host "✨ Cursor 试用期已重置"
Write-Host "🎉 重启 Cursor 编辑器即可开始新的试用期"
