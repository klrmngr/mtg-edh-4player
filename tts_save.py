#!/usr/bin/env python3
"""
Decompose a Tabletop Simulator save into per-object JSON (so the whole table —
every card, deck, token, transform and image URL, not just the scripts — can be
version controlled) and recompose those files back into a loadable save.

Two modes:

    python tts_save.py split [save.json]
        Read a full TTS save and write one file per top-level object to
        objects/<name>.<guid>.json, plus the surrounding save metadata to
        save.template.json. Defaults to the most-recently-modified TS_Save in
        the TTS Saves directory.

    python tts_save.py build [--out-dir DIR]
        Reassemble save.template.json + objects/*.json + main.lua + ui.xml into
        a full save written to
            DIR/MTG EDH 4-player (χ) <version>-<YYYYMMDDHHMMSS>.json
        where <version> is read from src/patchnotes.lua. DIR comes from the
        argument, else SAVE_DIR in a local .env, else the current directory.

The Lua/XML *source* stays single-sourced: the global script comes from main.lua
and ui.xml, and each object's script comes from its objects/<name>.<guid>.{lua,xml}
when one exists. Those are stripped out of the JSON on split and injected back on
build, so the JSON only carries the "everything else" — transforms, nicknames,
image URLs, contained cards, saved Lua state, etc.
"""

import datetime
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_OBJECTS_DIR = os.path.join(HERE, "objects")
TEMPLATE_PATH = os.path.join(HERE, "save.template.json")
MAIN_LUA = os.path.join(HERE, "main.lua")
UI_XML = os.path.join(HERE, "ui.xml")
PATCHNOTES = os.path.join(HERE, "src", "patchnotes.lua")
ENV_PATH = os.path.join(HERE, ".env")

SAVES_DIR = os.path.expanduser("~/.local/share/Tabletop Simulator/Saves")
# Built saves are named "<SAVE_NAME> <version>-<timestamp>.json".
SAVE_NAME = "MTG EDH 4-player (χ)"

# Per-file extension -> the object key it maps to.
SCRIPT_KEYS = {".lua": "LuaScript", ".xml": "XmlUI"}


def safe_name(name: str) -> str:
    name = (name or "unnamed").strip() or "unnamed"
    return re.sub(r"[^A-Za-z0-9._-]+", "_", name)


def latest_save() -> str:
    saves = glob.glob(os.path.join(SAVES_DIR, "TS_Save_*.json"))
    if not saves:
        sys.exit(f"[tts] ERROR: no TS_Save_*.json found in {SAVES_DIR}")
    return max(saves, key=os.path.getmtime)


def script_files_by_guid(objects_dir: str) -> dict:
    """Map guid -> {".lua": path, ".xml": path} for tracked object scripts."""
    out: dict = {}
    for path in glob.glob(os.path.join(objects_dir, "*")):
        ext = os.path.splitext(path)[1]
        if ext not in SCRIPT_KEYS:
            continue
        base = os.path.basename(path)[: -len(ext)]
        guid = base.rpartition(".")[2]
        if guid:
            out.setdefault(guid, {})[ext] = path
    return out


def walk_objects(obj: dict):
    """Yield obj and every object nested in ContainedObjects / States."""
    yield obj
    for child in obj.get("ContainedObjects") or []:
        yield from walk_objects(child)
    for child in (obj.get("States") or {}).values():
        yield from walk_objects(child)


def read(path: str) -> str:
    with open(path, encoding="utf-8") as f:
        return f.read()


def load_env(path: str = ENV_PATH) -> dict:
    """Parse a simple KEY=VALUE .env file (no external dependency)."""
    env: dict = {}
    if not os.path.exists(path):
        return env
    for line in read(path).splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        env[key.strip()] = value.strip().strip('"').strip("'")
    return env


def read_version() -> str:
    """Current release tag from src/patchnotes.lua, e.g. 'v0.2.0'."""
    if os.path.exists(PATCHNOTES):
        m = re.search(r'VERSION\s*=\s*"([^"]+)"', read(PATCHNOTES))
        if m:
            return m.group(1)
    return "v0.0.0"


def split(save_path: str, objects_dir: str) -> None:
    with open(save_path, encoding="utf-8") as f:
        save = json.load(f)

    objects = save.pop("ObjectStates", [])
    tracked = script_files_by_guid(objects_dir)
    os.makedirs(objects_dir, exist_ok=True)

    written = 0
    for obj in objects:
        # Strip any script that is tracked as a .lua/.xml file (it gets injected
        # back on build); leave inline scripts that have no tracked file.
        for node in walk_objects(obj):
            files = tracked.get(node.get("GUID"), {})
            for ext, key in SCRIPT_KEYS.items():
                if ext in files:
                    node[key] = ""
        base = f"{safe_name(obj.get('Nickname') or obj.get('Name'))}.{obj.get('GUID')}"
        with open(os.path.join(objects_dir, base + ".json"), "w", encoding="utf-8") as f:
            json.dump(obj, f, indent=2, ensure_ascii=False)
        written += 1

    # The global script lives in main.lua / ui.xml; don't duplicate it here.
    save["LuaScript"] = ""
    save["XmlUI"] = ""
    with open(TEMPLATE_PATH, "w", encoding="utf-8") as f:
        json.dump(save, f, indent=2, ensure_ascii=False)

    print(f"[tts] split {os.path.basename(save_path)} -> {written} object(s) + save.template.json")


def build(objects_dir: str, out_dir: str = None) -> None:
    # Output location: explicit arg > SAVE_DIR in .env > current directory.
    if out_dir is None:
        out_dir = load_env().get("SAVE_DIR") or os.getcwd()
    out_dir = os.path.abspath(os.path.expanduser(out_dir))

    with open(TEMPLATE_PATH, encoding="utf-8") as f:
        save = json.load(f)

    save["LuaScript"] = read(MAIN_LUA) if os.path.exists(MAIN_LUA) else ""
    save["XmlUI"] = read(UI_XML) if os.path.exists(UI_XML) else ""

    tracked = script_files_by_guid(objects_dir)
    paths = sorted(
        p for p in glob.glob(os.path.join(objects_dir, "*.json"))
    )
    objects = []
    for path in paths:
        with open(path, encoding="utf-8") as f:
            obj = json.load(f)
        for node in walk_objects(obj):
            files = tracked.get(node.get("GUID"), {})
            for ext, key in SCRIPT_KEYS.items():
                if ext in files:
                    node[key] = read(files[ext])
        objects.append(obj)
    # Deterministic order by GUID for stable, reviewable saves.
    objects.sort(key=lambda o: o.get("GUID") or "")
    save["ObjectStates"] = objects

    now = datetime.datetime.now()
    stem = f"{SAVE_NAME} {read_version()}-{now:%Y%m%d%H%M%S}"
    save["SaveName"] = stem
    save["Date"] = now.strftime("%m/%d/%Y %I:%M:%S %p")
    save["EpochTime"] = int(now.timestamp())

    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, stem + ".json")
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(save, f, indent=2, ensure_ascii=False)
    print(f"[tts] built {len(objects)} object(s) -> {out_path}")


def main() -> None:
    args = sys.argv[1:]
    if not args or args[0] not in ("split", "build"):
        sys.exit(__doc__)
    mode, rest = args[0], args[1:]

    if mode == "split":
        positional = [a for a in rest if not a.startswith("--")]
        save_path = os.path.abspath(positional[0]) if positional else latest_save()
        split(save_path, DEFAULT_OBJECTS_DIR)
    else:
        # Accept either `build DIR` or `build --out-dir DIR`; otherwise the
        # output location comes from SAVE_DIR in .env (then the current dir).
        out_dir = None
        if rest and rest[0] == "--out-dir" and len(rest) > 1:
            out_dir = rest[1]
        elif rest and not rest[0].startswith("--"):
            out_dir = rest[0]
        build(DEFAULT_OBJECTS_DIR, out_dir)


if __name__ == "__main__":
    main()
