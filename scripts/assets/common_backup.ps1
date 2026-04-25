param(
    [Parameter(Mandatory = $true)]
    [string]$ScriptName,

    [string[]]$Targets = @(),

    [string]$BackupRoot = ""
)

$ErrorActionPreference = "Continue"

if (-not $BackupRoot) {
    $BackupRoot = Join-Path $env:USERPROFILE "ScriptLauncherBackups"
}

$safeName = ($ScriptName -replace '[^\w\.-]', '_')
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupDir = Join-Path $BackupRoot "$safeName`_$timestamp"
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

function Write-BackupInfo {
    param([string]$Message)
    Write-Host "[backup] $Message"
    Add-Content -Path (Join-Path $backupDir "backup.log") -Value $Message
}

function Export-RegistryKey {
    param(
        [string]$Key,
        [string]$Name
    )
    $out = Join-Path $backupDir "$Name.reg"
    & reg.exe export $Key $out /y *> $null
    if ($LASTEXITCODE -eq 0) {
        Write-BackupInfo "Registry exported: $Key -> $out"
    } else {
        Write-BackupInfo "Registry export skipped/failed: $Key"
    }
}

Write-BackupInfo "Backup started for $ScriptName"
Write-BackupInfo "Targets: $($Targets -join ', ')"

if ($Targets -contains "registry") {
    Export-RegistryKey "HKCU\Software\Microsoft\Windows\CurrentVersion" "HKCU_CurrentVersion"
    Export-RegistryKey "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion" "HKLM_CurrentVersion"
    Export-RegistryKey "HKLM\SYSTEM\CurrentControlSet\Services" "HKLM_Services"
}

if ($Targets -contains "hosts") {
    $hosts = Join-Path $env:SystemRoot "System32\drivers\etc\hosts"
    if (Test-Path $hosts) {
        Copy-Item $hosts (Join-Path $backupDir "hosts.bak") -Force
        Write-BackupInfo "Hosts file copied"
    }
}

if ($Targets -contains "firewall" -or $Targets -contains "network") {
    $firewallOut = Join-Path $backupDir "firewall.wfw"
    & netsh advfirewall export $firewallOut *> $null
    Write-BackupInfo "Firewall export attempted: $firewallOut"

    & ipconfig /all | Out-File (Join-Path $backupDir "ipconfig_all.txt") -Encoding UTF8
    & netsh interface show interface | Out-File (Join-Path $backupDir "interfaces.txt") -Encoding UTF8
    & netsh winsock show catalog | Out-File (Join-Path $backupDir "winsock_catalog.txt") -Encoding UTF8
}

if ($Targets -contains "path") {
    [Environment]::GetEnvironmentVariable("Path", "Machine") |
        Out-File (Join-Path $backupDir "machine_path.txt") -Encoding UTF8
    [Environment]::GetEnvironmentVariable("Path", "User") |
        Out-File (Join-Path $backupDir "user_path.txt") -Encoding UTF8
    Write-BackupInfo "PATH snapshots written"
}

if ($Targets -contains "services") {
    Get-Service | Select-Object Name, Status, StartType |
        Export-Csv (Join-Path $backupDir "services.csv") -NoTypeInformation -Encoding UTF8
    Write-BackupInfo "Service snapshot written"
}

if ($Targets -contains "scheduled_tasks") {
    Get-ScheduledTask |
        Select-Object TaskName, TaskPath, State |
        Export-Csv (Join-Path $backupDir "scheduled_tasks.csv") -NoTypeInformation -Encoding UTF8
    Write-BackupInfo "Scheduled task snapshot written"
}

if ($Targets -contains "defender") {
    Get-MpPreference | Out-File (Join-Path $backupDir "defender_preferences.txt") -Encoding UTF8
    Write-BackupInfo "Defender preferences snapshot written"
}

if ($Targets -contains "appx") {
    Get-AppxPackage |
        Select-Object Name, PackageFullName, InstallLocation |
        Export-Csv (Join-Path $backupDir "appx_packages.csv") -NoTypeInformation -Encoding UTF8
    Write-BackupInfo "Appx package list written"
}

if ($Targets -contains "power") {
    & powercfg /list | Out-File (Join-Path $backupDir "power_plans.txt") -Encoding UTF8
    & powercfg /query | Out-File (Join-Path $backupDir "power_query.txt") -Encoding UTF8
    Write-BackupInfo "Power configuration snapshot written"
}

if ($Targets -contains "files") {
    Write-BackupInfo "File deletion target detected. Script-specific file copies may be required."
}

try {
    Checkpoint-Computer -Description "ScriptLauncher-$safeName-$timestamp" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    Write-BackupInfo "System restore point requested"
} catch {
    Write-BackupInfo "System restore point unavailable: $($_.Exception.Message)"
}

Write-Host "[backup] Backup folder: $backupDir"
Write-BackupInfo "Backup completed"
