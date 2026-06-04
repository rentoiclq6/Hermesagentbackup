# Unity Modding (BepInEx + Harmony)

> Absorbed from `unity-modding` skill. Referenced by the main `game-modding` decision tree when the target game is Unity Mono.

## Prerequisite Checks (do before modding)

### 1. Mono vs IL2CPP
| Feature | Mono | IL2CPP |
|---------|------|--------|
| `游戏_Data/Managed/` | ✅ Has DLLs | ❌ Absent |
| `Assembly-CSharp.dll` | ✅ 1–2MB | ❌ Absent |
| `GameAssembly.dll` | ❌ Absent | ✅ Present |

This guide covers **Mono only**. IL2CPP requires MelonLoader.

### 2. Game has built-in Mod system?
- Game root contains `Mod/` folder
- `Assembly-CSharp.dll` has Mod API classes (e.g. `ChronoArkMod.Plugin.ChronoArkPlugin`)
- **If yes → use built-in Mod Loader (Scheme B below), don't install BepInEx**

### 3. What does the user want?
- Tweak values/difficulty → Harmony Patch
- Add new content → resource loading required, larger scope

---

## Scheme A: BepInEx + Harmony (no built-in mod loader)

### Five-step flow

**1. Analyze**: `strings Assembly-CSharp.dll | grep -iE "coin|gold|damage|reward"` to find target methods

**2. Install BepInEx 5.4 x64**: Extract to game root directory

**3. Write patches (scan first, don't guess signatures)**:
- First version: only scan and log all candidate method signatures
- After confirmation, second version does the precise patch

**Key Harmony patterns:**
```csharp
// Basic Patch
[HarmonyPatch(typeof(TargetClass), "MethodName")]
static class MyPatch {
    [HarmonyPrefix] static bool Prefix(ref int param) { param *= 2; return true; }
    [HarmonyPostfix] static void Postfix(ref int __result) { __result *= 2; }
}

// Property setter (critical — distinguish gain vs spend)
[HarmonyPrefix, HarmonyPatch(typeof(PlayData), "set_Gold")]
static bool GoldPrefix(ref int value) {
    int current = PlayData.Gold;
    if (current > 0 && value > current) {  // only affect increases
        int gain = value - current;
        value = current + (int)(gain * multiplier);
    }
    return true;
}
```

**4. Compile**:
- Preferred: `dotnet build` (.NET SDK, supports modern C#)
- Fallback: system csc (C# 5 only, no `$""`, `nameof()`, `?.`)
- csproj references: `0Harmony.dll` + `Assembly-CSharp.dll` + `UnityEngine.dll`

**5. Test**: Check `BepInEx/LogOutput.log`; console is off by default, enable in BepInEx.cfg

---

## Scheme B: Built-in Mod Loader (Chrono Ark pattern)

### Directory structure
```
Mod/YourMod/
├── ChronoArkMod.json              # Manifest (with ModSettingEntries)
├── Assemblies/
│   ├── YourMod.dll
│   └── 0Harmony.dll
└── Localization/
    └── LangSystemDB.csv           # Localization
```

### ChronoArkMod.json key fields
```json
{
    "id": "YourMod",
    "Title": "YourMod/ChronoArkMod/Title",
    "ModSettingEntries": [{
        "SettingType": "SliderSetting",
        "SettingKey": "Multiplier",
        "InitValue": 2.0,
        "Max": 100.0, "Min": 1.0, "StepSize": 0.5
    }]
}
```

### C# base class & config loading
```csharp
public class YourMod : ChronoArkMod.Plugin.ChronoArkPlugin {
    Harmony harmony;
    static float multiplier = 2f;

    public override void Initialize() { harmony = new Harmony("your.id"); /* patches */ LoadSettings(); }
    void LoadSettings() {
        var info = ChronoArkMod.ModManager.getModInfo(this.ModId);
        var setting = info?.GetSetting("Multiplier") as SliderSetting;
        if (setting != null) multiplier = setting.Value;
    }
    public override void OnModSettingUpdate() => LoadSettings();
    public override void Dispose() => Harmony.UnpatchID("your.id");
}
```

### Compile from WSL
```bash
curl -sL "https://dot.net/v1/dotnet-install.sh" | bash
export PATH="$HOME/dotnet:$PATH"
dotnet build  # csproj target: net472
```

---

## Scheme C: BepInEx Config (user-configurable mods)

```csharp
static ConfigEntry<float> CoinMul;
void Awake() {
    CoinMul = Config.Bind("倍率", "CoinMul", 3f, "金币倍率");
    Config.Save();  // ← mandatory! Otherwise .cfg won't generate
}
// In patch: CoinMul.Value
```

---

## Scheme D: Deep nested field access (reflection chains)

When target is `A.B.C.D.Field`, use `AccessTools.TypeByName` + `GetField` + `BindingFlags` to walk the chain.

---

## Pitfalls (critical)

1. **Coroutine crashes**: `IntPrefix` patch on coroutine methods → parameter doubling used as array index → NullReferenceException. Use Postfix (modify return) or patch the non-coroutine caller instead.

2. **Gain vs spend**: Property setter Prefix must check `value > current`; otherwise spending/repairing also doubles.

3. **Load-doubling**: Guard with `current > 0` to skip initialization assigns.

4. **Config not generating**: BepInEx 5 requires explicit `Config.Save()`.

5. **Harmony 2.9 deprecated API**: Use `Harmony.UnpatchID("id")` instead of deprecated `harmony.UnpatchAll(string)`.

6. **C# version**: System csc is C# 5 only; use `dotnet build` for modern features.

## Diagnosis (mod not working)

1. BepInEx loaded? → Check `LogOutput.log`
2. Console enabled? → `BepInEx.cfg` → `[Logging.Console] Enabled = true`
3. Plugin skipped? → Log search for `Skipping`
4. Patch failed? → Log search for `Failed to patch`
5. Hook triggered? → Add `Debug.Log` in Prefix to verify

---

## Session-specific references

- `references/chronoark-mod-example.md` — full Chrono Ark mod example project
- `references/chronoark-multiplier-mod.md` — multiplier mod walkthrough
- `references/chronoark-bloodmist-level.md` — Bloodmist level mod specifics
