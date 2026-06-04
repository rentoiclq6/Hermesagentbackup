# Chrono Ark 自定义 Mod 示例：MultiplierMod

完整的多倍率 Mod 制作记录。可用于参考 Unity Mono 游戏 + 内置 Mod Loader + Harmony 的完整工作流。

## 目标
给 Chrono Ark（Unity 2018.4.32f1 Mono）制作一个 Mod：
- 金钱（Gold）和灵魂石（Soul）获取按倍率翻倍
- 在 Mod 设置界面可调倍率（滑块，1x~100x）
- 游戏过程中固定，开局前调整

## 关键发现

### PlayData 是静态类
`PlayData` (Assembly-CSharp.dll) 是 `abstract sealed`（静态类），`Gold` 和 `Soul` 是静态属性

### Harmony 2.9 API 变更
- `Harmony.UnpatchAll(string)` → 已弃用，改用 `Harmony.UnpatchID(string)`

### 设置读取（非 ModData）
`ChronoArkMod.ModData` **不存在**。正确方式：
```csharp
var modInfo = ChronoArkMod.ModManager.getModInfo(this.ModId);
var entry = modInfo.GetSetting("GoldMultiplier") as ChronoArkMod.ModData.Settings.SliderSetting;
float value = entry.Value;
```

## Mod 最终代码结构

```
Mod/MultiplierMod/
├── ChronoArkMod.json       ← 清单 + 滑块设置
├── README.txt
├── Localization/
│   └── LangSystemDB.csv    ← 中/英/日/韩 本地化
└── Assemblies/
    ├── 0Harmony.dll        ← Harmony 2.9.0
    └── MultiplierMod.dll   ← 编译产物
```

## ChronoArkMod.json 关键字段
```json
{
    "id": "MultiplierMod",
    "Title": "MultiplierMod/ChronoArkMod/Title",
    "ModSettingEntries": [{
        "SettingType": "SliderSetting",
        "SettingKey": "GoldMultiplier",
        "DisplayName": "MultiplierMod/ChronoArkMod/GoldMultiplier/DisplayName",
        "InitValue": 2.0, "Max": 100.0, "Min": 1.0, "StepSize": 0.5
    }]
}
```

## 编译 （WSL + 便携 dotnet）
```bash
curl -sL "https://dot.net/v1/dotnet-install.sh" | bash
export PATH="$HOME/dotnet:$PATH"
dotnet build
```

## Harmony Prefix 关键逻辑
```csharp
public static bool GoldPrefix(ref int value)
{
    // 只翻倍正值（获得时），不翻倍 0（消耗时）
    if (value > 0 && GoldMul != 1f)
    {
        value = Mathf.Max(1, (int)(value * GoldMul));
    }
    return true; // 继续执行原 setter
}
```
