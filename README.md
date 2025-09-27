# Bash Bunny DFIR Core Collector

Repurposing the Hak5 Bash Bunny into a **defensive DFIR triage tool** for Windows endpoints.  
This project provides a lightweight, native-only PowerShell collector that generates a timestamped, integrity-protected snapshot of key forensic artifacts.

> ⚠️ **Important:** Operational payloads (HID automation and launcher scripts) are dual-use and should **not** be shared publicly.  
> This repo contains the documentation and sanitized examples. Full payloads should be kept in a **private repository**.

---

## ✦ What It Does

When deployed, the Bash Bunny runs a PowerShell collector (`collector.ps1`) that:

- Captures **volatile/runtime data** (processes, network connections, logged-on users, scheduled tasks).
- Enumerates **system & drive info**.
- Produces **listings** of user files (Documents, Downloads, Desktop, Pictures, Videos).
- Lists **temp files**, **recycle bin items**, and **browser profile directories** (Chrome, Edge, Firefox).
- (If run with UAC elevation) exports **event logs** (System, Security, Application) and **registry hives** (SAM, SYSTEM, SECURITY, SOFTWARE, NTUSER.DAT).
- Records a **manifest** and **PowerShell transcript** for audit.
- Hashes all outputs with **SHA256** for chain-of-custody.

---

## ✦ Output Structure

All results are saved to a timestamped folder on the Bunny drive:

<BUNNY_ROOT>\DFIR_<HOSTNAME>_<YYYYMMDD_HHMMSS>\

markdown
Copy code

Key files include:
- `manifest.txt` — host, UTC time, admin status, script version  
- `collection_transcript.txt` — PowerShell transcript  
- `hashes.txt` — SHA256 for every collected file  
- `processes.txt`, `netstat_full.txt`, `installed_software.txt`, etc.  
- Browser artifact listings (`<user>_Chrome_artifacts_listing.txt`, etc.)  
- Event logs & hives (if elevated): `System.evtx`, `Security.evtx`, `SAM`, `SOFTWARE`, etc.  
- `admin_warning.txt` if run without elevation

---

## ✦ The Role of `BUNNY.TAG`

The file **`BUNNY.TAG`** sits in the root of the Bunny’s storage partition.  
It’s a zero-byte marker that allows the script to reliably detect the Bunny drive letter across different hosts.

- Path: `D:\BUNNY.TAG` (if Bunny mounts as D:)  
- Created with:  
  ```powershell
  New-Item -ItemType File -Path D:\BUNNY.TAG -Force
If the tag is missing, the script falls back to a default drive letter (D:).

✦ Safe Usage Workflow
Prep

Place BUNNY.TAG at root.

Put payload.txt + collector.ps1 in payloads/switch1/ (private).

Deploy

Set switch to slot 1.

Plug into an unlocked Windows host.

Accept UAC when prompted for full collection.

Verify

Remount Bunny.

Inspect the new DFIR_* folder.

Review manifest.txt, collection_transcript.txt, and hashes.txt.

Copy to secure analysis host.

✦ Legal & Operational Notes
Authorization required — only run on systems where you have explicit permission.

Not a replacement for full imaging — this is a triage tool to prioritize deeper investigation.

Chain-of-custody — preserve manifest, transcript, and hash files alongside evidence.

Private repo for full payloads — keep HID automation and full collector code access-controlled.
