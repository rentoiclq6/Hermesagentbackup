# Windows Batch Launcher for liteLLM + Hermes

## Background

A one-click desktop launcher that starts liteLLM gateway and optionally launches Hermes (WSL or Windows). The user's setup has two Hermes installations:

| Location | Path | Version |
|----------|------|---------|
| WSL | `wsl -e bash -c "hermes"` | v0.12.0 |
| Windows | `C:\Users\<user>\AppData\Local\hermes\hermes-agent\venv\Scripts\hermes.exe` | v0.14.0 |

## CRITICAL: Windows CMD Batch File Rules

1. **NO Unicode characters** — Box-drawing characters (╔║╚╝ █ ● ○ →) render as garbage in Windows CMD. Use pure ASCII:
   ```
   Good: +------------------------------------+
         | Hermes + LiteLLM Launcher          |
         +------------------------------------+
   Bad:  ╔══════════════════════════════════╗
         ║       Hermes + LiteLLM           ║
         ╚══════════════════════════════════╝
   ```

2. **CRLF line endings** mandatory — batch files with LF-only endings fail silently. Verify:
   ```
   file start-hermes.bat
   # Should output: "DOS batch file, ASCII text, with CRLF line terminators"
   # Fix in WSL: sed -i 's/$/\\r/' start-hermes.bat
   ```

3. **No `chcp 65001`** — Switching to UTF-8 code page breaks text rendering on many Windows CMD terminals. Avoid it entirely.

4. **STRUCTURE: subroutine labels must come AFTER a `goto` jump** — Every subroutine (`:name`) that ends with `goto :eof` must be placed BELOW a `goto main_menu` at the top of the file. If the script falls through to a label (without `call`), `goto :eof` terminates the ENTIRE script immediately. This causes the "open and close instantly" flash-exit.

   **WRONG** (script will flash-exit):
   ```batch
   @echo off
   :check_status
   >nul 2>&1 curl -s http://localhost:4000/health/readiness
   if %errorlevel% equ 0 (set OK=1) else (set OK=0)
   goto :eof   ← script EXITS here because :check_status wasn't called
   :menu
   call :check_status
   ...
   ```

   **RIGHT**:
   ```batch
   @echo off
   setlocal enabledelayedexpansion
   goto menu   ← JUMP over subroutine labels

   :check_status
   ...
   goto :eof   ← safe: only reached via `call :check_status`

   :menu
   call :check_status
   ...
   ```

5. **Startup notifications** — Start liteLLM hidden with `start /B /MIN ""` and redirect output to a log file. Then poll the health endpoint in a loop (max 25s timeout) to confirm readiness before launching Hermes.

## Launcher Script Template

See `templates/hermes-litellm-launcher.bat` for the full template.

### Menu Structure

```
+-------------------------------------------+
|        Hermes + LiteLLM Launcher          |
+-------------------------------------------+
| LiteLLM: [RUNNING] / [STOPPED]            |
| Hermes WSL:  v0.12.0  [installed]        |
| Hermes Win:  v0.14.0  [installed]        |
+-------------------------------------------+
| [1] Full: LiteLLM + Hermes (WSL)         |
| [2] Full: LiteLLM + Hermes (Windows)     |
| [3] LiteLLM gateway only (background)    |
| [4] Open Hermes (WSL) without LiteLLM   |
| [5] Open Hermes (Windows) without LiteLLM |
| [6] Stop LiteLLM gateway                 |
| [7] Exit                                 |
+-------------------------------------------+
```

### Key Patterns

**Starting liteLLM in background:**
```batch
start /B /MIN "" "%LITELLM_EXE%" --config "%LITELLM_CONFIG%" --port %LITELLM_PORT% > "%LITELLM_LOG%" 2>&1
```

**Waiting for gateway:**
```batch
set wait_count=0
:wait_loop
set /a wait_count+=1
if !wait_count! gtr 25 ( echo [FAIL] timeout & exit /b 1 )
>nul 2>&1 curl -s http://localhost:%LITELLM_PORT%/health/readiness
if !errorlevel! neq 0 ( timeout /t 1 /nobreak >nul & goto wait_loop )
```

Requires `setlocal enabledelayedexpansion` at top for `!wait_count!`.

**Opening WSL Hermes in new window:**
```batch
start "Hermes (WSL)" wsl -e bash -c "hermes; echo; echo 'Exited.'; exec bash"
```

**Opening Windows Hermes in new window:**
```batch
start "Hermes (Windows)" "C:\Users\<user>\AppData\Local\hermes\hermes-agent\venv\Scripts\hermes.exe"
```

**Stopping liteLLM:**
```batch
taskkill /f /im litellm.exe >nul 2>&1
taskkill /f /im litellm-proxy.exe >nul 2>&1
```

### Status Detection

```batch
>nul 2>&1 curl -s http://localhost:%LITELLM_PORT%/health/readiness
if %errorlevel% equ 0 (set LITELLM_RUNNING=1) else (set LITELLM_RUNNING=0)
```

Called before rendering the menu so the status line is always fresh.

## PowerShell Alternative

Batch files have structural fragility (see rule 4 above). For complex interactive scripts, **PowerShell is significantly more reliable**. Use a `.ps1` file with a small `.bat` launcher that bypasses execution policy:

### Launcher Pattern

**HermesLauncher.bat** (double-click this):
```batch
@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0start-hermes.ps1"
pause
```

**start-hermes.ps1** (the actual logic):
```powershell
#Requires -Version 5.1

# === Config ===
$litellmExe = "C:\Users\<user>\AppData\Local\Programs\Python\Python312\Scripts\litellm.exe"
$litellmCfg = "C:\Users\<user>\AppData\Local\Programs\Python\Python312\Lib\site-packages\litellm\config.yaml"
$litellmPort = 4000
$litellmLog = "$env:USERPROFILE\Desktop\litellm-server.log"
$winHermes = "C:\Users\<user>\AppData\Local\hermes\hermes-agent\venv\Scripts\hermes.exe"

# === Helpers ===
function Test-LiteLLM {
    try {
        $req = Invoke-WebRequest -Uri "http://localhost:$litellmPort/health/readiness" -TimeoutSec 3 -UseBasicParsing
        return $req.StatusCode -eq 200
    } catch { return $false }
}

function Start-LiteLLM {
    if (Test-LiteLLM) { return $true }
    $proc = Start-Process -FilePath $litellmExe -ArgumentList "--config `"$litellmCfg`" --port $litellmPort --debug" -WindowStyle Hidden -PassThru -RedirectStandardOutput $litellmLog -RedirectStandardError $litellmLog
    for ($i = 0; $i -lt 25; $i++) {
        Start-Sleep -Seconds 1
        if (Test-LiteLLM) { return $true }
    }
    return $false
}

# === Menu Loop ===
do {
    Clear-Host
    $status = if (Test-LiteLLM) { "RUNNING" } else { "STOPPED" }
    Write-Host "  +-------------------------------------------+"
    Write-Host "  |        Hermes + LiteLLM Launcher          |"
    Write-Host "  | LiteLLM: [$status]                      |"
    Write-Host "  | [1] LiteLLM + Hermes (WSL)              |"
    Write-Host "  | [2] LiteLLM + Hermes (Windows)          |"
    Write-Host "  | [7] Exit                                |"
    Write-Host "  +-------------------------------------------+"
    $choice = Read-Host "Pick"
    switch ($choice) {
        "1" { Start-LiteLLM; Start-Process -WindowStyle Normal -FilePath "wsl" -ArgumentList '-e bash -c "hermes; exec bash"' -Wait }
        "2" { Start-LiteLLM; Start-Process -WindowStyle Normal -FilePath $winHermes -Wait }
    }
} while ($choice -ne "7")
```

### Why PowerShell Over Batch

| Concern | Batch | PowerShell |
|---------|-------|-----------|
| `goto :eof` trap | Silent exit | No equivalent issue |
| Unicode rendering | Breaks (garbage chars) | Native |
| Error handling | `%errorlevel%` everywhere | try/catch |
| Process management | `taskkill` | `Stop-Process` |
| HTTP health checks | `curl` (may not exist) | `Invoke-WebRequest` (built-in) |
