# Windows Server Performance Stats

A simple yet powerful PowerShell script to analyze and display key server performance metrics on any Windows system. Built as a Windows-compatible version of the [roadmap.sh](https://roadmap.sh/) DevOps / System Administrator learning path.

## Goal

Create a script that helps system administrators and DevOps engineers quickly understand the current health and resource utilization of a Windows server or workstation.

## Features

### Core Requirements
- **Total CPU Usage** – Current CPU utilization percentage
- **Memory Usage** – Total, used, free, and usage percentage of physical RAM
- **Disk Usage** – Total, used, free, and usage percentage for all local storage drives
- **Top 5 Processes by CPU** – Sorted list of the most CPU-intensive processes
- **Top 5 Processes by Memory** – Sorted list of the most memory-intensive processes

### Stretch Goals (Included)
- Operating System version, build, architecture, and installation date
- System uptime
- Load average (Processor Queue Length)
- Active logged-in users/sessions list (with fallback support for Home editions)
- Failed login attempts (audited from Windows Security logs for the last 24 hours)

## Prerequisites

- Windows-based system (tested on Windows 10, Windows 11, and Windows Server)
- PowerShell 5.1 or PowerShell Core (7+)
- Administrator privileges (optional, required only for failed login auditing)

## Installation & Usage

### 1. Clone or Download

```powershell
git clone https://github.com/M-b-a-s/roadmap
cd server-performance-stats
```

### 2. How to Run

#### Option A: The Batch Launcher (Easiest - Command Prompt or Double-Click)
You can run the script by double-clicking `server-stats.bat` in File Explorer, or by executing it from a Command Prompt:
1. Open **Command Prompt** (Run as Administrator to see Security Audit stats).
2. Navigate to the folder where you saved the script (use `/d` to switch drives automatically if needed):
   ```cmd
   cd /d "path\to\your\folder"
   ```
3. Run the launcher:
   ```cmd
   server-stats.bat
   ```

#### Option B: PowerShell
1. Open **PowerShell** (Run as Administrator to see Security Audit stats).
2. Navigate to the folder where you saved the script:
   ```powershell
   cd "path\to\your\folder"
   ```
3. Run the script:
   ```powershell
   powershell -ExecutionPolicy Bypass -File server-stats.ps1
   ```

## How It Works
The script leverages native Windows CIM/WMI cmdlets and diagnostic tools:
- `Get-CimInstance Win32_OperatingSystem` for system uptime, install date, and memory info
- `Get-CimInstance Win32_Processor` and `Win32_PerfFormattedData_PerfOS_System` for CPU load metrics
- `Get-CimInstance Win32_LogicalDisk` for storage drive analytics
- `Get-CimInstance Win32_PerfFormattedData_PerfProc_Process` for live process CPU utilization
- `Get-Process` for memory usage metrics by process
- `Get-WinEvent` to audit security logs for failed login attempts (Event ID 4625)

## Project Structure
server-performance-stats/
├── server-stats.ps1         # Main PowerShell script
├── server-stats.bat         # CMD batch launcher
└── README.md                # This file

## Learning Outcomes
By completing this project, you will gain practical experience with:

- Windows performance monitoring tools (CIM/WMI)
- PowerShell scripting best practices
- Windows System administration fundamentals
- Resource utilization analysis
- Analyzing Windows Event Logs for security insights
