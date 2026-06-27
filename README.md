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
- `Makefile` — rebuilds `main.lua`.
- `tts_push.py` — live-pushes the script + UI to a running game.

## Development

Edit files under `src/`, then rebuild:

```sh
make
```

To push changes into a running game on save (TTS must be open with a save loaded):

```sh
python tts_push.py
```

Releases are versioned with git tags (`vX.Y.Z`); bump `VERSION` in `src/patchnotes.lua` when cutting one.

## Fix Card Images:

This band-aid fix currently relies on a third party image proxy. I will be removing this dependency soon, probably with self hosted bulk downloads of scryfall card images.
