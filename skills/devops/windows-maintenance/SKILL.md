---
name: windows-maintenance
description: >-
  Windows system maintenance tasks performed from WSL: disk space analysis, identifying safe
  cleanup targets (temp/cache/installers), disk usage attribution, and one-shot cleanup execution.
trigger:
  - "C盘"
  - "清理"
  - "disk cleanup"
  - "磁盘空间"
  - "Windows temp"
  - "disk space"
  - "clean C drive"
  - "clean windows"
  - "safe to delete"
---

# Windows Maintenance (from WSL)

## When to Use
- User asks about cleaning Windows disk space, checking how full C: is, or removing temp files
- User asks what on C: is safe to delete without breaking the system
- User wants to analyze Windows disk usage or attribute large space consumption
- You are already inside WSL and the Windows filesystem is mounted under /mnt/

## Approach

### 1. Check Overall Disk Usage

```bash
df -h /mnt/c
```

This shows total, used, and available space. C: at >90% full is urgent; >80% is worth addressing.

### 2. Find the Windows Username

The user's profile directory is the main target for safe cleanup:

```bash
ls /mnt/c/Users/
```

Ignore `All Users`, `Default`, `Default User`, `Public`, `desktop.ini`. The real user is typically the remaining entry.

### 3. Probe Safe-to-Clean Directories (targeted, one by one)

**Critical: WSL accessing NTFS via /mnt/c/ is extremely slow for recursive scans.** Never run `du -sh /mnt/c/Users/*` or `find /mnt/c/...` — these will time out. Use targeted one-level-deep stat calls instead.

| Target | WSL Path | Typical Size | Safety |
|--------|----------|-------------|--------|
| Downloads | `C:\Users\<user>\Downloads` | 1-10 GB | ✅ All installer files |
| User Temp | `C:\Users\<user>\AppData\Local\Temp` | 100 MB - 5 GB | ✅ Safe |
| WeChat cache | `C:\Users\<user>\AppData\Roaming\Tencent\xwechat\` | 500 MB - 2 GB | ✅ App cache only |
| QQPCManager | `C:\Users\<user>\AppData\Roaming\Tencent\QQPCMgr\` | 200 MB - 1 GB | ✅ If Tencent PC Manager unused |
| Browser caches | `AppData\Local\Google\Chrome\User Data\Default\Cache` | 200 MB - 2 GB | ✅ Safe |
| INetCache | `AppData\Local\Microsoft\Windows\INetCache` | Small | ✅ IE/Edge cache |
| Prefetch | `C:\Windows\Prefetch` | 10-100 MB | ✅ Safe but small |
| Windows Temp | `C:\Windows\Temp` | < 10 MB typically | ✅ Safe |
| $Recycle.Bin | `C:\$Recycle.Bin` | Variable | ✅ Safe (may show 0 in WSL) |

**Commands to use (fast, targeted):**

```bash
# Downloads — list large files, don't recursive-du
ls -lhS /mnt/c/Users/<user>/Downloads/ | head -20

# Quick size of a single directory
du -sb /mnt/c/Users/<user>/AppData/Local/Temp

# Check app cache presence
du -sb "/mnt/c/Users/<user>/AppData/Roaming/Tencent/"

# Check if Windows.old exists
ls -d /mnt/c/Windows.old 2>/dev/null && echo "EXISTS (reclaim via Disk Cleanup)"
```

### 4. Classify Files Into Safety Tiers

Present results to the user organized by:

**Tier 1 — ✅ Obviously Safe (anyone can delete)**
- Downloads folder contents (especially `.iso`, `.exe`, `.msi` installers)
- `AppData\Local\Temp` — temporary program files
- Browser caches
- App-specific caches (WeChat, QQ, etc.)
- `$Recycle.Bin`

**Tier 2 — ⚠️ Conditional (check first)**
- `Windows.old` — safe only after a Windows upgrade is confirmed stable (usually 10+ days)
- `SoftwareDistribution\Download` — Windows Update cache; safe but updates re-download
- Large `.iso` files — safe if the user has already used or doesn't need them
- App data folders for uninstalled programs

**Tier 3 — 🚫 Never touch**
- `Windows`, `Program Files`, `Program Files (x86)`, `ProgramData`
- `System32`, `System`, `Config`
- User profile folders like `Desktop`, `Documents`, `Pictures`, `Videos` (unless user explicitly requests)

### 5. Present a Cleanup Summary

Use a table format showing:
- What you found (path, size)
- What it is
- Whether it's safe to delete
- How much it would free

**Always let the user confirm before executing deletions. Never delete without explicit approval.**

### 6. Offer to Execute

If user agrees, use `rm -rf` for the confirmed targets. Example:

```bash
# Remove installers from Downloads (but preserve subdirectories)
rm -f /mnt/c/Users/<user>/Downloads/*.exe /mnt/c/Users/<user>/Downloads/*.msi /mnt/c/Users/<user>/Downloads/*.iso

# Clear Temp
rm -rf /mnt/c/Users/<user>/AppData/Local/Temp/*

# Clear WeChat cache (leaves WeChat installed and chat history intact)
rm -rf "/mnt/c/Users/<user>/AppData/Roaming/Tencent/xwechat/"/*
```

## Pitfalls

1. **WSL → NTFS is slow.** Do NOT run recursive `du -sh` or `find` on any Windows directory tree deeper than 1-2 levels. It will time out. Use `ls` and `du -sb` on individual known paths instead.

2. **Permission issues.** Some Windows directories are owned by SYSTEM or TrustedInstaller and may show as empty or inaccessible from WSL. `$Recycle.Bin` often appears as 0 bytes. Don't over-interpret these — they may still have content accessible from Windows tools like `cleanmgr`.

3. **Files in use.** Temp files that are currently locked by running processes can't be deleted. Use `rm -rf` with `|| true` or just accept some may stick. They'll be cleaned on next reboot.

4. **WeChat cache vs. chat history.** The `xwechat/` cache directory contains cached images/videos/files. Deleting it does NOT delete chat history (stored in a `Msg/` database). It just means WeChat will re-download cached media.

5. **ISO and installer files.** Users often forget they downloaded large ISOs. Always flag these explicitly with their size and filename. Ask before deleting — they may still need the ISO.

6. **Windows.old is NOT a simple rm target.** It has security descriptors that make `rm -rf` from WSL fail partially. Recommend `cleanmgr` (Disk Cleanup) instead.

## References

See `references/disk-cleanup-sites.md` for the canonical list of safe-to-clean Windows paths and their exact WSL-mounted paths.
