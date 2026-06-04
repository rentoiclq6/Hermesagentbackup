---
name: unity-modding
title: Unity Mono 游戏 Mod 制作（BepInEx + Harmony）
description: 为 Unity Mono 游戏制作客户端 Mod——分析游戏结构、安装 BepInEx、编写 Harmony Patch、编译部署、调试。也覆盖 Chrono Ark 等内置 Mod Loader 游戏。
---

# Unity Mono 游戏 Mod 制作

## 前置判断（3 个确认，不动手之前必做）

### 1. Mono 还是 IL2CPP？
| 特征 | Mono | IL2CPP |
|------|------|--------|
| `游戏_Data/Managed/` | ✅ 有 | ❌ 无 |
| `Assembly-CSharp.dll` | ✅ 1–2MB | ❌ 无 |
| `GameAssembly.dll` | ❌ 无 | ✅ 有 |

本 skill 仅覆盖 **Mono**。IL2CPP 需 MelonLoader，路线不同。

### 2. 游戏有内置 Mod 系统吗？
- 游戏根目录有 `Mod/` 文件夹
- `Assembly-CSharp.dll` 中有 Mod API 类（如 `ChronoArkMod.Plugin.ChronoArkPlugin`）
- **有 → 走方案 B（内置 Mod Loader），不装 BepInEx**

### 3. 用户要做什么？
- 改数值/难度 → Harmony Patch
- 加新内容 → 需理解资源加载，范围更大

---

## 方案 A：BepInEx + Harmony（无内置 Mod 加载器）

### 五步流程

**1. 分析**：`strings Assembly-CSharp.dll | grep -iE "coin|gold|damage|reward"` 找目标方法名

**2. 安装 BepInEx 5.4 x64**：解压到游戏根目录，文件结构见 BepInEx 官方文档

**3. 编写（扫描优先，不猜方法签名）**：
- 第一版只做扫描，完整记录所有候选方法签名到日志
- 确认后第二版精确 Patch

**Harmony 关键模式：**
```csharp
// 基础 Patch
[HarmonyPatch(typeof(TargetClass), "MethodName")]
static class MyPatch {
    [HarmonyPrefix] static bool Prefix(ref int param) { param *= 2; return true; }
    [HarmonyPostfix] static void Postfix(ref int __result) { __result *= 2; }
}

// 属性 setter（区分获得 vs 消耗）— 核心！
[HarmonyPrefix, HarmonyPatch(typeof(PlayData), "set_Gold")]
static bool GoldPrefix(ref int value) {
    int current = PlayData.Gold;
    if (current > 0 && value > current) {  // 只对增加操作生效
        int gain = value - current;
        value = current + (int)(gain * multiplier);
    }
    return true;
}
```

**4. 编译**：
- 首选 `dotnet build`（.NET SDK，支持现代 C#）
- 备选系统 csc（仅 C# 5，禁 `$""`、`nameof()`、`?.`）
- csproj 引用：`0Harmony.dll` + `Assembly-CSharp.dll` + `UnityEngine.dll`

**5. 测试**：看 `BepInEx/LogOutput.log`，控制台默认关闭需手动开启

---

## 方案 B：内置 Mod Loader（Chrono Ark 模式）

### 目录结构
```
Mod/YourMod/
├── ChronoArkMod.json        # 清单（含 ModSettingEntries）
├── Assemblies/
│   ├── YourMod.dll
│   └── 0Harmony.dll
└── Localization/
    └── LangSystemDB.csv     # 本地化
```

### ChronoArkMod.json 关键字段
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

### C# 基类与配置读取
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

### 编译（WSL）
```bash
curl -sL "https://dot.net/v1/dotnet-install.sh" | bash
export PATH="$HOME/dotnet:$PATH"
dotnet build  # csproj target: net472
```

---

## 方案 C：BepInEx Config（可配置化）

```csharp
static ConfigEntry<float> CoinMul;
void Awake() {
    CoinMul = Config.Bind("倍率", "CoinMul", 3f, "金币倍率");
    Config.Save();  // ← 必须！否则 .cfg 不生成
}
// Patch 中引用: CoinMul.Value
```

---

## 方案 D：深层嵌套字段访问（反射链）

当目标 `A.B.C.D.Field` 时，逐层 GetValue + SetValue。使用 `AccessTools.TypeByName` + `GetField` + `BindingFlags`。

---

## Pitfalls（关键陷阱）

1. **协程崩溃**：`IntPrefix` Patch 协程方法 → 参数翻倍被当索引用 → 崩。改用 Postfix 或 Patch 调用协程之前的纯数值方法。真实案例见 `game-modding` skill 协程铁律。

2. **获得 vs 消耗**：属性 setter 的 Prefix 必须 `value > current` 判断，否则花费/修理也翻倍。

3. **读档翻倍**：`current > 0` 跳过初始化赋值。

4. **Config 不生成**：BepInEx 5 必须显式 `Config.Save()`。

5. **Harmony 2.9 弃用 API**：`harmony.UnpatchAll(string)` 已弃用，改用 `Harmony.UnpatchID("id")`。

6. **C# 版本**：系统 csc 仅 C# 5，用 `dotnet build` 解决。

## 诊断（mod 没生效时）
1. BepInEx 加载了？→ 看 `LogOutput.log`
2. 控制台开了？→ `BepInEx.cfg` → `[Logging.Console] Enabled = true`
3. 插件被跳过？→ 日志搜 `Skipping`
4. Patch 失败？→ 日志搜 `Failed to patch`
5. Hook 触发？→ 加 Debug.Log Prefix 验证
