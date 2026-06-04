---
name: ghidra-mcp
description: Ghidra reverse engineering via MCP — setup, connectivity troubleshooting, and verification of the GhidraMCP bridge between Hermes (WSL) and Ghidra (Windows).
---

# Ghidra MCP

## Trigger
When the user wants to use Ghidra's reverse engineering capabilities through Hermes MCP — analyzing binaries, listing functions, decompiling, or debugging Ghidra MCP connectivity issues.

## Prerequisites
- Ghidra 11.3.2+ with GhidraMCP Extension installed and enabled
- JDK 21
- GhidraMCP bridge script (`bridge_mcp_ghidra.py`) in WSL
- Hermes MCP config pointing to the bridge

## Key Pitfall: WSL2 Networking

**WSL2 `localhost` forwarding to Windows is UNRELIABLE for arbitrary ports.** Do not assume `127.0.0.1` works from WSL to reach Windows-hosted services. port 8080 in particular is confirmed to NOT forward via localhost in this environment.

The Windows host IP is available in WSL's `/etc/resolv.conf`:
```bash
cat /etc/resolv.conf | grep nameserver | awk '{print $2}'
```

This IP changes on every WSL restart. **DO NOT hardcode the IP in config.yaml** — use dynamic resolution instead (see Recommended Config below).

## Connectivity Test Procedure

Run these in order when Ghidra MCP isn't working:

### Step 1: Check Ghidra is running
```bash
powershell.exe -Command "Get-Process -Name 'javaw' -ErrorAction SilentlyContinue | Select-Object Id,MainWindowTitle"
```
Look for "CodeBrowser" in the output. If absent, start Ghidra on Windows and open a project.

### Step 2: Check Ghidra Extension is listening
```bash
powershell.exe -Command "netstat -ano | Select-String ':8080'"
```
Should show `LISTENING` on `0.0.0.0:8080` with the Ghidra PID. If not, the GhidraMCP Extension is not loaded in Ghidra — install/enable it via File → Install Extensions.

### Step 3: Test connectivity from WSL
```bash
WINDOWS_IP=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')
curl -s -o /dev/null -w "%{http_code}" "http://${WINDOWS_IP}:8080/get_current_address" --connect-timeout 5
```
- `200` → Bridge can reach Ghidra
- `000` / timeout → Firewall or networking issue

### Step 4: Add firewall rule (if Step 3 fails)
```powershell
New-NetFirewallRule -DisplayName "Ghidra MCP (WSL)" -Direction Inbound -Protocol TCP -LocalPort 8080 -Action Allow -Profile Any
```

### Step 5: Hermes config (use dynamic IP — set once, works forever)

In `~/.hermes/config.yaml`, under `mcp_servers.ghidra`:

```yaml
  ghidra:
    command: bash
    args:
    - -c
    - exec python3 /home/da/GhidraMCP/bridge_mcp_ghidra.py --ghidra-server http://$(grep nameserver /etc/resolv.conf | awk '{print $2}'):8080/
    timeout: 180
```

The `bash -c` wrapper resolves the current Windows host IP from `/etc/resolv.conf` at MCP startup. This survives WSL reboots — no manual IP updates needed.

### Step 6: Restart Hermes
The MCP bridge loads config at startup. A config change requires a Hermes restart.

### Step 7: Verify MCP tools
- `mcp_ghidra_get_current_address` — returns current cursor address in Ghidra
- `mcp_ghidra_list_functions` — returns function list
- `mcp_ghidra_get_current_function` — returns function at cursor

## Architecture

```
Hermes (WSL)
  └─ config.yaml → bridge_mcp_ghidra.py (MCP server)
                      └─ HTTP → GhidraMCP Extension (Windows, port 8080)
                                   └─ Ghidra API (Java)
```

The bridge script is the MCP server that Hermes talks to (via stdio). The bridge forwards requests to the GhidraMCP Extension running inside Ghidra on Windows.

## Component Paths

| Component | Path |
|-----------|------|
| Ghidra install | `C:\Users\da\Downloads\ghidra_11.3.2_PUBLIC_20250415\ghidra_11.3.2_PUBLIC\` |
| JDK 21 | `C:\Program Files\Eclipse Adoptium\jdk-21.0.11.10-hotspot\` |
| GhidraMCP Extension zip | `C:\Users\da\Downloads\GhidraMCP-release-1-4\GhidraMCP-release-1-4\GhidraMCP-1-4.zip` |
| Bridge script (WSL) | `/home/da/GhidraMCP/bridge_mcp_ghidra.py` |
| Hermes MCP config | `~/.hermes/config.yaml` (mcp_servers.ghidra section) |

## Related
- `references/connectivity-debug-20260516.md` — Full debug transcript and findings from the session that identified the WSL2 localhost issue.
- Frida MCP: check with `mcp_frida_check_installation`; configured alongside Ghidra in config.yaml. **FRIDA_REMOTE_HOST** also needs the Windows host IP — same dynamic resolution concern.
- User desktop doc: `C:\Users\da\Desktop\Hermes-MCP-使用注意事项.txt` — startup checklists and troubleshooting for both MCP tools.
- `game-modding` skill → `references/mcp-re-tools.md` — consolidated WSL→Windows MCP toolchain reference (socket timeout bug, check_installation trap, firewall setup for both 8080 and 27042).
