# MCP 工具链在游戏 Mod 工作流中的集成规划

## 目标

让 Ghidra MCP 和 Frida MCP 在未来游戏 Mod 制作中成为真正可用的环节，
而不仅是"理论上有"的工具。

## 当前状态（已完成）

- [x] Frida MCP 配置（动态 IP 解析，config.yaml 第 409-415 行）
- [x] Ghidra MCP 配置（动态 IP 解析，config.yaml 第 405-408 行）
- [x] `game-modding` skill 更新——决策表中新增 MCP 工具链章节
- [x] 桌面文档 `Hermes-MCP-使用注意事项.txt` 含完整操作/排查指南
- [x] 记忆已更新，未来 Mod 相关会话会自动考虑 MCP 工具

## 核心问题

**所有 Windows 端服务需要用户手动启动，AI 无法代劳。**

这是 WSL→Windows 架构的固有限制：
| 工具 | 需手动启动 | 启动频率 |
|------|-----------|---------|
| Ghidra MCP | Ghidra + GhidraMCP Extension | 每次使用前 |
| Frida MCP | frida-server.exe -l 0.0.0.0:27042 | 每次 Hermes 重启后 |

这意味着每次会话的开场白都是"请先启动 XXX，然后告诉我"——体验很差。

## 改进方案

### 方案 A：批处理脚本（推荐）

在 Windows 桌面上放一个 `Start-MCP-Services.cmd`，一键启动所需服务：

```
@echo off
echo Starting Frida Server...
start /B C:\Users\da\tools\frida\frida-server-17.9.10-windows-x86_64.exe -l 0.0.0.0:27042
echo Frida Server started on port 27042
echo.
echo Now start Ghidra manually if needed (it's heavy, might not want every time)
pause
```

**优点**：一键搞定 Frida，Ghidra 看需要才开
**文件位置**：`C:\Users\da\Desktop\Start-MCP-Services.cmd`

### 方案 B：按需启动 + 精简检查清单

在 `game-modding` skill 中增加一个"启动前检查"节点，让 AI 在每次建议用 MCP 工具时自动输出标准化的启动指令：

```
────────────────────────────────
 需要使用 Frida MCP / Ghidra MCP
────────────────────────────────
Windows 端需要先启动：
  □ frida-server? → cd C:\Users\da\tools\frida
                    .\frida-server-17.9.10-windows-x86_64.exe -l 0.0.0.0:27042
  □ Ghidra?       → 启动 Ghidra + 加载 GhidraMCP Extension
  □ 目标游戏?     → 启动游戏，切到主菜单
启动后告诉我，我继续工作
────────────────────────────────
```

### 方案 C：PowerShell 远程检查（失败时的排查减负）

在 Hermes 中预置一个检查脚本，当 MCP 工具连不上时自动输出排查指引，减少追问次数。

## 下一步行动

| 优先级 | 行动 | 说明 |
|--------|------|------|
| P0 | 创建 `Start-MCP-Services.cmd` | 一键启动 frida-server 的批处理，减少用户每次手动 cd 的操作 |
| P1 | 标准化 AI 开场白 | 当 AI 决定使用 MCP 工具时，直接输出标准检查清单，不绕弯子 |
| P2 | 优化 `game-modding` skill 决策树 | 在决策树中增加"是否已有 frida-server/Ghidra 运行？"的判断节点 |
| P3 | 调研 Frida spawn 能力 | 看能否从 WSL 通过 frida 直接 spawn Windows 进程（跳过手动启动游戏这步） |

## 风险与开放问题

- **Frida spawn 跨 Windows 进程**：`frida.spawn()` 需要在 Windows 上运行 frida-server，且 spawn 的是 Windows exe 路径。理论上可行：`frida.spawn("D:\\path\\to\\game.exe")` 但需要验证路径转义和权限
- **Ghidra 太重**：每次 Mod 都开 Ghidra 不现实，应只在"需要理解新逻辑"时按需开
- **Frida 的 120 秒超时 bug**：如果 frida-server 没启动就调 MCP 工具，会卡 120 秒。需考虑在连接前加一个快速网络探测（`/dev/tcp` 或 Python socket 快速测试）

## 文件变更记录

| 文件 | 状态 | 说明 |
|------|------|------|
| `~/.hermes/skills/.../game-modding/SKILL.md` | ✅ 已更新 | 新增 MCP 工具链章节 |
| `C:\Users\da\Desktop\Hermes-MCP-使用注意事项.txt` | ✅ 已更新 | 含完整指南 |
| `C:\Users\da\Desktop\Start-MCP-Services.cmd` | ❌ 未创建 | P0 行动项 |
