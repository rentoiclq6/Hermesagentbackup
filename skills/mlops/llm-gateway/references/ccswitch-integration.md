# ccswitch + liteLLM Integration

## What is ccswitch

[huangdijia/ccswitch](https://github.com/huangdijia/ccswitch) is a Go CLI tool for managing and switching between multiple Claude Code API profiles. It stores profiles in `~/.ccswitch/ccs.json` and applies them by writing to `~/.claude/settings.json`.

**Install:**
```bash
curl -sSL https://raw.githubusercontent.com/huangdijia/ccswitch/main/install.sh | bash
```

## Adding the liteLLM Profile

Run this **after** liteLLM gateway is running:

```bash
ccswitch add litellm \
  --api-key "sk-0a86e74a48d34fc49916b96eff685f26" \
  --base-url "http://localhost:4000" \
  --model "general" \
  --description "LiteLLM → DeepSeek V4 (general=flash, v4-flash HA, v4-pro HA)"
```

This creates a profile with these settings (stored in `~/.ccswitch/ccs.json`):

| Setting | Value | Purpose |
|---------|-------|---------|
| `ANTHROPIC_BASE_URL` | `http://localhost:4000` | Points Claude Code to liteLLM |
| `ANTHROPIC_AUTH_TOKEN` | `sk-0a86e74a48d34fc49916b96eff685f26` | Gateway auth key |
| `ANTHROPIC_MODEL` | `general` | Default model (cheapest) |
| `ANTHROPIC_SMALL_FAST_MODEL` | `general` | Fast/cheap tasks |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | `general` | Lightweight tasks |
| `ANTHROPIC_DEFAULT_SONNET_MODEL` | `v4-flash` | Balanced tasks (HA flash) |
| `ANTHROPIC_DEFAULT_OPUS_MODEL` | `v4-pro` | Heavy reasoning (HA pro) |

## Switching Profiles

```bash
# Interactive selection (keyboard ↑↓ arrows)
ccswitch use

# Direct switch
ccswitch use litellm           # → liteLLM gateway
ccswitch use default           # → official Anthropic
ccswitch use deepseek          # → DeepSeek direct (bypasses liteLLM)

# View current profile
ccswitch show

# List all profiles
ccswitch list
```

## Model Selection in Claude Code

| Claude Code Command | Routes to | Cost |
|---|---|---|
| `claude "prompt"` (default) | `general` → v4-flash (direct) | Cheapest |
| `claude --model v4-flash "prompt"` | v4-flash HA (DeepSeek + OpenRouter) | Low + HA |
| `claude --model v4-pro "prompt"` | v4-pro HA + auto fallback to flash | Higher + HA |

Override per-session:
```bash
export ANTHROPIC_MODEL=v4-pro
claude "complex task"
unset ANTHROPIC_MODEL
```

## Under the Hood

When `ccswitch use litellm` runs, it writes to `~/.claude/settings.json`:
```json
{
  "ANTHROPIC_BASE_URL": "http://localhost:4000",
  "ANTHROPIC_AUTH_TOKEN": "sk-0a86e74a48d34fc49916b96eff685f26",
  "ANTHROPIC_MODEL": "general",
  "ANTHROPIC_SMALL_FAST_MODEL": "general",
  "ANTHROPIC_DEFAULT_SONNET_MODEL": "v4-flash",
  "ANTHROPIC_DEFAULT_OPUS_MODEL": "v4-pro",
  "ANTHROPIC_DEFAULT_HAIKU_MODEL": "general"
}
```

Claude Code reads these on startup and sends `/v1/messages` (Anthropic format) requests to liteLLM, which translates them to OpenAI format for DeepSeek.

## Important Notes

- liteLLM must be **running** before `ccswitch use litellm` or Claude Code will fail to connect.
- The OpenRouter backup provider requires `OPENROUTER_API_KEY` env var set **before** liteLLM starts. Without it, the HA entries behave as single-provider.
- DeepSeek's thinking blocks appear in the Anthropic response as `type: "thinking"` content blocks — Claude Code handles these natively.
- Switch back to official Anthropic anytime: `ccswitch use default`
