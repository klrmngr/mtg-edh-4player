#!/usr/bin/env python3
"""
Watch the Lua script and XML UI and push them to Tabletop Simulator on save.

Usage:
    python tts_push.py [path/to/script.lua] [path/to/ui.xml]

Defaults to main.lua and ui.xml in the current directory.
Saving either file pushes both (TTS reload carries script + ui together).
ui.xml is optional — if absent, only the script is pushed.
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


def send_to_tts(script: str, ui: str = "") -> None:
    state = {"name": "Global", "guid": GLOBAL_GUID, "script": script}
    if ui:
        state["ui"] = ui
    msg = json.dumps({
        "messageID": 1,
        "scriptStates": [state],
    })
    try:
        with socket.create_connection((TTS_HOST, TTS_PORT), timeout=3) as s:
            s.sendall(msg.encode())
        print("[tts] pushed — waiting for reload...")
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


def read_ui(ui_path: str) -> str:
    try:
        with open(ui_path, encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return ""


def watch(path: str, ui_path: str) -> None:
    print(f"[tts] watching {path}")
    if os.path.exists(ui_path):
        print(f"[tts] watching {ui_path}")
    print("[tts] save either file to push to TTS  |  Ctrl+C to stop\n")
    last_mtimes = {}
    while True:
        mtimes = {}
        try:
            mtimes[path] = os.path.getmtime(path)
        except FileNotFoundError:
            print(f"[tts] ERROR: {path} not found")
            time.sleep(2)
            continue
        if os.path.exists(ui_path):
            mtimes[ui_path] = os.path.getmtime(ui_path)

        if last_mtimes and mtimes != last_mtimes:
            with open(path, encoding="utf-8") as f:
                script = f.read()
            send_to_tts(script, read_ui(ui_path))

        last_mtimes = mtimes
        time.sleep(0.3)


if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "main.lua"
    path = os.path.abspath(path)
    ui_path = os.path.abspath(sys.argv[2]) if len(sys.argv) > 2 else os.path.join(os.path.dirname(path), "ui.xml")

    threading.Thread(target=listen_for_tts, daemon=True).start()

    try:
        watch(path, ui_path)
    except KeyboardInterrupt:
        print("\n[tts] stopped")
