# Duplicate File Cleanup (from WSL)

## Strategy

Two-phase approach to minimize slow NTFS reads:

```
Phase 1: Size grouping (fast) — os.walk + os.path.getsize
Phase 2: Hash verify (focused) — MD5 only on same-size file groups
Phase 3: Bulk delete — entire _MEI* dirs first, then individual files
```

## Common Duplicate Sources on C:

| Source | WSL Path | Typical Space | Safe Strategy |
|---|---|---|---|
| PyInstaller `_MEI*` dirs | `AppData/Local/Temp/_MEI*/` | 100-500 MB per dir | **Bulk delete** entire directory |
| WeChat file cache | `xwechat_files/` | 100 MB-1 GB | Delete WeChat copies, keep original |
| Game/project backups | Anywhere | Variable | Ask user which copy to keep |
| Ghidra documentation stubs | `Downloads/ghidra_*/docs/` | 5-50 MB | Keep pypredef or typestubs, not both |
| Repeated installer downloads | `Downloads/` + WeChat cache | 100 MB-2 GB | Keep Downloads copy, delete WeChat |

## Reusable Python Template

Save this as a `.py` file in WSL and run. It scans user directories, finds duplicates, and produces a JSON report on the desktop.

```python
#!/usr/bin/env python3
"""Duplicate file finder for C: user directories"""
import os, hashlib, json
from collections import defaultdict

HOME = "/mnt/c/Users/<user>"
TARGETS = [
    f"{HOME}/Desktop", f"{HOME}/Downloads", f"{HOME}/Documents",
    f"{HOME}/Pictures", f"{HOME}/Music", f"{HOME}/Videos",
    f"{HOME}/AppData/Local/Temp",
]
SKIP_DIRS = {'node_modules', '.git', '__pycache__', 'venv', '.venv'}
SKIP_EXTS = {'.tmp', '.temp', '.log', '.cache'}
MIN_SIZE = 1024

files = []
for target in TARGETS:
    if not os.path.isdir(target):
        continue
    for root, dirs, filenames in os.walk(target):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for fn in filenames:
            ext = os.path.splitext(fn)[1].lower()
            if ext in SKIP_EXTS:
                continue
            fp = os.path.join(root, fn)
            try:
                sz = os.path.getsize(fp)
                if sz >= MIN_SIZE:
                    files.append((fp, sz))
            except (OSError, PermissionError):
                pass

size_groups = defaultdict(list)
for fp, sz in files:
    size_groups[sz].append(fp)
candidates = {sz: paths for sz, paths in size_groups.items() if len(paths) > 1}

duplicates = []
for size, paths in candidates.items():
    hash_map = defaultdict(list)
    for fp in paths:
        try:
            h = hashlib.md5()
            with open(fp, "rb", buffering=0) as f:
                for chunk in iter(lambda: f.read(65536), b""):
                    h.update(chunk)
            hash_map[h.hexdigest()].append(fp)
        except (OSError, PermissionError):
            pass
    for hval, dupe_paths in hash_map.items():
        if len(dupe_paths) > 1:
            duplicates.append({
                "hash": hval, "size": size, "files": dupe_paths,
                "keep": dupe_paths[0], "to_delete": dupe_paths[1:]
            })

report_path = f"{HOME}/Desktop/duplicates_report.json"
with open(report_path, "w", encoding="utf-8") as f:
    json.dump({"scanned_dirs": TARGETS,
               "total_files_scanned": len(files),
               "duplicate_groups": len(duplicates),
               "duplicates": duplicates}, f, ensure_ascii=False, indent=2)

print(f"Report saved to {report_path}")
print(f"Duplicates: {len(duplicates)} groups")
```

## Cleanup Template

```python
#!/usr/bin/env python3
"""Delete duplicates from report JSON"""
import json, os, shutil, glob

HOME = "/mnt/c/Users/<user>"
TEMP_DIR = f"{HOME}/AppData/Local/Temp"
REPORT_PATH = f"{HOME}/Desktop/duplicates_report.json"

with open(REPORT_PATH) as f:
    data = json.load(f)

total_bytes = 0
errors = []

# Step 1: Bulk delete _MEI* dirs (PyInstaller artifacts)
for d in sorted(glob.glob(f"{TEMP_DIR}/_MEI*/")):
    if os.path.isdir(d):
        sz = sum(f.stat().st_size for f in os.scandir(d) if f.is_file())
        shutil.rmtree(d, ignore_errors=True)
        total_bytes += sz

# Step 2: Delete remaining file-level duplicates
for dup in data["duplicates"]:
    for fp in dup["to_delete"]:
        if "/_MEI" in fp or not os.path.exists(fp):
            continue
        try:
            sz = os.path.getsize(fp)
            os.remove(fp)
            total_bytes += sz
        except Exception as e:
            errors.append(f"{fp}: {e}")

print(f"Freed: {total_bytes/1024/1024:.1f} MB")
print(f"Errors: {len(errors)}")
```

## Pitfalls

1. **Sysinternals SDelete / `cleanmgr`** — for files WSL can't touch (e.g. `$Recycle.Bin`, `Windows.old`), recommend `cmd.exe /c cleanmgr`.
2. **`_MEI*` dirs** — some may have locked `.pyd`/`.dll` files if the originating process is still running. They'll be cleaned on reboot.
3. **WeChat chat database** — `solitaire.db-shm` etc. are locked while WeChat runs. Skip these.
4. **Large datasets (20k+ files)** — expect 1-5 minutes per 10,000 files for hashing through DrvFs. Acceptable for one-shot cleanup.
