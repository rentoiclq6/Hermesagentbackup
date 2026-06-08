---
name: llm-gateway
description: Deploy and manage LLM API gateways (liteLLM, etc.) — multi-model routing, provider HA, format translation, cost controls, and client integration.
category: mlops
triggers:
  - liteLLM, gateway, model routing, multi-provider, cost-based routing, latency-based routing, ANTHROPIC_BASE_URL, ccswitch, fallback strategy, model proxy
  - User asks to "route", "proxy", "gateway" LLM APIs, or deploy a unified API entry point
  - User mentions liteLLM, OpenRouter, or multi-provider HA for LLMs
---

# LLM Gateway — liteLLM Deployment & Management

## Overview

liteLLM is a lightweight proxy that exposes a unified OpenAI-compatible API for 100+ LLM providers. It supports:

- **Multi-model routing** — single endpoint serving multiple models
- **Provider HA** — same model from multiple providers with auto-failover
- **Format translation** — `/v1/messages` (Anthropic) → provider-native format
- **Cost controls** — budget caps, cooldowns, pricing-aware routing
- **Caching** — response caching for repeated queries

## Config File Location

liteLLM on Windows Python:
```
C:\Users\<user>\AppData\Local\Programs\Python\Python312\Lib\site-packages\litellm\config.yaml
```

## Model Entry Patterns

### Pattern 1: Simple Direct (single model, single provider)
```yaml
- model_name: general
  litellm_params:
    model: deepseek/deepseek-v4-flash
    api_key: sk-xxx
    rpm: 2400
  model_info:
    mode: chat
    supports_function_calling: true
    max_tokens: 384000
```

### Pattern 2: Dual-Provider HA (same model_name, two providers)
```yaml
- model_name: v4-flash
  litellm_params:
    model: deepseek/deepseek-v4-flash
    api_key: sk-xxx
    rpm: 2400
  model_info:
    mode: chat
    max_tokens: 384000
    input_cost_per_token: 0.00000014
    output_cost_per_token: 0.00000028

- model_name: v4-flash              # SAME model_name = load-balanced group
  litellm_params:
    model: openrouter/deepseek/deepseek-v4-flash
    api_key: os.environ/OPENROUTER_API_KEY
    rpm: 2400
  model_info:
    mode: chat
    max_tokens: 384000
    input_cost_per_token: 0.00000018
    output_cost_per_token: 0.00000035
```

### Pattern 3: Cross-Model Fallback
```yaml
router_settings:
  fallbacks:
    - {"v4-pro": ["v4-flash"]}    # Pro fails → fall back to Flash
```

## Router Settings

```yaml
router_settings:
  routing_strategy: latency-based-routing    # Preferred for HA: picks fastest
  enable_loadbalancing: true
  num_retries: 2
  request_timeout: 30
  fallbacks:
    - {"v4-pro": ["v4-flash"]}
  cooldown_time: 300                         # Failed providers cool for 5min
  max_budget: 20.0
  budget_duration: 1d
  cache: True
  cache_params:
    type: local
    ttl: 3600                                # 1-hour cache
```

### Routing Strategies
| Strategy | Best For | Behavior |
|----------|----------|----------|
| `latency-based-routing` | HA, reliability | Picks fastest provider, auto-skips slow/failing |
| `cost-based-routing` | Budget control | Picks cheapest (requires pricing in model_info) |
| `usage-based-routing` | Even distribution | Round-robin across providers |
| (unset) | Simple setups | Always tries first entry, falls back if fails |

## Windows Startup Script (Batch File)

For one-click desktop launchers that start liteLLM and optionally launch Hermes (WSL or Windows).

### Critical Rules

1. **Pure ASCII only** — Box-drawing Unicode (╔║╚╝) renders as garbage in Windows CMD. Use `+-|`.
2. **CRLF line endings** — LF-only batch files fail. Fix from WSL: `sed -i 's/$/\\r/' file.bat`
3. **No `chcp 65001`** — UTF-8 code page breaks text rendering. Avoid it.
4. **STRUCTURE: `goto` labels before `goto :eof`** — In batch files, every subroutine label (`:name`) that ends with `goto :eof` MUST be placed AFTER a `goto main_menu` jump at the top of the file. If the script falls through to a subroutine label and hits `goto :eof` without having been `call`ed, the ENTIRE SCRIPT terminates immediately (flash-exit). This is the #1 cause of batch files that "open and close instantly."
5. **Detect before launch** — Poll `/health/readiness` in a loop before declaring liteLLM ready.

### Key Code Snippets

```batch
:: Start liteLLM hidden
start /B /MIN "" "%LITELLM_EXE%" --config "%LITELLM_CONFIG%" --port %LITELLM_PORT% > "%LITELLM_LOG%" 2>&1

:: Wait loop (requires setlocal enabledelayedexpansion)
:wait_loop
set /a wait_count+=1
if !wait_count! gtr 25 ( exit /b 1 )
>nul 2>&1 curl -s http://localhost:%LITELLM_PORT%/health/readiness
if !errorlevel! neq 0 ( timeout /t 1 /nobreak >nul & goto wait_loop )

:: Open WSL Hermes in new window
start "Hermes (WSL)" wsl -e bash -c "hermes; exec bash"

:: Open Windows Hermes in new window
start "Hermes (Windows)" "C:\Users\<user>\AppData\Local\hermes\hermes-agent\venv\Scripts\hermes.exe"

:: Stop liteLLM
taskkill /f /im litellm.exe >nul 2>&1

:: Status detection
>nul 2>&1 curl -s http://localhost:%LITELLM_PORT%/health/readiness
if %errorlevel% equ 0 (set LITELLM_RUNNING=1) else (set LITELLM_RUNNING=0)
```

See `references/windows-batch-launcher.md` for full reference.
See `templates/hermes-litellm-launcher.bat` for a complete, copy-pasteable template.

## File Structure

| File | Purpose |
|------|---------|
| `templates/litellm-deepseek-config.yaml` | Full liteLLM config with dual-provider HA |
| `templates/hermes-litellm-launcher.bat` | Windows batch launcher (start liteLLM + Hermes) |
| `references/ccswitch-integration.md` | ccswitch profile setup for Claude Code |
| `references/windows-batch-launcher.md` | Batch file patterns and Windows CMD pitfalls |

## Anthropic Format Proxy

liteLLM **natively** translates Anthropic Messages API (`/v1/messages`) to provider-native format. No extra config needed.

**Quick env setup** (manual, no ccswitch):
```bash
export ANTHROPIC_BASE_URL="http://localhost:4000"
export ANTHROPIC_API_KEY="sk-xxx"       # Same as gateway's api_key
```

**ccswitch profile setup** (preferred — huangdijia/ccswitch CLI tool):
```bash
ccswitch add litellm \
  --api-key "sk-xxx" \
  --base-url "http://localhost:4000" \
  --model "general" \
  --description "LiteLLM → DeepSeek V4"

ccswitch use litellm   # Activate the profile
```
See `references/ccswitch-integration.md` for full ccswitch usage with model mapping and profile management.

**Test command:**
```bash
curl http://localhost:4000/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: sk-xxx" \
  -H "anthropic-version: 2023-06-01" \
  -d '{"model":"general","max_tokens":1024,"messages":[{"role":"user","content":"hi"}]}'
```

The response comes back in proper Anthropic format (`type: message`, `content` array, `stop_reason`, etc.) including thinking blocks if the model supports them.

## Cost Controls

### Pricing in model_info
```yaml
model_info:
  input_cost_per_token: 0.00000014          # $0.14/1M input
  output_cost_per_token: 0.00000028         # $0.28/1M output
  input_cost_per_token_cache_hit: 0.0000000028  # $0.0028/1M cache hit
```

### Budget Caps
```yaml
router_settings:
  max_budget: 20.0
  budget_duration: 1d
```

### Response Caching
```yaml
router_settings:
  cache: True
  cache_params:
    type: local                              # In-memory cache
    ttl: 3600                                # Seconds
```

## Pitfalls

1. **WSL cannot run Windows .exe directly** — liteLLM installed on Windows Python must be started from CMD/PowerShell, not WSL. Workaround: `cmd.exe /c "start /B litellm ... > log.txt 2>&1"`.
2. **max_tokens vs context window** — Set `max_tokens` to the model's *output* limit, not context window. DeepSeek V4: 384K max output (context is 1M).
3. **Cost-based routing is inert with single-entry model_names** — It only activates when a model_name has multiple `litellm_params` entries. Otherwise it's a no-op.
4. **OpenRouter env var** — `os.environ/OPENROUTER_API_KEY` requires the env var to be set BEFORE starting liteLLM. Missing var = that provider entry is silently skipped.
5. **Windows CMD vs PowerShell** — CMD uses `set VAR=val`, PowerShell uses `$env:VAR="val"`. Use CMD for best compatibility with liteLLM startup.
6. **Cache hit pricing** — DeepSeek cache hit is ~50x cheaper than cache miss. Always add `input_cost_per_token_cache_hit` for accurate cost tracking.

## Verification Checklist

- [ ] Server starts: `curl localhost:4000/health/readiness` → `{"status":"healthy"}`
- [ ] Models listed: `curl localhost:4000/v1/models` shows all model_names
- [ ] OpenAI format: `/v1/chat/completions` returns valid response
- [ ] Anthropic format: `/v1/messages` returns valid Anthropic-format response
- [ ] All model_names produce valid completions (general, v4-flash, v4-pro, etc.)
