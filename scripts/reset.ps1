# Get user config directory
$configDir = "$env:APPDATA\Cursor"

# Check if directory exists
if (-not (Test-Path $configDir)) {
    Write-Host "Cursor config directory does not exist"
    exit 1
}

# Delete trial-related files
Remove-Item -Path "$configDir\Local Storage" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$configDir\Session Storage" -Recurse -Force -ErrorAction SilentlyContinue

# Check if Cursor is installed
function Check-CursorInstalled {
    $cursorPath = Join-Path $env:LOCALAPPDATA "Programs\Cursor\Cursor.exe"
    if (-not (Test-Path $cursorPath)) {
        Write-Host "❌ Cursor editor not detected, please install Cursor first!"
        Write-Host "Download link: https://www.cursor.com/downloads"
        exit 1
    }
    Write-Host "✅ Cursor editor is installed"
}

# Check if Cursor is running
function Get-CursorProcess {
    $processes = Get-WmiObject -Class Win32_Process | Where-Object { 
        $_.Name -like "*cursor*" -and 
        $_.Name -notlike "*cursor-reset*" -and 
        $_.ProcessId -ne $PID 
    }
    return $processes
}

# Kill Cursor process
function Stop-CursorProcess {
    $processes = Get-CursorProcess
    if ($processes) {
        $processes | ForEach-Object {
            Stop-Process -Id $_.ProcessId -Force
        }
        Start-Sleep -Seconds 1.5
    }
}

# Generate random device ID
function New-DeviceId {
    return [guid]::NewGuid().ToString()
}

# Backup config file
function Backup-ConfigFile {
    param (
        [string]$ConfigFile
    )
    $timestamp = Get-Date -Format "yyyyMMddHHmmssfff"
    $backupFile = "${ConfigFile}.${timestamp}.bak"
    Copy-Item -Path $ConfigFile -Destination $backupFile -Force
    return $backupFile
}

# Disable auto-update
function Disable-CursorUpdate {
    $updaterPath = Join-Path $env:LOCALAPPDATA "cursor-updater"
    
    try {
        # If the directory or file exists, delete it first
        if (Test-Path $updaterPath) {
            Remove-Item -Path $updaterPath -Force -Recurse -ErrorAction Stop
        }
        
        # Create an empty file to prevent updates
        New-Item -ItemType File -Path $updaterPath -Force | Out-Null
        return $true
    } catch {
        Write-Host "Error disabling auto-update: $($_.Exception.Message)"
        return $false
    }
}

# Main program
function Main {
    Write-Host "🔍 Checking Cursor editor..."
    Check-CursorInstalled
    Write-Host

    Write-Host "🔍 Checking if Cursor is running..."
    $cursorProcess = Get-CursorProcess
    if ($cursorProcess) {
        $response = Read-Host "Cursor is running, do you want to close it automatically? (y/N)"
        if ($response -eq 'y' -or $response -eq 'Y') {
            Write-Host "Closing Cursor..."
            Stop-CursorProcess
            $cursorProcess = Get-CursorProcess
            if ($cursorProcess) {
                Write-Host "❌ Unable to close Cursor automatically, please close it manually and try again!"
                exit 1
            }
            Write-Host "✅ Cursor closed successfully"
        } else {
            Write-Host "❌ Please close the Cursor editor first and then run this tool!"
            exit 1
        }
    } else {
        Write-Host "✅ Cursor editor is closed"
    }
    Write-Host

    $configDir = Join-Path $env:APPDATA "Cursor"
    $storageFile = Join-Path $configDir "User\globalStorage\storage.json"
    
    Write-Host "📂 Preparing config file..."
    New-Item -ItemType Directory -Path (Split-Path $storageFile -Parent) -Force | Out-Null
    Write-Host "✅ Config directory created successfully"
    Write-Host

    if (Test-Path $storageFile) {
        Write-Host "💾 Backing up original config..."
        $backupFile = Backup-ConfigFile -ConfigFile $storageFile
        Write-Host "✅ Config backup completed, backup file path: $((Split-Path $backupFile -Leaf))"
        Write-Host
    }

    Write-Host "🎲 Generating new device ID..."
    $machineId = New-DeviceId
    $macMachineId = New-DeviceId
    $devDeviceId = New-DeviceId

    # Create or update config file
    $config = @{
        "telemetry.machineId" = $machineId
        "telemetry.macMachineId" = $macMachineId
        "telemetry.devDeviceId" = $devDeviceId
    }
    
    $config | ConvertTo-Json | Set-Content -Path $storageFile -Encoding UTF8

    Write-Host "✅ New device ID generated successfully"
    Write-Host
    Write-Host "💾 Saving new config..."
    Write-Host "✅ New config saved successfully"
    Write-Host
    Write-Host "🎉 Device ID reset successfully! New device ID is:"
    Write-Host
    Get-Content $storageFile
    Write-Host
    Write-Host "📝 Config file path: $storageFile"
    Write-Host

    # Automatically disable updates without asking
    Write-Host "🔄 Disabling auto-update..."
    if (Disable-CursorUpdate) {
        Write-Host "✅ Auto-update disabled successfully"
    } else {
        Write-Host "❌ Failed to disable auto-update"
    }

    Write-Host
    Write-Host "✨ You can now start the Cursor editor"
    Write-Host "⚠️ Note: Auto-update is disabled, please download the new version manually if needed"
}

# Run main program
Main
Write-Host "✨ Cursor trial period has been reset"
Write-Host "🎉 Restart the Cursor editor to start a new trial period"
