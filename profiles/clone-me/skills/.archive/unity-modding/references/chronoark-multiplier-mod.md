# Chrono Ark MultiplierMod — 制作实录（2026-05）

完整制作记录，涵盖 Unity 2018.4 Mono + 内置 Mod Loader + Harmony 2.9 的完整工作流。

## 目标

- 金钱（Gold）和灵魂石（Soul）获取按倍率翻倍
- 消耗时不变
- 在 Mod 设置界面可调倍率（滑块 1x~100x）
- 游戏过程中倍率固定，开局前调整
- 读档时存档数值不受影响

## 关键发现

### PlayData 是静态类

`PlayData` (Assembly-CSharp.dll) 是 `abstract sealed`（静态类），`Gold` 和 `Soul` 是静态属性。

```csharp
// 用 dotnet reflection 验证
var pd = Assembly.LoadFrom("lib/Assembly-CSharp.dll").GetTypes()
    .First(t => t.Name == "PlayData");
Console.WriteLine($"IsStatic: {pd.IsAbstract && pd.IsSealed}");
Console.WriteLine($"Gold set static: {pd.GetProperty("Gold").SetMethod.IsStatic}");
```

### Harmony 2.9 API 变更

- ❌ `harmony.UnpatchAll(string)` — 已弃用（编译报 CS0619）
- ✅ `Harmony.UnpatchID("com.chronoark.multipliermod")` — 正确用法（静态方法）

### 设置读取（非 ModData）

`ChronoArkMod.ModData` **不存在**。正确方式：

```csharp
void LoadSettings()
{
    var modInfo = ChronoArkMod.ModManager.getModInfo(this.ModId);
    if (modInfo != null)
    {
        var gEntry = modInfo.GetSetting("GoldMultiplier") as SliderSetting;
        if (gEntry != null) GoldMul = gEntry.Value;
    }
}
```

### SliderSetting 类结构

| 成员 | 类型 | 说明 |
|------|------|------|
| `Value` | float (property) | 当前设定值 |
| `_value` | float (field) | 底层存储字段 |
| `MinValue` | float | 最小值 |
| `MaxValue` | float | 最大值 |
| `StepSize` | float | 步进 |
| `Key` | string (inherited) | 设置标识符 |

### 本地化 CSV 列序

```
Key,Type,Desc,Korean,English,Japanese,Chinese,Chinese-TW
```

## 倍率逻辑进化史

### v1 (bug): 无条件倍数 — 消耗也会翻倍
```csharp
if (value > 0) value = value * multiplier;
// ❌ 消耗 200: (3000-200)=2800 → 2800*2=5600 ❌ 越花越多
```

### v2 (fixed): 只对增加翻倍 + 防读档
```csharp
int current = PlayData.Gold;      // setter 执行前的旧值
if (current > 0                   // 已初始化（防读档）
    && value > current            // 新值更大（获得，非消耗）
    && GoldMul != 1f)             // 倍率开启
{
    int gain = value - current;
    value = current + Mathf.Max(1, (int)(gain * GoldMul));
}
```

### v1.1.0: 新增血雾等级修改

通过多层对象引用链直接修改游戏内存中的 `BloodyMist.Level`：

```csharp
// SaveManager.savemanager (singleton) → TempSave → bMist → Level
var smType = AccessTools.TypeByName("SaveManager");
var smField = smType.GetField("savemanager", BindingFlags.Public | BindingFlags.Static);
var smInstance = smField.GetValue(null);
var tempSaveField = smType.GetField("TempSave", BindingFlags.Public | BindingFlags.Instance);
var tempSave = tempSaveField.GetValue(smInstance);
var bmInstance = bMistField.GetValue(tempSave);   // bMist : BloodyMist (带 'y')
var currentLevel = (int)levelField.GetValue(bmInstance);
if (currentLevel < BloodyMistLevel)
    levelField.SetValue(bmInstance, BloodyMistLevel);
```

注意类名是 `BloodyMist`（带 y），不是 `BloodMist`。`TempSaveData.bMist` 字段类型为 `BloodyMist`。

## 编译命令

```bash
# 便携 dotnet（WSL 无需 sudo）
curl -sL "https://dot.net/v1/dotnet-install.sh" | bash
export PATH="$HOME/dotnet:$PATH"

# 编译
cd ~/chronoark_multiplier_mod
dotnet build
cp bin/Debug/net472/MultiplierMod.dll "Mod/MultiplierMod/Assemblies/"
```

## Mod 目录结构

```
Mod/MultiplierMod/
├── ChronoArkMod.json       ← 清单 + 滑块设置
├── README.txt
├── Localization/
│   └── LangSystemDB.csv    ← 中/英/日/韩 本地化
└── Assemblies/
    ├── 0Harmony.dll        ← Harmony 2.9.0
    └── MultiplierMod.dll   ← 编译产物 (8.5KB)
```
