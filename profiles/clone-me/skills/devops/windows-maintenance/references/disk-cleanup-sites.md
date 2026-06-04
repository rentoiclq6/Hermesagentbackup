# Disk Cleanup: Canonical Safe-to-Clean Windows Paths

## C: Drive — System-Folder-Free Reference

Paths below are relative to `C:\Users\<username>\` unless prefixed with `C:\`.

### ✅ Tier 1 — Always Safe

| Path (Windows) | WSL Mount | Typical Size | Notes |
|---|---|---|---|
| `Downloads\` | `/mnt/c/Users/<user>/Downloads/` | 1-10 GB | Installers, ISOs, ZIPs. Biggest wins here. |
| `AppData\Local\Temp\` | `/mnt/c/Users/<user>/AppData/Local/Temp/` | 100 MB-5 GB | Temp files from all apps. Some may be in-use. |
| `AppData\Local\Microsoft\Windows\INetCache\` | (same pattern) | 100 MB-1 GB | IE/Edge legacy cache. |
| `AppData\Local\Google\Chrome\User Data\Default\Cache\` | (same pattern) | 200 MB-2 GB | Chrome cache. |
| `AppData\Local\Microsoft\Edge\User Data\Default\Cache\` | (same pattern) | 200 MB-2 GB | Edge cache. |
| `AppData\Local\Temp\chromium\` | (same pattern) | Variable | Electron app cache. |
| `AppData\Roaming\Tencent\xwechat\` | `/mnt/c/Users/<user>/AppData/Roaming/Tencent/xwechat/` | 500 MB-2 GB | WeChat image/file cache. Chat history NOT affected. |
| `AppData\Roaming\Tencent\QQPCMgr\` | (same pattern) | 200 MB-1 GB | Tencent PC Manager files. Delete if unused. |
| `C:\$Recycle.Bin` | `/mnt/c/$Recycle.Bin` | Variable | May show 0 in WSL due to permissions. OK. |

### ⚠️ Tier 2 — Conditional

| Path | Condition |
|---|---|
| `C:\Windows.old\` | Only after a Windows version upgrade. Use `cleanmgr` from Windows side. rm from WSL will partially fail. |
| `C:\Windows\SoftwareDistribution\Download\` | Windows Update cache. Safe but updates re-download. Empty only if experiencing update issues. |
| `C:\Windows\Temp\` | Typically tiny (<10 MB). Not worth the effort. |
| `AppData\Local\pip\Cache\` | pip package cache. Only if you don't reinstall often. |
| `AppData\Local\npm-cache\` | npm cache. `npm cache clean --force` from WSL is better. |
| `AppData\Local\Yarn\Cache\` | yarn cache. `yarn cache clean` from WSL is better. |

### 🚫 Tier 3 — Never Touch

- `C:\Windows\`
- `C:\Program Files\`
- `C:\Program Files (x86)\`
- `C:\ProgramData\`
- `C:\System Volume Information\`
- `C:\Users\<user>` — the profile root itself
- `C:\Users\<user>\Desktop\` (unless user explicitly requests)
- `C:\Users\<user>\Documents\`
- `C:\Users\<user>\Pictures\`
- `C:\Users\<user>\Videos\`

## Windows Built-in Tool

```cmd
cleanmgr /sageset:1   # configure which categories to clean
cleanmgr /sagerun:1   # run the configured cleanup
```

Use `cmd.exe /c cleanmgr` from WSL to launch it. The GUI covers:
- Temporary files
- Recycle Bin
- Delivery Optimization Files
- Windows Update Cleanup (can reclaim 1-10+ GB)
- Windows.old (when present, can reclaim 10-30+ GB)

## Typical Recovery Expectations

| Scenario | Expected Recovery |
|---|---|
| Clean Downloads (installers only) | 1-5 GB |
| Clear Temp | 0.5-5 GB |
| Clear WeChat cache | 0.5-2 GB |
| Clear browser caches | 0.2-2 GB |
| Windows Update Cleanup | 1-10 GB |
| Remove Windows.old | 10-30 GB |
| **Typical total (moderate)** | **3-10 GB** |
| **Typical total (aggressive)** | **10-40 GB** |
