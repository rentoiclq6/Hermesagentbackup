# Hermes Agent Configuration Backup

此仓库备份了 [Hermes Agent](https://hermes-agent.nousresearch.com) 的完整配置、技能（Skills）、计划（Plans）、钩子（Hooks）等关键状态文件，用于多机同步与故障恢复。

## 仓库内容包含

| 路径 | 说明 |
|---|---|
| `config.yaml` | Hermes 核心配置（模型、超时、压缩、工具等） |
| `SOUL.md` | 助手人格设定 |
| `skills/` | 所有已安装/开发的 Skills（~600 个技能文件） |
| `profiles/` | 多配置文件（含 clone-me 等 profile） |
| `plans/` | 历史执行计划 |
| `hooks/` | Shell 脚本钩子 |
| `memories/` | 持久化记忆（MEMORY.md + USER.md） |
| `cron/` | 定时任务定义 |
| `weixin/` | 微信集成配置 |
| `pastes/` | 历史粘贴内容 |

## ❌ 不包含（被 .gitignore 排除）

| 排除项 | 原因 |
|---|---|
| `.env` | 包含 API Key / 密钥，需手动备份 |
| `hermes-agent/` | Hermes 运行时代码（非配置） |
| `node/` | Node.js 依赖 |
| `sessions/` | 会话历史（可重建） |
| `checkpoints/` | 快照（可重建） |
| `logs/` | 运行日志 |
| `cache/` | 缓存文件 |
| `state.db` | 状态数据库（二进制，可重建） |

## 用法

### 1. 在其他机器上恢复/同步

```bash
# 克隆仓库
git clone https://github.com/rentoiclq6/Hermesagentbackup.git ~/hermes-backup

# 停止 Hermes（如正在运行）
pkill -f hermes

# 备份当前 ~/.hermes（如有）
mv ~/.hermes ~/.hermes.bak

# 创建新目录
mkdir ~/.hermes

# 恢复配置和技能
cp -r ~/hermes-backup/config.yaml ~/.hermes/
cp -r ~/hermes-backup/skills ~/.hermes/
cp -r ~/hermes-backup/profiles ~/.hermes/
cp -r ~/hermes-backup/plans ~/.hermes/
cp -r ~/hermes-backup/hooks ~/.hermes/
cp -r ~/hermes-backup/memories ~/.hermes/
cp -r ~/hermes-backup/cron ~/.hermes/
cp -r ~/hermes-backup/SOUL.md ~/.hermes/

# ⚠️ 重要：恢复 .env（含 API Key，单独保管，不在 git 中）
# 将你保存的 .env 复制到 ~/.hermes/.env

# 验证配置生效
hermes config show
```

### 2. 推送本地配置变更

```bash
cd ~/.hermes
git add -A
git commit -m "update: $(date +%Y-%m-%d_%H:%M)"
git push
```

### 3. 拉取远程最新配置

```bash
cd ~/.hermes
git pull
```

## 首次初始化说明

本仓库由 `git init ~/.hermes` 方式创建，将 Hermes 主的配置目录直接作为 git 仓库管理。首次推送后已在 `~/.hermes/.git/config` 中配置了 `credential.helper store`，后续 `git pull/push` 无需重复输入凭据。

如需切换为 SSH 方式：

```bash
cd ~/.hermes
git remote set-url origin git@github.com:rentoiclq6/Hermesagentbackup.git
```

## 关联文档

- [Hermes Agent 官方文档](https://hermes-agent.nousresearch.com/docs)
- [Hermes Agent GitHub](https://github.com/NousResearch/hermes-agent)
