# Frida MCP 连接故障实录

## 核心发现：socket.setdefaulttimeout() 对 Frida 无效

### 现象
即使 Hermes config.yaml 中设置了 `FRIDA_REMOTE_TIMEOUT=5`，如果 frida-server 
不可达（Windows 防火墙拦截、进程未启动等），`add_remote_device()` 仍会挂满 
MCP 框架的超时（~120 秒），不会在 5 秒内优雅 fallback。

### 根因
server.py 中 `get_device()` 函数：
```python
socket.setdefaulttimeout(timeout)           # ← 这只影响 Python stdlib socket
_session.device = manager.add_remote_device(remote_host)  # ← Frida 用 glib 网络栈
```
Frida 使用自己的 glib 网络栈，不继承 Python `socket` 模块的超时设置。
`add_remote_device()` 在 TCP SYN 被防火墙静默丢弃时，原地阻塞直至系统 TCP
超时（通常 120 秒+），不会触发 Python 异常 → fallback 到本地设备不会执行。

### 影响
- 用户必须先启动 Windows 上的 frida-server，再启动 Hermes
- 如果启动顺序不对（先开了 Hermes 再开 frida-server），不会自动恢复连接
- `mcp_frida_check_installation` 返回 `working:true` 有误导性——它只检查 pip
  包，不验证远程连接

### 变通方案
1. 用 `/dev/tcp` 或 Python socket 快速探测端口是否开放，再决定是否调 MCP 工具
2. 先把 Windows 端的 frida-server 启动好 (`-l 0.0.0.0:27042`)，再开 Hermes
3. Windows 桌面上的 `Start-MCP-Services.cmd` 批处理一键完成

### 验证成功的完整配置
config.yaml 第 409-415 行（已验证可用）：
```yaml
  frida:
    command: bash
    args:
    - -c
    - export FRIDA_REMOTE_HOST=$(grep nameserver /etc/resolv.conf | awk '{print $2}')
      && export FRIDA_REMOTE_TIMEOUT=5 && exec python3 -m frida_game_hacking_mcp
    timeout: 120
```

动态 IP 解析靠 `$(grep nameserver /etc/resolv.conf)`，在 WSL 重启后自动获取
新的宿主 IP。
