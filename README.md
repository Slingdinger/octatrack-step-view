# STEP VIEW

A step editor and pitch view for the Octatrack's MIDI tracks, written as an
[octabam](https://github.com/sambanks/octabam) module (ColdFire, a DRAM unit).

- **Step editor**: opens with MIXER + MIDI. Cursor, notes / VEL / LEN locked from a side panel with LEVEL, 8 tracks at a page or 4 pages of one track.
- **Pitch view**: ROLL 16, ROLL 32 and KEYS 16 layouts, a note range of 0-104, trig keys that play the note, pattern / bank select while held.
- **Saved with the project**: ten PROJECT settings in BRAIN, and the track names in `names.work` (a STORE client).
- The MIDI ARP page, ARP SETUP and TRAN are the stock's.

Called ARP BLANK until OctaZach build 140.

## Files

| File | What it is |
|---|---|
| `modules/step-view/stepview.s` | The module (GNU as, m68k/ColdFire). |
| `modules/step-view/sv_clean.s` | Cleans a Part saved before build 140 when it loads. |
| `modules/step-view/manifest.py` | The octabam manifest: detours, symbol refs, settings. |
| `modules/step-view/brain.lock` | The BRAIN settings lock. |
| `modules/step-view/README.md` | Build-by-build notes and measurements. |
| `modules/step-view/UI_RULES.md` | The rules the screens follow. |

## Using it

It needs octabam's build (the repo supplies the Octatrack OS 1.40C image from your own copy; none of Elektron's bytes are here) and two other octabam modules: BRAIN and STORE (`requires=("STORE",)`, `requires_brain=True`).

1. Copy `modules/step-view` into an octabam checkout's `modules/`.
2. Add `"STEP VIEW"` to a remix's `modules=(...)` after BRAIN and STORE. Add `("STEP VIEW", "sgn", (...))` to the CLIENTS list in `modules/store/manifest.py` (see the entry in OctaZach build 140).
3. `make bus REMIX=<yours>`.

It conflicts with nothing in the hook set it claims, but check `make modules` for your mix. Tested under octabam's emulator only, not yet on a unit by anyone but its author.

## Licence and credit

Local module by Zach (OctaZach). octabam is by Sam Banks and contributors; see its repository for its terms. No licence is set here yet: add one before others reuse the code.
