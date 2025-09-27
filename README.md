# 🐰 Bash Bunny DFIR Core Collector

Turn a Hak5 Bash Bunny into a portable, plug-and-play DFIR triage kit.  
This project repurposes the Bash Bunny from an offensive tool into a **forensic snapshot collector** that runs natively on Windows hosts without third-party binaries.

---

## 📌 Overview
When plugged into an unlocked Windows host (with UAC approved), the Bunny automatically launches a PowerShell script (`collector.ps1`).  
It creates a timestamped evidence folder on the Bunny with process, network, system, persistence, and user data artifacts.  

The output includes a full transcript, manifest, and SHA256 hashes for integrity and chain-of-custody.

---

## 📂 What It Collects

### Volatile & Runtime
- Running processes (`processes.txt`)  
- Logged-on users (`loggedon_users.txt`)  
- TCP/UDP connections, listening ports, routing table, ARP cache  
- Basic scheduled tasks (`tasks.txt`)  

### System & Files
- System information and drives (`systeminfo.txt`, `drives.txt`)  
- Temp and swap file listings  
- Installed software (x64 and WOW64)  
- User folders (Documents, Desktop, Downloads, Pictures, Videos)  
- Recycle Bin metadata  

### Persistence & Autoruns
- Detailed scheduled tasks (`scheduled_tasks_detailed.txt`)  
- Autoruns registry keys and Startup folders  
- Auto-start services  

### PowerShell & Process Activity
- PowerShell ScriptBlock logs (4104 events)  
- Process creation events (4688 events)  
- Console command history (PSReadLine)  

### WMI Persistence
- Event filters, consumers, and bindings from `root\subscription`  

### User & File Artifacts
- Suspicious executables/scripts in AppData (recent, >20 KB)  
- Browser profile listings (Chrome, Edge, Firefox)  
- USB device connection history  

### Network & Credentials
- Wi-Fi profiles and keys (if elevated) via `netsh`  

### Admin-Only (if elevated)
- Event logs: System, Security, Application  
- Registry hives: SAM, SYSTEM, SECURITY, SOFTWARE, NTUSER.DAT  

### Chain-of-Custody
- `manifest.txt` — version, host, UTC time, elevation status  
- `collection_transcript.txt` — full PowerShell transcript  
- `hashes.txt` — SHA256 hash of every file  

---

## ⚡ Payload LED Indicators
The payload provides clear status feedback using the Bunny’s LED:

- **Yellow (fast blink)** — launching and typing PowerShell  
- **Magenta (slow blink)** — waiting for UAC approval (10s)  
- **Blue (slow blink)** — active collection in progress (default 5 min)  
- **Green (solid)** — collection finished successfully  
- **Red (solid)** — reserved for error state (future use)  

---

## 🛠️ Setup Instructions

1. **Prep the Bunny**
   - Switch Bunny to arming mode (closest to USB plug).  
   - Plug into your workstation so it mounts as storage.  
   - Create a file called `BUNNY.TAG` in the root of the Bunny drive (zero-byte file is fine).  

2. **Deploy Payload & Collector**
   - Copy `payload.txt` and `collector.ps1` into:  
     ```
     payloads\switch1\
     ```  
   - Ensure `BUNNY.TAG` is still present in the Bunny root.  

3. **Run in the Field**
   - Flip switch to slot 1.  
   - Plug into an unlocked Windows target.  
   - Approve UAC when prompted.  
   - LED will show status (see colors above).  
   - After ~5 minutes, LED turns green — collection complete.  

4. **Collect the Goods**
   - Mount the Bunny on your workstation.  
   - Evidence will be under:  
     ```
     DFIR_<HOSTNAME>_<YYYYMMDD_HHMMSS>\
     ```  
   - Verify integrity with `hashes.txt`.  

---

## 📜 Changelog

### 📅 2025-09-27 — v1.5
**Collector**  
- Added detailed scheduled tasks, autoruns, and auto-start services  
- Captures PowerShell ScriptBlock (4104), process creation (4688), and console history  
- Collects WMI persistence artifacts  
- Scans AppData for suspicious executables/scripts  
- Captures USB device connection history  
- Dumps Wi-Fi profiles and keys (if elevated)  
- Maintains manifest, transcript, and SHA256 integrity hashes  

**Payload**  
- Added LED status scheme (Yellow → Magenta → Blue → Green, Red reserved)  
- UAC wait set to 10 seconds  
- Collection wait set to 5 minutes  
- Improved HID launch reliability with `Start-Process -Verb RunAs -Wait`  

---

## ⚖️ License
This project is licensed under the [MIT License](LICENSE).

---

## 🚨 Disclaimer
This tool is intended for **authorized DFIR and educational use only**.  
Do not deploy against systems without proper permission. Misuse may violate laws and organizational policies.
