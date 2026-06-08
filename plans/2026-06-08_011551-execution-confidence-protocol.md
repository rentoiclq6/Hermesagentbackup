# Execution Confidence Protocol — 防盲出防试错

**Plan created**: 2026-06-08 01:15 UTC
**Trigger**: start-hermes.bat 4 次盲出闪退，全部未在目标环境验证

---

## Goal

建立一套硬约束，防止我没在真实执行环境中测试就交付东西，导致你反复试错浪费时间。

---

## Current Context

### 根因分析：为什么这次出问题

| 环节 | 实际行为 | 问题 |
|------|---------|------|
| 写脚本 | WSL 下写 Windows .bat，盲出 | 无法本地测试 |
| 首次报错 | 盲猜原因，改一版本扔回去 | 没让你运行看错误 |
| 第 2 次报错 | 继续盲猜，又改一版本扔回去 | 重复低效循环 |
| 第 3-4 次 | 才意识到该换方案 | 反应太慢 |
| 全程 | 没告知你"这个没在 Windows 上测过，可能闪退" | 缺乏可信度标注 |

### 我当前的环境限制

- 运行在 WSL Ubuntu，**不是** Windows 原生环境
- Windows 上的 .bat / .ps1 我写了但**无法实际执行验证**
- 唯一能用的 `cmd.exe /c` 有 UNC 路径问题（WSL → Windows），测试结果≠双击桌面结果
- Windows GUI 行为（窗口打开/活跃/闪退）我**完全不可见**

---

## Proposed Approach

### 协议 1：可信度标注（所有跨环境交付强制）

在给出任何**不在当前环境可直接验证**的东西之前，必须标注可信度级别：

| 级别 | 含义 | 何时标注 |
|------|------|---------|
| `[VERIFIED]` | 已在目标环境实际执行过，看到成功输出 | 仅 curl 测试 / WSL 命令 / 已在运行的进程 |
| `[UNTESTED]` | 逻辑自认为正确，但没在目标环境跑过 | **所有 Windows .bat/.ps1 默认为此级别** |
| `[SPECULATIVE]` | 基于文档/经验推测，可能有环境差异 | 配置、API 参数、依赖版本 |

**规则**：跨环境交付（WSL→Windows 脚本、配置文件、部署指令）一律默认为 `[UNTESTED]`，除非刚在目标环境执行验证过。

### 协议 2：首次失败即诊断，禁止盲改

当用户报错后：

```
正确流程：
  1. 停下来。不要改代码。
  2. 要求用户提供诊断信息（error message / 运行输出）
  3. 说明我的猜测可信度（"我猜是 X 问题，可信度 60%"）
  4. 用户确认后，才改一版

错误流程（禁止）：
  ✗ 盲改 → 丢回去 → 再报错 → 再盲改 → 循环
```

**具体话术模板**：

```
[STATUS] 这个脚本我在 WSL 下写的，无法在 Windows 上实际执行验证。
当前失败的最可能原因（可信度 XX%）：[根因猜测]
要确认，你可以在 Win 的 CMD 里手动跑一次看完整报错：[命令]

可选方案：
  A) 你给我报错文本，我精准改
  B) 我换一个能在我这里测试的方案（如纯 WSL 脚本）
  C) 你接受 UNTESTED 风险，我继续盲出
```

### 协议 3：最大试错次数

同一个交付物最多试错 **2 次**。第 3 次必须：

1. 解释为什么前两次都猜错了
2. 要求用户给予更多诊断信息
3. 或换一个完全不同的技术方案（如 .bat → .ps1 → 纯 WSL 脚本）

这一条写入我自己的任务执行约束（硬规约）。

---

## Implementation Plan

### Step 1：更新记忆——任务执行约束

在已有「任务执行约束」中加入：

```
跨环境试错上限：同一交付物在非本地环境（如 WSL→Windows 脚本）最多试错 2 次。
第 3 次必须：① 解释前两次失败根因 ② 要求用户提供诊断信息 ③ 或换技术方案。
所有跨环境交付默认标注 [UNTESTED]。
```

这个已自动化——每次启动会注入记忆，下次遇到类似场景会自动遵守。

### Step 2：更新记忆——交付可信度前缀

新增一条：

```
跨环境交付可信度：WSL→Win 脚本 (bat/ps1/reg) 一律默认 [UNTESTED]。 
标注格式：[VERIFIED]/[UNTESTED]/[SPECULATIVE] 加在交付内容前。
```

### Step 3：更新 start-hermes 方案

当前状态：
- `HermesLauncher.bat` + `start-hermes.ps1` 已写到桌面
- `[UNTESTED]` 可信度——没在 Windows 上实际双击过
- .bat 闪退问题原因不明确，可能PS脚本本身是对的

下一步建议（等你审批后执行）：

- **A)** 你在 CMD 里手动跑一次 `powershell -NoProfile -ExecutionPolicy Bypass -File C:\Users\da\Desktop\start-hermes.ps1`，看 PS 脚本本身的报错
- **B)** 如果 PS 脚本能跑，只改 .bat 启动方式
- **C)** 如果 PS 脚本也报错，把错误信息贴给我针对性修
- **D)** 放弃 Windows 脚本，改成纯 WSL 方案（启动 liteLLM 通过 `cmd.exe /c start`，启动 Windows Hermes 通过 `cmd.exe /c start`，全程在 WSL 操作）

我的建议是先走 **A**——目前 `HermesLauncher.bat` 只是调用 PS 脚本的 3 行代码，最可能出错的是 PS 脚本本身。你开个 CMD 贴个错误马上就能定位。

---

## Files to Change

| 文件 | 操作 | 内容 |
|------|------|------|
| `~/.hermes/memory` | 追加 | 跨环境试错上限 + 可信度标注规则 |
| 待定 | 根据方案 A/B/C/D 修改 start-hermes 体系 |

---

## Risks & Open Questions

| 问题 | 风险 | 当前状态 |
|------|------|---------|
| .bat 闪退根因未知 | 可能修了很多版但根因还在 | 需要你在 CMD 里跑一次贴报错 |
| start-hermes.ps1 是否被正确调用 | PS 脚本没在目标环境执行过 | UNTESTED |
| 你那里的 PowerShell 执行策略 | 可能阻止 `-ExecutionPolicy Bypass` | 需要 `HermesLauncher.bat` 看结果 |

---

## 总结

长期：记忆里加入硬约束，我以后不会再对 Windows 脚本盲出 3+ 次。

短期：你先在 CMD 里跑一次 PS 脚本看报错，我定位根因后一次性修对。

你批准这个方案吗？还是你对第 3 步（start-hermes 修复方向）有不同偏好？
