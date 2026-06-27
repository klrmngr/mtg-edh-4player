#!/usr/bin/env python3
"""
Watch the source and push CHANGED files to Tabletop Simulator on save.

On save it pushes only what changed:
  - main.lua / ui.xml  -> the Global script (guid -1)
  - objects/<name>.<guid>.{lua,xml} -> that object

This keeps pushes small and reliable (pushing all ~117 scripts at once is
~1 MB and tends to fail). Use --all to push everything once at startup, e.g.
after a fresh tts_pull.

Usage:
    python tts_push.py [path/to/script.lua] [path/to/ui.xml] [objects_dir] [--all] [--log]

Defaults to main.lua, ui.xml, and ./objects next to the script.
TTS must be running with a save open.

--log also tails TTS's Unity Player.log and prints its lines (prefixed "[log]"),
which is the only place engine messages like image-load failures
("load image failed unsupported format: UNKNOWN") show up -- they are NOT sent
over the editor socket. Override the auto-detected path with env var TTS_LOG.
"""

import json
import os
import socket
import sys
import threading
import time

TTS_HOST = "localhost"
TTS_PORT = 39999   # TTS listens here (editor → TTS)
EDITOR_PORT = 39998  # we listen here (TTS → editor)
GLOBAL_GUID = "-1"


def read_file(path: str) -> str:
    try:
        with open(path, encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return ""


def global_state(script_path: str, ui_path: str) -> dict:
    state = {"name": "Global", "guid": GLOBAL_GUID, "script": read_file(script_path)}
    ui = read_file(ui_path)
    if ui:
        state["ui"] = ui
    return state


def object_state(objects_dir: str, base: str) -> dict:
    # base is "<name>.<guid>"; guid is the last dot-segment
    name, _, guid = base.rpartition(".")
    state = {"name": name or "object", "guid": guid}
    lua = os.path.join(objects_dir, base + ".lua")
    xml = os.path.join(objects_dir, base + ".xml")
    if os.path.exists(lua):
        state["script"] = read_file(lua)
    if os.path.exists(xml):
        state["ui"] = read_file(xml)
    return state


def states_for_changed(changed: set, script_path: str, ui_path: str, objects_dir: str) -> list:
    states = []
    if script_path in changed or ui_path in changed:
        states.append(global_state(script_path, ui_path))
    seen = set()
    for p in changed:
        if p in (script_path, ui_path):
            continue
        fn = os.path.basename(p)
        if not fn.endswith((".lua", ".xml")):
            continue
        base = fn[:-4]
        if base in seen:
            continue
        seen.add(base)
        states.append(object_state(objects_dir, base))
    return states


def all_states(script_path: str, ui_path: str, objects_dir: str) -> list:
    states = [global_state(script_path, ui_path)]
    if os.path.isdir(objects_dir):
        bases = sorted({fn[:-4] for fn in os.listdir(objects_dir) if fn.endswith((".lua", ".xml"))})
        for base in bases:
            states.append(object_state(objects_dir, base))
    return states


def send_to_tts(states: list) -> None:
    if not states:
        return
    msg = json.dumps({"messageID": 1, "scriptStates": states})
    names = ", ".join(s["name"] for s in states[:6]) + (" …" if len(states) > 6 else "")
    try:
        with socket.create_connection((TTS_HOST, TTS_PORT), timeout=3) as s:
            s.sendall(msg.encode())
        print(f"[tts] pushed {len(states)} ({names}) — waiting for reload...")
    except ConnectionRefusedError:
        print("[tts] ERROR: TTS not reachable on port 39999. Is the game running?")
    except Exception as e:
        print(f"[tts] ERROR: {e}")


def handle_tts_message(conn: socket.socket) -> None:
    with conn:
        chunks = []
        while chunk := conn.recv(4096):
            chunks.append(chunk)
        data = b"".join(chunks)
        if not data:
            return
        try:
            msg = json.loads(data.decode())
        except json.JSONDecodeError:
            print(f"[tts] unreadable message: {data[:200]}")
            return

        mid = msg.get("messageID")
        if mid == 0:
            print("[tts] pushing new object script")
        elif mid == 1:
            print("[tts] game reloaded ok")
        elif mid == 2:
            # Print/debug messages = the in-game console (print(), log(), and
            # engine notices). This is where image-load failures show up.
            print(f"[tts] log: {msg.get('message', '').rstrip()}")
        elif mid == 3:
            guid = msg.get("guid", "?")
            prefix = msg.get("errorMessagePrefix", "").strip()
            error = msg.get("error", "unknown error").strip()
            print(f"[tts] ERROR (guid={guid}): {prefix}{(' ' if prefix else '')}{error}")
        elif mid == 5:
            print(f"[tts] return ({msg.get('returnID', '?')}): {msg.get('returnValue')}")
        elif mid == 6:
            print("[tts] game saved")
        elif mid == 7:
            print(f"[tts] object created (guid={msg.get('guid', '?')})")
        else:
            # never silently drop anything TTS sends
            print(f"[tts] msg (id={mid}): {json.dumps(msg)[:1000]}")


def listen_for_tts() -> None:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as srv:
        srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            srv.bind((TTS_HOST, EDITOR_PORT))
        except OSError:
            print(f"[tts] WARNING: port {EDITOR_PORT} already in use — TTS responses won't be shown")
            return
        srv.listen(5)
        print(f"[tts] listening for TTS on port {EDITOR_PORT}")
        while True:
            try:
                conn, _ = srv.accept()
                threading.Thread(target=handle_tts_message, args=(conn,), daemon=True).start()
            except Exception:
                break


# Where TTS writes its Unity Player.log -- engine output plus the image-load
# failures ("load image failed unsupported format: UNKNOWN") that never reach the
# external-editor socket. First existing / most-recently-modified path wins.
TTS_LOG_CANDIDATES = (
    "~/.config/unity3d/Berserk Games/Tabletop Simulator/Player.log",
    "~/.steam/steam/steamapps/compatdata/286160/pfx/drive_c/users/steamuser/"
    "AppData/LocalLow/Berserk Games/Tabletop Simulator/Player.log",
    "~/.local/share/Steam/steamapps/compatdata/286160/pfx/drive_c/users/steamuser/"
    "AppData/LocalLow/Berserk Games/Tabletop Simulator/Player.log",
)

# Noisy Unity lines that would otherwise drown out the messages we care about.
LOG_SKIP = (
    "Unloading ",
    "Total: ",
    "BoxCollider does not support",
    "The effective box size",
    "If you absolutely need to use negative scaling",
    "cloud.unity3d.com",  # Unity telemetry curl spam (not weserv/scryfall)
)


def find_tts_log() -> str:
    existing = [os.path.expanduser(p) for p in TTS_LOG_CANDIDATES]
    existing = [p for p in existing if os.path.exists(p)]
    return max(existing, key=os.path.getmtime) if existing else ""


def tail_tts_log(path: str) -> None:
    """Follow TTS's Player.log and print new lines (the in-game/engine log)."""
    print(f"[log] tailing {path}")
    while True:
        try:
            with open(path, "r", encoding="utf-8", errors="replace") as f:
                f.seek(0, os.SEEK_END)
                inode = os.fstat(f.fileno()).st_ino
                while True:
                    line = f.readline()
                    if line:
                        s = line.rstrip()
                        if s and not any(skip in s for skip in LOG_SKIP):
                            print(f"[log] {s}")
                        continue
                    time.sleep(0.3)
                    # reopen if TTS rotated/truncated the log (it rewrites on launch)
                    try:
                        st = os.stat(path)
                        if st.st_ino != inode or st.st_size < f.tell():
                            break
                    except FileNotFoundError:
                        break
        except FileNotFoundError:
            time.sleep(1.0)


def collect_mtimes(script_path: str, ui_path: str, objects_dir: str) -> dict:
    mtimes = {}
    for p in (script_path, ui_path):
        if os.path.exists(p):
            mtimes[p] = os.path.getmtime(p)
    if os.path.isdir(objects_dir):
        for fn in os.listdir(objects_dir):
            if fn.endswith((".lua", ".xml")):
                p = os.path.join(objects_dir, fn)
                mtimes[p] = os.path.getmtime(p)
    return mtimes


def watch(script_path: str, ui_path: str, objects_dir: str, push_all: bool) -> None:
    print(f"[tts] watching {script_path}")
    if os.path.exists(ui_path):
        print(f"[tts] watching {ui_path}")
    if os.path.isdir(objects_dir):
        print(f"[tts] watching {objects_dir}/")
    print("[tts] save a watched file to push it  |  Ctrl+C to stop\n")

    if push_all:
        send_to_tts(all_states(script_path, ui_path, objects_dir))

    last_mtimes = {}
    while True:
        if not os.path.exists(script_path):
            print(f"[tts] ERROR: {script_path} not found")
            time.sleep(2)
            continue
        mtimes = collect_mtimes(script_path, ui_path, objects_dir)
        if last_mtimes:
            changed = {p for p, m in mtimes.items() if last_mtimes.get(p) != m}
            if changed:
                send_to_tts(states_for_changed(changed, script_path, ui_path, objects_dir))
        last_mtimes = mtimes
        time.sleep(0.3)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    push_all = "--all" in sys.argv
    tail_log = "--log" in sys.argv

    path = os.path.abspath(args[0]) if len(args) > 0 else os.path.abspath("main.lua")
    ui_path = os.path.abspath(args[1]) if len(args) > 1 else os.path.join(os.path.dirname(path), "ui.xml")
    objects_dir = os.path.abspath(args[2]) if len(args) > 2 else os.path.join(os.path.dirname(path), "objects")

    threading.Thread(target=listen_for_tts, daemon=True).start()

    if tail_log:
        log_path = os.environ.get("TTS_LOG") or find_tts_log()
        if log_path and os.path.exists(log_path):
            threading.Thread(target=tail_tts_log, args=(log_path,), daemon=True).start()
        else:
            print("[log] WARNING: --log set but no TTS Player.log found (set TTS_LOG=/path/to/Player.log)")

    try:
        watch(path, ui_path, objects_dir, push_all)
    except KeyboardInterrupt:
        print("\n[tts] stopped")
