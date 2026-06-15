#!/usr/bin/env python3
"""
Watch the source and push it to Tabletop Simulator on save.

Pushes the Global script (main.lua + ui.xml) AND every object script/UI under
objects/ (as produced by tts_pull.py), so the whole mod is updated at once.

Usage:
    python tts_push.py [path/to/script.lua] [path/to/ui.xml] [objects_dir]

Defaults to main.lua, ui.xml, and ./objects next to the script.
Saving any watched file pushes the full set.
TTS must be running with a save open.
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


def build_script_states(script_path: str, ui_path: str, objects_dir: str) -> list:
    """Assemble scriptStates for Global plus every object under objects_dir."""
    states = []

    global_state = {"name": "Global", "guid": GLOBAL_GUID, "script": read_file(script_path)}
    ui = read_file(ui_path)
    if ui:
        global_state["ui"] = ui
    states.append(global_state)

    if os.path.isdir(objects_dir):
        by_guid: dict = {}  # guid -> {name, script, ui}
        for fn in sorted(os.listdir(objects_dir)):
            if fn.endswith(".lua"):
                base, kind = fn[:-4], "script"
            elif fn.endswith(".xml"):
                base, kind = fn[:-4], "ui"
            else:
                continue
            name, _, guid = base.rpartition(".")  # "<name>.<guid>"
            if not guid:
                continue
            entry = by_guid.setdefault(guid, {"name": name or "object", "guid": guid})
            entry[kind] = read_file(os.path.join(objects_dir, fn))
        for guid, entry in sorted(by_guid.items()):
            state = {"name": entry["name"], "guid": guid, "script": entry.get("script", "")}
            if entry.get("ui"):
                state["ui"] = entry["ui"]
            states.append(state)

    return states


def send_to_tts(states: list) -> None:
    msg = json.dumps({"messageID": 1, "scriptStates": states})
    try:
        with socket.create_connection((TTS_HOST, TTS_PORT), timeout=3) as s:
            s.sendall(msg.encode())
        print(f"[tts] pushed {len(states)} script state(s) — waiting for reload...")
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
        if mid == 1:
            print("[tts] game reloaded ok")
        elif mid == 2:
            print(f"[tts] print: {msg.get('message', '').strip()}")
        elif mid == 3:
            guid = msg.get("guid", "?")
            error = msg.get("error", "unknown error").strip()
            print(f"[tts] ERROR (guid={guid}): {error}")
        elif mid == 6:
            print("[tts] game saved")


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


def watch(script_path: str, ui_path: str, objects_dir: str) -> None:
    print(f"[tts] watching {script_path}")
    if os.path.exists(ui_path):
        print(f"[tts] watching {ui_path}")
    if os.path.isdir(objects_dir):
        print(f"[tts] watching {objects_dir}/")
    print("[tts] save any watched file to push to TTS  |  Ctrl+C to stop\n")
    last_mtimes = {}
    while True:
        if not os.path.exists(script_path):
            print(f"[tts] ERROR: {script_path} not found")
            time.sleep(2)
            continue
        mtimes = collect_mtimes(script_path, ui_path, objects_dir)
        if last_mtimes and mtimes != last_mtimes:
            send_to_tts(build_script_states(script_path, ui_path, objects_dir))
        last_mtimes = mtimes
        time.sleep(0.3)


if __name__ == "__main__":
    path = os.path.abspath(sys.argv[1]) if len(sys.argv) > 1 else os.path.abspath("main.lua")
    ui_path = os.path.abspath(sys.argv[2]) if len(sys.argv) > 2 else os.path.join(os.path.dirname(path), "ui.xml")
    objects_dir = os.path.abspath(sys.argv[3]) if len(sys.argv) > 3 else os.path.join(os.path.dirname(path), "objects")

    threading.Thread(target=listen_for_tts, daemon=True).start()

    try:
        watch(path, ui_path, objects_dir)
    except KeyboardInterrupt:
        print("\n[tts] stopped")
