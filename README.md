# MTG EDH 4-player (χ)

A scripted [Tabletop Simulator](https://store.steampowered.com/app/286160/) mod for 4-player Magic: The Gathering Commander. Fork of [MTG EDH 4-player (π)](https://steamcommunity.com/sharedfiles/filedetails/?id=2296042369).

## Layout

- `src/*.lua` — the Lua source, split into modules.
- `main.lua` — built artifact, concatenated from `src/` (don't edit directly).
- `ui.xml` — Global screen-space UI.
- `objects/<name>.<guid>.json` — per-object save data (transforms, image URLs, contained cards, …), one file per table object.
- `objects/<name>.<guid>.{lua,xml}` — that object's script / UI (single source; injected into the JSON at build time).
- `save.template.json` — the save metadata around the objects (grid, lighting, hands, …); the global script comes from `main.lua` / `ui.xml`.
- `Makefile` — rebuilds `main.lua`, formats/lints the source, and assembles full saves.
- `tts_push.py` — live-pushes the script + UI to a running game.
- `tts_save.py` — splits a TTS save into the per-object JSON above and rebuilds it.

## Development

### Formatting and linting

```sh
make fmt     # stylua over src/, then rebuild main.lua
make lint    # luacheck
make check   # fail if main.lua is out of sync with src/
```

CI runs all three on every PR. Both tools are configured at the repo root
(`.stylua.toml`, `.luacheckrc`) and only cover `src/` — `objects/*.lua` are
exported TTS object scripts, several vendored from other mods, so they are left
untouched.

luacheck runs against the built `main.lua` rather than the individual `src/`
files, because they share one global namespace at runtime: a helper defined in
`src/core/helpers.lua` is called from `src/zones/draw.lua`, and luacheck can
only resolve that if it sees them as a single chunk. `tools/lint.py` translates
the warnings back to `src/<file>:<line>`.

Install locally with `pacman -S stylua luacheck` (Arch), or
`cargo install stylua` and `luarocks install luacheck`.

### Saves

The whole table — every card, deck, token, transform and image URL — is tracked
as per-object JSON, not just the scripts. To pull a save apart and put it back:

```sh
make split SAVE="path/to/TS_Save_NN.json"   # save -> objects/*.json + save.template.json
make save                                    # objects/*.json + main.lua/ui.xml -> a fresh save
```

`make split` defaults to the most-recently-modified `TS_Save_*.json`. `make save`
writes `MTG EDH 4-player (χ) <version>-<YYYYMMDDHHMMSS>.json` (version read from
`src/patchnotes.lua`) into the directory named by `SAVE_DIR` in a local `.env`
(copy `.env.example`); override per-run with `make save SAVE_OUT="path/to/Saves"`.

Releases are versioned with git tags (`vX.Y.Z`); bump `VERSION` in `src/patchnotes.lua` when cutting one.
