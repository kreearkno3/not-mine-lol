Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "     SERVER PERFORMANCE STATISTICS (WINDOWS)" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# ==================== SYSTEM INFORMATION ====================
Write-Host "System Information" -ForegroundColor Yellow
try {
    $os = Get-CimInstance Win32_OperatingSystem
    $installDate = $os.InstallDate
    Write-Host "OS: $($os.Caption) ($($os.Version) $($os.OSArchitecture))"
    Write-Host "OS Install Date: $installDate"

    $uptime = (Get-Date) - $os.LastBootUpTime
    Write-Host "Uptime: $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes"

    # Logged in users
    Write-Host "Logged in Users/Sessions:"
    $sessionUser = $null
    if (Get-Command query -ErrorAction SilentlyContinue) {
        $sessionUser = query user 2>$null
    } elseif (Get-Command quser -ErrorAction SilentlyContinue) {
        $sessionUser = quser 2>$null
    } elseif (Get-Command qwinsta -ErrorAction SilentlyContinue) {
        $sessionUser = qwinsta 2>$null
    }
    
    if ($sessionUser) {
        $sessionUser | Out-String | ForEach-Object { Write-Host "  $_" -NoNewline }
    } else {
        $loggedUser = (Get-CimInstance Win32_ComputerSystem).UserName
        if ($loggedUser) {
            Write-Host "  $loggedUser (Console)"
        } else {
            $activeUsers = Get-CimInstance Win32_LoggedOnUser | 
                ForEach-Object { [WMI]$_.Antecedent } | 
                Where-Object { $_.Name -and $_.Name -notmatch '^SYSTEM|^LOCAL SERVICE|^NETWORK SERVICE|^UMFD-\d+|^DWM-\d+' } |
                Select-Object -ExpandProperty Name -Unique
            if ($activeUsers) {
                Write-Host "  $($activeUsers -join ', ') (Active)"
            } else {
                Write-Host "  No active user session detected."
            }
        }
    }
} catch {
    Write-Warning "Could not retrieve all system info: $_"
}
Write-Host ""

# ==================== CPU & SYSTEM LOAD ====================
Write-Host "CPU & System Load" -ForegroundColor Yellow
try {
    $cpuLoad = (Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
    Write-Host "Total CPU Usage: $cpuLoad%"
    
    # System Load equivalent: Processor Queue Length
    $sysQueue = (Get-CimInstance -ClassName Win32_PerfFormattedData_PerfOS_System).ProcessorQueueLength
    Write-Host "Processor Queue Length (Load Average): $sysQueue"
} catch {
    Write-Warning "Could not retrieve CPU/Load usage: $_"
}
Write-Host ""

# ==================== MEMORY USAGE ====================
Write-Host "Memory Usage" -ForegroundColor Yellow
try {
    $totalRam = [Math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRam = [Math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRam = [Math]::Round($totalRam - $freeRam, 2)
    $usedPercent = [Math]::Round(($usedRam / $totalRam) * 100, 2)

    Write-Host "Total: ${totalRam} GB | Used: ${usedRam} GB | Free: ${freeRam} GB"
    Write-Host "Usage: ${usedPercent}%"
} catch {
    Write-Warning "Could not retrieve Memory usage: $_"
}
Write-Host ""

# ==================== DISK USAGE ====================
Write-Host "Disk Usage" -ForegroundColor Yellow
try {
    $disks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3"
    foreach ($disk in $disks) {
        $totalDisk = [Math]::Round($disk.Size / 1GB, 2)
        $freeDisk = [Math]::Round($disk.FreeSpace / 1GB, 2)
        $usedDisk = [Math]::Round($totalDisk - $freeDisk, 2)
        $diskPercent = [Math]::Round(($usedDisk / $totalDisk) * 100, 2)
        Write-Host "Drive $($disk.DeviceID) - Total: ${totalDisk} GB | Used: ${usedDisk} GB | Free: ${freeDisk} GB | Usage: ${diskPercent}%"
    }
} catch {
    Write-Warning "Could not retrieve Disk usage: $_"
}
Write-Host ""

# ==================== SECURITY AUDIT ====================
Write-Host "Security Audit" -ForegroundColor Yellow
try {
    # Check failed login attempts (Event ID 4625) in the last 24 hours
    $twentyFourHoursAgo = (Get-Date).AddDays(-1)
    $failedEvents = Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625; StartTime=$twentyFourHoursAgo} -ErrorAction SilentlyContinue
    
    $failedCount = 0
    if ($failedEvents) {
        $failedCount = $failedEvents.Count
    }
    Write-Host "Failed login attempts (last 24 hours): $failedCount"
    
    if ($failedCount -gt 0) {
        Write-Host "Top targeted accounts:"
        $failedEvents | Group-Object -Property @{Expression={$_.Properties[5].Value}} | 
            Sort-Object Count -Descending | Select-Object -First 3 | 
            ForEach-Object { Write-Host "  - User: $($_.Name) (Count: $($_.Count))" }
    }
} catch [System.UnauthorizedAccessException] {
    Write-Warning "Failed login attempts: Access Denied (Run PowerShell as Administrator to view Security Log)"
} catch {
    Write-Host "Failed login attempts (last 24 hours): 0"
}
Write-Host ""

# ==================== TOP 5 PROCESSES BY CPU ====================
Write-Host "Top 5 Processes by CPU Usage" -ForegroundColor Yellow
try {
    $topCpu = Get-CimInstance Win32_PerfFormattedData_PerfProc_Process | 
        Where-Object { $_.Name -ne "_Total" -and $_.Name -ne "Idle" } | 
        Sort-Object PercentProcessorTime -Descending | 
        Select-Object -First 5

    $topCpu | Format-Table -Property IDProcess, Name, @{Label="CPU Usage (%)"; Expression={$_.PercentProcessorTime}}
} catch {
    Write-Warning "Could not retrieve top CPU processes: $_"
}

# ==================== TOP 5 PROCESSES BY MEMORY ====================
Write-Host "Top 5 Processes by Memory Usage" -ForegroundColor Yellow
try {
    $topMem = Get-Process | 
        Sort-Object WorkingSet64 -Descending | 
        Select-Object -First 5

    $topMem | Format-Table -Property Id, ProcessName, @{Label="Memory (MB)"; Expression={[Math]::Round($_.WorkingSet64 / 1MB, 2)}}
} catch {
    Write-Warning "Could not retrieve top Memory processes: $_"
}

Write-Host "Script completed at $(Get-Date)" -ForegroundColor Gray
