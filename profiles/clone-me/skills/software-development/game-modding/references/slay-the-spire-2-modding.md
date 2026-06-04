# Slay the Spire 2 — Modding Reference

Game: Slay the Spire 2 (v0.105.1+)
Engine: Godot 4 + C# (Mono)
Mod system: Built-in (no Workshop yet, AppID 2868840)
Save format: JSON (schema_version 21)

## Mod Structure

All mods go into a `mods/` subfolder in the game root directory:

```
{game_root}/mods/
├── BaseLib/                    ← Required dependency for ALL mods
│   ├── BaseLib.json            ← Mod manifest
│   ├── BaseLib.dll             ← C# plugin (for mods that add new code)
│   └── BaseLib.pck             ← Godot resource pack
├── QuickReload/
│   ├── QuickReload.json
│   ├── QuickReload.dll
│   └── QuickReload.pck
└── Saber战士/
    ├── xiaotian.json
    └── xiaotian.pck            ← Some mods have only .pck (skins)
```

### Manifest format (`.json`)

```json
{
    "id": "ModId",              ← Unique ID. Duplicate IDs cause load errors!
    "name": "Display Name",
    "author": "Author Name",
    "description": "...",
    "version": "v1.0.0",
    "min_game_version": "0.103.2",  ← Optional. If missing, game shows warning
    "has_pck": true,                ← Has Godot .pck resource pack
    "has_dll": true,                ← Has C# .dll plugin
    "dependencies": ["BaseLib"],    ← Not all mods list deps, but BaseLib is implicit
    "affects_gameplay": false       ← Pure skins = false, gameplay mods = true
}
```

### File types
| File | Purpose |
|------|---------|
| `.json` | Manifest — game scans for this to discover mods |
| `.pck` | Godot resource pack — contains textures, scenes, assets |
| `.dll` | C# plugin — code (Harmony patches, new logic) |

### Required dependency

**BaseLib** (by Alchyr, v3.1.2+) is required by nearly all STS2 mods. It patches 177+ game methods and provides a mod loading framework. Without it, other mods won't load or will error.

## Built-in Developer Console

The game has a **built-in developer console** accessible by pressing **`~`** (backtick/tilde, below Escape) at any time.

BaseLib (`BetterConsoleAutocompletePatch`) improves autocomplete — press Tab to see available IDs.

### Command Reference

Discovered via DLL analysis (`sts2.dll`). All commands are available regardless of mods loaded:

| Category | Commands | Description |
|----------|----------|-------------|
| 🏆 **Relics** | `relic obtain {id}` `relic melt {slot}` `relic remove {id}` | Add/remove relics. Tab-complete for IDs. |
| 🧪 **Potions** | `potion` | Potion manipulation commands |
| 🃏 **Cards** | `card` `cardpile add {id}` `cardpile discard` `cardpile exhaust` | Card manipulation, add to deck/pile |
| ❌ **Remove card** | `remove_card CARD.{ID}` | ⭐ **Permanently remove a card from deck.** ID format is `CARD.XXX`. Examples: `CARD.STRIKE_IRONCLAD`, `CARD.BASH`. Console may show localized names but accepts `CARD.XXX` IDs. Discovered via DLL enum extraction — check save `progress.save` for discovered card IDs. |
| 💰 **Economy** | `gold {amount}` | Add gold |
| ❤️ **Healing** | `heal {amount}` | Heal player |
| ⚡ **Energy** | `energy {amount}` | Set/add energy |
| 🛡️ **Combat** | `block {amount}` `damage {amount}` `die` `kill` | Block, damage, kill entities |
| 🧟 **Creatures** | `creature add {id}` | Spawn monsters |
| 💪 **Powers** | `power apply {id}` `power remove {id}` | Buff/debuff manipulation |
| 📜 **Events** | `event` | Trigger game events |
| 🗺️ **Map** | `act` `travel` `fight` `room` | Act/zone/fight manipulation |
| 🌀 **Orbs** | `orb channel {id}` `orb evoke {slot}` `orb passive` | Orb manipulation (for Defect) |
| 🔧 **State** | `draw {n}` `enchant` `forge` `afflict` | Draw cards, enchant, forge, apply status |
| 🪦 **Death** | `die` `kill` | Kill player or target |
| 📊 **Meta** | `achievement` `unlock` `win` `dump` `bestiary` `ancient` | Unlocks, achievements, game info |
| 🎨 **Visual** | `art` `stars` `trailer` | Visual debug/toggles |

**Usage pattern:** Type a command, then space + Tab to see subcommands/IDs. Most commands support Tab autocomplete for entity IDs (relic names, card IDs, etc.).

**⚠️ Don't guess command syntax. Always check `help` first.** The console has its own command registration names that may differ from internal C# class names. Type `help` at the console prompt to see all registered commands with their exact syntax. Only document a command here after it's been verified via `help` output or user testing.

## Save File Protection (Read-Only Trick)

When the game's Steam cloud sync overwrites a manually-copied save file, set the file to **read-only (444)** before launching:

```bash
chmod 444 %AppData%/SlayTheSpire2/steam/{steamid}/modded/profile1/saves/progress.save
```

The game will fail to overwrite it but can still read it. Note: this also prevents save-while-playing until you remove the read-only flag.

## Mod Loading Notes

### Subdirectory scanning
The game recursively scans **all subdirectories** under `mods/` for `.json` manifest files. This means creating a subfolder like `mods/冲突删除/` does NOT hide mods from the game — they'll still be loaded. To truly disable a mod, move it outside `mods/` entirely.

### Conflict detection
| Conflict type | Symptom | Resolution |
|--------------|---------|------------|
| Same `"id"` in two mods | Game logs "already loaded with that name", second copy fails silently | Delete duplicate |
| Same character targeted by 2 skin mods | Only last-loaded skin visible, no error | Keep one skin per character |
| Mod `.dll` references removed game method | Game logs TypeLoadException, mod fails to load | Wait for mod update or remove it |

## Known Pitfalls

### 1. Duplicate mod IDs crash the mod with the second copy
If two mod folders contain `.json` with the same `"id"`, the game logs:
```
[ERROR] Tried to load mod with id X, but a mod is already loaded with that name!
```
→ The second copy silently fails. Remove one.

Example from session: `死灵法师` and `骨妹娘化` both had `"id": "Booba-Necrobinder-Mod"` — exact same DLL and PCK bundled twice.

### 2. QuickReload may fail on newer game versions
QuickReload v1.0.3 errors on v0.105.x:
```
[ERROR] Method 'get_ShouldBuffer' in type 'QuickReload.Multiplayer.QuickReloadMessage'
does not have an implementation.
```
→ The DLL references a method removed in this game version. Needs a QuickReload update.

### 3. Skin mods with same target character conflict
Multiple `.pck` files targeting the same character (e.g. Defect) load in an undefined order. Only the last-loaded one takes effect visually. Not an error, just invisible.

## Save System

STS2 uses **Steam cloud saves** stored at:

```
%AppData%/SlayTheSpire2/steam/{steamid}/
├── profile.save              ← Points to last profile ID
├── settings.save
├── profile1/saves/
│   ├── progress.save         ← Main save data (JSON)
│   ├── progress.save.backup  ← Auto-backup
│   ├── prefs.save            ← Preferences
│   └── history/              ← Run history
├── profile2/
├── profile3/
└── modded/                   ← ⚠️ SEPARATE save directory for modded mode!
    ├── profile1/saves/
    │   └── ...
    ├── profile2/
    └── profile3/
```

### Key insight: vanilla vs modded saves are SEPARATE

When the game starts **with mods**, it reads/writes from the `modded/` subtree, NOT the regular profiles.

When the game starts **without mods**, it reads from the regular `profile{1,2,3}/` paths.

The **save format is identical** (same `schema_version: 21`, same JSON structure). So a vanilla `progress.save` can be copied to `modded/profile1/saves/` to carry progress into modded mode.

### Copying vanilla save to modded (to keep progress when adding mods)

```bash
# Find the steam ID
ls %AppData%/SlayTheSpire2/steam/

# Copy the save
copy %AppData%/SlayTheSpire2/steam/{steamid}/profile1/saves/progress.save \
     %AppData%/SlayTheSpire2/steam/{steamid}/modded/profile1/saves/progress.save

# Also copy prefs and backup
copy %AppData%/SlayTheSpire2/steam/{steamid}/profile1/saves/progress.save.backup \
     %AppData%/SlayTheSpire2/steam/{steamid}/modded/profile1/saves/progress.save.backup
copy %AppData%/SlayTheSpire2/steam/{steamid}/profile1/saves/prefs.save \
     %AppData%/SlayTheSpire2/steam/{steamid}/modded/profile1/saves/prefs.save
```

Note: Copy while the game is NOT running, or the game may overwrite with a fresh save on launch.

## Game Versions Check

Version info at `{game_root}/release_info.json`:
```json
{"commit": "d5e30a22", "version": "v0.105.1", "date": "2026-05-08T19:47:15-07:00", "branch": "v0.105.1"}
```

## Cosmetics Mods — Console Commands

Some mods (e.g. Merchant2CuteII — 储君雌鬼子/商人娘化) expose console commands:

Press **`~`** (backtick/tilde below Escape) to open the in-game console.

Available commands (mod-specific):
```
merchant point hand/foot         Merchant hand/foot mode switch
merchant point white/black       Merchant white/black stockings
merchant voice default/jp/zh     Merchant voice language
merchant voice db {value}        Adjust voice volume (±10dB safe)
```

## Game Launch

The game root contains multiple batch files for different rendering backends:
- `launch_opengl.bat` — OpenGL 3
- `launch_vulkan.bat` — Vulkan
- `launch_d3d12.bat` — Direct3D 12
- `SlayTheSpire2.exe` (direct launch, uses default renderer)
