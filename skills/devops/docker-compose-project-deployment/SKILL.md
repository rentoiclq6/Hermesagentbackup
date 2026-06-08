---
name: docker-compose-project-deployment
title: Docker Compose Project Deployment
description: End-to-end workflow for deploying a project via Docker Compose — reading setup docs, installing Docker if needed, building, running, initializing data, and verifying.
triggers:
  - "帮我跑起来这个项目 / 用docker部署"
  - "我想用docker跑这个项目"
  - "帮我部署一下这个docker项目"
  - "参考 DOCKER_SETUP.md 部署"
  - Any request to build and run a project via Docker Compose from a local path
---

# Docker Compose Project Deployment

## Overview

When a user says "deploy this project with Docker" and provides a project path, follow this workflow. It handles the full lifecycle: from reading docs to verifying the running service.

**CRITICAL: Don't stop at backend verification.** Many projects are full-stack (backend in Docker + frontend as a separate dev server). The user judges success by seeing the UI in their browser, not by a healthy backend API. Always check if a frontend directory exists and serve it — proactively, before the user asks. But also: **don't assume a login page exists.** Many SPAs skip login UI entirely. Check the router config to know which pages are functional and tell the user upfront.

## Step 1: Read the Project's Docker Documentation

Look for these files in order of priority:
1. `DOCKER_SETUP.md` — most specific instructions
2. `docker-compose.dev.yml` — development setup
3. `docker-compose.yml` — production setup
4. `scripts/dev-start.sh` or `scripts/docker-start.sh` — helper scripts

Read them fully. Don't assume the setup — the project may have custom steps (e.g. init scripts, env files, specific compose files).

## Step 2: Check Project Structure

List the project root to confirm:
- `docker-compose*.yml` exists
- Any `.env` or `.env.example` files
- Dockerfile in backend/ or similar

**Pitfall**: The project lives on Windows (e.g. `D:\github\project`). Translate to `/mnt/d/github/project`. If the user's project is on an external drive, check all /mnt/ mounts.

## Step 3: Ensure Docker Is Available

```bash
# Check if Docker Engine is installed and running
which docker && docker ps 2>/dev/null
```

### If Docker is NOT installed (WSL Ubuntu):
Run the install script (requires sudo password):
```bash
# Install prerequisites
sudo apt-get update && sudo apt-get install -y ca-certificates curl

# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start Docker daemon
sudo service docker start

# Add user to docker group (may need newgrp docker to take effect)
sudo usermod -aG docker $USER
```

**Pitfall**: `sudo service docker start` may fail if Docker was installed as a snap or container. If so, try `sudo dockerd &` or `sudo systemctl start docker`. In WSL, systemd may not be available — `sudo service docker start` is the preferred approach.

**Pitfall**: After adding user to docker group, the user must run `newgrp docker` or re-login for permissions to take effect. `docker ps` without this will still show permission denied.

### If Docker is installed but not running:
```bash
sudo service docker start
```

## Step 4: Build and Run

Navigate to the project directory and run:

```bash
cd /mnt/<drive>/<path>/<project>

# Stop any stale containers
docker-compose -f docker-compose.dev.yml down 2>/dev/null

# Build and start
docker-compose -f docker-compose.dev.yml up --build -d
```

**Pitfall**: Some projects use `docker compose` (v2 plugin) vs `docker-compose` (v1 standalone). The docker-compose-plugin from Step 3 uses `docker compose`. Try both:
- `docker compose -f ...` (v2, preferred)
- `docker-compose -f ...` (v1, fallback)

**Pitfall**: Build failures from network timeouts or missing dependencies — retry once. If it persists, check if the Dockerfile references resources that need VPN or authentication.

## Step 5: Wait for Dependencies and Initialize Data

After containers are up, many projects need:
1. A wait period for DB to fully initialize
2. Running an init script to create tables and seed data

**Better than sleep: check for healthy status:**
```bash
# Wait until backend shows "(healthy)" — more reliable than fixed sleep
sleep 5
docker compose -f docker-compose.dev.yml ps
# Look for "(healthy)" in the STATUS column before proceeding
```

Then run init scripts:
```bash
docker compose -f docker-compose.dev.yml exec backend python init_default_user.py
docker compose -f docker-compose.dev.yml exec backend python test_db.py
```

**Pitfall**: `docker compose exec` vs `docker-compose exec` — use the same variant that worked in Step 4.

**Pitfall**: `docker compose exec` may fail if the backend container hasn't finished starting. Check with `docker compose -f docker-compose.dev.yml ps` first.

**Pitfall**: If the backend is restarting (exit code 1), check logs immediately — don't wait. Something crashed during startup.

## Step 6: Verify the Backend Service

```bash
# Check all containers are running
docker compose -f docker-compose.dev.yml ps

# Check logs for errors
docker compose -f docker-compose.dev.yml logs --tail=30

# Hit the health endpoint
curl http://localhost:<port>/health
```

Report to the user:
- Which port the backend is running on
- The default login credentials if created
- Log locations if troubleshooting

**DO NOT STOP HERE.** Proceed to Step 7 if the project has a frontend.

## Step 7: Serve the Frontend (if exists)

Many projects containerize only the backend. The frontend runs as a separate dev server. Check for a frontend directory:

```bash
ls <project>/frontend/package.json 2>/dev/null && echo "Frontend found"
ls <project>/frontend/vite.config.ts 2>/dev/null && echo "Vite project"
ls <project>/frontend/next.config.js 2>/dev/null && echo "Next.js project"
```

If a frontend exists, serve it:

### For Vite + React (most common)
```bash
cd <project>/frontend

# ✔ FIRST: Check and create .env if missing
# Vite reads VITE_API_BASE_URL at build time. Without it, API calls silently fail.
ls .env 2>/dev/null || {
  echo ".env missing — creating from .env.example (if exists)"
  cp .env.example .env 2>/dev/null || echo "VITE_API_BASE_URL=http://localhost:9000" > .env
}

npm install                # if node_modules missing
npx vite --host            # background mode
```

Then verify:
```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost:5173/
# Expect: 200
```

### For Next.js
```bash
cd <project>/frontend
npm install
npx next dev -p 3000
```

### For plain React (Create React App)
```bash
cd <project>/frontend
npm install
npx react-scripts start
```

**Pitfall: Background process output may buffer.** If `npx vite --host` runs in background with no output in the log, don't assume it's broken — check with `curl localhost:5173` to get the actual HTTP status. The Vite dev server starts silently when buffered.

**Pitfall: Node.js or npm missing from WSL.** If `node --version` fails, install via nvm or apt. Node 18+ is sufficient for modern frontend tooling.

**Pitfall: TypeScript + Vite may take 1-3 seconds to compile on first startup.** The 200 response may lag behind the process start. Wait a few seconds before curl-checking.

**CORS + API routing:** If the frontend calls the backend API directly (no vite proxy config), check that the backend's CORS_ORIGINS includes the frontend dev server URL (e.g. `http://localhost:5173`). If not, either:
- Add it to the docker-compose.env CORS_ORIGINS and restart backend, OR
- Add a `server.proxy` entry in vite.config.ts to proxy `/api` to the backend

**Pitfall — proxy + env variable conflict:** When you add a Vite proxy for `/api` to the backend, you MUST also clear `VITE_API_BASE_URL` in the `.env` file (set it to empty string). Otherwise the frontend's axios instance uses the absolute URL `http://localhost:9000/api/...` (bypassing the proxy) and hits CORS issues anyway. With the proxy, API calls go to the same origin — set `VITE_API_BASE_URL=` (empty) in `.env` so axios uses relative paths.

### Final delivery to the user

Tell the user exactly what to open in their browser and which routes are functional:

```text
前端页面: http://localhost:5173/
API 文档: http://localhost:9000/docs
登录账号: <username> / <password>

当前可用的页面:
- /interview/new （新的面试）✅
- /settings （系统设置）✅
- /interview/meeting （面试会议）✅
```

**Important — not every project has a login page.** Some SPA projects skip login UI and just store a token in localStorage. If the project's router has no `/login` route, tell the user which pages are functional and which are placeholder/under-development so they don't waste time clicking dead routes.

If the user specifically asks "where's the login page" and the project doesn't have one, explain honestly that the login UI wasn't built yet — the auth code exists in the store but has no corresponding component. Offer to build one if they want it.

## Troubleshooting

### Container keeps restarting (exit code 1)

Don't wait — check logs immediately:
```bash
docker compose -f docker-compose.dev.yml logs --tail=50 backend
```

Common causes for Python/FastAPI projects:
1. Missing Pydantic dependency (`email-validator`)
2. passlib + bcrypt version incompatibility
3. Database unreachable (wrong DATABASE_URL or postgres not ready yet)

For fix steps, see `references/python-dependency-pitfalls.md` in this skill directory.

### Docker permission errors

```bash
# Ensure docker group membership took effect
newgrp docker
# Or restart WSL
```

- [ ] Docker docs read and understood
- [ ] Docker Engine available and running
- [ ] docker compose up --build -d completes without error
- [ ] Database initializes (sleep + check)
- [ ] Init scripts (default user, DB schema) run successfully
- [ ] Health endpoint returns 200
- [ ] Frontend dev server running (check package.json in frontend/)
- [ ] Functional frontend page accessible via browser URL (check the router for real pages — not all projects have a login page)
- [ ] User informed of full access URLs and credentials
