# Hermes Config Backup to GitHub

Procedure for turning `~/.hermes/` into a git repository and syncing to a GitHub remote.

## When to Use

- Initial full backup of Hermes config, skills, profiles, and state
- Ongoing incremental sync after config changes, skill additions, or tuning

## Prerequisites

- A GitHub repo (public or private) created on github.com
- Classic GitHub PAT (`ghp_...`) with `repo` scope — fine-grained PATs require explicit repo access grant and may produce 403

## Step-by-Step

### 1. Initialize Git Repo

```bash
cd ~/.hermes
git init
git branch -m main
```

### 2. Create .gitignore

Exclude large/transient/secrets:

```
# === Hermes config gitignore ===
hermes-agent/
node/
checkpoints/
sessions/
logs/
cache/
audio_cache/
image_cache/
sandboxes/
state.db*
*.db
*.db-*
.env
profiles/*/checkpoints/
profiles/*/sessions/
profiles/*/logs/
profiles/*/cache/
```

`.env` is excluded deliberately — contains API keys. Copy manually if needed.

### 3. First Commit

```bash
git add -A
git commit -m "init: hermes full config backup"
```

### 4. Set Remote & Push

```bash
git remote add origin https://github.com/<user>/<repo>.git
git remote set-url origin https://<user>:<PAT>@github.com/<user>/<repo>.git
git push -u origin main
```

### 5. Clean Remote URL & Cache Credentials

```bash
git remote set-url origin https://github.com/<user>/<repo>.git
git config credential.helper store
printf "protocol=https\nhost=github.com\nusername=%s\npassword=%s\n" "$USER" "$PAT" | git credential-store store
```

### 6. Subsequent Syncs

```bash
cd ~/.hermes
git add -A
git commit -m "update: $(date +%Y-%m-%d)"
git push
```

## Pitfalls

- **Fine-grained PAT**: Needs explicit repo access in GitHub settings. If you get 403, switch to a classic PAT (`ghp_...`) instead.
- **Non-interactive terminal**: `git push` over HTTPS will fail without stored credentials since there's no TTY for login prompts. Always use credential store or SSH.
- **.gitignore first**: Add `.gitignore` before `git add -A` to avoid accidentally staging large dirs (sessions/, checkpoints/ can be 100s of MB).
- **No SSH setup**: On WSL, SSH keys may not be configured. The credential store approach is simpler for first-time setup.
- **~/.hermes/.git in scope**: The `.git` directory lives inside ~/.hermes/ — it's unobtrusive but means git config (user.name, user.email, remote) is repo-local unless you add --global.

## Related

- Clone/migration (tar.gz to desktop): separate workflow for physical transfer or profile cloning
- Config optimization: tuning `compression.threshold`, `gateway_timeout`, etc. — see the `prepare-writing` optimization plan in plans/
