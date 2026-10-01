#!/usr/bin/env python3
"""Lint the mod's Lua, reporting warnings against src/ instead of main.lua.

luacheck runs on the generated main.lua -- see the comment at the top of
.luacheckrc for why -- but main.lua is not where anyone edits. This translates
every main.lua line number in luacheck's output back to the src/ file and line
it came from, using the same concatenation order the Makefile builds with.
"""

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def line_index():
    """[(first_line, last_line, path)] for each src file inside main.lua."""
    srcs = subprocess.run(
        ["make", "--no-print-directory", "-s", "print-src"],
        cwd=ROOT, capture_output=True, text=True, check=True,
    ).stdout.split()
    spans, start = [], 1
    for src in srcs:
        n = len((ROOT / src).read_text().splitlines())
        spans.append((start, start + n - 1, src))
        start += n
    return spans


def locate(spans, line):
    for first, last, src in spans:
        if first <= line <= last:
            return src, line - first + 1
    return None, line


def main():
    luacheck = subprocess.run(
        ["luacheck", "main.lua", "--no-color", "--codes", "--formatter", "plain"],
        cwd=ROOT, capture_output=True, text=True,
    )
    if luacheck.returncode > 1:  # 1 == warnings found; >1 == luacheck failed
        sys.stderr.write(luacheck.stderr or luacheck.stdout)
        return luacheck.returncode

    spans = line_index()
    head = re.compile(r"^main\.lua:(\d+):(\d+):")
    # luacheck cross-references the other definition as "... on line 1234"
    ref = re.compile(r"\bon line (\d+)\b")

    for out in luacheck.stdout.splitlines():
        m = head.match(out)
        if not m:
            print(out)
            continue
        src, line = locate(spans, int(m.group(1)))
        rest = ref.sub(
            lambda r: "on line %d" % locate(spans, int(r.group(1)))[1],
            out[m.end():],
        )
        print(f"{src or 'main.lua'}:{line}:{m.group(2)}:{rest}")

    return luacheck.returncode


if __name__ == "__main__":
    sys.exit(main())
