# Turning a Bash Bunny Into a DFIR Triage Kit

The Hak5 **Bash Bunny** is usually thought of as an offensive tool — something red teamers use to inject payloads, exfiltrate data, or establish quick footholds. But with a bit of repurposing, you can flip it into a lightweight, plug-and-play **digital forensics & incident response (DFIR) collector**.

I’ve been building exactly that: a **DFIR Core Collector** payload. Below I’ll break down what the script does, why we use a little marker file called `BUNNY.TAG`, and how you can set it all up yourself.

---

## What the Collector Script Captures

Once the Bunny is plugged into a Windows host (unlocked, UAC accepted), the PowerShell collector (`collector.ps1`) runs and drops its output into a timestamped folder on the Bunny drive:

DFIR_<HOSTNAME>_<YYYYMMDD_HHMMSS>

markdown
Copy code

### Volatile & Runtime
- `processes.txt` — running processes snapshot  
- `net_connections.txt`, `tcp_connections.txt` — structured view of sockets  
- `loggedon_users.txt` — interactive/remote sessions  
- `tasks.txt` — persistence and automation tasks  

### Network State
- `netstat_full.txt` — all sockets + PIDs  
- `udp_endpoints.txt` — UDP endpoints  
- `listening_ports.txt` — listening ports  
- `routing_table.txt` — routing table  
- `arp_table.txt` — ARP cache  

### System Information
- `systeminfo.txt` — system summary  
- `drives.txt` — drive information  

### Temp & Swap (Listings Only)
- `temp_listing.txt`, `windows_temp_listing.txt`, `<user>_temp_listing.txt`  
- `swapfile_listing.txt` — metadata for pagefile/hiberfile  

### Installed Software
- `installed_software.txt` — 64-bit programs  
- `installed_software_wow64.txt` — 32-bit programs  

### User Data (Listings Only)
Per-user listings:
- `<user>_Documents_listing.txt`  
- `<user>_Pictures_listing.txt`  
- `<user>_Videos_listing.txt`  
- `<user>_Desktop_listing.txt`  
- `<user>_Downloads_listing.txt`  

### Deleted Items
- `recycle_bin_listing.txt` — Recycle Bin contents  

### Browser Artifact Listings
- `<user>_Chrome_artifacts_listing.txt`  
- `<user>_Edge_artifacts_listing.txt`  
- `<user>_Firefox_artifacts_listing.txt`  

### Admin-Only (UAC required)
- Event logs: `System.evtx`, `Security.evtx`, `Application.evtx`  
- Registry hives: `SAM`, `SYSTEM`, `SECURITY`, `SOFTWARE`, `NTUSER.DAT`  

If not elevated, the script writes `admin_warning.txt` instead.

### Chain-of-Custody
- `manifest.txt` — version, host, UTC time, elevated status  
- `collection_transcript.txt` — full PowerShell transcript  
- `hashes.txt` — SHA256 of every file created  

---

## What’s With `BUNNY.TAG`?

Windows assigns drive letters dynamically. On one host your Bunny might be `D:`, on another `E:` or `F:`. To avoid hardcoding, the collector looks for a tiny marker file named `BUNNY.TAG` in the root of the Bunny storage.

- If found → that drive root is treated as the Bunny  
- If not found → it falls back to a default (usually `D:`)  

How to create it:

```powershell
New-Item -ItemType File -Path D:\BUNNY.TAG -Force
It can be zero bytes. Some folks like to put a short identifier inside (e.g., DFIR-BUNNY-01) for clarity. Just make sure it sits at root, not inside payloads.

How to Set It Up
1. Prep the Bunny
Switch Bunny to arming mode (position nearest USB plug)

Plug into your workstation so it mounts as storage

Create BUNNY.TAG at the root

Copy payload.txt and collector.ps1 into payloads\switch1

2. Verify Layout
Root should have:

Copy code
BUNNY.TAG
payloads\
Switch folder should have:

Copy code
payloads\switch1\payload.txt
payloads\switch1\collector.ps1
3. Run in the Field
Flip switch to slot 1

Plug into an unlocked Windows target

Wait for Run box → PowerShell bootstrap launches

Click Yes on UAC

Wait 30–120s (longer if logs are large)

LED goes solid (finish state). Eject

4. Collect the Goods
Mount the Bunny on your workstation

Look for a new folder like:

makefile
Copy code
D:\DFIR_HOSTNAME_20250927_143512\
Check manifest.txt and collection_transcript.txt

Spot-check outputs (processes.txt, netstat_full.txt, hashes.txt)

Copy folder to secure analysis storage and verify hashes

Why This Matters
With this setup, you’ve transformed the Bash Bunny from an attack platform into a forensic triage tool. It’s quick, self-contained, and generates an integrity-protected package you can analyze later. Perfect for:

Grabbing volatile data from a suspicious host

Collecting consistent snapshots across multiple machines

Carrying a ready-to-go DFIR kit in your pocket

📅 Update – 2025-09-27

Collector v1.5

Persistence & Autoruns

Detailed Scheduled Tasks (scheduled_tasks_detailed.txt)

Autoruns registry keys, RunOnce keys, Startup folders, auto-start services (autoruns_registry_and_startup.txt)

PowerShell & Process Activity

ScriptBlock logging events (4104) (powershell_scriptblock_4104.txt)

Process creation events (4688) (security_process_creation_4688.txt)

PowerShell console history (PSReadLine) (powershell_console_history.txt)

WMI Persistence

Event filters, consumers, and bindings in root\subscription (wmi_persistence_artifacts.txt)

User & File Artifacts

Suspicious executables/scripts in AppData (recent, >20 KB) (suspicious_appdata_files.txt)

USB device connection history via registry + PnP (usb_connection_history.txt)

Network & Credentials

Wi-Fi profiles and keys (if elevated) via netsh (wifi_profiles.txt)

Integrity & Chain of Custody

Transcript, manifest, and SHA256 hashes remain included for every run

Payload v1.5

Added LED status scheme for clear operator feedback:

Yellow (fast blink) – launching & typing PowerShell

Magenta (slow blink) – waiting for UAC approval (10s)

Blue (slow blink) – active collection in progress (5 min default)

Green (solid) – collection finished successfully

Red (solid) – reserved for error state (future use)

Adjusted timing windows:

UAC wait set to 10 seconds

Collection wait set to 5 minutes (300s)

HID launch now uses Start-Process -Verb RunAs -Wait for reliable elevation and timing
