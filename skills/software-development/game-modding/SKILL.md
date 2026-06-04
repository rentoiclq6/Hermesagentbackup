---
name: game-modding
title: 游戏逆向、Mod制作与Steam Workshop
description: 单机游戏修改全流程：卡关决策树→Unity Mod制作(BepInEx/Harmony)→Steam Workshop Mod搜索下载→内存修改(Frida)→逆向分析(Ghidra)。覆盖控制台/存档/配置/注入/MCP工具链。
tags: [game-modding, bepinex, harmony, steam-workshop, unity-modding, frida, ghidra]
---

# 游戏逆向与难度修改助手

## 工作流约定

- 非 trivial 问题（多步骤、需用户配合、有多个方案）必须先走 PLAN 模式，
  写 `.hermes/plans/` 文档，用户确认后再执行
- 遇到连续失败/卡顿时，先停下来总结所有根因，提出干净方案，再执行，
  不要逐个尝试不同解法
- 涉及 Windows 端服务的操作，必须明确标注哪些步骤需要用户手动完成

## 原则
- 只碰单机，不碰联机
- 优先最轻量方案（能不改代码就不改）
- 所有修改可逆（备份原文件）
- 出问题先系统性分析，不要逐个修
- **交付修改脚本时必须附完整使用说明**，包括：功能描述、副作用（如槽位覆盖/存档文件/原文件覆盖）、旧存档兼容性、如何关闭/还原
- **不要假设标准 API**：重度 Mod 游戏（如 RPG Maker VX Ace 魔改版）会删除/重命名/替换基类方法。
  - 每用到一个全局方法名（`$game_temp.in_battle`、`DataManager.max_savefiles` 等），
    先反查该游戏实际脚本源码，确认方法存在。
  - 游戏自定义方法名常与标准 VX Ace 不同，直接套标准模板会报 NoMethodError。

## 决策树（按优先级）

1. **官方控制台/难度选项？** → 搜 PCGamingWiki、"游戏名 console commands"
2. **存档可编辑？** → JSON/XML/明文直接改（备份！），加密 .sav → 放弃，改用注入方案
3. **配置文件？** → .ini/.cfg/.json 改数值
4. **游戏自带 Mod 系统？** → 有 `Mod/` 文件夹 + Mod API 类（如 `ChronoArkPlugin`）→ 走内置 Mod Loader，参考 `references/unity-modding.md` 方案 B
5. **Unity Mono 游戏？** → 参考 `references/unity-modding.md`，按方案 A (BepInEx) 或方案 B (内置Mod Loader) 执行
6. **RPG Maker VX Ace？** → Scripts.rvdata2 中代码是 Zlib 压缩后 Marshal 序列化存储。需要游戏内方法名的实地验证——重度魔改版（如 KingExit）会删除标准 API。详见 `references/rpg-maker-vx-ace.md`
7. **GameMaker？** → 改数据文件
8. **其他引擎？** → 其余用 Cheat Engine 或 Frida MCP（跨平台内存修改，见 `references/mcp-re-tools.md`）
9. **现成 Trainer/Mod？** → NexusMods、社区 Cheat Table
10. **需要静态逆向理解代码？** → GhidraMCP（见 `references/mcp-re-tools.md`）

## 跨引擎通用模式

### 数值修改三件套
改金钱/资源时防止三种 bug：
| Bug | 触发条件 | 防护 |
|-----|---------|------|
| 消耗时也翻倍 | 卖出/花费操作 | `value > current` 只对增加操作生效 |
| 读档时翻倍 | 存档恢复 | `current > 0` 跳过初始化赋值 |
| 初始值翻倍 | 新游戏开局 | 同上，`current > 0` 同时挡住 |

### 协程修改铁律
**永远不要用 `IntPrefix`（改参数）Patch 返回 `IEnumerator` 的协程方法。**
参数翻倍后被用作数组索引 → 越界 → NullReferenceException → 游戏卡死。
→ 改用 Postfix（只改返回值）、Transpiler、或在调用协程之前的纯数值方法上做 Patch。

### 系统性排查原则
用户报告 ≥2 次同类崩溃时：**停下来**，列出所有 Patch，按类型分类分析（协程？索引？参数类型？），**批量修复同类的全部 Patch**，不要逐个试。

### Patch 类型速查
| 目标 | 类型 | 签名关键 |
|------|------|---------|
| 改传入参数 | Prefix | `ref int __0` 或 `ref int 参数名` |
| 改返回值 | Postfix | `ref int __result` |
| 属性 setter | Prefix | Patch `set_PropertyName` |

## MCP 工具链（AI 可直接调用，但 Windows 端需手动准备）

**⚠️ 使用前必须告诉用户的一句话：**
每次 AI 决定建议使用 Frida 或 Ghidra 时，必须先输出如下标准提示，不得跳过：

```
══════════════════════════════════════════════
 需要用到 MCP 工具，但 Windows 端需要你先准备
══════════════════════════════════════════════
【Frida MCP】（内存扫描 / 运行时 Hook）
  → 启动 frida-server（管理员 PowerShell）：
      cd C:\Users\da\tools\frida
      .\frida-server-17.9.10-windows-x86_64.exe -l 0.0.0.0:27042
  → 启动目标游戏
  → 防火墙 27042 端口已放行（只需一次）
  ⚠ frida-server 不加 -l 0.0.0.0 只监听 127.0.0.1，WSL 连不上

【Ghidra MCP】（静态逆向分析）
  → 启动 Ghidra + 加载 GhidraMCP Extension
  → 打开一个已分析的项目/二进制
  → 防火墙 8080 端口已放行（只需一次）
  ⚠ Ghidra 较重，只在需要理解新逻辑时开启

准备好后告诉我，我继续操作。
══════════════════════════════════════════════
```

**Ghidra MCP** — 静态逆向，适合分析代码结构、找目标方法签名、查看反编译伪代码
  - 工具前缀：`mcp_ghidra_*`
  - 典型场景：Mod 开工前翻函数定义 → 确定 Harmony target 方法

**Frida MCP** — 动态内存/运行时 Hook，适合搜数值、热补丁测试、找隐藏数据
  - 工具前缀：`mcp_frida_*`
  - 典型场景：验证 Ghidra 分析结果、不用重启就试 Hook、修改跑起来的数值

**工作流中的位置**：Ghidra（离线分析）→ Frida（运行时验证）→ 写 Mod 代码

**注意事项**：两个工具都依赖 WSL→Windows 网络连接，Windows 端服务（Ghidra/frida-server）需要用户手动启动，详见 `references/mcp-re-tools.md`。连接失败的坑见 `references/frida-mcp-connection-pitfalls.md`（关键发现：socket.setdefaulttimeout() 对 Frida 无效）。

## 工具速查
| 工具 | 用途 |
|------|------|
| BepInEx 5.4 | Unity Mono 注入 |
| Cheat Engine | 通用内存修改 |
| PCGamingWiki | 控制台/秘籍 |
| NexusMods | 已有 Mod |
| **WorkshopDL** | Steam Workshop Mod 下载（参考 `references/steam-workshop.md`） |
| **Ghidra MCP** | AI 直接反编译/查函数（需 Windows 端提前启动 Ghidra，见 `references/mcp-re-tools.md`） |
| **Frida MCP** | AI 直接扫内存/Hook（需 Windows 端提前启动 frida-server） |

## 模板文件 (`templates/`)

BepInEx/Harmony C# Unity Mod 模板（搬运自存档技能 `unity-modding`）：

| 文件 | 用途 |
|------|------|
| `Plugin.cs` | 基础 Harmony Patch 插件骨架 |
| `Plugin_Generic.cs` | 带通用工具方法的插件 |
| `Plugin_Simple.cs` | 最简单文件插件 |
| `build_mod.bat` | Windows 批处理构建脚本 |
| `build_mod.ps1` | PowerShell 构建脚本 |
| `mod.csproj` | C# 项目文件 (.NET Framework 4.x) |

## Unity Modding（BepInEx + Harmony）

Unity Mono 游戏有两条 Mod 路线：

- **内置 Mod Loader**（如 Chrono Ark）→ 游戏根目录有 `Mod/` 文件夹 → 方案 B（参考 `references/unity-modding.md` 方案 B）
- **BepInEx 注入** → 无内置系统 → 安装 BepInEx 5.4 → 编写 Harmony Patch（参考 `references/unity-modding.md` 方案 A）

关键陷阱：
- **协程崩溃**：IntPrefix Patch 协程方法 → 参数翻倍被当索引用 → 改用 Postfix
- **获得 vs 消耗**：属性 setter Prefix 必须 `value > current` 判断
- **读档翻倍**：`current > 0` 跳过初始化赋值
- **Config 不生成**：BepInEx 5 必须显式 `Config.Save()`

详情见 `references/unity-modding.md`。

## Steam Workshop Mod 查找与下载

从创意工坊找 Mod 并下载到本地：

1. 用 AppID 打开 Workshop 浏览页（按订阅量排序）
2. 从列表提取 PublishedFileID
3. 选择下载方式：Steam 客户端订阅 / SteamCMD自动化（需登录）/ WorkshopDL（Windows GUI）
4. 放入游戏对应 Mod 目录

常见陷阱：
- Steam Guard / 2FA 会卡住 SteamCMD 登录
- Darkest Dungeon Mod 不识别：检查 project.xml 的语言代码和 Visibility 标签
- BaseLib (Harmony 补丁) 使内存修改器失效
- 不要从 DLL 类名猜控制台命令名——先输 `help` 看真实语法

详情见 `references/steam-workshop.md`。

## 子流程
- Unity Mono 专属 → `references/unity-modding.md`
- Chrono Ark 内置 Mod Loader 方案 → `references/unity-modding.md` 方案 B
- Steam Workshop Mod 下载 → `references/steam-workshop.md`
- 协程崩溃完整案例 → `references/unity-modding.md` Pitfalls
- **RPG Maker VX Ace 脚本修改**（Scripts.rvdata2 结构、方法名核实、自动存档模板）→ `references/rpg-maker-vx-ace.md`

## 环境依赖
- Ghidra 需要 JDK 21+。从 WSL 安装/配置 Java 环境变量 → `references/wsl-windows-env.md`（含 PATH 陷阱）
- Ghidra MCP 连接调试记录 → `references/connectivity-debug-20260516.md`
- 所有 MCP 工具（Ghidra + Frida）的完整安装、防火墙配置、WSL2 网络陷阱 → `references/mcp-re-tools.md`
