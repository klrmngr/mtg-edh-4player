#!/usr/bin/env python3
"""
Pull every object's Lua script and XML UI out of a running Tabletop Simulator
game and dump them to disk, so the whole mod's source can be version controlled.

Usage:
    python tts_pull.py [output_dir]

Defaults to ./objects. TTS must be running with the save open.

Each object with a non-empty script or UI is written as:
    <output_dir>/<name>.<guid>.lua
    <output_dir>/<name>.<guid>.xml

The Global script (guid -1) is skipped by default since it is tracked here as
main.lua / src/. Pass --global to include it too.
"""

import json
import os
import re
import socket
import sys

TTS_HOST = "localhost"
TTS_PORT = 39999    # TTS listens here (editor -> TTS)
EDITOR_PORT = 39998  # we listen here (TTS -> editor)
GLOBAL_GUID = "-1"
TIMEOUT = 10.0


def request_scripts() -> list:
    """Ask TTS for all scripts and return the scriptStates list."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as srv:
        srv.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        srv.bind((TTS_HOST, EDITOR_PORT))
        srv.listen(1)
        srv.settimeout(TIMEOUT)

        # messageID 0 = "Get Lua Scripts"
        with socket.create_connection((TTS_HOST, TTS_PORT), timeout=3) as s:
            s.sendall(json.dumps({"messageID": 0}).encode())
        print("[tts] requested all scripts — waiting for response...")

        # TTS may send other messages first; keep reading until we get the dump.
        while True:
            conn, _ = srv.accept()
            with conn:
                chunks = []
                while chunk := conn.recv(65536):
                    chunks.append(chunk)
            data = b"".join(chunks)
            if not data:
                continue
            try:
                msg = json.loads(data.decode())
            except json.JSONDecodeError:
                continue
            if msg.get("messageID") == 1 and "scriptStates" in msg:
                return msg["scriptStates"]


def safe_name(name: str) -> str:
    name = (name or "unnamed").strip() or "unnamed"
    return re.sub(r"[^A-Za-z0-9._-]+", "_", name)


def main() -> None:
    include_global = "--global" in sys.argv
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    out_dir = os.path.abspath(args[0]) if args else os.path.abspath("objects")

    try:
        states = request_scripts()
    except ConnectionRefusedError:
        sys.exit("[tts] ERROR: TTS not reachable on port 39999. Is the game running?")
    except socket.timeout:
        sys.exit("[tts] ERROR: no response from TTS within the timeout.")

    os.makedirs(out_dir, exist_ok=True)
    written = 0
    for st in states:
        guid = st.get("guid", "")
        if guid == GLOBAL_GUID and not include_global:
            continue
        script = st.get("script", "") or ""
        ui = st.get("ui", "") or ""
        if not script.strip() and not ui.strip():
            continue
        base = f"{safe_name(st.get('name'))}.{guid}"
        if script.strip():
            with open(os.path.join(out_dir, base + ".lua"), "w", encoding="utf-8") as f:
                f.write(script)
            written += 1
        if ui.strip():
            with open(os.path.join(out_dir, base + ".xml"), "w", encoding="utf-8") as f:
                f.write(ui)
            written += 1

    print(f"[tts] wrote {written} file(s) to {out_dir}")


if __name__ == "__main__":
    main()
