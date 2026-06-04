# Chrono Ark Mod 冲突检测

> 日期: 2026-05-12
> 游戏版本: XDGAME 免安装版（Unity Mono）

## 已知冲突矩阵

| Mod A | Mod B | 重叠功能 | 冲突级别 |
|-------|-------|---------|---------|
| **QualityLife** | **SlightlyBetterArk** | 加速控制、力量测试实时显示、地图标记（售货机/密道） | 🔴 高 |
| BattleStats | CardWinRateStatistics | 战斗UI/数据hook | 🟡 中 |
| DebugMode | 任何其他代码mod | 核心系统hook | 🟡 中 |
| BanItem | Backpack+ | 物品池修改 | 🟢 低 |

## 冲突诊断方法

### 方法1：功能重叠扫描（无游戏运行）

```python
# 检查两个 Mod 是否修改了相同的方法/资源
# 1. 对比 Assemblies/*.dll 中引用的一致的目标类名
# 2. 对比 gdata/ 目录下相同的 JSON 数据覆盖
```

### 方法2：二分排查法

```
1. 将 Mod/ 目录下所有文件夹移到 Mod_备份/
2. 启动游戏验证正常
3. 每次移回一半 Mod，启动测试
4. 出问题的批次 → 继续二分缩小范围
5. 最终锁定冲突的具体 Mod 对
```

### 方法3：症状 → 冲突映射

| 症状 | 最可能冲突对 |
|------|------------|
| 卡死、无法移动、点击失效 | QualityLife + SlightlyBetterArk |
| 战斗UI显示异常 | BattleStats + CardWinRateStatistics |
| 启动崩溃 | DebugMode + 任何Mod |
| 特定功能不生效 | 功能重叠的两个mod |

## 处理建议

1. **QualityLife vs SlightlyBetterArk**：二选一。推荐保留 SlightlyBetterArk（功能更全、更新更晚 2025.2），删除 QualityLife
2. **BattleStats vs CardWinRateStatistics**：二选一，推荐 BattleStats
3. **DebugMode**：只在需要调试时临时开启，平时禁用

## Chrono Ark Mod 安装结构速查

```
Mod/
├── ModName/
│   ├── ChronoArkMod.json    ← 必需，mod 清单
│   ├── Assemblies/           ← DLL 代码（Harmony patch）
│   │   ├── ModName.dll
│   │   ├── 0Harmony.dll     ← Harmony 依赖（通用）
│   │   └── Mono.Cecil.dll   ← MonoMod 依赖（通用）
│   ├── Localization/         ← 多语言 CSV
│   │   └── LangSystemDB.csv
│   ├── gdata/Add/            ← 新增游戏数据（JSON）
│   ├── gdata/Replace/        ← 替换游戏数据（JSON）
│   ├── Assets/               ← 资源文件（图片等）
│   └── Scripts/              ← 可选：动态编译 C# 脚本
└── ...
```
