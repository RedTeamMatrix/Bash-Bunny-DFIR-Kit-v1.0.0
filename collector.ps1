# collector.ps1 - DFIR Core Triage Script (patched core-1.2)
# Native-only Windows collection (listings-only where appropriate)
# Place this file in the same payload folder as payload.txt (e.g., D:\payloads\switch1\collector.ps1)

$ErrorActionPreference = 'SilentlyContinue'
$hostWidth = 4096
$script:CollectorVersion = 'core-1.2'

function Get-BunnyRoot {
    Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        $tag = Join-Path $_.Root 'BUNNY.TAG'
        if (Test-Path $tag) { return $_.Root.TrimEnd('\') }
    }
}

function Test-IsAdmin {
    $wi = [Security.Principal.WindowsIdentity]::GetCurrent()
    $wp = New-Object Security.Principal.WindowsPrincipal($wi)
    return $wp.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Determine Bunny root (where outputs will be written)
$BunnyRoot = Get-BunnyRoot
if (-not $BunnyRoot) { $BunnyRoot = 'D:' }  # fallback (adjust if your Bunny commonly mounts to another letter)

$hostname = $env:COMPUTERNAME
$date = Get-Date -Format "yyyyMMdd_HHmmss"
$outdir = Join-Path $BunnyRoot ("DFIR_${hostname}_$date")
New-Item -ItemType Directory -Force -Path $outdir | Out-Null

# Start transcript for chain-of-custody / debug
Start-Transcript -Path (Join-Path $outdir 'collection_transcript.txt') -IncludeInvocationHeader | Out-Null
$IsAdmin = Test-IsAdmin
"CollectorVersion=$script:CollectorVersion`nAdmin=$IsAdmin`nHost=$hostname`nTimeUTC=$([DateTime]::UtcNow.ToString('o'))" |
    Out-File (Join-Path $outdir 'manifest.txt') -Encoding UTF8

# ---- Volatile Data ----
Get-Process |
  Out-File (Join-Path $outdir 'processes.txt') -Encoding UTF8 -Width $hostWidth

Get-NetTCPConnection |
  Out-File (Join-Path $outdir 'net_connections.txt') -Encoding UTF8 -Width $hostWidth

query user |
  Out-File (Join-Path $outdir 'loggedon_users.txt') -Encoding UTF8 -Width $hostWidth

Get-ScheduledTask |
  Out-File (Join-Path $outdir 'tasks.txt') -Encoding UTF8 -Width $hostWidth

# ---- Network State ----
netstat -ano |
  Out-File (Join-Path $outdir 'netstat_full.txt') -Encoding UTF8 -Width $hostWidth

Get-NetTCPConnection |
  Out-File (Join-Path $outdir 'tcp_connections.txt') -Encoding UTF8 -Width $hostWidth

Get-NetUDPEndpoint |
  Out-File (Join-Path $outdir 'udp_endpoints.txt') -Encoding UTF8 -Width $hostWidth

netstat -an | findstr LISTENING > (Join-Path $outdir 'listening_ports.txt')
route print > (Join-Path $outdir 'routing_table.txt')
arp -a > (Join-Path $outdir 'arp_table.txt')

# ---- System Info ----
systeminfo |
  Out-File (Join-Path $outdir 'systeminfo.txt') -Encoding UTF8 -Width $hostWidth

wmic logicaldisk get caption,description,filesystem,freespace,size |
  Out-File (Join-Path $outdir 'drives.txt') -Encoding UTF8 -Width $hostWidth

# ---- Temp File Listings ----
Get-ChildItem -Recurse $env:TEMP -Force -ErrorAction SilentlyContinue |
  Out-File (Join-Path $outdir 'temp_listing.txt') -Encoding UTF8 -Width $hostWidth

Get-ChildItem -Recurse $env:WINDIR\Temp -Force -ErrorAction SilentlyContinue |
  Out-File (Join-Path $outdir 'windows_temp_listing.txt') -Encoding UTF8 -Width $hostWidth

Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  $user = $_.Name
  $userTemp = "C:\Users\$user\AppData\Local\Temp"
  if (Test-Path $userTemp) {
    Get-ChildItem -Recurse $userTemp -Force -ErrorAction SilentlyContinue |
      Out-File (Join-Path $outdir ("${user}_temp_listing.txt")) -Encoding UTF8 -Width $hostWidth
  }
}

# ---- Swap / Hibernation Files (metadata only) ----
Get-ChildItem C:\ -Force -ErrorAction SilentlyContinue | Where-Object {
  $_.Name -match "pagefile.sys|hiberfil.sys"
} | Format-List Name, Length, LastWriteTime, CreationTime |
  Out-File (Join-Path $outdir 'swapfile_listing.txt') -Encoding UTF8 -Width $hostWidth

# ---- Installed Software ----
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
  Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
  Out-File (Join-Path $outdir 'installed_software.txt') -Encoding UTF8 -Width $hostWidth

Get-ItemProperty HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
  Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
  Out-File (Join-Path $outdir 'installed_software_wow64.txt') -Encoding UTF8 -Width $hostWidth

# ---- User File Listings (Documents/Pictures/Videos/Desktop/Downloads) ----
Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  $user = $_.Name
  $paths = @("Documents","Pictures","Videos","Desktop","Downloads")
  foreach ($p in $paths) {
    $folder = "C:\Users\$user\$p"
    if (Test-Path $folder) {
      Get-ChildItem -Recurse $folder -Force -ErrorAction SilentlyContinue |
        Out-File (Join-Path $outdir ("${user}_${p}_listing.txt")) -Encoding UTF8 -Width $hostWidth
    }
  }
}

# ---- Recycle Bin (Trash) Listing ----
Get-ChildItem "C:\$Recycle.Bin" -Recurse -Force -ErrorAction SilentlyContinue |
  Out-File (Join-Path $outdir 'recycle_bin_listing.txt') -Encoding UTF8 -Width $hostWidth

# ---- Browser Artifacts (Listings Only) ----
$users = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue
foreach ($u in $users) {
  $user = $u.Name
  $chrome = "C:\Users\$user\AppData\Local\Google\Chrome\User Data"
  $edge   = "C:\Users\$user\AppData\Local\Microsoft\Edge\User Data"
  $ff     = "C:\Users\$user\AppData\Roaming\Mozilla\Firefox\Profiles"

  if (Test-Path $chrome) {
    Get-ChildItem -Recurse $chrome -Force -ErrorAction SilentlyContinue |
      Out-File (Join-Path $outdir ("${user}_Chrome_artifacts_listing.txt")) -Encoding UTF8 -Width $hostWidth
  }
  if (Test-Path $edge) {
    Get-ChildItem -Recurse $edge -Force -ErrorAction SilentlyContinue |
      Out-File (Join-Path $outdir ("${user}_Edge_artifacts_listing.txt")) -Encoding UTF8 -Width $hostWidth
  }
  if (Test-Path $ff) {
    Get-ChildItem -Recurse $ff -Force -ErrorAction SilentlyContinue |
      Out-File (Join-Path $outdir ("${user}_Firefox_artifacts_listing.txt")) -Encoding UTF8 -Width $hostWidth
  }
}

# ---- Event Logs & Registry Hives (admin only) ----
if ($IsAdmin) {
  try {
    wevtutil epl System (Join-Path $outdir 'System.evtx')
    wevtutil epl Security (Join-Path $outdir 'Security.evtx')
    wevtutil epl Application (Join-Path $outdir 'Application.evtx')
  } catch {}

  try {
    reg save HKLM\SAM (Join-Path $outdir 'SAM') /y
    reg save HKLM\SYSTEM (Join-Path $outdir 'SYSTEM') /y
    reg save HKLM\SECURITY (Join-Path $outdir 'SECURITY') /y
    reg save HKLM\SOFTWARE (Join-Path $outdir 'SOFTWARE') /y
    reg save HKCU (Join-Path $outdir 'NTUSER.DAT') /y
  } catch {}
} else {
  "Not elevated: skipping event log and registry hive exports." |
    Out-File (Join-Path $outdir 'admin_warning.txt') -Encoding UTF8
}

# ---- Hash everything ----
Get-ChildItem -Recurse $outdir | Where-Object { -not $_.PSIsContainer } |
  ForEach-Object {
    $hash = Get-FileHash $_.FullName -Algorithm SHA256
    "$($hash.Hash)  $($_.FullName)" | Out-File (Join-Path $outdir 'hashes.txt') -Append -Encoding UTF8
  }

Stop-Transcript | Out-Null
Write-Output "DFIR collection complete. Output saved to $outdir"
