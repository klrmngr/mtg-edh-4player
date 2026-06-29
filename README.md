# MTG EDH 4-player (χ)

A scripted [Tabletop Simulator](https://store.steampowered.com/app/286160/) mod for 4-player Magic: The Gathering Commander. Fork of [MTG EDH 4-player (π)](https://steamcommunity.com/sharedfiles/filedetails/?id=3719365187).

## Features

- Per-player table buttons: Draw, Scry, Mill, Untap, Reveal (left click = 1, right click = several, or type a number).
- Mulligan button with a running counter; right click resets it (any player can reset another's).
- Serum Powder button: exiles your hand and draws a fresh one of the same size.
- Scryfall card search and decklist importer.
- Cascade and reveal-until-type helper panels.
- Patch-notes button that pulls release notes from GitHub.

## Layout

- `src/*.lua` — the Lua source, split into modules.
- `main.lua` — built artifact, concatenated from `src/` (don't edit directly).
- `ui.xml` — Global screen-space UI.
- `objects/<name>.<guid>.json` — per-object save data (transforms, image URLs, contained cards, …), one file per table object.
- `objects/<name>.<guid>.{lua,xml}` — that object's script / UI (single source; injected into the JSON at build time).
- `save.template.json` — the save metadata around the objects (grid, lighting, hands, …); the global script comes from `main.lua` / `ui.xml`.
- `Makefile` — rebuilds `main.lua` and assembles full saves.
- `tts_push.py` — live-pushes the script + UI to a running game.
- `tts_save.py` — splits a TTS save into the per-object JSON above and rebuilds it.

## Development

Edit files under `src/`, then rebuild:

```sh
make
```

To push changes into a running game on save (TTS must be open with a save loaded):

```sh
python tts_push.py
```

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
