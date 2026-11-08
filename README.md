# STEP VIEW

**See and edit the Octatrack's MIDI sequences on its screen.**

On a stock Octatrack, a MIDI track's notes live in the 16 trig LEDs and in parameter-lock menus. You
see one track and one page at a time, and a note is a number you dial in. STEP VIEW draws the
sequences on the screen: all 8 MIDI tracks at once, a whole 64-step track, or a piano roll of the
notes. You edit them right there.

It's a module for [octabam](https://github.com/sambanks/octabam), a toolkit for building your own
Octatrack OS (1.40C, MKI and MKII).

> **Work in progress.** The way you move between screens is still being worked out. This page explains
> both *how* it works and *why* it works that way, so you can judge it, change it, or suggest
> something better.

---

## Quick start

| Action | Result |
|---|---|
| Hold **MIXER**, press **MIDI** | STEP VIEW opens, from any page. |
| Press **MIXER + MIDI** again | The next view: **Tracks → Pages → Pitch → Panel →** back to Tracks. |
| **Arrows** | Move the cursor. |
| **YES** | Put a note on the step (or open it if there's one already). |
| **FUNC + PLAY** | Clear the step. |
| **FUNC + NO** | Undo. **FUNC + YES** redoes. |
| Press **encoder F** | Zoom in or out (Tracks, Pages), or switch the piano-roll layout (Pitch). |
| **NO** | Back out: closes whatever is open, and from the grid, leaves STEP VIEW. |

Leaving takes you back to the page you were on, in the mode you were in (MIDI or audio).

---

## The four views at a glance

Each view answers one question.

| View | The question it answers |
|---|---|
| **Tracks** | *What's happening in my pattern?* All 8 tracks at once. |
| **Pages** | *What is this one track doing over all 64 steps?* With the arranger on: *what plays next, and when?* |
| **Pitch** | *What notes am I writing?* A piano roll of one track. |
| **Panel** | *What exactly is on this step, or in this arrangement row?* Numbers next to the grid. Built with the arranger in mind. |

## 1. Tracks: the whole pattern

All 8 MIDI tracks, one row each. Use it to place trigs quickly and see what every track is doing.

**Arranger off**

![Tracks, 32 steps a row](docs/screens/tracks-32.png)
*32 steps a row (the default).*

![Tracks, 16 steps a row](docs/screens/tracks-16.png)
*16 steps a row: press encoder F.*

![Tracks while playing](docs/screens/tracks-playing.png)
*Playing: the play position is marked on every track.*

**Arranger on**

![Tracks, arranger on](docs/screens/tracks-arranger.png)
*The same grid, with the arrangement row (R00) at the top right. While playing, the title also counts
down the bars to the next row.*

How to read it:

- **Tall bar** = a note. **Short bar** = a trigless trig. **Line** = an empty step.
- **Blank** = past the end of that track (tracks can be different lengths).
- A track shorter than the row repeats to fill it, so a 16-step track shows twice at 32 a row.
- The track number at the left is **inverted** for the active track and flashes **M** when the track
  is muted.
- At the right: the cursor's step (S01) and which part of the pattern you're looking at (1/2). The
  zoom is at the bottom (32/R = 32 steps a row).

**Whole tracks.** Press LEFT on step 1 and the cursor moves onto the track number, which gets a box.
There, **FUNC + REC** copies the whole track (all 64 steps, their locks, the length and scale),
**FUNC + STOP** pastes it onto the track you're on, and **FUNC + PLAY** clears all its steps.
**UP / DOWN** move between track numbers, and **RIGHT** goes back to step 1. **FUNC + NO** undoes.

![Tracks, the cursor on a track number](docs/screens/tracks-number.png)
*The cursor on track 5's number, ready to copy, clear or paste the whole track.*

## 2. Pages: one track, all 64 steps

The cursor's track, its four pages stacked. Use it to see a whole long track at once.

**Arranger off**

![Pages, 32 steps a row](docs/screens/pages-32.png)
*32 steps a row: two pages per row.*

![Pages, 16 steps a row](docs/screens/pages-16.png)
*16 steps a row: one page per row. Press encoder F to switch.*

- The bar under the title shows the pattern (A03) and the track's length (64).
- **Knob D** changes the spacing between the rows.

**Arranger on: the timeline**

![Pages, arranger on: the timeline](docs/screens/pages-arranger.png)
*The timeline. The inverted line is an arrangement row's settings: R00 (row 0), A03 (its pattern), X2
(played twice), 00:00 (offset and length; 0 = the pattern's length), S-/- (no scenes). Under it, that
row's pages for the cursor's track, in the order they play.*

**With the arranger on, Pages becomes the timeline.** Your arrangement is laid out in the order it
plays, one page per row, for the cursor's track. Each arrangement row starts with a line of its
settings: row number, pattern, repetitions, offset and length, scenes, mute. You can change those
settings right there: **LEFT / RIGHT** pick one, **LEVEL** changes it. A countdown shows the bars left
before the next row.

## 3. Pitch: a piano roll

The cursor's track as notes on a keyboard, for writing melodies and bass lines. **Press encoder F** to
switch between three layouts. They all show the same notes and keep the same range. The arranger
doesn't change this view.

![Pitch, ROLL 16](docs/screens/pitch-roll16.png)
*ROLL 16: one page of 16 steps, a keyboard on the left. Press encoder F for the next layout.*

![Pitch, ROLL 32](docs/screens/pitch-roll32.png)
*ROLL 32: two pages across two octaves.*

![Pitch, KEYS 16](docs/screens/pitch-keys16.png)
*KEYS 16: turned sideways, steps run down the screen over a keyboard.*

How to read it:

- **Squares** are notes, and the box is the cursor.
- A small arrow means a note that's **above or below** what's on screen.
- Dotted rows are the sharps.
- The title shows the cursor's note and step (F3 S01).

Moving around:

- **Up and down in pitch**: the arrows along the keyboard, or **knob A**. Go past the edge and the
  range scrolls.
- **FUNC +** those moves by an octave.
- **Along the steps**: the other two arrows, or **LEVEL**.
- **To another page**: FUNC + those arrows, or the **SCALE / PAGE** key.
- **To the lowest / highest note on the page**: press **encoder A / C**.

**The trig keys become a keyboard** in this view:

- The 16 trig keys play 16 notes in a row, starting from C.
- Press one to hear it. **FUNC + a trig key** writes that note into the cursor's step.
- **Knob E** slides the keyboard up and down a semitone, and **FUNC + knob E** an octave.
- **PATTERN + trig** and **BANK + trig** still pick patterns and banks as usual.

## 4. Panel: the numbers, for the arranger

The grid with a panel of values on the left: the step's four notes, velocity and length, the track's
name, the play clock and the patterns. It was designed as the arranger's companion:

- **Arranger on**: the timeline, plus the arrangement controls. You can see and change the row
  playing, the pattern of this row and the next, mute the row, and save the arrangement (a SAVE
  button appears when there are changes).
- **Arranger off**: the 8 tracks, plus the step's details and the track names.

**Arranger off**

![Panel view, arranger off](docs/screens/panel.png)
*The step's notes, velocity and length on the left, the 8 tracks on the right.*

**Arranger on**

![Panel view, arranger on](docs/screens/panel-arranger.png)
*ROW 00 is the row playing. M A03 is this row's mute and pattern; -- A01 is the next row's pattern
(the -- becomes a countdown while playing). The timeline is on the right.*

It follows the arranger: turn the arranger on or off and the Panel view switches with it.

In the panel: **UP / DOWN** pick a line, **LEFT / RIGHT** a value, and **LEVEL** changes it (as a
parameter lock on that step). **NO** goes back to the grid.

## Pop-up windows

![Step window](docs/screens/step-window.png)
*Step window: one step, big. YES on a note opens it, LEVEL and the arrows edit it, NO closes it.*

![Copy window](docs/screens/copy-window.png)
*Copy window: FUNC + REC with nothing marked. Copy one step (TRIG), a page (ROW) or chosen pages.*

---

## Encoder F: press it to change how the view looks

Press **encoder F** in any view to change how it's shown. Turning F does nothing in STEP VIEW.

| View | Press F |
|---|---|
| **Tracks** | Zoom: 16 ↔ 32 steps a row |
| **Pages** | Zoom: 16 ↔ 32 steps a row |
| **Pitch** | Next layout: ROLL 16 → ROLL 32 → KEYS 16 |
| **Panel** (arranger on) | Zoom the timeline: 4 → 8 → 16 steps a row |

---

## Everything else

### Editing steps

- **Track keys** jump the cursor to that track. **UP / DOWN** in Tracks also make that track the
  active one.
- **SCALE / PAGE** jumps a page.
- **Notes** have four voices (NOTE and NOT2–4), a velocity and a length. They're all locked to the
  step, so each step can be different.
- **Undo** goes back ten steps, for the whole pattern.
- **Grid recording**: hold a trig key for a moment to open that step. Turn **LEVEL** with the key
  held to change its note.

### Copy, clear, paste

In STEP VIEW, **FUNC + REC / PLAY / STOP** are **COPY / CLEAR / PASTE**:

- **FUNC + LEVEL** marks a run of steps from the cursor. COPY, CLEAR or PASTE then work on that run.
  PASTE repeats what you copied to fill the run.
- On a **track number** (Tracks): COPY, CLEAR and PASTE act on the whole track, length and scale
  included. In AUDIO, CLEAR only.
- With nothing marked: **CLEAR** clears the cursor's step, **COPY** opens the copy window, and
  **PASTE** puts the copy at the cursor.
- **Copying between audio and MIDI tracks** (grid recording's FUNC + REC / FUNC + STOP) converts
  between them. An audio track's pitch becomes notes, and an OCTA-303 line keeps its accents and
  slides.

### AUDIO

Press **MIDI** alone (without MIXER) to see the 8 **audio** tracks instead. Tracks and Pages work
there: you can see, add and clear trigs. Pitch and Panel are MIDI only.

### Track names

Each MIDI track can have a 12-character name, per Part and bank. Set it on the name line in the Panel
view. Hold **FUNC** for a keyboard of characters. Names are saved with the project.

---

## Settings (BRAIN > SETTINGS > STEP VIEW)

octabam keeps module settings in its **BRAIN** menu. STEP VIEW's are **project settings**: each
project saves its own copy when you SAVE PROJECT and gets it back when you load it. STEP VIEW writes
them itself as you use it, so you never need to touch them. They're there so a project opens the way
you left it, and so you can see or reset them.

| Setting | What it means |
|---|---|
| **FULL** | Which kind of view you were in: 1 = Tracks, Pages or Pitch; 0 = Panel. |
| **PAGES** | 0 = Tracks, 1 = Pages. (The Panel view ignores this and follows the arranger.) |
| **PITCH** | 1 = you were in the Pitch view. |
| **LAYOUT** | The Pitch layout: ROLL 16, ROLL 32 or KEYS 16. |
| **RANGE** | The lowest note the Pitch view shows (45 = A2). The view shows two octaves from here. |
| **ROW** | Where the Pitch cursor is, in semitones above RANGE. |
| **ROLL16 BASE** | ROLL 16 shows 11 of those notes at a time; this is which one is at the bottom. |
| **TRIG ROOT** | The lowest note of the trig-key keyboard. -1 = start from the C below the cursor. |
| **FULL ZOOM** | Steps per row in Tracks and Pages: 2 = 16, 3 = 32. |
| **ZOOM** | Steps per row in the Panel view's timeline: 0 = 4, 1 = 8, 2 = 16. |

MIXER + MIDI always opens Tracks, Pages or Pitch, whichever you used last. The Panel view is one press
of the combo further on.

---

## Why it works this way

These choices are the current answers, not final ones. Here's the thinking, so you can disagree with
it.

- **MIXER + MIDI to get in.** The Octatrack has no spare page key. STEP VIEW draws on top of the MIDI
  ARP page but only while it's open, so the arpeggiator stays fully usable. MIXER + MIDI works from
  any page and doesn't take a key away from anything.
- **The same combo to switch views.** One gesture to remember. The cost is that the Panel view is
  four presses away.
- **NO to go back.** Everywhere else on the Octatrack NO means "back" or "cancel", so it does here
  too: it closes what's open, and from the grid it leaves.
- **FUNC + PLAY to clear.** That's the Octatrack's own CLEAR combo. Undo (FUNC + NO) is there if you
  clear the wrong thing.
- **Press F to change the view.** One action does the same kind of thing everywhere: zoom in Tracks,
  Pages and the timeline, the layout in Pitch. Turning F does nothing, so a knob bump can't change
  the screen.
- **The track number for whole-track actions.** The number is already the track's label, so putting
  the cursor on it means "this whole track", the same way the cursor on a step means "this step".
- **The Panel view for the arranger.** The arranger is the part of the Octatrack that's hardest to
  see. The Panel view puts the arrangement's timeline next to the numbers you need to edit it.
- **Nothing outside STEP VIEW changes**, apart from these:
  - **MIXER** opens its window when you let go, not when you press it, so that MIXER + MIDI can work.
  - **FUNC + BANK** twice with the arranger on opens the arrangement editor.
  - In the stock SCALE window (FUNC + SCALE / PAGE), **UP / DOWN** move between rows and **SCALE**
    opens ALL TRACK SCALES.
  - Copying a track in grid recording can convert between audio and MIDI tracks.

Ideas being considered: a single VIEW setting in place of FULL / PAGES / PITCH, and a quicker way into
the Panel view.

---

## Adding it to your build

You need octabam's build, which uses your own copy of the Octatrack OS (no Elektron code is in this
repo). STEP VIEW needs two other octabam modules: **BRAIN** (settings) and **STORE** (track names).

1. Copy `modules/step-view` into an octabam checkout's `modules/` folder.
2. Add `"STEP VIEW"` to your remix's `modules=(...)`, after `"BRAIN"` and `"STORE"`.
3. In `modules/store/manifest.py`, add this line to `CLIENTS`:
   ```python
   ("STEP VIEW", "sgn", ("loadall_pre", "loadmask_pre", "newproj", "bankw_post", "pstore_pre",
                         "pstore_post", "preload_post", "partclear")),
   ```
4. Run `make modules` to check it doesn't clash with your other modules, then
   `make bus REMIX=<yours>`.

If you also use octabam's TRIG MODES module, STEP VIEW keeps the active track's trig mode in step
with it.

| File | What it is |
|---|---|
| `modules/step-view/stepview.s` | The code (ColdFire assembly, runs from RAM). |
| `modules/step-view/manifest.py` | Tells octabam where it hooks in, and its settings. |
| `modules/step-view/brain.lock` | The settings' fixed IDs. |
| `modules/step-view/UI_RULES.md` | The layout rules the screens follow (centring, spacing). |
| `docs/screens/` | The screenshots on this page, from octabam's Octatrack emulator. |

**Status:** built and tested in octabam's emulator. Parts of it have run on its author's MKI, but not
every feature has been tested on hardware. Back up your card before flashing anything.

## Licence and credit

MIT (see `LICENSE`): use it, change it and share it, keeping the notice. Written by Slingdinger. It
builds inside [octabam](https://github.com/sambanks/octabam) by Sam Banks and contributors, which has
its own terms.
