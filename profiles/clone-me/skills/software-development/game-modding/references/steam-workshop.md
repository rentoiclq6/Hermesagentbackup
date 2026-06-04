# Steam Workshop Mod Sourcing

> Absorbed from `steam-workshop` skill. Referenced by the main `game-modding` decision tree when the user wants to find and download mods from Steam Workshop.

## Key concepts

| Concept | Description |
|---------|-------------|
| AppID | Steam game numeric ID (e.g. Chrono Ark = 1188930) |
| PublishedFileID | Workshop item numeric ID (e.g. 3361965030) |
| steamcmd | Valve CLI tool for downloading Workshop content |

## Workflow

### 1. Find game AppID

```bash
curl -s "https://store.steampowered.com/api/storesearch/?term=<game-name>&l=english&cc=us"
```
Returns JSON with `items[].id` = AppID. Try English names if Chinese fails.

### 2. Browse Workshop hot mods

Direct URL to sort by most subscribed:
```
https://steamcommunity.com/workshop/browse/?appid={AppID}&browsesort=totaluniquesubscribers&p=1
```

### 3. Extract mod list from browser page

```javascript
// Get file IDs from current Workshop browse page
Array.from(document.querySelectorAll('a[href*="sharedfiles"]'))
  .map(a => ({text: a.textContent.trim().substring(0, 60), href: a.href}))
  .filter(x => x.href && !x.href.includes('browse') && x.text)
```

Each mod URL: `https://steamcommunity.com/sharedfiles/filedetails/?id={PublishedFileID}`

### 4. Download methods

#### Method A: Steam client subscribe (easiest — user clicks Subscribe in Workshop UI)
Output: `C:\Program Files (x86)\Steam\steamapps\workshop\content\{AppID}\{PublishedFileID}\`

#### Method B: SteamCMD (automation / no GUI)

Install:
```bash
mkdir -p ~/steamcmd && cd ~/steamcmd
curl -sL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar xz
```

Download item:
```bash
~/steamcmd/steamcmd.sh +login <username> +workshop_download_item <AppID> <PublishedFileID> +quit
```
Output: `~/Steam/steamapps/workshop/content/{AppID}/{PublishedFileID}/`

#### Method C: WorkshopDL (Windows GUI — preferred when Steam Guard/2FA blocks SteamCMD)
```
https://github.com/imwaitingnow/WorkshopDL/releases/download/2.0.4/WorkshopDL.2.0.4_installer.exe
```

## Darkest Dungeon mod install troubleshooting

### Mod not showing in game mod manager
1. **Invalid language code in project.xml**: Only `english`, `schinese`, `tchinese`, etc. `chinese` alone is invalid → use `schinese`
2. **Visibility: private**: Change to `<Visibility>public</Visibility>`
3. **Missing project.xml or modfiles.txt**: Both files must exist in each mod subdirectory
4. **Folder name with fullwidth/special characters**: Use pure ASCII names
5. **Localization/font mods**: May not appear in mod list — check in-game instead

### Quick validation script
```bash
for d in /path/to/mods/*/; do
  echo "=== $(basename "$d") ==="
  grep -o '<Language>.*</Language>' "$d/project.xml" 2>/dev/null || echo "  no project.xml"
  grep -o '<Visibility>.*</Visibility>' "$d/project.xml" 2>/dev/null
done
```

## Pitfalls

- **Steam Guard / 2FA**: Blocks SteamCMD `+login` (times out waiting for code). Either disable temporarily, use interactive login, or use WorkshopDL instead.
- **32-bit libs**: SteamCMD Linux binary needs `lib32gcc-s1` on 64-bit systems.
- **Python `steam` library**: Broken (protobuf v4 incompatibility, eventemitter regression). Don't use.
- **WSL steamcmd**: Linux binary needs 32-bit libs; alternatively run Windows steamcmd.exe from `/mnt/` (must be on NTFS, not ext4).
- **Do NOT guess console commands from class names**: Actual registered command names differ from class names. Run `help` in game console to get real syntax.
- **BaseLib (Harmony patches) breaks memory editors**: BaseLib applies 177+ Harmony patches (e.g. STS2) that change memory layout. Cheat Engine / trainers become incompatible — not a bug, it's inherent to Harmony.

## References
- `references/chrono-ark-mods-2026-05.md` — Chrono Ark mod installation session log
- `references/chrono-ark-mod-conflicts.md` — Chrono Ark mod conflict detection notes
- `references/darkest-dungeon-1-mods.md` — DD1 specific mod info
