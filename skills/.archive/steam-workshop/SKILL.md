---
name: steam-workshop
title: Steam Workshop 模组搜索与下载
description: 查找 Steam 创意工坊热门模组，获取文件信息，通过 SteamCMD 下载。覆盖游戏 AppID 定位、Workshop 浏览、订阅量排序、文件 ID 提取、steamcmd 安装与下载。
---

# Steam Workshop 模组搜索与下载

## 触发条件
用户要求：查找模组、下载创意工坊内容、找热门 Mod、安转 / 下载 Steam Workshop 物品。

## 前置知识

| 概念 | 说明 |
|------|------|
| AppID | Steam 游戏的数字 ID（如 Chrono Ark = 1188930） |
| PublishedFileID | Workshop 物品的数字唯一 ID（如 3361965030） |
| steamcmd | Valve 官方 CLI 工具，可下载 Workshop 内容 |

---

## 工作流程

### 1. 定位游戏 AppID

通过 Steam Store API 搜索：

```bash
curl -s "https://store.steampowered.com/api/storesearch/?term=游戏名&l=english&cc=us"
```

返回 JSON 中的 `items[].id` 即为 AppID。

> **注意**：中文游戏名可能搜不到，先试英文名。如果不知英文名，可先用浏览器搜索确认。

### 2. 浏览 Workshop 热门模组

直接用 URL 跳转到按"最多订阅"排序的浏览页：

```
https://steamcommunity.com/workshop/browse/?appid={AppID}&browsesort=totaluniquesubscribers&p=1
```

参数说明：
- `browsesort=totaluniquesubscribers` — 按总订阅数降序（即最热门）
- `p=1` — 页码
- 可选：`&requiredtags[]=GamePlay` 等标签过滤

### 3. 提取模组列表

从浏览器 snapshot 中可直接读到模块名称、作者。用 `browser_console` 提取文件 ID：

```javascript
Array.from(document.querySelectorAll('a[href*="sharedfiles"]'))
  .map(a => ({text: a.textContent.trim().substring(0, 60), href: a.href}))
  .filter(x => x.href && !x.href.includes('browse') && x.text)
```

每个模组的 URL 格式：`https://steamcommunity.com/sharedfiles/filedetails/?id={PublishedFileID}`

点击进入详情页可看到文件大小、订阅数、评分、作者。

### 4. 下载方式选择

#### 方案 A：Steam 客户端直接订阅（推荐给已安装 Steam 的用户）
用户登录 Steam → 打开 Workshop 页面 → 点 Subscribe → 文件会自动下载到 Steam 缓存目录：
- Windows：`C:\Program Files (x86)\Steam\steamapps\workshop\content\{AppID}\{PublishedFileID}\`
- 用户也可直接使用 Steam 客户端内的"订阅"按钮

> **用户偏好提示**：如果用户明确说「禁止用 SteamCMD / 用 WorkshopDL」，**不要尝试绕过**。立即停止 SteamCMD 方案，直接提供 WorkshopDL 下载链接和操作指引。重试只会让用户更烦躁。

#### 方案 B：SteamCMD 下载（适合自动化/无 GUI 环境）

##### 安装 steamcmd（WSL 无 sudo 方案）

```bash
mkdir -p ~/steamcmd
cd ~/steamcmd
curl -sL https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz | tar xz
```

##### 下载 Workshop 物品

```bash
# 首次需要登录（交互式输入密码）
~/steamcmd/steamcmd.sh +login <username> +quit

# 下载 Workshop 物品
~/steamcmd/steamcmd.sh \
  +login <username> \
  +workshop_download_item <AppID> <PublishedFileID> \
  +quit
```

##### 关键路径
下载完成后文件输出到 `~/Steam/steamapps/workshop/content/{AppID}/{PublishedFileID}/`

##### 批量下载脚本模板

```bash
#!/bin/bash
APPID=1188930
IDS=(3275873272 3016820036 3241429473 3210142135 3358768980)
for id in "${IDS[@]}"; do
  ~/steamcmd/steamcmd.sh +login "$1" +workshop_download_item $APPID $id +quit
done
```

---

### 4b. 搜索特定模组

在 Workshop 浏览页按名称搜索：

```
https://steamcommunity.com/workshop/browse/?appid={AppID}&searchtext={关键词}&browsesort=totaluniquesubscribers
```

从搜索结果中用 `browser_console` 提取 ID（方法同第 3 步）。

---

### 4c. 获取模组元数据（Steam Web API）

不需要登录，可获取模组文件大小、订阅数、评分等信息：

```bash
curl -s -X POST "https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/" \
  -d "itemcount=1" \
  -d "publishedfileids[0]={PublishedFileID}"
```

关键返回字段：
- `file_size` — 文件大小（字节）
- `subscriptions` / `lifetime_subscriptions` — 当前 / 历史订阅数
- `favorited` — 收藏数
- `hcontent_file` — 文件内容哈希（Steam CDN 定位用，不是下载 URL）
- `file_url` — 通常为空，Steam 不公开直接下载链接
- `creator` — 创作者的 SteamID

> ⚠️ 该 API 返回元数据但**不返回可下载的 URL**。实际下载仍需 Steam 客户端认证。

---

### 用户偏好：WorkshopDL vs SteamCMD

某些用户可能明确要求使用 **WorkshopDL** 而非直接使用 SteamCMD。**如果用户说「禁止用 SteamCMD / 用 WorkshopDL」，立即停止所有 SteamCMD 尝试，直接提供 WorkshopDL 下载链接和操作指引。不要试图绕过这个要求，反复重试 SteamCMD 只会让用户更烦躁。**

WorkshopDL 是 Windows GUI 工具，封装了 SteamCMD 的复杂性：
- 仓库：`imwaitingnow/WorkshopDL`（注意不是 `VovoloGames/WorkshopDL`）
- 类型：Windows GUI（Clickteam Fusion 2.5），**不能在 WSL CLI 中运行**
- 下载：`curl -L -o WorkshopDL_installer.exe "https://github.com/imwaitingnow/WorkshopDL/releases/download/2.0.4/WorkshopDL.2.0.4_installer.exe"`
- 仓库：`imwaitingnow/WorkshopDL`（不是 `VovoloGames/WorkshopDL`）
- 版本：当前最新 2.0.4
- 下载：`curl -L -o WorkshopDL_installer.exe "https://github.com/imwaitingnow/WorkshopDL/releases/download/2.0.4/WorkshopDL.2.0.4_installer.exe"`
- 限制：Windows GUI 工具，**不能在 WSL CLI 中运行**

> ⚠️ 如果用户说「禁止用 SteamCMD / 用 WorkshopDL」，不要尝试绕过 — 直接提供 WorkshopDL 下载链接和操作指引。

## 下载后的安装：游戏模组目录

下载 Workshop 内容后，需要放入游戏的 mod 目录才能生效。**不同类型的游戏有不同的 mod 安装结构。**

### 通用规则

| 游戏类型 | Mod 目录 | 文件夹命名规则 |
|---------|---------|--------------|
| 大多数 Workshop 游戏 | `{游戏根目录}/mods/` 或 `{游戏根目录}/Mods/` | 建议用 `project.xml` 中的 `<Title>` 作为文件夹名 |
| Unity 游戏 (BepInEx) | `{游戏根目录}/BepInEx/plugins/` | 通常用 DLL 文件名 |

### Darkest Dungeon (暗黑地牢) — Mod 安装规范

```
游戏根目录/
├── mods/                       ← 所有 Mod 放这里
│   ├── {Mod Display Name}/     ← 每个 Mod 一个文件夹，名称用 project.xml 中的 <Title>
│   │   ├── project.xml         ← Mod 清单文件（用来识别名称）
│   │   ├── preview_icon.png    ← 预览图
│   │   ├── modfiles.txt        ← 文件清单
│   │   ├── campaign/           ← 战役数据
│   │   ├── heroes/             ← 英雄/职业数据
│   │   ├── localization/       ← 本地化文本
│   │   └── ... (其他资源文件)
│   └── ...
├── heroes/
├── dungeons/
└── ...
```

**启用方式**：启动游戏 → Settings → 勾选 Mod → 应用。部分 Mod 需重启游戏生效。

**WorkshopDL → DD1 安装流程**：
1. WorkshopDL 下载到 `WorkshopDL\steamcmd\steamapps\workshop\content\262060\{PublishedFileId}\`
2. 将 `{PublishedFileId}` 整个文件夹 **复制到** `{游戏根目录}/mods/`
3. **重命名文件夹**为 `project.xml` 中 `<Title>` 定义的名称（如 `840391233` → `Level Restrictions Removal`）
4. 启动游戏勾选启用

### Chrono Ark (超时空方舟) Mod 安装结构

```
游戏根目录/
├── Mod/                       ← 所有 Mod 放这里，游戏自动扫描
│   ├── ModName/               ← 每个 Mod 一个子文件夹
│   │   ├── ChronoArkMod.json  ← Mod 清单文件（必需！）
│   │   ├── Assemblies/        ← C# DLL 代码文件
│   │   │   └── Mod.dll
│   │   ├── Scripts/           ← 可选：动态编译 C# 脚本 (.cs)
│   │   └── ... (其他资源文件)
│   └── ...
├── ChronoArk_Data/
└── ...
```

**启用/管理方式**：
- 游戏主菜单 → Mod 选项 → 勾选启用/禁用
- 直接删除 `Mod/ModName/` 文件夹可卸载
- 部分 Mod 在游戏设置中有专属开关（如 SlightlyBetterArk、QualityLife）

## 下载方式汇总

| 方式 | 适用场景 | 需要账号 | 需要游戏拥有 | 备注 |
|------|---------|---------|------------|------|
| Steam 客户端订阅 | 用户有 Steam GUI | ✅ | ✅ | 最简单 |
| SteamCMD | 自动化/无 GUI | ✅ | ✅ | 官方工具 |
| WorkshopDL (GUI) | 用户想用图形化工具 | ✅ | ✅ | 封装了 SteamCMD |
| smods.ru | 网页下载 | ❌ | ❌ | ⚠️ Cloudflare 拦截，不可靠 |
| ggntw.com/steam | 网页下载 | ✅ 需注册 | ❌ | JS 渲染，不可靠 |
| Steam Web API | 仅获取元数据 | ❌ | ❌ | 无下载 URL |

### WorkshopDL 工具

当用户明确要求使用 WorkshopDL 时，或 SteamCMD 因 Steam Guard / 2FA 无法使用时，改用 WorkshopDL：

```bash
# 下载（Windows GUI 工具）
curl -L -o /mnt/d/path/WorkshopDL_installer.exe \
  "https://github.com/imwaitingnow/WorkshopDL/releases/download/2.0.4/WorkshopDL.2.0.4_installer.exe"
```

- 仓库：`imwaitingnow/WorkshopDL`（注意不是 `VovoloGames/WorkshopDL`）
- GitCode 镜像：`gh_mirrors/wo/WorkshopDL`（README 里有完整说明）
- 类型：Windows GUI（Clickteam Fusion 2.5），**不能在 WSL CLI 中运行**
- 内部仍使用 SteamCMD 下载，但对用户更友好
- 安装后操作：输入 Workshop Homepage URL → 输入 Mod URL → 点击 Download
- 支持队列批量下载、集合下载、SteamWebAPI 模式

**WorkshopDL 默认输出目录结构：**

下载后的文件存放在 WorkshopDL 安装目录内（不是游戏目录）：
```
{WorkshopDL_install_dir}/steamcmd/steamapps/workshop/content/{AppID}/{PublishedFileId}/
```

例如 `C:\Users\{username}\WorkshopDL\steamcmd\steamapps\workshop\content\262060\840391233\`

每个 PublishedFileId 文件夹内包含 `project.xml`（定义 Mod Title）、`preview_icon.png`、`modfiles.txt` 以及实际的游戏资源文件。

**从 WorkshopDL 到游戏 Mod 目录的安装流程：**

1. 找到 WorkshopDL 输出目录中的 `{PublishedFileId}/` 文件夹
2. 将整个文件夹**复制**到游戏的 `mods/` 子目录
3. **重命名**文件夹为 `project.xml` 中 `<Title>` 定义的名称（这会决定 Mod 管理器中的显示名）
4. 启动游戏 → Settings → 勾选启用

> 🔴 **用户明确说「禁止用 SteamCMD」时，不要试图绕过。** 立即停止所有 SteamCMD 尝试，直接提供 WorkshopDL 下载链接和操作指引。重试 SteamCMD 只会让用户更烦躁。

---

### 5. 详细模组数据提取（评分、订阅量、元数据）

从 Workshop 列表页找到感兴趣的模组后，进入单个模组详情页提取结构化数据。

#### 5a. 进入详情页

```
https://steamcommunity.com/sharedfiles/filedetails/?id={PublishedFileID}
```

#### 5b. 提取关键数据

用 `browser_snapshot` 读取，或用 `browser_console` 直接提取：

```javascript
// 1. 提取评分数（页面标题区域显示 "X,XXX ratings"）
// 用 browser_snapshot 直接看 StaticText 中的数字

// 2. 提取订阅/收藏/访问统计（LayoutTable 中）
// snapshot 中可见带数字的 LayoutTableCell

// 3. 提取文件信息
// File Size / Posted / Updated 三个字段在 snapshot 的 StaticText 中
```

**详情页关键信息分布：**

| 数据 | 位置 | 示例 |
|------|------|------|
| 评分 | 标题区域 StaticText | `"5,792 ratings"` |
| 订阅量 | LayoutTable · LayoutTableCell | `483,065 Current Subscribers` |
| 收藏数 | LayoutTable · LayoutTableCell | `13,816 Current Favorites` |
| 访问量 | LayoutTable · LayoutTableCell | `1,057,647 Unique Visitors` |
| 文件大小 | Stat 区域 StaticText | `180.947 KB` |
| 发布/更新 | Stat 区域 StaticText | 两条日期 |
| 标签 | Tags 区域 link | `Difficulty`, `Balance`, `New Class` |
| 作者 | CREATED BY 区域 link | 作者名 + 离线/在线状态 |
| 前置依赖 | REQUIRED ITEMS 区域 link | 要求先装其他 Mod |

#### 5c. 批量提取订阅列表数据

从列表页用 `browser_console` 快速抓取所有可见项的名称和链接：

```javascript
// 提取当前页所有 Mod 的名称和 URL
JSON.stringify(Array.from(document.querySelectorAll('a[href*="filedetails"]'))
  .filter(a => a.href.match(/filedetails\/\?id=\d+$/))
  .map(el => ({
    name: el.innerText.replace(/\s+/g, ' ').trim().substring(0, 80),
    url: el.href
  })))
```

#### 5d. 输出推荐格式

当用户问"有什么好 Mod"时，结构化输出：

```
| Mod 名称 | 评分/订阅数 | 类型 | 说明 |
|---------|------------|------|------|
| ...     | ...        | ...  | ...  |
```

按分类组织：QoL 必备 → 职业 Mod → 大修 → UI/视觉。

---

## Troubleshooting：Darkest Dungeon Mod 不识别/不加载

当用户安装 Mod 后游戏识别不到（mods 文件夹有子目录但游戏 Mod 管理器不显示），依次检查：

### 1. `project.xml` 无效语言代码

DD 识别以下语言代码：`english`, `schinese`, `tchinese`, `russian`, `koreana`, `japanese`, `french`, `german`, `spanish`, `polish`, `brazilian`, `italian`。

**常见错误**：`<Language>chinese</Language>` → **非法的**，应改为 `<Language>schinese</Language>`（简体中文）。如果使用 `chinese`，游戏可能跳过该 Mod。

### 2. `project.xml` Visibility 标签

检查 `<Visibility>` 标签值。`<Visibility>private</Visibility>` 可能会导致某些版本的 DD 跳过加载。应改为 `<Visibility>public</Visibility>`。

### 3. 确认 `project.xml` 和 `modfiles.txt` 都存在

每个 Mod 子目录下必须同时有这两个文件。`modfiles.txt` 中引用的所有文件路径必须实际存在于 Mod 目录中。

快速检查脚本参考：
```bash
# 检查每个 Mod 的 project.xml 语言和可见性
for d in /path/to/mods/*/; do
  echo "=== $(basename "$d") ==="
  grep -o '<Language>.*</Language>' "$d/project.xml" 2>/dev/null || echo "  no project.xml"
  grep -o '<Visibility>.*</Visibility>' "$d/project.xml" 2>/dev/null
  echo ""
done

# 检查 modfiles.txt 中第一个文件是否存在
for d in /path/to/mods/*/; do
  first=$(head -1 "$d/modfiles.txt" 2>/dev/null | awk '{print $1}')
  if [ -n "$first" ] && [ -f "$d/$first" ]; then
    echo "OK $(basename "$d")"
  else
    echo "FAIL $(basename "$d"): missing $first"
  fi
done
```

**定位 WorkshopDL 下载目录**（用户忘记下载位置时）：
```bash
# 搜索任意 PublishedFileID 文件夹
find /mnt/c/Users/ -maxdepth 5 -type d -name "840391233" 2>/dev/null | head -5
# WorkshopDL 输出目录通常在：
find /mnt/ -maxdepth 6 -type d -name "WorkshopDL" 2>/dev/null | head -5
```

### 4. 检查 `app.log`

DD 的日志文件记录游戏启动和运行信息。搜索关键字 `modfiles`, `project.xml`, `ERROR`, `WARNING` 等可发现加载失败线索。但注意——DD 的 Mod 加载信息通常**不写入 app.log**，该日志主要用于 Steam 登录错误等。Mod 不显示时更可能是 project.xml 配置问题（见上面 1-3 项）。

```
# 破解版（nosteam）→ 日志在此
{GameDir}/_windowsnosteam/win64/app.log

# Steam 版 → 日志在此
{GameDir}/_windows/win64/app.log
```

### 5. 中文 Localization / Font Mod 不显示在列表中

以 `<Tags>Localization</Tags>` 或纯字体替换的 Mod（如「中文字体重做」「Mod 简体中文化」）可能在 Mod 管理器列表中**不显示为可切换的条目**，而是自动生效。进游戏看字体/文字变化以确认是否生效。

### 6. 文件夹名含特殊字符导致跳过

DD 的 Mod 加载器对**文件夹名中的全角符号/非 ASCII 字符**可能处理不佳。如果 Mod 文件夹名包含 `「」`、中文括号、特殊空格等字符，游戏可能直接跳过不加载。

**修复**：将文件夹重命名为纯 ASCII 名称（如 `「莫德凯撒」Mordekaiser Class` → `Mordekaiser Class`）。

### 7. project.xml 中 Visibility: private 导致跳过

某些 Mod 的 `project.xml` 中 `<Visibility>private</Visibility>`（这在 Steam Workshop 上传时有用），下载到本地后 DD 会跳过加载。应改为 `<Visibility>public</Visibility>`。

### 8. time_scale_combat 类 Mod 在非 Steam 版可能无效

使用 `time_scale_combat` 规则的 Mod（如 x2 Combat Speed、+50% Combat Speed）在某些**非官方/破解版** DD 中可能不生效，因为游戏引擎移除了该功能或规则系统不完整。如果确认 Mod 已启用但无效，有两种方案：

**方案 A**：换用同作者的其他速度变体（如 +50% Combat Speed, +25% Combat Speed），试哪个生效
**方案 B**：手动修改等效的游戏文件（不推荐，需了解游戏文件结构）

---

## 注意事项 / 陷阱

### ⚠️ 身份验证要求
- **所有 Workshop 下载都需登录 Steam 账户**
- 账户**必须拥有该游戏**（在库中）
- SteamCMD 登录凭据会保存会话，后续不需要重复输入密码
- **不要**在脚本中硬编码密码，使用交互式登录或环境变量

### ⚠️ 浏览器访问限制
| 目标 | 状态 |
|------|------|
| steamcommunity.com Workshop 页 | ✅ 无需登录可浏览 |
| steamcommunity.com 模组详情页 | ✅ 可访问 |
| store.steampowered.com | ❌ 登录/年龄验证墙 |
| 搜索引擎（Google/Bing） | ❌ Cloudflare/验证码 |

### ⚠️ 文件类型
Workshop 物品可能是文件夹或 .vpk 等格式。Chrono Ark 等 Unity 游戏的 mod 通常是文件夹形式，需手动放入游戏的 Mods 目录。

### ⚠️ 已知无 Workshop 支持的游戏

| 游戏 | AppID | 原因 |
|------|-------|------|
| Slay the Spire 2 | 2868840 | Early Access，未开放 Workshop（社区页无 Workshop 选项卡） |

### ⚠️ 不要从代码类名反推控制台命令

当用户询问游戏内控制台命令时，**禁止**从 DLL 类名（如 `RelicCmd+Obtain`）猜测命令语法（如 `relic obtain`）。类名/方法名 ≠ 控制台注册的命令名。正确做法：

1. 让用户进游戏按对应键（通常是 `~` 或 `` ` ``）打开控制台
2. 输入 `help` 或 `?` 查看真实命令列表
3. 根据 help 输出提供准确语法

**真实教训（2026.5 会话）**：
- ❌ 从 `RelicCmd+Obtain` 猜测 `relic obtain <ID>` → 实际是 `relic add <ID>`
- ❌ 从 `CardPileCmd+RemoveFromDeck` 猜测 `cardpile removefromdeck` → 实际是 `remove_Card CARD.XXX`
- ❌ 从 `RemoveCardConsoleCmd` 猜测命令名 → 实际控制台显示为 `remove_card`

**正确流程**：先输 `help`，再告诉用户。

### ⚠️ 控制台命令信息要标注确定性

控制台命令的文档信息（语法、参数格式）如果不是从 `help` 输出或官方文档读取的，而是从代码推断的，必须标注 🟡 推测，并建议用户在控制台输入 `help` 验证。

### ⚠️ BaseLib (Harmony 补丁) 与内存修改器不兼容

BaseLib 对游戏代码打了大量 Harmony 补丁（如 STS2 上 177 处补丁），这会改变游戏的内存布局。内存修改器（风灵月影、Cheat Engine 表）依赖固定地址，因此打 BaseLib 后必然失效。这不是 Bug，是 Harmony 注入的本质特性。如果用户需要修改器，必须移除 BaseLib 和相关 Mod。

### ⚠️ Steam Guard / 2FA 导致登录超时

如果账户启用了 Steam Guard（手机令牌/邮箱验证），SteamCMD 的 `+login` 会暂停等待输入验证码，导致超时：

```
// 无 2FA 时可正常登录
[  0%] Checking for available update...
OK

// 有 2FA 时会卡住等待输入验证码（60s 超时）
```

**解决方式**：
1. **临时关闭 Steam Guard** — 在 Steam 设置 → 账户 → 管理 Steam Guard 中临时禁用
2. **使用 Steam 客户端生成的备用码** — 登录后输入
3. **交互式运行** — 让用户自行在终端中输入密码，不通过 +login 传参
4. **改用 WorkshopDL** — GUI 工具会弹出验证码输入框

> 🔴 **不要反复重试失败的 SteamCMD 登录**。如果连续 2 次失败应停止并告知用户，询问是否关闭 Steam Guard 或改用其他方式。

### ⚠️ WSL 无 sudo 时运行 SteamCMD（Windows exe 方案）

当 Linux 版 steamcmd 因缺少 32 位库而无法运行时（`cannot execute: required file not found`），可用 Windows 版 steamcmd.exe 绕过：

```bash
# 1. 下载 Windows 版到 Windows 文件系统（必须！WSL 的 ext4 为大小写敏感）
mkdir -p /mnt/d/path/to/
curl -sL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd.zip" -o /mnt/d/path/to/steamcmd.zip
cd /mnt/d/path/to/ && unzip -qo steamcmd.zip

# 2. 从 WSL 运行 Windows 可执行文件
cd /mnt/d/path/to/ && ./steamcmd.exe +login <username> <password> +quit

# 3. 首次运行会自动更新到最新版
```

**关键要求**：
- 必须放在 Windows 文件系统（NTFS/FAT），不能用 WSL 的 `/home/...`（大小写敏感检查失败）
- 需要 chmod +x 赋予执行权限
- 首次运行会自动下载 ~43MB 更新
- 同样受 Steam Guard 登录限制

### ⚠️ WorkshopDL 工具

当用户明确要求使用 WorkshopDL 时，或 SteamCMD 无法使用时：

```bash
# 下载 WorkshopDL（Windows GUI 工具）
curl -L -o /mnt/d/path/WorkshopDL_installer.exe \
  "https://github.com/imwaitingnow/WorkshopDL/releases/download/2.0.4/WorkshopDL.2.0.4_installer.exe"
```

- 仓库：`imwaitingnow/WorkshopDL`（注意不是 `VovoloGames/WorkshopDL`，也不是 GitCode 镜像）
- 类型：Windows GUI（Clickteam Fusion 2.5），**不能在 WSL CLI 中运行**
- 内部仍使用 SteamCMD 下载
- 安装后操作：输入 Workshop Homepage URL → 输入 Mod URL → 点击 Download
- 支持队列批量下载、集合下载、SteamWebAPI 模式

### ⚠️ 32 位库依赖
SteamCMD 是 32 位 ELF 二进制。在 64 位 Linux（如 WSL）上，需要 32 位兼容库：
```bash
sudo apt-get install -y lib32gcc-s1 lib32stdc++6
# 或
sudo dpkg --add-architecture i386 && sudo apt-get update && sudo apt-get install -y libc6:i386
```

如果 steamcmd 启动报 `No such file or directory` 或段错误，通常是缺 32 位库。

### ⚠️ Python `steam` 库存在兼容性问题（截至 2026.5）

`pip install steam` 安装的 `ValvePython/steam` 库（v1.4.4）存在多个依赖问题：

```text
# 问题 1：protobuf 版本冲突
Descriptors cannot be created directly.
→ 需降级 protobuf 到 3.20.3：pip install "protobuf>=3.20,<4"

# 问题 2：eventemitter v0.2.0 与 steam 不兼容
'SteamClient' object has no attribute '_listeners'
→ 当前无已知修复。gevent 模块依赖链也容易出问题。
```

结论：**不推荐使用 Python `steam` 库下载 Workshop 内容**。直接使用 SteamCMD 或 WorkshopDL。

### ⚠️ 安全提醒

Steam 帐号密码不要直接暴露在对话中。建议：
1. 由用户**自行**执行 SteamCMD 命令
2. 或使用交互式登录（steamcmd 会提示输入密码）
3. 如用户主动提供密码，下载完成后提醒用户修改密码

### ⚠️ 失败处理守则

当连续操作失败超过 2 次时：
1. **立即停止重试**，不要重复相同或相似的操作
2. 总结所有失败原因及根因链
3. 提出一个确定的方案，让用户确认后再执行
4. 不要逐个尝试不同解法而不停询问用户

---

## 增量流程：批量查找指定 Mod 列表

当用户给出一个**明确的 Mod 名称列表**并要求全部找到链接时（如"帮我找到这些mod的链接，一个都不能少"）：

### 工作流

1. **逐个搜索**，每个 Mod 用独立搜索 URL：
   ```
   https://steamcommunity.com/workshop/browse/?appid={AppID}&searchtext={URL编码名称}
   ```

2. **提取结果** — 搜索结果页第一项通常是精确匹配，用 `browser_console` 提取：
   ```javascript
   // 提取当前页所有 Mod 的 filedetails 链接
   JSON.stringify(Array.from(document.querySelectorAll('a[href*="filedetails/?id="]'))
     .reduce((acc, a) => {
       const id = a.href.match(/id=(\d+)/)?.[1];
       const txt = a.innerText?.trim();
       if (id && txt && txt.length > 1 && txt !== 'Learn More' && !acc.some(x => x.id === id)) {
         acc.push({name: txt, id, url: `https://steamcommunity.com/sharedfiles/filedetails/?id=${id}`});
       }
       return acc;
     }, [])
     .filter(r => r.name.toLowerCase().includes(搜索关键词)))
   ```

3. **验证** — 用 `browser_navigate` 检查详情页标题确认是正确 Mod，记录订阅量评分等元数据。

4. **关键避免的错误**：
   - 不要用同一个搜索词搜多个 Mod，结果会混淆
   - 如果搜索结果第一项不是精确匹配，往下翻看前 3-5 项
   - 中文 Mod 名搜不到时改搜英文名
   - 注意区分同名不同作者的 Mod（如 Mordekaiser 有三个版本）

5. **输出格式**：按用户列表顺序排出表格，每行包含 Mod 名称 + 完整 URL

### 效率技巧

- 搜索中文名称在 URL 中做百分号编码（如 `中文字体重做` → `%E4%B8%AD%E6%96%87%E5%AD%97%E4%BD%93%E9%87%8D%E5%81%9A`）
- 对强关联的 Mod（如"原版+区域扩展"两个版本）在表中用编号标注关系
- 如果有冲突的 Mod（如多个背包修改 Mod），提醒用户只能选一个

### 参考文件

- 已有 Workshop 数据可存入 `references/<game-name>-mods.md` 供后续复用

---

## 参考链接
- Workshop 浏览 API 参数：https://steamcommunity.com/dev
- SteamCMD 官方文档：https://developer.valvesoftware.com/wiki/SteamCMD
- 游戏 AppID 查询：https://store.steampowered.com/api/storesearch/?term=
- Chrono Ark 模组冲突检测：见 `references/chrono-ark-mod-conflicts.md`
- Chrono Ark 模组安装记录：见 `references/chrono-ark-mods-2026-05.md`
