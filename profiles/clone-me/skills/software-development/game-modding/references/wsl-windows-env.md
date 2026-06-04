# WSL → Windows 环境配置技巧

从 WSL 操作 Windows 环境变量、注册表、安装软件时的方法和陷阱。

## 原则

**`cmd.exe /c` 和 `powershell.exe` 从 WSL 调用经常超时。优先用 `/mnt/c/Windows/System32/reg.exe` 直接操作注册表。**

## 安装 Java（供 Ghidra 等使用）

```bash
# winget 安装 JDK 21
cmd.exe /c "winget install EclipseAdoptium.Temurin.21.JDK --accept-package-agreements"

# 找到安装路径
ls /mnt/c/Program\ Files/Eclipse\ Adoptium/

# 验证 Java 可用
"/mnt/c/Program Files/Eclipse Adoptium/jdk-xx/bin/java.exe" -version
```

## 设置环境变量（via 注册表）

```bash
REG="/mnt/c/Windows/System32/reg.exe"

# 读取
$REG query "HKCU\Environment" /v JAVA_HOME

# 写入
$REG add "HKCU\Environment" /v JAVA_HOME /t REG_SZ /d "C:\path\to\jdk" /f
```

### ⚠️ PATH 修改陷阱

**绝对不要在 reg add 的值里写 `%PATH%`！** WSL shell 会把 `%PATH%` 展开成 WSL 的 PATH，污染 Windows 的 PATH 注册表。

```bash
# ❌ 错误 — %PATH% 被 WSL shell 展开
$REG add "HKCU\Environment" /v PATH /t REG_EXPAND_SZ /d "%PATH%;C:\new\path" /f

# ✅ 正确 — 先读出当前值，自行拼接
CURRENT=$($REG query "HKCU\Environment" /v PATH | ...extract value...)
$REG add "HKCU\Environment" /v PATH /t REG_EXPAND_SZ /d "${CURRENT};C:\new\path" /f
```

如果误写了 PATH，可以从之前的 `reg query` 输出恢复原始值。

## 验证

环境变量写入注册表后，**新打开的进程**才能看到。当前已打开的 cmd/PS 窗口不会立即生效。重新打开终端或双击目标程序即可。

## 从 Python (hermes_tools.terminal) 调用

```python
# reg add 通常秒级完成，不会超时
terminal('"/mnt/c/Windows/System32/reg.exe" add "HKCU\\Environment" /v KEY /t REG_SZ /d "value" /f')

# cmd.exe /c 经常超时（>30s），尽量避免
terminal('cmd.exe /c "some command"', timeout=30)  # 可能超时
```
