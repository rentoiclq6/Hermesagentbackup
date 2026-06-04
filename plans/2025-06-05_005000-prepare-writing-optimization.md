# Hermes `prepare-writing` 性能调优执行方案

## Goal

解决 `prepare-writing` 阶段长时间卡顿问题，通过配置调优 + 自愈脚本实现根治。

## 调整清单（用户确认版）

共 3 项配置修改 + 1 项自愈脚本，按顺序执行。

---

### 1. 压缩阈值调低

| 项目 | 当前值 | 目标值 |
|---|---|---|
| `compression.threshold` | `0.5` | `0.4` |

- 文档中写 `compaction.trigger_threshold`, 实际 config 键为 `compression.threshold`（功能一致，都是触发上下文压缩的阈值）。
- 目标值 0.4 意味着上下文利用率达到 40% 即触发压缩，比 0.5 更激进，能更早预防膨胀。

**命令：**
```yaml
# ~/.hermes/config.yaml
compression:
  threshold: 0.4
```

---

### 2. Gateway 超时 + 独立超时参数

| 项目 | 当前值 | 目标值 |
|---|---|---|
| `agent.gateway_timeout` | `1800` | `300` |

- `gateway_timeout` 从 1800s（30分钟）降到 300s（5分钟），防止 prepare-writing 无限挂起。
- 用户还指定了 `request_timeout_seconds: 300` 和 `stale_timeout_seconds: 120`，这两个键在当前 Hermes 版本的 config 模板中不存在。
- **处理策略**：先执行 `hermes config set` 尝试写入，如果该版本支持则生效；如果不支持，命令会报错，届时只保留 `gateway_timeout: 300` 作为等效替代。

**命令（顺序执行）：**
```bash
hermes config set agent.gateway_timeout 300
hermes config set request_timeout_seconds 300    # 尝试，可能跳过
hermes config set stale_timeout_seconds 120      # 尝试，可能跳过
```

---

### 3. 异步工具执行模式

| 项目 | 当前值 | 目标值 |
|---|---|---|
| `tool_execution_mode` | （不存在） | `async` |

- 当前 config 中无此键。用户指定的值为 `asy`，按文档上下文推断实际应为 `async`。
- **处理策略**：先执行 `hermes config set` 尝试写入。若该命令不支持此键或报错，则不再处理。

**命令：**
```bash
hermes config set tool_execution_mode async
```

---

### 4. 自愈脚本 + crontab（可选执行项）

- 创建 `~/hermes_fix.sh`
- 内容：检测日志中 `prepare-writing` 挂起超过 10 分钟，自动 `/new` 重建会话。
- 注册 crontab：每 10 分钟执行一次。

**是否执行此步骤由你决定。**

---

## 执行顺序

```
Step 1 → compression.threshold → 0.4
Step 2 → gateway_timeout → 300 + 尝试新增超时键
Step 3 → tool_execution_mode → async
Step 4 → 自愈脚本 + crontab（待你确认）
```

前 3 步互不依赖，可依次执行。每步执行后输出结果，出错即停。

## 验证方法

```bash
# 1. 检查配置是否正确写入
hermes config show | grep -E "threshold|timeout|execution"

# 2. 直接查看 config.yaml 确认
grep -n "threshold\|timeout\|execution" ~/.hermes/config.yaml

# 3. 新建会话测试 prepare-writing 速度
hermes session new
```

## 风险 & 回退

- `compression.threshold: 0.4` 更频繁压缩可能增加少量 token 开销，但不影响功能。回退：改为 0.5。
- 不存在的 config 键写入会报错但不影响已有配置（`hermes config set` 失败不会破坏文件）。
- 如有重大故障：`hermes config edit` 手动恢复或从 backup 还原。

## 待你确认

1. **前三步是否可以立即执行？**
2. **第 4 步（自愈脚本 + crontab）是否一并执行？**
