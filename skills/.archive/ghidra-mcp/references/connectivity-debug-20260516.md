# Ghidra MCP Connectivity Debug — 2026-05-16

## Context
Ghidra running on Windows, Hermes + MCP bridge running in WSL2. Previous session had tried to get them connected, added firewall rules, but the issue persisted.

## Test Sequence

### 1. Ghidra process check
```
powershell.exe Get-Process javaw
→ PID 9620, "CodeBrowser: test1:/frida-clr-17.9.10-windows-x86_64.dll"
```
✅ Ghidra running with test1 project open.

### 2. Port check from Windows side
```
powershell.exe netstat -ano | Select-String ':8080'
→ TCP 0.0.0.0:8080 LISTENING 9620
```
✅ GhidraMCP Extension is listening on all interfaces.

### 3. Connectivity test from WSL

| Target | Result |
|--------|--------|
| `http://127.0.0.1:8080/` | ❌ Connection refused (exit 7) |
| `http://172.19.240.1:8080/` (Windows host IP from `/etc/resolv.conf`) | ✅ HTTP 200 |

### 4. Firewall rule
```
New-NetFirewallRule -DisplayName "Ghidra MCP (WSL)" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow -Profile Any
```
Added, but wasn't the root cause — `127.0.0.1` still didn't work after adding the rule.

### 5. MCP tools
All three (`get_current_address`, `list_functions`, `get_current_function`) failed with:
```
HTTPConnectionPool(host='127.0.0.1', port=8080): Connection refused
```
Config in `~/.hermes/config.yaml` hardcoded `127.0.0.1:8080`.

## Root Cause

WSL2's `localhost` → Windows port forwarding is **not reliable for all ports**. The GhidraMCP bridge was configured to use `http://127.0.0.1:8080/` which the WSL2 network stack does not forward. Using the Windows host's virtual network IP (`172.19.240.1` in this session) works.

## Fix Applied

Changed `~/.hermes/config.yaml` line 407:
```diff
-    - http://127.0.0.1:8080/
+    - http://172.19.240.1:8080/
```

## Caveat

The Windows host IP (`/etc/resolv.conf` nameserver) changes on every WSL restart. If Ghidra MCP stops working after a reboot, re-run:
```bash
cat /etc/resolv.conf | grep nameserver | awk '{print $2}'
```
And update the config.yaml if the IP changed.

## Handoff Document Correction

The handoff doc (`/home/da/ghidra-mcp-handoff.md`, line 24) stated:
> "WSL2 本身支持 localhost 转发 — 网络层面没问题"

This is **incorrect in practice** for Ghidra's port 8080. The firewall rule alone does not fix it; the Windows host IP must be used directly.
