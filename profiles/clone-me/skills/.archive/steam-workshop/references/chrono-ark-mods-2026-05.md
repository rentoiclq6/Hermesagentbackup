# Chrono Ark (超时空方舟) 模组下载 & 安装记录
> 日期: 2026-05-12
> AppID: 1188930
> 游戏类型: Unity Mono 国产独立卡牌肉鸽
> 游戏版本（测试用）: XDGAME 免安装版

## 目标路径
`D:\mygit\QuarkPanTool\downloads\chrono_ark_mods\`

## 用户指定模组列表（按最热门订阅排序）

| # | 模组名 | 描述 | Workshop ID | 作者 |
|---|--------|------|-------------|------|
| 1 | **Backpack+** | 背包栏数量增加到36格 | 3361965030 | Midana |
| 2 | **Hidden Treasure Hint** | 在地图上自动标记隐藏宝箱的可能位置 | 3361964944 | Midana |
| 3 | **CardWinRateStatistics** | 显示每张卡牌的抓取胜率及玩家评价 | 3210142135 | Nephthys |
| 4 | **BattleRestart** | 增加"重新战斗"按钮，悔棋功能 | 3363754284 | windypanda1 |
| 5 | **BattleStats** | 统计全队输出、治疗等详细数据 | 2981171006 | surprise4u |
| 6 | **QualityLife** | 整合加速移动、提升售货机便利性等优化 | 2949998001 | Swind |
| 7 | **SlightlyBetterArk** | 可手动移除露西的诅咒技能等多项优化 | 2969177460 | surprise4u |
| 8 | **DebugMode** | 图鉴中直接拿道具、开启控制台等调试功能 | 2949757673 | Swind |
| 9 | **Ban Item** | 可禁用不喜欢的道具或技能，定制物品池 | 3250382789 | surprise4u |

## Chrono Ark Mod 安装指南

### 游戏文件结构
```
游戏根目录/
├── Mod/                       ← Mod 目录（已存在，为空）
├── ChronoArk_Data/
│   ├── Managed/               ← Unity Mono DLL
│   ├── StreamingAssets/
│   │   ├── Mod/               ← 官方示例配置（HowtoStatChange.txt）
│   │   ├── CampSDExample/     ← 营地素材示例
│   │   └── ...
│   └── ...
├── x64/Master/ChronoArk.exe   ← 64位启动
├── x86/Master/ChronoArk.exe   ← 32位启动
└── 游戏启动说明.txt
```

### Mod 安装结构
每个 Workshop 模组是一个文件夹，放入 `Mod/` 目录下：

```
Mod/
├── Backpack+/
│   ├── ChronoArkMod.json      ← Mod 清单（JSON，必需）
│   └── Assemblies/
│       └── Backpack+.dll      ← 编译后的 C# 程序集
├── QualityLife/
│   ├── ChronoArkMod.json
│   ├── Assemblies/
│   │   └── QualityLife.dll
│   └── WIKI/                  ← 文档（可选）
└── ...
```

### ChronoArkMod.json 格式（推论）
从 BasicMethods 等 Mod 的描述中推断，清单文件可能包含：
- `Name`: Mod 名称
- `Author`: 作者
- `Version`: 版本号
- `GameVersion`: 兼容的游戏版本
- `Dependencies`: 依赖的其他 Mod ID 列表
- `Assemblies`: 需要加载的 DLL 文件列表

### Mod 启用和管理
| 操作 | 方法 |
|------|------|
| **启用/禁用** | 游戏主菜单 → Mod 选项 → 勾选/取消 |
| **卸载** | 删除 `Mod\<Mod名>\` 整个文件夹 |
| **临时禁用** | 把 Mod 文件夹移出 `Mod\` 目录 |
| **配置** | 部分 Mod（SlightlyBetterArk, QualityLife）在游戏设置中有专属开关 |
| **排序冲突** | 功能重叠的 Mod 可能冲突，出问题时先全禁用再逐个启用排查 |

### 注意事项
1. **版本兼容**: Mod 标注了 `Game Version x.x`，版本不匹配可能报错
2. **BepInEx**: 老版本 Mod 使用 BepInEx，新版本用游戏自带 Mod 加载器。如果 x64 下有 BepInEx 文件夹，删除它以免冲突
3. **日志**: 崩溃时检查 `ChronoArk_Data/output_log.txt`
4. **动态编译**: BasicMethods Mod 支持在 Mod 文件夹下放 `Scripts/` 目录，自动编译 `.cs` 文件为动态程序集

## WorkshopDL 信息
- 仓库: `imwaitingnow/WorkshopDL`（不是 VovoloGames/WorkshopDL！GitCode 上是镜像，内容相同）
- 版本: 2.0.4
- 下载: `D:\mygit\QuarkPanTool\downloads\WorkshopDL_installer.exe`
- 使用: 安装后 → 输入 Workshop Homepage = `https://steamcommunity.com/app/1188930/workshop/` → 逐个输入 Mod URL 或 ID → 下载
- 内部依赖: 使用 SteamCMD 下载，首次启动会自动下载和配置 SteamCMD
- 限制: Windows GUI 工具，不能在 WSL CLI 中运行

## 下载尝试记录

| 方法 | 结果 | 问题 |
|------|------|------|
| SteamCMD (Linux, WSL) | ❌ | 缺少 32 位库，无 sudo 权限 |
| SteamCMD (Windows exe via WSL) | ⏳ 超时 | 登录后 Steam Guard 等待验证码 |
| smods.ru | ❌ | Cloudflare 验证 |
| ggntw.com/steam | ❌ | JS 渲染，需注册 |
| steamworkshop.download | ❌ | 连接关闭（已下线） |
| Python `steam` 库 | ❌ | protobuf + eventemitter 兼容性问题 |
| WorkshopDL 安装程序 | ✅ 已下载 | 需用户在 Windows GUI 中操作 |
