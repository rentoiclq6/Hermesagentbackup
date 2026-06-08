# Python Docker Deployment — Dependency Pitfalls

## 1. Pydantic EmailStr → Missing email-validator

**Symptoms during startup:**
```
ImportError: email-validator is not installed, run `pip install pydantic[email]`
```

**Fix:** Add to requirements.txt:
```
email-validator==2.1.0.post1
```

**Root cause:** Pydantic v2's `EmailStr` type requires `email-validator` as an extra dependency. It's not pulled in automatically with `pydantic==2.5.0`.

**Rebuild after fix:** Always use `--no-cache` when rebuilding after dependency changes:
```bash
docker compose -f docker-compose.dev.yml build --no-cache backend
docker compose -f docker-compose.dev.yml up -d backend
```

---

## 2. passlib + bcrypt 5.x incompatibility

**Symptoms during init script execution:**
```
(trapped) error reading bcrypt version
AttributeError: module 'bcrypt' has no attribute '__about__'
...
Error creating default user: password cannot be longer than 72 bytes
```

**Fix:** Pin bcrypt to 4.0.1 in requirements.txt:
```
passlib[bcrypt]==1.7.4
bcrypt==4.0.1
```

**Root cause:** passlib 1.7.4 hardcodes `bcrypt.__about__.__version__` to detect the backend, but bcrypt >= 4.1 removed the `__about__` submodule. The "72 bytes" error is a red herring — the real issue is passlib can't detect/initialize its bcrypt backend at all.

**Note:** Saving the hashed password to the database may succeed with a fallback handler, but the user creation will fail. The fix must go in requirements.txt BEFORE the Docker build.

---

## 3. General Python Dependency Checklist for Docker Builds

Watch for these common missing items when a FastAPI/Python app crashes on startup:

| Missing Dependency | Error Signature | Fix |
|---|---|---|
| `email-validator` | `ImportError: email-validator is not installed` | Add to requirements.txt |
| `bcrypt<4.1` | `AttributeError: module 'bcrypt' has no attribute '__about__'` | Pin `bcrypt==4.0.1` |
| `psycopg2-binary` | `ModuleNotFoundError: No module named 'psycopg2'` | Add to requirements.txt |
| `python-multipart` | `ImportError: multipart form data is not supported` | Add to requirements.txt |
| `alembic` | `ModuleNotFoundError: No module named 'alembic'` | Add to requirements.txt |

**Diagnostic workflow:**
1. Check container logs: `docker compose logs --tail=50 backend`
2. Identify the ImportError or stack trace
3. Add missing dependency to requirements.txt
4. Rebuild: `docker compose build --no-cache backend`
5. Recreate: `docker compose up -d backend`
6. Verify: `docker compose ps` → confirm "(healthy)" status
