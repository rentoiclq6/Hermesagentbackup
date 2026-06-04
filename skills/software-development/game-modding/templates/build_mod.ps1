# Unity Mono Mod Build Script
# Copy to game root, edit $SourceFile to point to your Plugin.cs, then run:
#   powershell -ExecutionPolicy Bypass -File build_mod.ps1

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# EDIT THESE
$Managed    = "$ScriptDir\GAMENAME_Data\Managed"
$BepInEx    = "$ScriptDir\BepInEx"
$PluginName = "MyMod"
$SourceFile = "$BepInEx\plugins\$PluginName\Plugin.cs"
$OutputDll  = "$BepInEx\plugins\$PluginName\$PluginName.dll"

Write-Host "=== Mod Build ==="

# Find C# compiler
$CSC = $null
$candidates = @(
    "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe",
    "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
)
foreach ($c in $candidates) {
    if (Test-Path $c) { $CSC = $c; Write-Host "Compiler: $CSC"; break }
}

if (-not $CSC) {
    Write-Host "ERROR: No C# compiler found!"
    Write-Host "Install .NET Framework 4.7.2 SDK or .NET SDK 8.0+"
    Read-Host "Press Enter to exit"; exit 1
}

# Gather references (path-exists check)
$refs = @(
    "$BepInEx\core\0Harmony.dll",
    "$BepInEx\core\BepInEx.dll",
    "$Managed\Assembly-CSharp.dll",
    "$Managed\Assembly-CSharp-firstpass.dll",
    "$Managed\UnityEngine.dll",
    "$Managed\UnityEngine.CoreModule.dll",
    "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\netstandard.dll"
)

$refArgs = ""
foreach ($r in $refs) {
    if (Test-Path $r) {
        $refArgs += " /r:`"$r`""
    }
}

if ($refArgs -eq "") {
    Write-Host "ERROR: No reference DLLs found in $Managed"
    Write-Host "Check GAMENAME in the script."
    Read-Host "Press Enter to exit"; exit 1
}

Write-Host "Source : $SourceFile"
Write-Host "Output : $OutputDll"
Write-Host ""

# Compile — note: .NET Framework csc only supports C# 5!
# No $"" string interpolation, no nameof(), no ?. operator
$cmd = "& `"$CSC`" /target:library /out:`"$OutputDll`"$refArgs `"$SourceFile`" 2>&1"
Write-Host "Running: $cmd"
$result = Invoke-Expression $cmd

if ($LASTEXITCODE -eq 0) {
    Write-Host "=== BUILD SUCCESS ==="
    Write-Host "Plugin: $OutputDll"
    Write-Host "Launch the game to test."
} else {
    Write-Host "=== BUILD FAILED ==="
    Write-Host $result
    Write-Host ""
    Write-Host "Common fixes:"
    Write-Host "  CS1056 '$': C# 6+ not supported. Replace `$` strings with `+` concatenation."
    Write-Host "  CS0012 'System.Object': add netstandard.dll reference."
    Write-Host "  Missing DLL: check Managed/ folder for actual filenames."
}

Read-Host "Press Enter to exit"
