---
name: agent-self-management
title: 代理自我管理 — 跨会话衔接与自检诚实度
description: >-
  Class-level meta-skill for how the agent manages itself across sessions:
  cross-session handoff (session_search triggers, memory state management)
  and self-audit (weekly honesty/uncertainty reports via cronjob).
tags: [meta, session-handoff, self-audit, cross-session, honesty-report, memory, cronjob]
---

# Agent Self-Management

> **Class of tasks:** Managing how the agent recalls cross-session context and
> audits its own uncertainty labeling. A human maintainer would write this as
> one skill with labeled subsections — not two separate micro-skills.

Loaded when: the user mentions continuing previous work, refers to past sessions,
or the self-audit cronjob fires.

---

## Section A: Cross-Session Handoff

### Trigger Conditions

When the user says any of the following, **immediately** call `session_search()` to
locate the relevant prior session — do NOT ask "what do you mean?":

- "继续" + project/tool name (e.g., "继续 MCP", "继续 STS2 Mod")
- "接上", "上次那个", "之前那个", "之前的事"
- "还记得我们做的..." / "之前搞的那个..."
- "接着之前的工作"
- Simple mention of a previously-discussed game/tool name — search first, then
  ask if unclear

### Search Strategy

1. Use project name + key verbs (e.g., "Frida MCP 连接", "STS2 Mod", "Ghidra 反编译")
2. If nothing found, retry with synonyms once
3. If still nothing, then ask the user for clarification
4. Once found, summarize: "last step reached + next options"

### Memory State Management

- After complex multi-session tasks (mod development, reverse engineering, etc.),
  save a **one-line status line** to memory at end of conversation
- Format: `[ProjectName] Progress summary | Next step`
- Before saving, check memory capacity — compress or replace older entries if full

### Relationship with PLAN Mode

- New task → use PLAN mode
- Continuing old task → session_search first → decide whether a new plan is needed

---

## Section B: Config Management & Backup

### Purpose
Maintain Hermes configuration under version control and recover from corruption or hardware migration.

### Config Backup to GitHub
When the user asks to sync/backup/mirror Hermes config, reference the full procedure in:
- `references/config-backup-github.md` — step-by-step: git init, .gitignore, credential store, push

Key points extracted from that procedure:
- Exclude `.env` (API keys), `hermes-agent/`, `node/`, `checkpoints/`, `sessions/`, `logs/`, `cache/`, `state.db*`
- Use classic PAT (`ghp_...`) not fine-grained — fine-grained PATs require explicit repo grant and often 403
- Credential must be cached since git push runs non-interactively in WSL terminal
- Subsequent syncs: `git add -A && git commit -m "update: $(date +%Y-%m-%d)" && git push`

### Config Tuning
Performance tuning (e.g., `prepare-writing` optimization) typically modifies:
- `compression.threshold` — 0.4 for more aggressive compaction (from default 0.5)
- `agent.gateway_timeout` — 300s (from 1800s)
- `request_timeout_seconds` / `stale_timeout_seconds` — 300s / 120s (if supported)
- `tool_execution_mode` — `async` (if supported)

Always verify with `grep -n "threshold\|timeout\|execution" ~/.hermes/config.yaml` after changes.

### Clone vs Backup
- **Clone** (profile-based): `hermes profile create clone-me --clone-all`, then clean + tar.gz to desktop. For physical transfer to another machine.
- **Backup** (git-based): Turn `~/.hermes/` into git repo, push to GitHub. For ongoing incremental sync and history.

---

## Section C: Self-Audit (Honesty Report)

### Purpose
Weekly cronjob that scans the past 7 days of conversations and reports the
proportion of ✅ / 🟡 / ❓ certainty labels used in assistant messages.

### Trigger
Cronjob runs once per week, delivers result to the user's terminal.

### Method
1. Use `session_search` to find conversations from the past 7 days
2. Scan each assistant message for certainty labels ✅ / 🟡 / ❓
3. Count occurrences, calculate percentages, note trends

### Output Format
```
═══════════════════════════════════════
  AI 诚实度周报 (2026-05-09 ~ 2026-05-16)
═══════════════════════════════════════

✅ 确定:   42 次 (67%)
🟡 推测:   15 次 (24%)
❓ 不确定:  6 次 (9%)

总计: 63 条带标签的回复

本周需要注意：
- 控制台命令部分推测过多，应优先查 help
- 存档机制描述准确，无问题
```

### Notes
- Only counts messages that have certainty labels; untagged messages are skipped
- If no tagged messages exist in the week, output "本周无标签数据"
- Data comes from `session_search` results — approximate, not perfect
- Session handoff behavior is documented in **Section A** above
