# MCP 逆向工程工具链

通过 MCP 协议让 AI 直接操作 Ghidra（静态分析）和 Frida（动态内存修改）。

## 环境上下文

- Hermes 运行在 WSL (Ubuntu) 中
- 目标游戏在 Windows 上运行
- MCP SDK 已安装 (`pip install mcp`)
- 配置在 `~/.hermes/config.yaml` 的 `mcp_servers:` 段

## GhidraMCP — 静态逆向

**仓库**: `LaurieWired/GhidraMCP` (★8896)
**路径**: `~/GhidraMCP/`
**架构**: Ghidra (Java GUI, Windows) → 内置 HTTP 插件 → Python bridge (WSL) → MCP stdio → Hermes

**前提**: 需要先在 Windows 上安装 Ghidra 本体 + 导入 GhidraMCP 插件。

**配置** (`config.yaml`):
```yaml
mcp_servers:
  ghidra:
    command: "python3"
    args:
      - "/home/da/GhidraMCP/bridge_mcp_ghidra.py"
      - "--ghidra-server"
      - "http://127.0.0.1:8080/"   # 已验证：配置防火墙后 127.0.0.1 可用，见下方 WSL2 网络说明
    timeout: 180
```
工具前缀: `mcp_ghidra_*`

### ⚠️ WSL2 网络隔离（127.0.0.1 陷阱）

Ghidra 在 Windows 上监听 `127.0.0.1:8080`，但 WSL2 的 `127.0.0.1` **默认不转发**到 Windows 的 localhost（被 Windows 防火墙拦截）。Ghidra 日志显示 `HTTP server started on port 8080`，但 WSL 端 `Connection refused` → 就是这个问题。

**✅ 推荐方案：Windows 防火墙 + 127.0.0.1（已验证可用）**

在 Windows 防火墙中添加入站规则允许 8080 端口，然后 WSL2 的 `127.0.0.1:8080` 即可正常转发到 Windows。

```powershell
# 在 Windows PowerShell（管理员）中执行：
New-NetFirewallRule -DisplayName "Ghidra MCP (8080)" `
    -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8080 `
    -Profile Any
```

验证：
```bash
# 1. 确认防火墙规则已生效
powershell.exe -Command "Get-NetFirewallRule -DisplayName 'Ghidra MCP (8080)' | Select DisplayName,Enabled,Action"
# 预期: DisplayName=Ghidra MCP (8080), Enabled=True, Action=Allow

# 2. 测试 WSL → Windows localhost 连通性
python3 -c "import requests; print(requests.get('http://127.0.0.1:8080/list_functions', timeout=3).status_code)"
# 预期: 200
```

**方案 B（备选）：使用 Windows 宿主机动态 IP**

如果防火墙方案不可行，可以用 WSL 网关 IP 直连（但 IP 每次重启可能变化）：

```bash
# 查看 Windows 宿主机 IP（WSL2 视角）
grep nameserver /etc/resolv.conf
# 输出: nameserver 172.19.240.1   ← 这个 IP 就是 Windows

# 验证连通性
python3 -c "import requests; print(requests.get('http://172.19.240.1:8080/list_functions', timeout=3).status_code)"
# 预期: 200
```

### ⚠️ 版本兼容性（必须先确认！）

GhidraMCP 的 `extension.properties` 强制要求插件版本匹配 Ghidra 主版本。**不匹配的扩展可以安装但不会激活**，HTTP 服务不会启动。

| GhidraMCP Release | 兼容 Ghidra 版本 |
|-------------------|------------------|
| 1-4 | 11.3.2 |
| 以上 | 查看 release notes |

如果你用的是 Ghidra 12.x，要么找匹配的新版 release，要么从源码编译（见仓库 `Building from Source`）。降级 Ghidra 到 11.3.2 是最快方案。

⚠️ **降级 Ghidra 后记得重新安装扩展！** 每个 Ghidra 版本有独立的 `AppData/Roaming/ghidra/<version>/Extensions/` 目录，在旧版装的扩展不会自动出现在新版里。

### 安装 GhidraMCP 扩展

1. 确认版本兼容
2. 下载 Release ZIP（如 `GhidraMCP-release-1-4.zip`），解压
3. ⚠️ **常见陷阱**：Release 通常有嵌套目录结构：
   ```
   GhidraMCP-release-1-4/
     GhidraMCP-release-1-4/       ← 内层同名目录
       GhidraMCP-1-4.zip           ← 这才是 Ghidra 需要的
       bridge_mcp_ghidra.py        ← Python bridge 脚本
   ```
3. Ghidra → `File` → `Install Extensions...` → 点绿色 **+** → **选择 `.zip` 文件**（不是文件夹！）
   - ❌ 选了文件夹 → `does not point to a valid ghidra extension`
   - ✅ 选了 `.zip` → 正常安装
4. OK → 重启 Ghidra

### 激活与验证

安装后必须验证扩展已激活，否则 HTTP 服务不会启动：

1. **确认扩展已勾选**：`File` → `Install Extensions...` → GhidraMCP 前必须有 ✅
2. **确认开发者插件已启用**：`File` → `Configure...` → `Developer` 分类 → 搜 `GhidraMCP` → 确保勾选
3. **打开 CodeBrowser**（打开任意项目 + 二进制文件）
4. **查看 Console**：`Window` → `Console` → 应有 GhidraMCP 启动日志

### 排查 "Connection refused" (127.0.0.1:8080)

`mcp_ghidra_*` 工具返回 `Connection refused`。分两种情况：

**情况 A：Ghidra 日志无 HTTP server 启动记录** → 扩展未激活。排查顺序：
1. 扩展是否在 Install Extensions 里勾选了？
2. 是否在 Configure → Developer 里启用了？
3. 装扩展后是否重启了 Ghidra？
4. Console 里有没有 GhidraMCP 报错（版本不兼容 / 缺少依赖）？
5. 如果是 Ghidra 12.x，GhidraMCP release 版本是否匹配？

**情况 B：Ghidra 日志显示 `HTTP server started on port 8080`，但 WSL 连不上** → WSL2 网络隔离问题。
→ 参见上方「WSL2 网络隔离」章节，用 Windows 宿主机 IP 替代 `127.0.0.1`。
→ 验证：`grep nameserver /etc/resolv.conf` 得到 IP 后用 curl 测试。

## Frida MCP — 动态内存（Cheat Engine 替代）

**仓库**: `0xhackerfren/frida-game-hacking-mcp` (★60, Python)
**路径**: `~/frida-game-hacking-mcp/`
**架构**: Frida Python (WSL) → TCP → frida-server (Windows) → 目标进程

**为什么选 Frida 而非 CE MCP/GhostMCP**:
- CE MCP (`miscusi-peek/cheatengine-mcp-bridge`, ★688): 依赖 Windows Named Pipes + pywin32，WSL2 无法访问 Named Pipes
- GhostMCP (`mq1n/GhostMCP`, ★19): Rust 编译的 DLL 注入器，纯 Windows 操作
- Frida: 跨平台，Python 客户端可在 WSL 运行，通过 TCP 连 Windows 上的 frida-server

**配置** (`config.yaml`):
```yaml
mcp_servers:
  frida:
    command: "bash"
    args:
      - "-c"
      - "export FRIDA_REMOTE_HOST=$(grep nameserver /etc/resolv.conf | awk '{print $2}') && export FRIDA_REMOTE_TIMEOUT=5 && exec python3 -m frida_game_hacking_mcp"
    timeout: 120
```
工具前缀: `mcp_frida_*`

> **为什么用 `bash -c` 包裹？** WSL2 宿主机 IP 每次重启可能变化。`$(grep nameserver ...)` 在 MCP 启动时动态解析 IP，避免硬编码。`exec` 让 Python 进程替换 shell，不残留 bash 进程。

### ⚠️ WSL2 → Windows 远程连接（完整流程）

Frida Python 在 WSL2 的 `device: local` 是 Linux 内核进程表，**看不到 Windows 宿主机的进程**。必须通过 frida-server 远程连接。

**步骤 1：安装匹配版本的 frida-server**

版本必须精确匹配。先确认 WSL 侧 frida 版本：
```bash
frida --version
# 例如输出: 17.9.10
```

下载并解压到 Windows 可访问路径：
```bash
FRIDA_VER=$(frida --version)
mkdir -p /mnt/c/Users/da/tools/frida
curl -fSL -o /mnt/c/Users/da/tools/frida/frida-server-${FRIDA_VER}-windows-x86_64.exe.xz \
  "https://github.com/frida/frida/releases/download/${FRIDA_VER}/frida-server-${FRIDA_VER}-windows-x86_64.exe.xz"
unxz /mnt/c/Users/da/tools/frida/frida-server-${FRIDA_VER}-windows-x86_64.exe.xz
```

**步骤 2：在 Windows 上运行 frida-server**

用**管理员 PowerShell**，先 cd 到目录再运行（直接双击会闪退无日志）：

```powershell
cd C:\Users\da\tools\frida
.\frida-server-17.9.10-windows-x86_64.exe -l 0.0.0.0
```

> ⚠️ 某些版本默认绑定 `127.0.0.1:27042`（只有 Windows 本地能访问），WSL2 连不上。**必须加 `-l 0.0.0.0`** 监听所有接口。
> ⚠️ 如果报错 `Error binding to address 127.0.0.1:27042: 通常每个套接字地址只允许使用一次` — 说明已经有 frida-server 在后台运行（可能之前双击启动的）。`taskkill /F /IM frida-server*.exe` 杀掉后重启。

**步骤 3：放行 Windows 防火墙**

WSL2 是独立 VM，即使 frida-server 监听 0.0.0.0，Windows 防火墙也会拦截来自 WSL 虚拟网络的 TCP 连接。

```powershell
# 管理员 PowerShell：
New-NetFirewallRule -DisplayName "Frida Server" -Direction Inbound -Protocol TCP -LocalPort 27042 -Action Allow
```

验证连通性：
```bash
# 从 WSL 端测试
nc -zv $(grep nameserver /etc/resolv.conf | awk '{print $2}') 27042
# 预期: Connection to 172.19.240.1 27042 port [tcp/*] succeeded!
```

**步骤 4：Patch `server.py` 支持远程连接 + 超时保护**

frida-game-hacking-mcp 的 `server.py` 硬编码了 `frida.get_local_device()`。关键问题：`frida.get_device_manager().add_remote_device()` **没有内置超时**，连不上时永久阻塞 → 整个 MCP 进程卡死 → Hermes 标记 MCP 服务器 unreachable。

修改 `~/frida-game-hacking-mcp/src/frida_game_hacking_mcp/server.py`，在文件顶部已有 `import os` 后添加 `import socket`，然后找到 `def get_device()` 替换为：

```python
import socket

def get_device() -> Any:
    """Get the local or remote Frida device."""
    global _session
    if _session.device is None:
        remote_host = os.environ.get("FRIDA_REMOTE_HOST", "")
        if remote_host:
            timeout = int(os.environ.get("FRIDA_REMOTE_TIMEOUT", "5"))
            old_timeout = socket.getdefaulttimeout()
            try:
                socket.setdefaulttimeout(timeout)
                manager = frida.get_device_manager()
                _session.device = manager.add_remote_device(remote_host)
                logger.info(f"Connected to remote Frida device: {remote_host}")
            except Exception as e:
                logger.warning(f"Remote Frida device {remote_host} unreachable: {e}. Falling back to local.")
                _session.device = frida.get_local_device()
            finally:
                socket.setdefaulttimeout(old_timeout)
        else:
            _session.device = frida.get_local_device()
    return _session.device
```

> **关键改进**: 连接失败时自动 fallback 到本地设备，不阻断 MCP 启动。
>
> **⚠️ 已知局限：socket timeout 无效** — `socket.setdefaulttimeout(5)` **不会影响 Frida 的内部网络连接**。Frida 使用自己的 glib 网络栈，不继承 Python 的 `socket` 模块超时设置。所以即使设置了 `FRIDA_REMOTE_TIMEOUT=5`，如果 frida-server 不可达（如防火墙拦截），`add_remote_device()` 仍会阻塞整个 MCP 连接，直到 MCP 框架超时（通常 ~120s）。**
> 这个 fallback 只有在遇到 Python 级异常（如 DNS 解析失败、端口拒绝等）时才生效。防火墙 drop 情景下 TCP SYN 被静默丢弃，不会触发 Python 异常 → fallback 不会执行 → MCP 进程卡死。实际调试中确认：即使 `socket.setdefaulttimeout(5)` 已设，远程连接不通时 `list_processes` 仍然挂满 120 秒超时。**

**步骤 5：配置 config.yaml（动态 IP）**

见上方配置示例。关键点：
- 用 `command: bash` + `-c` 包裹，内联 `$(grep nameserver ...)` 动态获取 IP
- `export FRIDA_REMOTE_TIMEOUT=5` 设置超时（对应 server.py 中的 patch）
- `exec python3` 替换 shell 进程

**步骤 6：重启 Hermes / `/reload-mcp`**

Frida MCP 工具前缀 `mcp_frida_*`，42 个工具：进程管理、内存读写、数值扫描 (scan_value/scan_next)、AOB 模式搜索、函数 Hook、模块分析、窗口截图、键盘输入。

### 排查 Frida MCP 连接失败

| 症状 | 原因 | 解决 |
|------|------|------|
| **`check_installation` 返回 `working: true`，但其他工具全超时** | ⚠️ **常见陷阱** — `check_installation` 不真正连接 frida-server。它只检查 MCP bridge 是否按配置运行（即 frida 库可导入 + 看到环境变量里有 `FRIDA_REMOTE_HOST`），不验证远程能否连通。所以即使 Windows 端 frida-server 没启动，`working: true` 也会返回。 | 用 `mcp_frida_list_processes` 做实际连通性验证（它会尝试 TCP 连接）。如果 `list_processes` 超时而 `check_installation` 显示 OK，100% 是 frida-server 未运行或不可达。 |
| `mcp_frida_*` 全部超时 | frida-server 没运行 | 在 Windows 管理员 PowerShell 运行 frida-server |
| 同上 | Windows 防火墙拦截 | 加防火墙规则 (步骤 3) |
| 同上 | frida-server 绑了 127.0.0.1 而非 0.0.0.0 | 加 `-l 0.0.0.0` 重启 |
| 同上 | WSL2 IP 变了 | 配置中已用 `$(grep nameserver ...)` 动态解析，无需手动改 |
| `frida-ps -H <ip>` 返回 `operation was cancelled` | TCP 建立了但被中断，frida-server 崩溃 | 检查版本匹配、用 `-v` 模式看日志 |
| MCP 服务器 marked unreachable | `add_remote_device()` 无超时阻塞了整个 MCP 进程 | 确保 server.py 已 patch（步骤 4），设置了 `FRIDA_REMOTE_TIMEOUT` |
| `Unable to bind to address` / 端口被占用 | 已有 frida-server 实例在运行 | `taskkill /F /IM frida-server*.exe` |

## 与现有 Modding 路径的关系

```
game-modding 决策树
├─ 4. 游戏自带 Mod 系统 → BepInEx/Harmony (现有)
├─ 5. Unity 游戏 → unity-modding skill (现有)
├─ 6. 内存修改 → Frida MCP (新增，跨平台)
└─ 7. 静态逆向理解 → GhidraMCP (新增)
```

Ghidra + Frida 互补：Ghidra 理解代码结构（找目标方法签名），Frida 动态修改内存/数值。

## 实战胜证记录

**2026-05-16 — STS2 (Slay the Spire 2) 全流程验证通过**

| 步骤 | 操作 | 结果 |
|------|------|------|
| 1 | `check_installation` | `working:true, device_type:remote` (但实际 frida-server 未启动也返回 true — 陷阱) |
| 2 | 防火墙放行 `27042` | `New-NetFirewallRule -LocalPort 27042 -Action Allow` |
| 3 | `list_processes("Spire")` | `PID 9220 — SlayTheSpire2.exe` |
| 4 | `attach(9220)` | `success: true` |
| 5 | `list_modules` | 198 个模块，含 `sts2.dll` (9.2MB), `GodotSharp.dll`, `coreclr.dll`, `0Harmony.dll` + 7 个 Mod DLL |

**环境**：Hermes (WSL Ubuntu) → frida-server (Windows, C:\Users\da\tools\frida\)
**Frida 版本**：17.9.10 / frida-game-hacking-mcp 1.1.0

**桌面文档**：`C:\Users\da\Desktop\Hermes-MCP-使用注意事项.txt` — 含完整启动操作和排查指南。
