# OctaZach screen rules

Rules Zach has set for every screen of the step view (TRKS, PAGES, PITCH, the timeline, windows,
and any new screen). Read this before any change to what the screen draws. They apply at every zoom
(knob F) and every row spacing (knob D), not only the default.

## Centering is the rule

- Anything between two things is centred between them: equal blank pixels on both sides.
- When the space can't split evenly, change the item's size to match the space's parity instead of
  leaving it off-centre. In an odd gap use a 1 or 3 px item; in an even gap use a 2 px item.
- Recompute on every zoom and spacing step. A layout that is centred at one setting and not at
  another is wrong.

- When one element defines the centre (the 4-step dots between rows, for example), everything else
  centres on that element, even if it doesn't match other spacing on the screen.

## Between rows of steps

- The 4-step dots define the centre line between two rows, with equal blank pixels above and below.
- The 16-step divider sits on the same centre line. It is taller than the dots and stays centred.
  Where the gap allows, it fills the centre line, leaving a pixel clear of each row.
- Horizontally, dots and dividers sit centred in the gap between the step columns they divide.

## Bars and headers

- A bar (the black strip under the title in PAGES, readout rows in the timeline) uses the least space
  that stays uniform with the rest: the gap from a bar to the next row equals the gap from a centre
  line to a row.

## Same behaviour everywhere

- A behaviour defined on one screen applies to its counterpart on every other screen (TRKS and
  PAGES, MIDI and AUDIO, the timeline and the 4-page grid, windows) unless Zach says otherwise.

## Process

- UI changes: send a mock with pixel measurements first, and build after Zach approves.
- Name things the way Zach does, or say plainly what a new name refers to.
- Check by measuring the emulator screen, not by eye.
