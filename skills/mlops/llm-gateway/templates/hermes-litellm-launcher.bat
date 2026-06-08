@echo off
title Hermes + LiteLLM Launcher
setlocal enabledelayedexpansion

:: ============================================================
:: CONFIG — adjust paths for your system
:: ============================================================
set LITELLM_EXE=C:\Users\da\AppData\Local\Programs\Python\Python312\Scripts\litellm.exe
set LITELLM_CONFIG=C:\Users\da\AppData\Local\Programs\Python\Python312\Lib\site-packages\litellm\config.yaml
set LITELLM_PORT=4000
set LITELLM_LOG=%USERPROFILE%\Desktop\litellm-server.log
set WSL_HERMES=wsl -e bash -c "hermes; echo; echo 'Hermes exited.'; exec bash"
set WIN_HERMES_CMD=C:\Users\da\AppData\Local\hermes\hermes-agent\venv\Scripts\hermes.exe

:: ============================================================
:: Check liteLLM status
:: ============================================================
:check_status
>nul 2>&1 curl -s http://localhost:%LITELLM_PORT%/health/readiness
if %errorlevel% equ 0 (set LITELLM_RUNNING=1) else (set LITELLM_RUNNING=0)
goto :eof

:: ============================================================
:: Menu
:: ============================================================
:menu
call :check_status
cls
echo.
echo   +-------------------------------------------+
echo   |        Hermes + LiteLLM Launcher          |
echo   +-------------------------------------------+
if %LITELLM_RUNNING% equ 1 (
    echo   | LiteLLM: [RUNNING] on port %LITELLM_PORT%        |
) else (
    echo   | LiteLLM: [STOPPED]                      |
)
echo   | Hermes WSL:  [installed]                    |
echo   | Hermes Win:  [installed]                    |
echo   +-------------------------------------------+
echo   | [1] Full: LiteLLM + Hermes (WSL)          |
echo   | [2] Full: LiteLLM + Hermes (Windows)      |
echo   | [3] LiteLLM gateway only (background)     |
echo   | [4] Open Hermes (WSL) without LiteLLM     |
echo   | [5] Open Hermes (Windows) without LiteLLM  |
echo   | [6] Stop LiteLLM gateway                  |
echo   | [7] Exit                                  |
echo   +-------------------------------------------+
echo.
set /p choice="Pick (1-7): "

if "%choice%"=="1" goto opt_wsl
if "%choice%"=="2" goto opt_win
if "%choice%"=="3" goto opt_litellm
if "%choice%"=="4" goto opt_hermes_wsl
if "%choice%"=="5" goto opt_hermes_win
if "%choice%"=="6" goto opt_stop
if "%choice%"=="7" goto end
goto menu

:: ============================================================
:: Start liteLLM (background, wait for ready)
:: ============================================================
:start_litellm
if %LITELLM_RUNNING% equ 1 (
    echo   LiteLLM already running, skipping.
    timeout /t 1 /nobreak >nul
    goto :eof
)
echo.
echo   -- Starting LiteLLM gateway --
start /B /MIN "" "%LITELLM_EXE%" --config "%LITELLM_CONFIG%" --port %LITELLM_PORT% > "%LITELLM_LOG%" 2>&1
echo   Waiting for gateway...
set wait_count=0
:wait_loop
set /a wait_count+=1
if !wait_count! gtr 25 (
    echo   [FAIL] LiteLLM startup timeout. Check: %LITELLM_LOG%
    pause
    exit /b 1
)
>nul 2>&1 curl -s http://localhost:%LITELLM_PORT%/health/readiness
if !errorlevel! neq 0 (
    timeout /t 1 /nobreak >nul
    goto wait_loop
)
echo   [OK] LiteLLM ready on port %LITELLM_PORT%
set LITELLM_RUNNING=1
timeout /t 1 /nobreak >nul
goto :eof

:: ============================================================
:: Options
:: ============================================================
:opt_wsl
cls & call :start_litellm
if %errorlevel% neq 0 pause & goto menu
start "Hermes (WSL)" %WSL_HERMES%
echo. & echo Press any key to return... & pause >nul & goto menu

:opt_win
cls & call :start_litellm
if %errorlevel% neq 0 pause & goto menu
start "Hermes (Windows)" "%WIN_HERMES_CMD%"
echo. & echo Press any key to return... & pause >nul & goto menu

:opt_litellm
cls & call :start_litellm
if %errorlevel% neq 0 pause & goto menu
echo. & echo LiteLLM running in background. Log: %LITELLM_LOG%
echo. & echo Press any key to return... & pause >nul & goto menu

:opt_hermes_wsl
cls
start "Hermes (WSL)" %WSL_HERMES%
echo. & echo Press any key to return... & pause >nul & goto menu

:opt_hermes_win
cls
start "Hermes (Windows)" "%WIN_HERMES_CMD%"
echo. & echo Press any key to return... & pause >nul & goto menu

:opt_stop
cls
if %LITELLM_RUNNING% equ 0 (
    echo   LiteLLM is not running.
) else (
    taskkill /f /im litellm.exe >nul 2>&1
    taskkill /f /im litellm-proxy.exe >nul 2>&1
    echo   [OK] LiteLLM stopped.
    set LITELLM_RUNNING=0
)
echo. & echo Press any key to return... & pause >nul & goto menu

:end
cls & echo. & echo Bye! & timeout /t 1 /nobreak >nul & exit /b 0
