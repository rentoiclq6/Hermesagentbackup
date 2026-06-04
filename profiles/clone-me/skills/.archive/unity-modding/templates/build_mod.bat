@echo off
REM Unity Mono Mod 编译脚本
REM 放到游戏根目录运行

set GAMEDIR=%~dp0
set MANAGED=%GAMEDIR%游戏名_Data\Managed
set BEPINEX=%GAMEDIR%BepInEx
set PLUGINDIR=%BEPINEX%\plugins\MyMod
set PLUGIN_SRC=%PLUGINDIR%\Plugin.cs
set OUTPUT=%PLUGINDIR%\MyMod.dll

mkdir "%PLUGINDIR%" 2>nul

REM 找 C# 编译器
set CSC=
if exist "%MANAGED%\..\..\MonoBleedingEdge\bin\mcs.bat" set CSC="%MANAGED%\..\..\MonoBleedingEdge\bin\mcs.bat"
if exist "%MANAGED%\..\..\MonoBleedingEdge\bin\csc.bat" set CSC="%MANAGED%\..\..\MonoBleedingEdge\bin\csc.bat"
where csc >nul 2>&1 && set CSC=csc

if "%CSC%"=="" (
    echo [错误] 找不到 C# 编译器！
    echo 请安装 .NET Framework SDK 或 Visual Studio
    pause
    exit /b 1
)

echo 编译器: %CSC%
echo 源文件: %PLUGIN_SRC%
echo 输出:   %OUTPUT%
echo.

%CSC% ^
    -target:library ^
    -out:"%OUTPUT%" ^
    -reference:"%BEPINEX%\core\0Harmony.dll" ^
    -reference:"%BEPINEX%\core\BepInEx.dll" ^
    -reference:"%BEPINEX%\core\BepInEx.Harmony.dll" ^
    -reference:"%MANAGED%\Assembly-CSharp.dll" ^
    -reference:"%MANAGED%\UnityEngine.dll" ^
    -reference:"%MANAGED%\UnityEngine.CoreModule.dll" ^
    "%PLUGIN_SRC%"

if %ERRORLEVEL% EQU 0 (
    echo === 编译成功！===
) else (
    echo === 编译失败 ===
    echo 检查：DLL 引用路径、方法签名、.NET 版本
)
pause
