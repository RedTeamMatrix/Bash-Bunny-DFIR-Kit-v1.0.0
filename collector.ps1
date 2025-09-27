# collector.ps1 — DFIR Core + Expanded Collection + Wifi raw (v1.5)
# Native-only Windows collection; no 3rd-party tools.
# Output: <BUNNY_ROOT>\DFIR_<HOSTNAME>_<YYYYMMDD_HHMMSS>\

$ErrorActionPreference = 'SilentlyContinue'
$hostWidth = 4096
$script:CollectorVersion = 'core+expanded+wifi-1.5'

# ---------- Helpers ----------
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
function Write-Report {
    param($Path, $Input)
    $dir = Split-Path $Path -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    $Input | Out-File -FilePath $Path -Encoding UTF8 -Width $hostWidth -Force
}

# ---------- Resolve output ----------
$BunnyRoot = Get-BunnyRoot
if (-not $BunnyRoot) { $BunnyRoot = 'D:' }  # fallback
$hostname = $env:COMPUTERNAME
$date = Get-Date -Format "yyyyMMdd_HHmmss"
$outdir = Join-Path $BunnyRoot ("DFIR_${hostname}_$date")
New-Item -ItemType Directory -Force -Path $outdir | Out-Null

# ---------- Transcript & manifest ----------
Start-Transcript -Path (Join-Path $outdir 'collection_transcript.txt') -IncludeInvocationHeader | Out-Null
$IsAdmin = Test-IsAdmin
"CollectorVersion=$script:CollectorVersion`nAdmin=$IsAdmin`nHost=$hostname`nTimeUTC=$([DateTime]::UtcNow.ToString('o'))" |
  Out-File (Join-Path $outdir 'manifest.txt') -Encoding UTF8

# ===================== CORE ======================

# Volatile / runtime
Get-Process | Out-File (Join-Path $outdir 'processes.txt') -Encoding UTF8 -Width $hostWidth
Get-NetTCPConnection | Out-File (Join-Path $outdir 'net_connections.txt') -Encoding UTF8 -Width $hostWidth
query user | Out-File (Join-Path $outdir 'loggedon_users.txt') -Encoding UTF8 -Width $hostWidth
Get-ScheduledTask | Out-File (Join-Path $outdir 'tasks.txt') -Encoding UTF8 -Width $hostWidth

# Network state
netstat -ano | Out-File (Join-Path $outdir 'netstat_full.txt') -Encoding UTF8 -Width $hostWidth
Get-NetTCPConnection | Out-File (Join-Path $outdir 'tcp_connections.txt') -Encoding UTF8 -Width $hostWidth
Get-NetUDPEndpoint | Out-File (Join-Path $outdir 'udp_endpoints.txt') -Encoding UTF8 -Width $hostWidth
netstat -an | findstr LISTENING > (Join-Path $outdir 'listening_ports.txt')
route print > (Join-Path $outdir 'routing_table.txt')
arp -a > (Join-Path $outdir 'arp_table.txt')

# System info
systeminfo | Out-File (Join-Path $outdir 'systeminfo.txt') -Encoding UTF8 -Width $hostWidth
wmic logicaldisk get caption,description,filesystem,freespace,size | Out-File (Join-Path $outdir 'drives.txt') -Encoding UTF8 -Width $hostWidth

# Temp listings
Get-ChildItem -Recurse $env:TEMP -Force -ErrorAction SilentlyContinue | Out-File (Join-Path $outdir 'temp_listing.txt') -Encoding UTF8 -Width $hostWidth
Get-ChildItem -Recurse $env:WINDIR\Temp -Force -ErrorAction SilentlyContinue | Out-File (Join-Path $outdir 'windows_temp_listing.txt') -Encoding UTF8 -Width $hostWidth
Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  $userTemp = Join-Path $_.FullName 'AppData\Local\Temp'
  if (Test-Path $userTemp) {
    Get-ChildItem -Recurse $userTemp -Force -ErrorAction SilentlyContinue |
      Out-File (Join-Path $outdir ("$($_.Name)_temp_listing.txt")) -Encoding UTF8 -Width $hostWidth
  }
}

# Pagefile / hiberfile metadata
Get-ChildItem C:\ -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'pagefile\.sys|hiberfil\.sys' } |
  Format-List Name,Length,LastWriteTime,CreationTime |
  Out-File (Join-Path $outdir 'swapfile_listing.txt') -Encoding UTF8 -Width $hostWidth

# Installed software
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
  Select-Object DisplayName,DisplayVersion,Publisher,InstallDate |
  Out-File (Join-Path $outdir 'installed_software.txt') -Encoding UTF8 -Width $hostWidth
Get-ItemProperty HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
  Select-Object DisplayName,DisplayVersion,Publisher,InstallDate |
  Out-File (Join-Path $outdir 'installed_software_wow64.txt') -Encoding UTF8 -Width $hostWidth

# User file listings
Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  $u = $_.Name
  foreach ($p in 'Documents','Pictures','Videos','Desktop','Downloads') {
    $folder = "C:\Users\$u\$p"
    if (Test-Path $folder) {
      Get-ChildItem -Recurse $folder -Force -ErrorAction SilentlyContinue |
        Out-File (Join-Path $outdir ("${u}_${p}_listing.txt")) -Encoding UTF8 -Width $hostWidth
    }
  }
}

# Recycle Bin
Get-ChildItem "C:\$Recycle.Bin" -Recurse -Force -ErrorAction SilentlyContinue |
  Out-File (Join-Path $outdir 'recycle_bin_listing.txt') -Encoding UTF8 -Width $hostWidth

# Browser profile listings
Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
  $u = $_.Name
  $chrome = "C:\Users\$u\AppData\Local\Google\Chrome\User Data"
  $edge   = "C:\Users\$u\AppData\Local\Microsoft\Edge\User Data"
  $ff     = "C:\Users\$u\AppData\Roaming\Mozilla\Firefox\Profiles"
  if (Test-Path $chrome) { Get-ChildItem -Recurse $chrome -Force -ErrorAction SilentlyContinue | Out-File (Join-Path $outdir ("${u}_Chrome_artifacts_listing.txt")) -Encoding UTF8 -Width $hostWidth }
  if (Test-Path $edge)   { Get-ChildItem -Recurse $edge   -Force -ErrorAction SilentlyContinue | Out-File (Join-Path $outdir ("${u}_Edge_artifacts_listing.txt"))   -Encoding UTF8 -Width $hostWidth }
  if (Test-Path $ff)     { Get-ChildItem -Recurse $ff     -Force -ErrorAction SilentlyContinue | Out-File (Join-Path $outdir ("${u}_Firefox_artifacts_listing.txt")) -Encoding UTF8 -Width $hostWidth }
}

# ================= EXPANDED ADDITIONS =================

# 1) Scheduled Tasks (detailed)
Try {
  $out = Join-Path $outdir 'scheduled_tasks_detailed.txt'
  Get-ScheduledTask | ForEach-Object {
    $t = $_
    $info = [PSCustomObject]@{
      TaskName    = $t.TaskName
      TaskPath    = $t.TaskPath
      State       = (Get-ScheduledTaskInfo -TaskName $t.TaskName -TaskPath $t.TaskPath -ErrorAction SilentlyContinue).State
      Actions     = ($t.Actions | ForEach-Object { $_.Execute + ' ' + ($_.Arguments -join ' ') }) -join '; '
      Triggers    = ($t.Triggers | ForEach-Object { $_.ToString() }) -join '; '
      Principal   = $t.Principal.UserId
      LastRunTime = ($t | Get-ScheduledTaskInfo -ErrorAction SilentlyContinue).LastRunTime
    }
    $info
  } | Format-List | Out-String | Write-Report -Path $out
} catch {}

# 2) Autoruns: Run keys, Startup folders, Services
$outAR = Join-Path $outdir 'autoruns_registry_and_startup.txt'
$runKeys = @(
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
  'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run',
  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
  'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
  'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
)
foreach ($k in $runKeys) {
  if (Test-Path $k) {
    "`n--- $k ---`n" | Out-File -FilePath $outAR -Append -Encoding UTF8
    Get-ItemProperty -Path $k -ErrorAction SilentlyContinue |
      Select-Object * -ExcludeProperty PS*,PSPath,PSParentPath,PSChildName,PSDrive,PSProvider |
      Format-List | Out-File -FilePath $outAR -Append -Encoding UTF8
  }
}
$startupPaths = @(
  "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp",
  "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
)
foreach ($sp in $startupPaths) {
  "`n--- Startup Folder: $sp ---`n" | Out-File -FilePath $outAR -Append -Encoding UTF8
  if (Test-Path $sp) {
    Get-ChildItem -Recurse $sp -Force -ErrorAction SilentlyContinue |
      Select-Object FullName,Length,LastWriteTime |
      Out-File -FilePath $outAR -Append -Encoding UTF8
  } else { "Missing: $sp" | Out-File -FilePath $outAR -Append -Encoding UTF8 }
}
"`n--- Services (Auto/AutoDelayed) ---`n" | Out-File -FilePath $outAR -Append -Encoding UTF8
Get-Service | Where-Object { $_.StartType -in @('Automatic','AutomaticDelayedStart') } |
  Select-Object Name,DisplayName,Status,StartType |
  Out-File -FilePath $outAR -Append -Encoding UTF8

# 3) PowerShell Operational & ScriptBlock (if enabled) + 4688
Try {
  $outSB = Join-Path $outdir 'powershell_scriptblock_4104.txt'
  Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-PowerShell/Operational'; Id=4104; StartTime=(Get-Date).AddDays(-7) } -ErrorAction SilentlyContinue |
    Select-Object TimeCreated,Id,ProviderName,Message |
    Format-List | Out-String | Write-Report -Path $outSB
} catch {}
Try {
  $out4688 = Join-Path $outdir 'security_process_creation_4688.txt'
  Get-WinEvent -FilterHashtable @{ LogName='Security'; Id=4688; StartTime=(Get-Date).AddDays(-7) } -ErrorAction SilentlyContinue |
    Select-Object TimeCreated,Id,Message |
    Format-List | Out-String | Write-Report -Path $out4688
} catch {}

# 4) WMI persistence artifacts (root\subscription)
Try {
  $outWmi = Join-Path $outdir 'wmi_persistence_artifacts.txt'
  $ns='root\subscription'
  foreach ($c in '__EventFilter','CommandLineEventConsumer','ActiveScriptEventConsumer','FilterToConsumerBinding','ConsumerToFilterBinding') {
    "`n--- $c ---`n" | Out-File -FilePath $outWmi -Append -Encoding UTF8
    Get-CimInstance -Namespace $ns -ClassName $c -ErrorAction SilentlyContinue |
      Select-Object * | Format-List |
      Out-File -FilePath $outWmi -Append -Encoding UTF8
  }
} catch {}

# 5) Suspicious files in AppData (recent executables/scripts)
Try {
  $outSus = Join-Path $outdir 'suspicious_appdata_files.txt'
  $patterns = '*.exe','*.dll','*.ps1','*.vbs','*.js','*.scr','*.lnk'
  $cutoff = (Get-Date).AddDays(-30)
  foreach ($u in Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue) {
    $appd = Join-Path $u.FullName 'AppData'
    foreach ($p in $patterns) {
      Get-ChildItem -Path $appd -Include $p -Recurse -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -ge $cutoff -and $_.Length -ge 20KB } |
        Select-Object FullName,Length,LastWriteTime |
        Sort-Object LastWriteTime -Descending |
        Out-File -FilePath $outSus -Append -Encoding UTF8
    }
  }
} catch {}

# 6) PowerShell console history (PSReadLine)
Try {
  $outHist = Join-Path $outdir 'powershell_console_history.txt'
  $paths = @(
    "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt",
    "$env:USERPROFILE\Documents\WindowsPowerShell\consoleHost_history.txt"
  )
  foreach ($p in $paths) {
    if (Test-Path $p) {
      "`n--- $p ---`n" | Out-File -FilePath $outHist -Append -Encoding UTF8
      Get-Content $p -ErrorAction SilentlyContinue | Out-File -FilePath $outHist -Append -Encoding UTF8
    }
  }
  foreach ($u in Get-ChildItem 'C:\Users' -Directory -ErrorAction SilentlyContinue) {
    $hp = Join-Path $u.FullName 'AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt'
    if (Test-Path $hp) {
      "`n--- $hp ---`n" | Out-File -FilePath $outHist -Append -Encoding UTF8
      Get-Content $hp -ErrorAction SilentlyContinue | Out-File -FilePath $outHist -Append -Encoding UTF8
    }
  }
} catch {}

# 7) USB device connection history
Try {
  $outUsb = Join-Path $outdir 'usb_connection_history.txt'
  "`n--- USBSTOR ---`n" | Out-File -FilePath $outUsb -Append -Encoding UTF8
  Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR' -ErrorAction SilentlyContinue |
    ForEach-Object { Get-ItemProperty -Path $_.PsPath -ErrorAction SilentlyContinue | Select-Object PSChildName,FriendlyName,DeviceDesc,Class | Format-List } |
    Out-File -FilePath $outUsb -Append -Encoding UTF8
  "`n--- USB (all) ---`n" | Out-File -FilePath $outUsb -Append -Encoding UTF8
  Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Enum\USB' -ErrorAction SilentlyContinue |
    ForEach-Object { Get-ItemProperty -Path $_.PsPath -ErrorAction SilentlyContinue | Select-Object PSChildName,* | Format-List } |
    Out-File -FilePath $outUsb -Append -Encoding UTF8
  "`n--- Get-PnpDevice -Class USB ---`n" | Out-File -FilePath $outUsb -Append -Encoding UTF8
  Get-PnpDevice -Class USB -ErrorAction SilentlyContinue |
    Select-Object InstanceId,Status,Class,Driver,ContainerId |
    Format-List | Out-File -FilePath $outUsb -Append -Encoding UTF8
} catch {}

# ----------------------------
# NEW: Wi-Fi profiles (raw netsh output only)
# ----------------------------
function Collect-WifiProfilesRaw {
    param([string]$OutDir)

    $outFile = Join-Path $OutDir 'wifi_profiles.txt'

    try {
        if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Force -Path $OutDir | Out-Null }

        # Capture the list of profiles and append full per-profile dumps
        $profilesList = netsh wlan show profiles 2>&1
        $profilesList | Out-File -FilePath $outFile -Encoding UTF8 -Append

        foreach ($line in $profilesList) {
            if ($line -match 'All User Profile\s*:\s*(.+)$' -or $line -match 'User Profile\s*:\s*(.+)$') {
                $profileName = $Matches[1].Trim()
                if ($profileName) {
                    "`n----- Profile: $profileName -----`n" | Out-File -FilePath $outFile -Append -Encoding UTF8
                    netsh wlan show profile name="$profileName" key=clear 2>&1 | Out-File -FilePath $outFile -Append -Encoding UTF8
                }
            }
        }

    } catch {
        "Collect-WifiProfilesRaw encountered an error: $_" | Out-File -FilePath $outFile -Append -Encoding UTF8
    }
}

# Invoke the Wi-Fi collector (integrated)
Collect-WifiProfilesRaw -OutDir $outdir

# ================= ADMIN-ONLY EXPORTS =================
if ($IsAdmin) {
  Try { wevtutil epl System      (Join-Path $outdir 'System.evtx') } catch {}
  Try { wevtutil epl Security    (Join-Path $outdir 'Security.evtx') } catch {}
  Try { wevtutil epl Application (Join-Path $outdir 'Application.evtx') } catch {}
  Try { reg save HKLM\SAM      (Join-Path $outdir 'SAM') /y } catch {}
  Try { reg save HKLM\SYSTEM   (Join-Path $outdir 'SYSTEM') /y } catch {}
  Try { reg save HKLM\SECURITY (Join-Path $outdir 'SECURITY') /y } catch {}
  Try { reg save HKLM\SOFTWARE (Join-Path $outdir 'SOFTWARE') /y } catch {}
  Try { reg save HKCU          (Join-Path $outdir 'NTUSER.DAT') /y } catch {}
} else {
  "Not elevated: skipping event log and registry hive exports." |
    Out-File (Join-Path $outdir 'admin_warning.txt') -Encoding UTF8
}

# ================= HASH EVERYTHING =================
Get-ChildItem -Recurse $outdir | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
  $h = Get-FileHash $_.FullName -Algorithm SHA256
  "$($h.Hash)  $($_.FullName)" | Out-File (Join-Path $outdir 'hashes.txt') -Append -Encoding UTF8
}

Stop-Transcript | Out-Null
Write-Output "DFIR collection complete. Output saved to $outdir"
