# Contributing to Bash Bunny DFIR Core Collector

Thanks for your interest! This repo is public for documentation and education. The **operational kit** (payloads, elevation launchers) is dual-use and must be handled responsibly.

> **Defensive Use Only:** By participating, you agree to contribute content intended for authorized DFIR activities. Do not submit content designed for unauthorized access or exploitation.

## How to contribute

1. **Discuss first (optional but helpful)**
   - Open an Issue describing what you want to change or add.

2. **Fork & branch**
   - Fork the repo and create a feature branch:
     ```
     git checkout -b feat/short-title
     ```

3. **Make changes**
   - Keep docs public-safe (no raw HID macros that auto-elevate, no step-by-step offensive content).
   - Prefer examples, pseudocode, or sanitized snippets.

4. **Write clearly**
   - Use concise Markdown.
   - Add code comments and short rationales for changes.

5. **Open a Pull Request (PR)**
   - Target the `main` branch.
   - Our branch protection requires:
     - At least **1 approval**
     - **Code Owners** review for protected paths
     - **All conversations resolved**
     - (Optional) passing status checks, if enabled
   - Keep PRs small and focused.

6. **Licensing**
   - By submitting a PR, you certify you have the right to contribute the content and you license it under this repository’s LICENSE.
   - Do **not** include third-party code you cannot relicense.

## What’s in / out of scope

**In scope (welcome):**
- Documentation, diagrams, troubleshooting guides
- Public-safe examples and verification scripts
- Improvements to README / setup / chain-of-custody notes

**Out of scope (will be closed):**
- Raw offensive payloads or automation designed for unauthorized access
- Bypass techniques, exploit PoCs, or content that meaningfully lowers abuse barriers
- Secrets or sensitive data (redact everything)

## Code of conduct

Be respectful, constructive, and professional. No harassment, discrimination, or doxxing. Violations may result in blocks/reporting.

## Contact

- Security issues → see **SECURITY.md**
- General questions → open an Issue
