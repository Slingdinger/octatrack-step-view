# `step-view` — STEP VIEW


Called ARP BLANK (`arp-blank`) until OctaZach 140. Renamed with the stock ARP page back; the sections below keep the old name only in quoted history.
Local module (not upstream), written for Zach's MKI build (`octazach`).

**Since build 140 the ARP page is the stock's again**: TRAN, LEG, MODE, SPD, RNGE, NLEN, ARP SETUP and the
arpeggiator are back, and the step editor opens only with MIXER + MIDI (its full view, as since build
108; FUNC + the ARP page key and the combo then switch its windows as before). Track names live in
`names.work` beside the bank files (a STORE client), no longer in the Part. The notes below describe the
module as it was built up to 139; "the ARP page" in them means the step editor's view.

**What it does.** On the MIDI tracks:

- **The ARP page is a step editor for the 8 MIDI tracks** (builds 44-64). TRAN, LEG, MODE, SPD, RNGE
  and NLEN are gone and the six knobs do nothing; the page's title bar and scene indicator at the
  bottom are gone too (build 46). Right: a row of 16 steps per MIDI track, numbered 1-8 at the left (each number's foot level with
  its steps' foot, build 48),
  the page the cursor is on (full bar = trig, half bar = trigless trig, a line at the foot = no trig,
  blank = past that track's length; a line over a step = the step that track is playing; a line under
  one, as wide as the step, blinking = the cursor). LEFT/RIGHT move the cursor along the 64 steps (the page follows), UP/DOWN between
  the tracks; held, an arrow repeats after 300 ms every 50 ms (build 49; the stock's repeat is 500 ms);
  FUNC + LEFT/RIGHT moves a page (16 steps); a track key moves the cursor to that track, the step kept
  (the stock still selects the track).
  Build 52: the page in view and the trig keys' page (the one PAGE steps in grid recording) are one:
  PAGE moves the cursor to its page, and the cursor reaching another page moves the trig keys there
  (clamped to the active track's pages). Hands off for 1.5 s with the panel shut while the cursor's
  track plays, the window shows the page it is playing, the cursor and the trig keys staying put; any
  arrow, YES, NO, LEVEL, trig, track or PAGE key brings it back. FUNC + the ARP page key switches the
  window between the 8 tracks at one page and the cursor's track at its 4 pages (rows 1-4 = pages,
  UP/DOWN a page). VEL and LEN have four blank rows between them.
  Build 53: LEFT/RIGHT stay within the page (pages are FUNC + LEFT/RIGHT's); a press past the first or
  last column opens the panel on NOTE (a held arrow stops at the edge), and RIGHT past the end of a
  panel line returns to the grid; LEVEL on a step without a trig gives it a note trig first, as YES
  does. In the 8-track window UP/DOWN also make that track the stock's active one (as a tap on its
  track key: the trig keys and their LEDs, the info box follow). A muted MIDI track shows M in place
  of its number (and M after the name in the panel), as the MIDI engine computes it (build 55: the
  pattern's mute byte 0x8000000e, the arrangement's 0x46c78d6a and the solo byte 0x8000000f, the
  engine's formula at 0x4009f804; builds 53-54 read the pattern's byte only, so arrangement mutes
  did not show).
  Build 54: sharps show as + (F+), narrower than #.
  Build 55: FUNC + LEFT/RIGHT and FUNC + LEVEL move a page in the panel too (FUNC + LEVEL's main
  volume is not on this page); LEVEL in the grid moves the cursor's step, 1-64; the four notes sit in
  fixed 8 px slots (a + no longer shifts the ones after it); leaving the page with the CHROMATIC or
  QUICK MUTE trig mode on, the trig mode's box and the arrangement box are drawn again (they stayed
  blank until the mode was changed).
  Build 56: the screen is nine 7-px rows shared by the grid and the panel; the first is blank (for a
  title later), the panel's eight lines sit level with tracks 1-8, each track's number and steps sit
  at the foot of its row with the cursor on the row's last line right under them (4-page window: two
  rows per page).
  Build 57: in grid recording a trig key held 400 ms opens the panel on that step with NOTE picked
  (the stock's own hold test is shorter, so the trig is not removed on release); LEVEL with the key
  still down changes the note (the held-trig layer's LEVEL, 0x400434d8, does nothing on a MIDI track);
  FUNC + UP/DOWN with a note picked moves it an octave (a NOT2-4 that is off stays off), elsewhere it
  changes the trig mode as before.
  Build 58: in grid recording a trig key's press moves the cursor to its step at once, so the panel
  shows the held step's values from the press on; LEN's fraction sits right-aligned against the
  divider ("L 10 3/32" in one string was 34 px and lost its fraction).
  Build 59 (fix): the track name's fifth character sits on the setup byte the note path reads as the
  arp's KEY (scale, live setup + 0x11, read at 0x4009fad2 whether or not the arp runs), so every named
  track's notes were snapped to a scale (measured under the port on build 58: the byte at 1 played a
  C#4 step as C4; at 32, a space, A3 as G#3 and D3 as C#3). That read now always gives 0 (no scale);
  with either value the notes go out as written. The name's second character is the arp's LEN
  (read by the arpeggiator at 0x40099f78), which with MODE forced off changes nothing heard.
  Build 60: the screen's first row runs across panel and grid: the name, now seven characters (4 px
  each from x 11), then the pattern and page from x 45; the divider starts under it; the step playing
  is the panel's line 1, two blank lines before STEP. Its two new bytes
  are CTRL1 SETUP's unused + 18..19 (128 values each, so the Part validator keeps them; no reader under
  the port while the sequencer plays and the NOTE, LFO, CTRL1, CTRL2 pages and CTRL1 SETUP are open).
  The name's keyboard, as the stock's naming screens: FUNC held with a name character picked shows
  every character (32-95, eight rows of eight) over the grid; FUNC + the arrows or LEVEL pick one;
  releasing FUNC writes it and moves to the next character.
  Build 61: undo for the whole pattern on this page. FUNC + NO goes a state back, FUNC + YES forward
  (the stock's FUNC + YES / NO elsewhere), with "UNDO 3/9" or "NO UNDO" at the first row's end for
  1.5 s. Ten states of the current pattern (365,680 B of .bss in the platform reserve): every 6 ticks
  the pattern is summed; a change opens an edit, 500 ms without one closes it into the newest state
  (undone states past the current one go). Trigs placed or removed, locks, the panel's edits, clears
  and pastes are all changes; another pattern or bank, a window over the page or leaving the page
  starts the history again. A state is written back through the stock pattern paste's writer
  (0x4002b9b0: bank, CS1 copy, the tracks' and the engine's refresh). Under the port: no state
  added while the sequencer played 4 s untouched; a lock edit and a grid-recorded trig undone and
  redone.
  Build 62: FUNC + UP/DOWN's octave also with a trig key held (a hold-to-edit's step); until then
  it needed no trig key down and went to the stock's trig mode menu (the unit, 23 Oct 2026). In the
  4-page window, hands off while the track plays, the cursor itself moves to the playing page (its
  column kept). Arranging: the first row shows the arrangement row ("R03", from 00) left of the
  pattern (now from x 61), in both windows, and the panel's line 1 the step playing only; in the
  4-page window the rows are one 7 px row a page, this pattern's four over a dotted line and the next
  arrangement row's pattern's four (the same track, read only, not playing), ">A02" at the first
  row's end. The arrangement in use is read as 0x4004a100 reads it: 0x10000000 -> the record, the
  row count at +18, 22-byte rows from +20 (+0 0 = a pattern row, +1 bank << 4 | pattern). Under the
  port: arrangement mode on, row 00, the next row's pattern drawn under the current one.
  Build 63: STEP is a panel value: UP/DOWN reach it, LEVEL moves the cursor's step (wrapping); LEVEL
  in the grid wraps 64 -> 1 too. The next pattern comes from the arranger's own row resolver
  (0x4009aed0, as the arranger starts: through LOOP and JUMP rows, past REM rows): under the port,
  on the row before a LOOP back to row 1 the lower half shows row 1's pattern (">A01").
  Build 64: a note trig's LEN is drawn: from the top two rows of its bar a line runs right as far as
  LEN reaches (6 a step, a column's 3 px 2 units each; INF to the next note), stopping a gap short of
  the next note trig and at the track's end; a note on an earlier page reaching into the row starts
  its line at the row's left (its lock, else the Part's value). The track's name is twelve
  characters (the five new ones are the ARP page's LEG MODE SPD RNGE NLEN bytes, +13..17 of the
  page-1 record, their validator counts poked to 128; MIDI out unchanged with all five at 90 in every
  track under the port) and sits in the first row from x 49, over step 1, M after it for a muted
  track; the pattern and page ("A01 1/4") move to the panel's top, where an undo message now shows.
  The panel's line 1: the arrangement row and pattern ("R01 A01", the pattern alone when not
  arranging); line 2: the pattern to come and the steps until it starts ("55 A01"; "-- A01" stopped;
  an infinity sign and this pattern when nothing else is queued); line 3: the step playing. To come:
  arranging, the next playable row's pattern, the steps the row has left (its LEN, +12, times the
  repetitions left, 0x800066a4, which counts down from the row's +2 to 0 -- measured -- plus LEN less
  the step count 0x800065b4); otherwise the pattern chosen to come (0x800065bf bank, 0x800065c0
  pattern, measured with PTN + a trig while playing) and the steps to this pattern's end (it changed
  after count 127 of a 128-step master length, measured). The arranger's row (0x80006698) moves a step
  or two before the row starts, so the row shown is read when the step count starts again (and when
  stopped, and on entering the page): under the port at count 62 of a 64-step row the arranger held
  row 2 and the panel R01, "2 A02". The 4-page window draws no page numbers and no ">A02".
  Build 65: the LEN line is one pixel tall, the bar's top row (two rows in build 64).
  Build 66: the page numbers are back in the 4-page window (1-4, and 1-4 again for the next pattern).
  The panel's top-left shows the arrangement row and the page ("R01 1/4", or "1/4"); line 1 the
  pattern playing and line 2 the pattern to come, both against the divider; line 2's count is in bars
  of 16 steps, rounded up (the last 16 steps show 1).
  Build 67: YES in the panel with LEN picked hides the grid's note-length lines, again shows them (kept
  until power-off; YES elsewhere in the panel still does nothing).
  Build 68: the arrangement row reads "ROW01". In the 4-page window while arranging it stands in the
  first row against the divider, over the pattern, and the page ("1/4") is not shown; not arranging,
  the page stays at the panel's top-left. In the 8-track window lines 1-2 show no patterns: line 1
  has the row ("ROW01", against the divider) while arranging, the page stays top-left. The cursor's
  track muted: M at the left of line 1 (after the name before). Over the rows' numbers, in the first
  row at x 45: TRK (8-track window) or PG (4-page window); the name follows from x 59.
  Build 69: ROW is a panel value while arranging (UP/DOWN reach it between the name and STEP; skipped
  when not arranging): LEVEL picks the row to go to, from the one already asked for or the one
  playing, through the arranger's own call for YES in arrangement mode (0x400a013c, 0x4004903c's):
  stopped, that row at once (under the port: row 2 and its pattern A02); playing, it comes next, the
  row playing ending this pass (0x8000669c, which the arranger's advance 0x4004a668 takes; under the
  port a jump to row 0 asked for during row 1 was taken, row 1 playing again 84 steps later). The
  arranger's cursor follows. While a row is asked for, ROW shows it and the row playing in turn with
  the cursor's blink, and the next pattern (line 2 and the lower half) is that row's. In the 8-track
  window the page ("1/4") moved to the top right corner.
  Build 70: both windows' panels alike: ROW against the divider in the first row while arranging,
  line 1 the pattern, line 2 the next pattern and its countdown (the 8-track window had none in
  68-69). The page ("1/4") at the first row's far right (its last column x 117), past the name, in
  both windows (not in the 4-page window while arranging); the name from x 58.
  Build 71: the timeline. In the 4-page window while arranging the eight rows are the arrangement's
  pages in time, a page a row: playing, the page playing at the top and the pages after it -- the
  rest of its row (LEN / 16 pages, rounded up), its repetitions (+2), the next rows through the
  arranger's resolver (after the row playing, the row asked for or the one the arranger has moved
  on to, as sg_nxt) -- scrolling up a row each page; stopped, from the arranger's row, scrolled by the
  cursor past the window's edges (back by row index, past LOOP / JUMP / REM rows). A row shows the
  cursor track's steps of its pattern, the row's step mod the track's length, and its page number;
  a dotted line where a new arrangement row starts; the note-length lines run on the row's steps.
  The cursor is a row and a column: UP/DOWN, FUNC + LEFT/RIGHT and FUNC + LEVEL a row, LEVEL (and
  STEP in the panel) a step along the timeline, LEFT/RIGHT the column (an edge opens the panel).
  Playing, it stays within the window and moves up with its page (hands off, to the page playing);
  stopped, it scrolls the window. Its step is in its row's pattern: the panel shows it, LEVEL locks
  it, YES gives an empty one a trig -- another pattern of the current bank written as the current one
  (its bank and CS1 copies; under the port a trig and a NOTE lock on A02 step 1 from the timeline
  while A01 was current, both copies, A01 untouched); another bank's pattern is not written. Undo
  covers the current pattern only. The trig keys stay on the current pattern (a held key's step
  takes the cursor there until it moves). The stock's MIDI activity dots at (10, 2) and (40, 2) are
  no longer shown on this page: after the periodic message draws them, the two pixels go back to
  what the page drew there (the one at x 40 blinked in ROW's last digit).
  Build 72 (stability, from a review of the module): FUNC + UP/DOWN on NOT2-4 in the panel (sg_kfud,
  a handler the stock's keymap calls) overwrote a2 through sg_sel, a register the caller keeps; it
  now saves it. LEVEL on ROW with an arrangement of no rows does nothing (it asked the arranger
  for row -1). Build 71's two dot pixels never reach a menu or popup: the windows are planes of
  their own over the page (lcd_view's composite); under the port, NOTE SETUP open over both dots
  while playing, the screen was the same with the cover on and off.
  Build 73: the step playing marked by a line under it (over it in 44-72), in both windows and the
  timeline; the cursor is its step flashing (the bar, or an empty step's foot line, drawn in the
  blink's on phase; past a track's end its foot line) in place of the line under it; a muted
  track's steps (sg_mm: mutes, the arranger's and solo, as the engine plays them) drawn as a
  checkerboard, x + y odd cleared (the cursor's track's in the 4-page window and the timeline).
  The divider from the top row down; PAGE in place of PG, the name 4 px further right there; the
  step playing at the top left ("--" stopped; line 3 empty); a play triangle left of the pattern
  playing while playing; the pattern to come flashes with the cursor's blink (not the repeat's
  infinity); the note-length lines hidden at boot (YES on LEN shows them).
  Build 74: the step playing flashes (the line under it of build 73 gone); playing hands off (the
  panel shut, no touch for 1.5 s) the cursor is not shown, only the steps playing flash; an empty
  step under the cursor flashes as an outline box the row's height. When the transport stops the
  cursor goes to the step the cursor's track stopped on (the timeline's to that column on its first
  row); STOP again while stopped puts it on step 1. A muted track shows X in place of its number (M
  before) and in the panel's line 1; its steps drawn as any other (73's checkerboard gone). "ROW 01"
  with a space.
  Build 75: a muted track's note trigs drawn as an x (3 px wide, 3 rows tall in a 4-px row, 5 in an
  8-px one), empty steps and trigless trigs as ever; its number (8-track window) or the page numbers
  (4-page window, the timeline: the cursor's track) and M in turn with the blink; M back in the
  panel's line 1. The top-left counter stopped shows the cursor's step ("--" in 73-74). The ARP
  page's key pressed on the ARP page switches the window (as FUNC + it); pressed twice within 20
  display ticks (~330 ms) the second undoes the switch and opens the arranger menu (the MKII ARR
  key's handler, 0x40058ab8; under the port it opened "ARR 2:DEADCODE303", EDIT first, and took
  DOWN). TRKS: / PAGES: and a space before the name. With a menu or popup open the page keeps
  still and the screen-changed flag is set every tick (the stock's tempo drawer does so on the
  other pages; it is off on this one), so the window's redraws reach the panel: Zach saw the
  PROJECT menu open on the unit and not move (builds 72-74); under the port it moved in every
  state tried, plane and panel stream, so the cause on the unit is inferred, not measured.
  Build 76: the double press opens the arranger's editor itself: the ARR menu's EDIT row
  (0x400be770: "EDIT", its handler 0x40058c14, a top-level 128 x 64 window, record 0x400c0b6c);
  under the port the editor opened on the arrangement, DOWN moved its cursor, NO went back to the
  ARP page and RIGHT moved the step editor's cursor. The M flash and the pattern to come flash on
  bit 5 of the blink counter (~530 ms each way), together; so do the cursor and the step playing.
  The step playing is drawn and, in the off phase, inverted over its cell (a trig's bar goes
  blank, an empty step a block); the cursor's step is drawn as ever with a frame round it (1 px
  outside the 3-px column and the row) in the on phase, so a note under the cursor stays visible
  (73-75 blanked it). The play triangle sits over line 2's countdown (or the infinity), not left
  of the pattern.
  Build 77: the cursor and the step playing share one mark: the step's cell and a pixel round it
  filled solid (sg_mark): the cursor's in the blink's on phase, the step itself in the off phase;
  the step playing's steady, no flash (76's frame and inverted cell gone). Under the port: Pages
  view stopped (hands on, 3 s hands off, after PLAY / STOP) shows the cursor's box in one phase
  and the bare step in the other; playing, each track's box stays in both.
  Build 78: playing with the panel shut, the 8-track window follows the page playing at once,
  hands on too (after 1.5 s hands off before; the 4-page window as ever). Arranging, the panel's
  lines 1 and 2 are values (SG_PA, SG_PB; SG_PS and the notes renumbered 16, 17-22): the pattern of
  the row playing and of the row to come (sg_tnr), picked with UP / DOWN, changed by LEVEL and
  FUNC + LEFT / RIGHT -- the row's byte (+ 21 from its + 20) written in the arrangement in use
  (0x10000000), 0-255 (A01-P16), and its unsaved bit set (bit 0 of the record's + 16 word, which
  the ARR menu's SAVE clears). Line 1 shows the row's pattern while arranging. With that bit set a
  SAVE button sits on line 3 (SG_PV); YES there calls the ARR menu's SAVE (0x40058250: its name
  first when it has none, then the SAVE ARRANGEMENT? question, window 0x460d1e14, which sg_free now
  counts). Under the port: ROW 00 A01 -> A02 by LEVEL (+ 16 bit 0 set), line 2 A01 -> A03 by FUNC +
  RIGHT twice, SAVE, YES, YES: the saved copy (0x1000b0a4 + 0x1614, the second arrangement) holds
  A02, bit 0 clear, the button gone. The question's window is outside lcd_view's composite (the
  five windows only), so its drawing was not seen.
  Build 79: LEN in the panel: LEVEL alone moves its value by one (0-127); FUNC + LEVEL steps through
  the subdivisions (sg_lstep: the next sg_lv value strictly past the value, either way; through
  the nearest in 55-78, LEVEL alone). The readout marks a value off its nearest subdivision: "-5/8"
  under it, "5/8+" over it; when that is too wide beside "L nn" the label alone, and when even that
  is, nothing (as before). Under the port: 58 "-5/8", +1 59 "-5/8", FUNC +1 60 "5/8"; 56 "9/16"
  (the marked form too wide), FUNC -1 54.
  Build 80: the other way round: LEVEL alone through the subdivisions, FUNC + LEVEL by one.
  Build 81: a bug since build 62: sg_run's signature lost everything mixed in before sg_nrec (it
  takes d0) whenever the next pattern was set (arranging in the 4-page window), so stopped the
  timeline never redrew -- no flash, no M; d0 now kept round it (under the port the label and the
  cursor's box now alternate stopped). The timeline's rows take their own arrangement rows' MIDI
  mutes (+ 5; the row playing, playing, sg_mm), for the M flash and the x trigs, so a row to come
  without mutes shows none. No gap between groups of four steps (sg_colx 4 col + 51). The
  countdown flashes with the pattern to come (the line's box cleared in the off phase). Arranging,
  M at the left of line 1 is a value (SG_PM, line 2 with the pattern; STEP 17, notes 18-23): YES
  opens the arranger editor's MUTE ROW window (its M column's YES, 0x40058e18) on the row playing
  (0x460d16e4); under the port it opened over the page ("MUTE ROW:000"), YES and NO closed it.
  The 6 px the group gaps took went to the panel: the divider at x 49 (43 before), the panel's
  values right-aligned against x 48, the row numbers at x 51, the grid from x 55 (sg_colx 4 col +
  55), the name after TRKS: / PAGES: from x 55 + the label. SCALE (MKI) / PAGE (MKII), 0x1b, in the
  8-track window: the cursor a page on, wrapping after the longest track's last page (sg_kscale,
  a SymbolRef on both keymaps' handlers 0 and 1; the 4-page window and FUNC keep the stock's);
  under the port 1/4 -> 2/4, four presses back to 1/4.
  Build 82: the stock's MIDI track strips either side (x 0-8, the track number and its icons; x
  119-127) are drawn over: the page owns the whole plane (sg_sum's columns 0-127; under the port no
  stock drawer wrote those columns while the page was up and playing, measured with --watch-pc on
  the fill, text and rect drawers' callers). The panel runs from x 1 (SG_PX), its values against x
  57, the divider at x 58, the row numbers at x 60, the grid from x 64 to 126. The 8-track window
  inverts the active track's number (0x100b14cc). The time since play started, "mm:ss", on line 3
  above STEP (sg_clock: DMA timer 3's free-running count, 132 MHz, added while 0x800065b8 is set;
  00:00 at the start, held when stopped); SAVE moved against the divider (x 36-56). COPY / CLEAR /
  PASTE -- FUNC + REC / PLAY / STOP, SymbolRefs on FUNC's sub-map records in both keymaps (stock
  0x40060f34 / 0x40060eb4 / 0x40060db0, which the timeline, the name's keyboard and a held trig or
  track key still reach): FUNC + LEVEL in the grid marks a run from the cursor (its cells inverted;
  gone when FUNC is let go; pages before, still in the panel); with a run, COPY copies it, CLEAR
  clears it and PASTE fills it with the clip repeated; with none, COPY and CLEAR open a window over
  the grid -- TRIG, ROW (the cursor's page of its track), PAGES 1 2 3 4 (LEFT / RIGHT pick one,
  LEVEL right on, left off = X; PAGES picked and all four on when it opens) -- YES does it, NO
  closes; PASTE without a run puts a run at the cursor, a row at the cursor's page, pages at the
  pages they came from. A step is what the stock's MIDI trig paste (0x4002c4d4) moves: the three
  masks' bits (+0x00, +0x08, +0x10), the 32 lock bytes and the trig word, into the bank and its
  CS1 copy, the step's track bit for a lock, then 0x40029b9c(t) (the paste's own ending). A clear
  keeps the trig word's condition (as sg_trig). "COPY 4" / "CLEAR 16" / "PASTE 4" for 1.5 s at the
  panel's top. Under the port: steps 1-4 of T1 copied and pasted at 10-13 (the grid and the
  panel's notes match); CLEAR's TRIG emptied step 1; PAGES with page 2 off copied 48 steps, pasted
  into T3's pages 1, 3, 4.
  Build 83: FUNC + SCALE (MKI) / FUNC + PAGE (MKII) on the page opens a scale window over the whole
  screen in place of the stock's PATTERN SCALE window (0x40059f88; a SymbolRef on FUNC's sub-map 0x1b
  record in both keymaps; elsewhere, over the name's keyboard or a copy window, the stock's). PER
  TRACK (+0x8e55): MASTER on the title's row -- LEN (+0x8e50, a word: 2-1024 with INF, -1, between
  the ends, as the stock window's field 3) and SCALE (+0x8e52) -- then T1-T8, each LEN (+0x48f8 of the
  track's record, 2-64) and SCALE (+0x48f9, 0-6 = 2X 3/2X 1X 3/4X 1/2X 1/4X 1/8X; LEVEL right faster,
  the index down, as the stock's field 2) and a bar its LEN long. NORMAL: one row, the pattern's LEN
  (+0x8e53) and SCALE (+0x8e54). UP / DOWN a row, LEFT / RIGHT LEN or SCALE, LEVEL the value (FUNC +
  LEVEL a LEN by 16), YES / NO / FUNC + SCALE close. Written to the bank and its CS1 copy, then the
  dirty flags, 0x400339d8, 0x4009da20(-1) and the LEDs, as the stock LEN setter (0x4004c6e0) ends;
  that setter's copy of page 1 into a newly reached empty page (0x4009a4fc) is not done. Under the
  port: the window matched the stock one's values (MASTER 128 1X); T2 16 -> 2 and 3/2X, T1 2X and 63;
  back on the grid T2 had two steps.
  Build 106: LEFT of a row's LEN picks its number (T1-T8, or NORMAL's row), inverted; YES there
  closes the window and opens the stock PATTERN SCALE window (0x40059f88) -- its LEN / TOTAL pair
  (1-16/16, 1-32/32 ..) and MASTER -- a track's row first making that track the active one
  (0x40083bf8). Under the port: T3's number, YES -> "SCALE, MIDI 3" 64/64; an edit to 63 there, then
  FUNC + SCALE again showed T3 63 in the list.
  Build 107: the cursor's track follows that jump (it stayed on T1 under the stock window in 106).
  Build 84: zoom and scroll in the 4-page window and the timeline, the audio editor's way: knob F
  zooms -- 4, 8, 16, 32 or 64 steps a row at 16, 8, 4, 2 or 1 px (16 at boot) -- and knob E scrolls:
  the 4-page window's rows when they do not all fit (16 rows of 4 steps, 8 shown; a cursor that
  moves out of view brings its row back), the timeline further on through the arrangement (pages
  past its first, as far as the arrangement goes; the first row is then not the page playing).
  SymbolRefs on the shared encoder table's knob records (E 0x400c08b4, F 0x400c08ca; stock 0x40055008),
  the stock's in the 8-track window, over the name's keyboard or a window. The timeline zoomed: a page
  in 2 or 4 segments down as many rows, or 2 or 4 pages side by side (sg_tl now holds up to 32); the
  rows' page numbers on a row's first segment; the bars as wide as the pitch less one, an x only at
  4 px and wider; the note-length lines only at 16 a row. COPY / CLEAR / PASTE in the timeline too: on
  the cursor's row's pattern (sg_cpat), its page for ROW and its pages for PAGES; FUNC + LEVEL marks a
  run along the row (the column 0-15; FUNC + LEVEL in the panel still moves rows); a row playing
  another bank's pattern can be copied, CLEAR and PASTE show "OTHER BANK" and write nothing (the
  pattern's CS1 copy is not there, as for a lock: sg_cedit). Under the port: the 4-page window at all
  five zooms and scrolled; the timeline at 8, 32 and 64 a row and scrolled three pages on; steps 1-4
  of a timeline row copied and pasted into the row two pages down (the panel showed the copied note).
  Build 85: the scale window shows any pattern of the bank: the title row's first value is the
  pattern (the current one when it opens; LEVEL A01-A16), its mode after it, and every value read and
  written there (sg_spat). MASTER moved to its own row under the title, "M", its LEN and SCALE in the
  tracks' columns; the rows 6 px apart (7 + 6 r). sg_skey kept d2 for its caller (a draft that used it
  stopped the arrows after the first press). Under the port: A02 shown with its own lengths (T1 16), T1
  set to 8 in A02, A01 and back to A02 kept it.
  Build 86: the scale window's mode reads SCALE SETUP for PER TRACK (PER TRK before; NORMAL stays).
  The bars from x 47 (60 before), 5 px for 4 steps, a page a 20 px segment with a gap, so 64 steps
  reach x 126. The rows drawn bottom up and the title's line last: a text's cell clears the row
  over its glyphs, which at 6 px apart cut the picked value's box on the row above (seen as a hollow
  "[64]" under the port in 85; solid now).
  Build 87: the panel's LEN line keeps its fraction next to the value, 3 px after "L 58" ("L 58
  -5/8"), not right-aligned against the divider (the panel widened in 81-82 and left a gap); left out
  or shortened as before when it would reach the divider.
  Build 88: with the arrangement on but never played (0x80006698 -1) sg_prow takes the first row that
  will play (sg_tnr(-1), as the timeline does), so ROW 00 and the rows' pattern lines show before play
  (under the port, arrangement mode poked on: no ROW in 87, ROW 00 now). The panel's first line: the
  time top left (line 3 in 82-87), the step count right-aligned against ROW (3 px between) or, not
  arranging, against the divider; an undo / copy message takes the whole line while it shows.
  Build 89: in the timeline each arrangement row's pattern name sits on the panel's right edge,
  right-aligned against the divider and level with the grid row where that arrangement row begins
  (sg_tnl, noted as the timeline draws rows that start at the grid's left; up to 8; sg_tnames after
  sg_panel). Line 2 keeps only the countdown there, from x 12. The first name is the pattern to come:
  it flashes with the countdown, and picking line 2 inverts both (LEVEL / FUNC + LEFT / RIGHT change
  it as before). A name that would overlap SAVE (line 3, the arrangement unsaved) is left out. Without
  the timeline (Tracks view), or with no row starting at the grid's left, line 2 is as in 88.
  Build 90: the stock's MIDI pages keep their track strips: sg_rest makes the two strip drawers'
  caches stale (0x400c0c50 / 0x400c0c94, the MIDI-mode copies, -1; each track's value -1 and selected
  flag 2 at 0x400c0c54 / 0x400c0cb8 and 0x400c0c74 / 0x400c0c98), so the periodic handler's next
  tick (0x40052200 -> 0x4003fed8, 0x4004bd48) draws all 8 (82-89 left them blank after a visit;
  under the port the NOTE page after the step editor: blank in 89, drawn now). The timeline: the play
  triangle 1 px before the pattern playing on line 1, M before it; the countdown with the next row's
  name ("3 A02" / "-- A02", sg_nrow from sg_nxt, sg_tl2set; line 2 from x 12 when that row is not on
  screen). VEL and LEN: "V" / "L" and the value 2 px apart (a space before); VEL picked inverts its
  whole row, as LEN. Zoom: "16/R" (steps a row) at the first row's right in the 4-page window and the
  timeline, before "1/4" when that shows, and "ZOOM 16" at the panel's top for 1.5 s on knob F. At
  4 and 8 steps a row a muted trig's x sits over the cell's middle with the step's foot line under it
  (sg_xm). Zoomed out (32, 64) each pass of an arrangement row starts a screen row, pages 1 and 3 at the
  left (pads in sg_tl, flag 4, which the cursor passes over; 84-89 ran the pages on, so a row's page 1
  could sit at the right half). The scale window: PATTERN + a trig picks that pattern (SymbolRefs on
  the PATTERN layer's 16 trig records, 0x400bef04 + 0x1a n + 2, stock 0x40056b2c; the stock's pattern
  change not made; under the port PATTERN + trig 4: A04 in the window, A01 still playing). NO in the
  grid deletes the cursor's step (CLEAR's TRIG, "CLEAR 1"). A second YES within 20 ticks of the one that
  opened the panel opens the step's window over the screen: STEP, the four notes with octaves, VEL, LEN
  and its fraction in the big font, the panel's pick shown and changed there (UP / DOWN a line, LEFT /
  RIGHT the notes, LEVEL, FUNC + UP / DOWN an octave), YES or NO back to the grid; the panel stays as
  it was (the window is meant to take its place later).
  Build 91: the frame's top line runs the whole width (x 0-127; the stock's x 8-119 since the strips
  went in 82), drawn after the panel and the names, whose text cells clear row 0. Knob F zooms 4, 8 and
  16 steps a row only (4/R-16/R); 32 and 64 are left for a view of their own (sg_tfill's pads only
  come into play there).
  NO in the grid asks first: "CLEAR? YES" at the panel's top for 5 s (sg_nconf, sg_umt 300); YES then
  deletes the step (sg_ndel, as 90's NO), NO again cancels, the cursor moved drops the question
  (sg_nask, each tick) and YES goes on as YES.
  Build 92: the full view. FUNC + ARP on the page (SymbolRefs on FUNC's sub-map ARP press handler in
  both keymaps, 0x400bf3a0 / 0x400bf714, stock 0x400322f0; elsewhere the stock's, the same under the port
  as 91 on the NOTE page) turns it on and off in both windows; ARP still flips them. The grid takes the
  whole screen: sg_gx 0 (sg_colx), no panel, divider, row numbers, note-length lines or names. The
  8-track window shows each track's 64 steps (2 px a step) or the cursor's 32 (4 px); the 4-page window
  and the timeline 32 or 64 a row, the timeline's rows aligned as 90's pads made them. Knob F picks 32 /
  64 (sg_fzr; "ZOOM 32"), in the 8-track window too. LEFT / RIGHT run along all 64 steps, wrapping. The
  title row (sg_fhdr): TRKS: / PAGES: and the name at the left, a message there while it shows, the
  pattern playing and "64/R" at the right. The panel opened there (YES, a held trig, an edge) is the
  step's window (set as the draw starts). Under the port: both windows at 64 and 32, the timeline at both,
  YES -> the step's window, FUNC + ARP back to the normal view.
  Build 93: no 2-px steps: the full view is 32 columns at 4 px everywhere. The 8-track window's 64 (knob
  F, sg_fzr 4, "64/R", the default) is two lines of 32 a track (sg_f2l): steps 1-32, then 33-64 three
  rows down, each line 2 px tall (sg_rh 2; a muted trig its top row alone, sg_xm), 2 rows between tracks;
  its 32 the cursor's half on one line. The 4-page window and the timeline: 32 a row only (knob F does
  nothing there; their 64 is already two rows of 32).
  Playing, zoomed out (2 pages a screen row: the full view's timeline), the window starts at the first
  page of the screen row the page playing is on (sg_tupd: the page less its place in the row, sg_tpo;
  the page-playing flag on that entry; the cursor up a screen row's pages when the window moves), so
  the play line runs across the row; in 92 the window moved on each page and the line crossed only
  the row's first half before everything shifted left (seen on the unit). Not run under the port: play
  does not start there with the arrangement poked on. The 8-track window's 32 follows the playing half
  hands off, as the page does.
  Build 94: the full view is 32 a row only (93's 64 in two lines unreachable: sg_f2l returns no; knob F
  does nothing there). Each track's steps are repeated across the 32 columns (sg_fstep: the column's
  step mod the track's length), so a 16-step track fills the row. Playing, the 8-track window shows the
  pattern's count's 32 (0x800065b4 & -32: on at each 32) and each track's play mark is the last column at
  or before the count whose step is the one it plays (sg_fpcs; the 4-page window's 64 the count mod 64),
  so the line runs across the screen; stopped, the cursor's half. Under the port (pattern mode, play):
  the mark at column 2 of the second 32 after 3 s, column 28 after 6 s, the same column on every track;
  16-step tracks shown twice a row.
  Build 95: in the full view's timeline each arrangement row's start (its first pass, first page) gets
  a screen row of its own first, its readout, inverted across the screen (sg_tinfo; an sg_tl entry with
  flag 8, the rest of that screen row pads; the cursor passes over both): "R01 A01 X4 OF3 LN16 S03/03
  M" -- the row, its pattern, repetitions (+2 plus one), offset (+10, word), length (+12 less +10: +12 is
  the end, measured in the ARR editor: OF 3 made +12 19 with LN still 16), scenes A / B (+8 / +9, 0xff
  none, 1-based as the editor shows them) and M when it mutes (+4 / +5). The ARR editor's T and B
  columns did not change a byte with LEVEL under the port and are not shown. Knob F gives the full view
  16 or 32 a row (sg_fzr 2 / 3) in every window: 16 is 8 px a step (the 8-track window 16 steps of each
  track, the 4-page window four rows). Open: the timeline treats +12 as the row's length (pre-95);
  with an offset it shows the steps before it too -- whether the arranger's count starts at the offset
  decides the fix, not seen under the port (play does not start there with the arrangement on).
  Build 96: the full view's title, right side: the steps in view, the cursor's step, the pattern
  playing and the zoom -- "33-64 S33 A01 32/R" (the 4-page window "1-64", the timeline without the
  steps; sg_fwin, the 8-track window's first step). FUNC + LEFT / RIGHT there move the cursor a whole
  window (16 or 32 steps; 16 before), so each press is a new screen. Playing, the full 8-track window
  follows the count only hands off (SG_IDLE), staying on the cursor's window while it moves (94-95: at
  once, so FUNC + LEFT / RIGHT seemed to do nothing or to jump). Moving the view never changes the
  pattern: only the cursor's step moves.
  Build 97: dotted lines down the full view's grid (sg_fdots): at 32 a row one down the middle (x 63,
  between steps 16 and 17), at 16 a row one every 4 steps (x 31 / 63 / 95), in the gap after a column's
  bar, every other row from 9, left off the timeline's readout rows (sg_fband, set by sg_tinfo).
  Build 98: the readout rows are edited in place: the cursor goes onto them (sg_tmv passes only pads
  now; sg_tsync leaves the step), LEFT / RIGHT pick a field (sg_tcol 0-5: pattern, repetitions,
  offset, length, scene A, scene B; boxed light in the band), LEVEL changes it (sg_aedit: +1 0-255, +2
  0-63, +10 0-255 with the length kept, the end +12 = offset + length 1-1024, +8 / +9 none or 1-16),
  written in the arrangement in use and marked unsaved as the ARR editor does (sg_patlv); YES and NO do
  nothing there. Under the port: row 0's pattern A01 -> A02, X1 -> X4, LN16 -> LN18, scene A -> S03.
  STOP keeps the cursor where play stopped in every view: the full 8-track window stays on the window
  it stopped in until the cursor moves (sg_fwv / sg_fsc / sg_fws), and its cursor is boxed on its first
  column only (sg_fcur1; the repeats showed it twice); the timeline keeps the screen row that was
  playing and puts the cursor on its page (sg_tstop, sg_tsfix; not run under the port). At 32 a row a
  single dot after every 4th step, in the gap, midway between a row's foot and the next row's top.

Build 99: the full 8-track window labels its tracks. Each row starts with the pattern and the track, "A01:1", at x 1-29, as the 8-track window's numbers did: a muted track's number turns to M with the blink, and the active track's is inverted. The steps start at x 32 with a 3 px pitch at 32 a row (6 px at 16), still 32 (or 16) steps a row. The dotted lines and the 4-step dots follow the grid. The 4-page full view is unchanged.

Build 100 (image tag A0: the build field takes two characters): the full timeline's readout rows put the row number first as a field of its own (LEFT from the pattern picks it), then a flashing 4-3-2-1 on the next row's readout over the last 4 steps before it starts, the pattern, X and M; OF, LN and the scenes are right-aligned, the scenes compact ("S3/12", "S-/-" for none). YES on a readout row opens the arranger's editor at that row (its row 0x460d16e4 set before the EDIT handler, 0x40058c14, which opens on it). UP / DOWN in the full timeline go straight up / down the screen: onto a readout the field nearest the cursor's x, onto the steps the column under it. LEFT / RIGHT run on into the page beside on the same screen row and stop at the ends: no edge opens the step's window in the full view (YES on a step and a held trig still do). A row shows its LN steps only, from its offset: measured under the port, the step count starts at 0 at the offset (OF4 LN16 counted 0-15), so the play line is drawn at offset + count, and the countdown counts LN steps (end less offset). STOP keeps the timeline where play stopped: sg_stopk keeps the page playing (sg_tps) as it plays, since sg_tupd stopped cleared its own copy when it ran first in the tick (in the emulator the window went back to the first page; on the unit Zach saw the same); STOP again moves the timeline to the arrangement's first row. The panel's SAVE button sits at the left above STEP. The full Tracks view: track numbers in a 16-px left column (x 6-8), the steps at x 16-111 (3 px, 6 at 16/R), a free 16-px right column with the zoom ("32/R") at its foot; the title row "R01 TRKS: T1 A01 4 ... >>A02" (the row playing, the pattern and the bars left before the next, flashing; the pattern to come in the top right corner after two play triangles, flashing); the right column holds the cursor's step ("S01", first row), the window in view of the pattern's ("1/2", second) and the zoom at its foot.

Build 101 (tag A1): the full views' steps are 3 px tall (their foot where it was), and their guides sit only between the rows: each line a 2-px dash midway between one row's foot and the next's, nothing beside the steps; the 4-step dots at 32 a row 2 px lower than in 98-100, a pixel over the next row's tops. A muted trig is an x at a 3 px pitch too (the full Tracks view at 32 a row), the x taking the gap. The full Tracks title row ends in "4321>>A02": the bars left in a 4-place count whose place moves toward the triangles as it falls; the arrangement row moved to the right column's first row (S01 second, the window third). The panel's M flashes while a track is muted (the engine's mutes, or the row playing's own). The timeline holds its window on an arrangement row's first page until the row has played when the row fits (a page a screen row or two, or two to a row); zoomed in to 4 a row it follows the page playing as before.

Build 102 (tag A2): sg_poll calls TRIG MODES' tm_poll first (a weak reference: nothing without that module), which puts the active track's own trig mode in place after a project load or a SETTINGS edit (modules/trig-modes/README.md).

Build 103 (tag A3): in the full 8-track window a muted trig's x sits a row up, over the step's foot line (drawn as an empty step's), as at a pitch of 8 or 16; the x's left column at x0 at 3 px, centred at 6.

Build 105 (tag A5): on octabam main of 30 Oct 2026. Flashing follows the tempo while playing: sg_poll sets the blink's bits 4 and 5 from the step count (0x800065b4), so bit 5's off phase is the second half of each beat and bit 4's every other step; stopped, the blink runs on the poll's ticks as before. The full timeline's countdown moved to the middle of the next row's readout: the bars left before that row starts, in a 4-place field at x 56-71 whose place moves right as it falls ("4...", ".3..", "..2.", "...1"; more than 4 at the 4's place), as the full Tracks title's; the 4-3-2-1 after the row number (100-104) is gone.
  Left, in place of the tempo, the LEV column and the info box: the track's name (five
  characters, "T<n>" until set), the pattern and page in view / pages, the step playing (1-64; with
  the arrangement on, its row first), STEP nn, then the cursor's step: its four notes by name (NOTE,
  NOT2-4 as notes, octaves a row below; - = off), VEL as "V 100", and on the line below LEN as
  "L 24 1/4", its value 0-127 then its note fraction (build 55), from its locks or the Part's NOTE page values. **YES** goes to
  the panel (an empty step gets a note trig first): LEFT/RIGHT move along a line (name, notes), UP/DOWN
  between lines (name, notes, VEL, LEN), the **LEVEL** knob changes the value (a step value as a lock on
  that step; LEN through its fractions only, 1/32 to 5/4 and INF -- the stock's own fraction values
  (21/16, 126, dropped in build 55: "L 126 21/16" is wider than the panel), a value between two of
  them shows the nearer's fraction and starts from it; a name character through space,
  digits, A-Z and signs), **NO** goes back to the grid. UP/DOWN, YES and NO with FUNC, the arrows, YES and NO with a trig or a track key held or with a
  menu or popup open over the page (build 51), and all keys on other pages
  work as before. On this page the tempo (and EXT's blink with
  an external clock) and the transport icon do not draw; leaving it, the stock's screen is drawn whole
  again (build 49: until then the panel stayed on the NOTE, LFO and CTRL pages), and a grid-recorded
  trig lights its LED at once (build 49: until then only at the next REC or transport key). In arrangement mode UP/DOWN on this page move the cursor, not the
  row. The stock's MIDI activity dots stay at (10, 2) and (40, 2).
- **No arpeggiator, no legato, no arp scale.** The MIDI engine always sees MODE off, LEG off and KEY off (build 59), whatever a Part, a lock
  or a scene holds for those slots.
- **FUNC + the ARP page key opens no window.** ARP SETUP (the arp's note row, LEN, KEY) is gone with it;
  on the ARP page the combination switches the step editor's window (build 52).
- **TRAN is in NOTE SETUP** (FUNC+SRC on a MIDI track), the fourth slot, next to CHAN BANK PROG SBNK:
  −64 to +63 semitones, turned and confirmed with YES (NO drops it) like the other NOTE SETUP slots,
  saved in the Part. It is no longer lockable or scene-able. A project saved before this module keeps
  its transpose: an old Part's empty slot takes the ARP page's TRAN when the Part is loaded.

**How.** NOTE SETUP's unused byte +3 (parameter 9 of the NOTE descriptor, `----` in stock) becomes TRAN
(name, default 64, TRAN's formatter, a value widget, its enable nibble). The ARP descriptor's enable
nibbles are cleared (`docs/firmware/PARAM_PAGES.md` section 3b), and the setup-window dispatch returns
for the ARP page. The MIDI engine reads its page-1 values from a snapshot of the live records
(`0x46c76fe0 + 32 t`, copied at `0x40003dc4`; TRAN is read at `0x4009fb3a`, MODE by the arpeggiator at
`0x40099xxx`); a detour on that copy writes NOTE SETUP's TRAN into the snapshot and clears LEG and
MODE. A second detour in the Part validator's NOTE SETUP check gives an old Part's 0 the old TRAN. The
code sits in the OS image's free space, not the DRAM runtime: the validator runs in the power-up load.

**Measured** under the port (`octazach`, build 39, 22 Oct 2026, project RIG): NOTE SETUP shows
`TRAN +0` on the old project; +12, +7 and −5 confirmed with YES move every note MIDI track 1 sends by
exactly that much; the ARP page is empty and a knob turn on it changes nothing; FUNC+AMP in MIDI mode
opens nothing, in audio mode AMP SETUP as before; with MODE UP and SPD forced into the Part, stock
sends the arp's extra notes (20 in 3 s) and this build sends the pattern's 15. **Not run on a unit.**

**The step editor** (`stepview.s`, a DRAM unit). Drawn after the main view draws the page (a
detour at `0x4004e936`, the end of `0x4004d948(page)`) and from the UI's periodic message (UI message 5,
its call of `0x40052200` at `0x40061e8e` retargeted) when its inputs change or a checksum of the plane
it owns (x 9-118, rows 0-63, but row 2, where the periodic message's MIDI activity dots are set or
cleared every tick, `0x40052328`) no longer matches. On this page the info box's drawer (`0x4004c0a8`, also
run by a soft timer), the pattern field's (`0x400418e0`) and the beat boxes (`0x400373dc`, the step
message's call) return. The keys are the handler pointers of LEFT/RIGHT (`0x4004b970`), UP/DOWN
(`0x400491a0`), YES (`0x4005e4c8`) and NO (`0x4005e25c`) in both keymaps' records (MKI `0x400bfc10`,
MKII `0x400c01f4`; handler(code, state 1 press / 2 repeat / 0 release)), and LEVEL's in the shared
encoder table (`0x400c08e0`, `0x4004eb24`); a key is the editor's on this page unless FUNC, a trig or a
track key is down (held flags `0x46c7d8ee + code*24`, `0x4003171c`). Data: a MIDI track's record
`bank + pattern*0x8ed8 + 0x48d0 + t*0x8b0` (+0 trigs, +0x10 trigless, +0x28 length, +0x30 + 32 s the
step's 32 lock bytes, 0xff none, +0x830 + 2 s the trig word), its CS1 copy at `0x1001614e + the same
offset`; the Part's MIDI page-1 values `bank + 0x8f162 + part*0x18b2 + t*32` (NOTE VEL LEN NOT2 NOT3
NOT4 at 0-5), the track's name in its ARP SETUP, `bank + 0x8f262 + part*0x18b2 + t*0x24 + 13..17` (claimed:
+12 is MIDI PART STATE's flags; the ARP descriptor's setup counts 7-11 raised to 128 so the Part
validator keeps the characters), written to the Part, its CS1 copy and the live record
`0x46c76dc0 + 0x44 t + 0x2d`. A lock is written as the stock
p-lock store's MIDI branch writes one (`0x4004f7ba`: both copies, the dirty flags `bank+0x9b332` /
`0x100f8598` / `0x40027e00`, the step's track bit `0x46c7d2e4[s]`, `0x4009da20(8+t)`), a trig as GRID
RECORDING's (`0x400514e0`: the bit in both copies, the trig word's micro timing and count cleared).
Names and values come from the NOTE page's own formatters (`0x4003b9c4` NOTE, `0x4003bb40` VEL,
`0x4003bb28` LEN). Build 47 draws LEN from its own fraction table instead: the engine counts a note's
LEN down one a tick and never for 127 (`0x4009a30a`), so the value is linear and 120 / 126 are 5/4 and
21/16 (stock's labels there say 11/8 and 6/3).

**Measured** under the port (builds 44-53, 22-23 Oct 2026, project RIG): build 53, MIDI tracks 2-8
(muted in RIG; FUNC + T1 set bit 8 of 0x8000000c for T1, measured) show M; LEFT at column 1 opens the
panel; LEFT, DOWN, DOWN, RIGHT returns to the grid; RIGHT held 2.5 s stops at step 16; DOWN makes T2
the active track (0x100b14cc = 1); on T2's empty step LEFT then LEVEL +3 adds the trig and the lock. build 52, grid recording,
PAGE twice: the window at 3/4, the cursor on step 33, the trig keys' page 2; FUNC + RIGHT twice: page
2 in both; playing 4 s hands off: the window shows page 3 (the cursor on step 1, the trig keys' page
still 0), RIGHT then: page 1, step 2; FUNC + AMP: the cursor's track at its 4 pages, DOWN to step
17, FUNC + AMP back: the 8 tracks at page 2. Screens read from the plane (`--lcd`), which equals what
the panel receives since build 50. build 51, the panel stream
again: over the ARP page the PROJECT menu (FUNC+MIXER) follows DOWN at once and closes with NO, TEMPO
and PATTERN SCALE take DOWN and LEVEL, and RIGHT under TEMPO leaves the editor's cursor where it was
(build 50 moved it under the popup); with the window closed the arrows are the editor's again. Build
49 showed the PROJECT menu not moving on the panel after two DOWNs (the screen-changed flag again). build 50, read from what the
panel receives (`--interactive`'s `tx` decoded by `PanelLink`, against the plane): the ARP page, two
RIGHTs, DOWN, five DOWNs, a grid-recorded trig, both blink phases and the NOTE page after it all
match the plane exactly (0 pixels); build 49 differed by 15-24 pixels after a cursor move, the frames
reaching the panel only when a stock drawer set the screen-changed flag (`0x46c7c72c`, the TRAPS
entry `trap-lcd-plane`). Every earlier check below read the plane (`--lcd`), which cannot see that. build 49, ARP page, PLAY,
STOP, then SRC: the screen equals the NOTE page reached without the ARP page but for one beat box
(after STOP the restore fills the box of the step it stopped on, stock's leaves them empty), where
build 48 left the panel and the grid's pixels; on the page PLAY and STOP reach the tempo's and the
transport's drawers twice each and neither draws; RIGHT held 2 s moves 36 steps (500 ms repeat: 7 in
3 s); FUNC + RIGHT goes to step 17 (page 2/4), T4 to track 4; grid recording, trig 5 on this page
now makes the LED refresh call (0x4007e998(0)) the NOTE page makes, the LED itself not decoded; the
cursor is drawn in one frame and not in another 267 ms later. STEP .. LEN sit at the panel's bottom (LEN rows 57-61, its box 56-62). Not with an external clock. build 48, the numbers' bottom
rows are the steps' (rows 5, 13 .. 61) and the frame's top line stays whole over the "1"; build 47, T1 step 7 locked to
F5 with LEN L1/16 plays F5 for 298 frames, with L1/4 for 1191 (4x); L1/1 also ends at 1191, where the
track's next trig starts, so values past that gap were not heard; the cursor is 3 px, the step's width; idle on the page it draws once
(2 panel draws in 4 s), playing once a step (46 in 4.4 s); a name edited to "W" and "R *"
lands in the Part's and the live record's bytes; the grid draws the 8 MIDI tracks'
trigs as their records hold them, the cursor moves and wraps (row 8 above row 1, step 64 left of
step 1); T1 step 1 shows its locks (F#4, VEL 100) and the Part's LEN 58; YES on the empty step 2, RIGHT
(NOT2), LEVEL +3: the step gets a trig and a NOT2 lock of 67, and the MIDI out plays D3 + F3 at
velocity 55 on step 2 where stock plays nothing; LEN edited to 55 the same way; NO returns to the grid;
playing, each track's bar follows it; arrangement mode shows the row and the step; the NOTE page with
the same keys draws as stock's; FUNC + UP on this page reaches the stock. verify_dram_boot,
verify_menu, verify_labels pass. **Not run on a unit.**

**Retracted:** build 49's cursor, track-key and trig checks read the plane only; on the unit those
frames did not reach the screen until FUNC (fixed in build 50).

**Retracted:** "the NOTE page with the same keys draws as stock's" (builds 44-46) was measured
without the ARP page first; after it, builds 44-48 left the panel there.

**Known:** a MIDI LFO aimed at LEG or MODE writes the engine's snapshot after the detour and still
reaches the engine.

Build 107:
- COPY's window has a fourth line, 303: LEVEL picks an audio track (the cursor's number when the
  window opens), "T1 OK" when it is an OCTA-303 track in the current Part. YES copies its sequence
  (its length's pages) into the clip as MIDI steps: a trig becomes a note trig whose NOTE lock is its
  TUNE lock (or the Part's TUNE) - 16 (TUNE C3 = raw 64 = MIDI 48, 303 FOLLOW's mapping); an ACC lock
  above 0 becomes VEL 101-127; a trigless step after a note (OCTA-303's slide) becomes a note and the
  note before it gets a LEN lock past it (6 a step + 3), so 303 FOLLOW slides. PASTE puts it on the same
  pages of the cursor's MIDI track. Under the port: OCTA-303 trigs at steps 1, 5, 9 and a trigless 6
  (TUNE locks 69, 60, 67, the Part's 64, ACC 110 on 5) pasted as notes 53, 44 (VEL 110, LEN 9), 51, 48.
- Knob D in the full view's PAGES: the timeline's row pitch 7-17 px (8 rows at 7, 48 / pitch + 1
  past it), the 4-page grid's row stride 5-28 px (the rows that fit in 56 px, knob E scrolling the
  rest); "SPACE n". SymbolRef on the shared encoder table's knob D record (0x400c089e).


Build 108:
- MIXER + MIDI (hold MIXER, press MIDI) opens the step editor's full view from anywhere: MIDI mode on
  when it was off (0x40055548, the MIDI key's own switch), the ARP page (0x4005578c with key 0x23, the
  last key cleared so it is not a double press), the full view; the MIXER window MIXER's press opened
  closed (0x4007d274). The combo again goes back: the MIDI side's page (page 0-4 -> key 0x22 0x24 0x23
  0x25 0x26, the inverse of 0x400a7280), audio mode when it was on, the full view as it was. Another
  page key or MIDI also ends it (sg_poll, after a 60-tick grace for the asked page to land).
  SymbolRefs on the MIDI key's press and release in both keymaps (stock 0x40055678). The switch runs
  on MIDI's release, as the stock's does, and is called with the stock's arguments (0x35, 0): it
  writes its first argument's slot before its tail call (0x4005566a), and called with none it
  overwrote the caller's saved registers and hung the port. NO does not end the view (it is the
  grid's CLEAR?). Under the port:
  from audio mode on LFO, the combo showed the full view on the MIDI side; again, audio mode on LFO.
- The full view's PAGES title: the pattern before the step ("1-64 A01 S05 32/R").
- Not yet: the ARP page back to the stock arpeggiator. The track names live in the arp's setup bytes
  (LEG MODE SPD RNGE and ARP SETUP 7-11, the KEY read disabled), so the arp needs the names moved first.

Build 109 -- the pitch view (the full view's third window; ARP there cycles TRKS -> PAGES -> PITCH):
the cursor's MIDI track as a piano roll, its page's 16 steps across (7 px a step from x 16) and 12
semitones up the screen, A at the bottom to G+ at the top (4 px a row, rows 12-59; the sharps' rows
dotted). A step with a trig is a 5 x 3 block at its NOTE (its lock, else the Part's NOTE), a trigless
step its outline; a note above the window an up arrow at the top of its column, below it a down arrow
at the foot; the step playing a line over its column. Title: PITCH, the track, the window's bottom
note (A3), the pattern and step. The cursor is a box at (step, semitone), its note's name at the left.
LEFT / RIGHT a step (wrapping, the page following), UP / DOWN a semitone (past an edge the window
an octave), FUNC + UP / DOWN the window an octave, FUNC + LEFT / RIGHT a page, YES the cursor's note:
no trig -> a note trig with that NOTE lock; that note already -> the step cleared (CLEAR 1); another
note -> this one. The window opens on the cursor step's note. Only the main NOTE is drawn (not NOT2-4).
Under the port: T1's page 1 showed F+4 at step 1 (row 9 over A3), A3 at step 3, down arrows on the
steps below A3; YES at step 3 with the cursor on D+4 wrote its NOTE lock 63.

Build 110:
- AUDIO: in MIXER + MIDI's view, MIDI alone switches the view between the 8 MIDI tracks and the 8 audio
  tracks (the Octatrack stays in MIDI mode). The views read an audio track's record (pattern + 0x91a t:
  trig mask +0x00, trigless +0x08, plock +0x10, locks +0x59 + 32 s, its LEN +0x50 in PER TRACK) and its
  step playing (0x800064e0 + t, running 0x80006500 + t: the first 8 entries of 0x4009b2b0 / 0x4009b290's
  tables). Titles AUD: / APGS:, the track "T<n>"; no panel, note-length lines, mutes or pitch view;
  COPY / CLEAR / PASTE do nothing. YES cycles the cursor's step none -> trig -> trigless -> none, NO
  clears it; a new trig or a cleared step gets its 32 lock bytes 0xff and its plock bit cleared (as the
  stock's trig placing), in the bank and its CS1 copy, then the dirty flags and 0x4009da20(t). Under
  the port: T1 of A01 (empty) after YES at step 1, YES YES at 2, YES x3 at 3, YES NO at 4: trig mask
  0x01, trigless 0x02, plock 0. Leaving the view (the combo, a page key) turns AUDIO off.
- The pitch view draws NOT2-4 (NOTE + v - 64; 64 off) as 3-wide blocks on their rows, inside the window.
  Under the port: NOT2 -5 and NOT3 -9 on F+4 showed C+4 and A3 under it.

Build 111:
- The pitch view's left: all 12 names, A at the bottom to G+ at the top, the even rows' at x 0 and the
  odd rows' at x 8 (a 5-px name by each 4-px row), the cursor's row's inverted (the cursor's single
  name in 109-110). The step playing: its column inverted over the grid, rows 11-59, as the other
  views mark the step playing (a line over it in 109-110).
- ARP pressed twice quickly on the page no longer opens the arranger's editor (build 76's shortcut):
  each press flips the window.
- MIXER (both keymaps' press and release, stock 0x4007d468 / 0x4007d320): the press does nothing;
  the release opens or closes the MIXER window, unless MIDI was pressed while it was held (MIXER +
  MIDI). Holding MIXER no longer opens it, so the stock's hold-and-release closing is not used. Under
  the port: MIXER held 700 ms on LFO, no window; let go, the window; MIXER + MIDI, the view, no window.

Build 112: inside MIXER + MIDI's view the combo cycles the windows (TRKS -> PAGES -> PITCH, as ARP
there) instead of leaving. Another page key leaves it: sg_pkey first puts back what the combo changed
(the MIDI side's page, audio mode -- sg_mxout), then the key's own page follows there. Under the port:
from audio LFO, the combo three times showed TRKS, PAGES, PITCH; the combo twice and SRC: audio mode
(0x80000012 = 0), page 0 (PLAYBACK).

Build 113: an audio track pasted on a MIDI track, the stock's way. GRID RECORDING, FUNC + REC on an
audio track copies it (stock 0x4002993c, now through sg_acpy, which notes whether the track is
OCTA-303 and its Part's TUNE); FUNC + STOP on a MIDI track (stock 0x4002b62c, now sg_mpst) pastes it
converted when the clipboard holds an audio track (0x460d0ffa = 4): trig, trigless and swing masks,
each step's trig word, and the pitch -- OCTA-303 TUNE - 16 as the NOTE lock, ACC as VEL 101-127, a
slid trigless step a note with the note before it held over it; another machine's PTCH lock as NOTE +
PTCH - 64. The destination's Part values and setup are written back unchanged through the stock's
MIDI track writer (0x4002b470). The page's PASTE does the same when the stock's copy is the latest
(the page's COPY clears the stock's clipboard type). The COPY window's 303 line (build 107) is gone.
Under the port: OCTA-303 T1 with trigs on 1, 5, 9, a trigless on 6, TUNE locks 69 / 60 / 67 and ACC
110 on 5 -> MIDI T1 NOTE 53 / 44 (VEL 110, LEN 9) / 51 / 48 (Part TUNE 64), Part values unchanged
(D3); the page's PASTE the same.
PAGES, the full 4-page grid (arranger off): a pattern bar as the timeline's readout rows -- "A01" at
the left, the cursor's track's length at the right, a pattern to come's bars-left count centred and
its name after it ("7 A02"); the grid 8 px lower. The timeline's readout: offset and length as
"00:16" (was "OF0 LN16"); the next row's count centred on x 64 (was a 4-place field).

Build 114: the full 4-page grid (PAGES, arranger off) centred by UI_RULES.md at every zoom and
knob D spacing. Between two rows of steps with g blank pixels: the 4-step dots 1 px tall in an odd
gap, 2 px in an even one, the same blank above and below; at 32 a row the 16-step divider on the
same centre line, filling it a pixel clear of each row (the dots' rows in a 2-px gap); the bar
under the title sits the same margin above the first row (sg_frow, sg_fgc, sg_fgm). Without knob D
the stride narrows until every row fits under the bar (sg_fzfit: 113's fourth 16/R row was below the
screen). Under the port: 16/R and 32/R at knob D unset and 5-20, 34 screens, every gap measured
equal above and below.

Build 115: the arranger timeline centred like the 4-page grid (sg_fgap / sg_fgc for both): 4-step
dots 1 px in an odd gap, 2 px in an even one; the 16-step page marker on the same centre 2 px taller
(3 / 4 px), filling a gap of 3 or 4 so it still stands out. TRKS unchanged (its screen bytes match
114). Under the port: PAGES knob D 5-20 and the timeline 7-17 at 16/R and 32/R, 54 screens measured.

Build 116: AUDIO in MIXER + MIDI's view turns the MIDI key's LED off (id 0x46, each tick; the stock's
0x40033f70 puts it back when AUDIO goes off or the view ends); NO in AUDIO asks "CLEAR? YES" as on a
MIDI track. Track copy / paste carries LEN and SCALE both ways; a MIDI track pastes onto an audio track
(GRID RECORDING FUNC + STOP, 0x4005eb52 -> sg_apst; the page's PASTE in AUDIO too): masks, trig words,
LEN / SCALE, the audio track's locks and p-lock / slide masks cleared. FUNC + SCALE opens the stock's
SCALE window everywhere (the page included); in it SCALE (MKI keymap 0x400cb654) opens ALL TRACK SCALES
-- from a stock page in the view, NO / YES back there -- and UP / DOWN change rows (fields 0-2 / 3-4 by
the stock's RIGHT / LEFT), not values. ALL TRACK SCALES shows and sets the audio tracks in AUDIO
(sg_sto). Under the port: LED bits 70/71 clear in AUDIO; NO then YES cleared an audio trig, NO alone
kept it; audio LEN 32 / SCALE 2 -> MIDI; MIDI masks, LEN 24 / SCALE 3 -> audio, locks 0xff; DOWN in the
stock window moved to MASTER with the LEN unchanged; SCALE there opened the audio tracks' window and NO
returned to PLAYBACK in audio mode.

Build 119: the pitch view's dotted rows on the sharps (sg_psh is indexed by the note mod 12, C first;
it was laid out from A, so 109-118 dotted A, B... instead of A+, C+...). Under the port: dots on rows
13, 21, 33, 41, 53 = G+, F+, D+, C+, A+. AUDIO in the view also turns the trig keys' LEDs off (ids 0-31,
0x460ba98c and 0x460ba9ae cleared each tick): the Octatrack stays in MIDI mode there, so they showed
the MIDI track's trigs; leaving AUDIO puts them back (0x400486cc). Under the port, GRID RECORDING on a
MIDI track with trigs: LED bitmap 0x55551005 in MIDI, 0 in AUDIO, 0x55551005 again after MIDI.

Build 120: FUNC + BANK twice with the arranger on opens EDIT (the active arrangement): the MKI FUNC
sub-map's BANK record (0x400bf4a4, stock 0x40058a64, which opens the ARRANGER menu with its cursor on
EDIT, or PATTERN SETTINGS with the arranger off) is sg_kfbank; a second press while that menu is still
open (0x460d175c set) presses the key layer's YES for it. Arranger off: the stock's. Under the port:
FUNC held, BANK BANK -> the arrangement editor; arranger off -> PATTERN SETTINGS.

Build 121 -- a data-corruption fix. An audio track's trig words (micro timing / condition, a word a
step) are at +0x89a + 2 s, not +0x899 + 2 s as 113 and 116 assumed (measured: micro timing +2 on audio
step 1 writes 0x0080 at +0x89a; on a MIDI step at +0x830). The audio -> MIDI paste (113-120) copied
misaligned bytes into the MIDI track's trig words, and the MIDI -> audio paste (116-120) wrote them one
byte early into the audio record; a project saved after either could fail to load ("corrupt or saved
with a newer OS"). Under the port now: micro timing +2 carried both ways (0x0080 at +0x830 / +0x89a),
the byte at +0x899 untouched.

Build 122 -- leaving DISK MODE drops the unit off USB for 100 ms (`modules/usb`, `audio_disk_detach`), so a
Mac that still has the card mounted loses it at once instead of retrying writes against "no medium" and
writing again later. Cause found in Zach's macOS log of 1 Nov 2026 (build 120): DISK MODE 20:22-20:38 with a
WRITE(10) at 20:27, left with the volume mounted, then retries, EP0 timeouts and a reset; the open project's
bank01-10, project.work and markers.work came back cross-linked. Under the port (`--usb-host --frame`): two
DISK MODE exits, each RS cleared then set, then enumeration, 1,000 audio polls with 0 and 1 empty, MIDI out
accepted, no uninitialised queue head primed; `verify_usb_midi_replug` 21/21. Not on a unit yet; not modelled:
the host's view of the detach. The port cannot run the exit with an open stream (it paces device time on the
bench's isochronous polls).

Build 123 -- muted steps and the pitch view. A muted track's trig no longer draws an x: in every window
and zoom it flashes with the track's M (a trig in the blink's M phase, sg_bk bit 5; an empty step in the
other). The pitch view (Zach's picks from two rounds of mockups, 2 Nov 2026) spans two octaves (sg_pb, an
A, to 23 above; on entry the A below an octave under the cursor's note) in three layouts on knob F
("ROLL 16" / "ROLL 32" / "KEYS 16"): 16 steps x 9 named rows with a dot on each step, the window following
the cursor and a bar at the right; 32 steps x 24 notes beside a piano keyboard, the cursor's note, step and
velocity at the right; horizontal, 16 steps down the screen with a dotted line every 4 over a 24-key
keyboard. The title: the cursor's note and step ("PITCH T1 F+4 S01"), the pattern, four page boxes. YES
on a step already on the cursor's note leaves it (it cleared before). LEVEL moves the cursor across the
steps (it did already under the port). Measured under the port: the three layouts drawn; YES on the
step's own note changes no pixel; with sg_bk bit 5 clear a muted trig is its foot line only, set the
whole step. Not on a unit yet.

Build 124 -- pitch view fixes. LEVEL moves the cursor in every layout with the arranger on too: sg_tlon
counted the pitch view as the timeline (sg_view stays set under it), so LEVEL scrolled the hidden timeline
(reproduced under the port on 121 with 0x460d1aec set: S01 stayed; 124: S06). KEYS 16: UP / DOWN a step,
LEFT / RIGHT a semitone. SCALE (MKI) / PAGE (MKII) a page on in the pitch view (ROLL 32: two). ROLL 16: 11
rows of 5 px, naturals named (drawn glyph by glyph: SG_SMALL's cell clears a row above and below, which
the touching rows share), sharps a dash; 5 x 5 squares; a note in another octave an arrow on its letter's
row, pointing to its octave (no row for its letter: a mark at the edge).

Build 125 -- the mutes' flash slower. Playing, the M and a muted step flashed with bit 5 of the step count's
beat phase (2 steps on, 2 off: 0.25 s at 120 BPM). Now their own phase (sg_mbk): a half period of 2^k steps
from the tempo (0x8000181c, BPM x 24) -- 2 steps under 85 BPM, 4 to 170, 8 above -- so 0.35-0.7 s at any
tempo (0.5 s at 60, 120 and 240). Stopped, unchanged (the blink's bit 5). The pattern countdown's flash
keeps the beat. Under the port at 139 BPM: sg_mbk bit 5 = (step >> 2) & 1.

Build 126 -- one flash speed, and the pitch view's trig keys. sg_flash sets sg_bk bits 4 and 5 (every flash
in the step editor: the M, muted steps, the countdown, the playing-step and cursor-side marks) and sg_mbk
to one phase that flips every 2^k steps by tempo (125's ranges); stopped it keeps flipping at that rate
from DTCN0 (11.2896 MHz; a 16th is 4,064,256,000 / tempo24 counts). Pitch view, outside grid recording: the
trig keys are the page's 16 steps -- a press puts the cursor there, a release opens the step's window, YES
while one is held puts the cursor's note there (sg_kyes takes it before sg_keyok, which refuses with a
trig key down); their LEDs light the steps on the cursor's note (first colour) and the step playing
(second); in grid recording the stock's. The note playing lights its key (ROLL 32, KEYS 16) or its name
(ROLL 16). Under the port: trig 4 opens STEP 04's window; trig 6 + YES puts F+4 on step 6, no window,
LEDs 0x01040000 (steps 1 and 6).

Build 127 -- KEYS 16's step playing is a solid line in the gap under its row, not its row inverted (the
inversion turned its notes off and its blanks on as the bar passed, which read as notes changing).

Build 128 -- the pitch view's trig keys are a chromatic keyboard (126-127's step keys were a misread):
trig 1 = C of the cursor's note's octave .. trig 12 = B, 13-16 = C .. D+ above. A press plays the note on
the cursor's MIDI track (0x4009e9a8(track, note, the Part's VEL, 1), the stock CHROMATIC keys' call); FUNC
+ a trig puts that note on the cursor's step (the cursor moves to it) and plays it. The 16 keys' handlers
in the key table (0x46c7d8de + code * 24) are ours while the view is up (re-set each poll; the stock's
kept and put back); the note-off is the poll's, when the key is up (the release did not reach the table's
handler under the port). LEDs: the key of the cursor's step's note, and the step playing's in the second
colour; in grid recording everything is the stock's. Under the port: FUNC + trig 1 on step 3 put C4 there
(LED id 0); trig 5 held 300 ms sent 90 40 37, then 40 00.

Build 129 -- the pitch view's trig keys are a 16-note chromatic window (sg_pkb0) that knob E moves a
semitone at a time ("TRIGS C4" at the title; the range follows an octave when the window would leave it).
Unset, it starts on a C that puts all 16 inside the range's 24 notes. Their LEDs light the window's
naturals, as CHROMATIC does, and move with it (the cursor step's note and the playing note in the second
colour). The window is marked in every layout (ROLL 16 a line at x 5 on its rows, ROLL 32 one beside the
keyboard's edge, KEYS 16 a line over the keys) and a held trig's note is lit (ROLL 16 its name inverted
and its row a solid line, ROLL 32 its key inverted, KEYS 16 its key). ROLL 32 takes the whole screen:
no right column (the title has the note and step; the step's window the velocity), 3-px notes with a
2-px gap every 4 steps (a note before the same note on the next step 2 px, so they never touch), octave
numbers at the C's, a dot per step at the foot with the cursor's step a square and the step playing a
hollow one. YES in the pitch view on a step with a trig opens its step's window (SG_WST); on an empty
step it puts the cursor's note there. Knob D scrolls ROLL 16's 11 rows a semitone (past the range's ends
the range an octave). Under the port: knob E -1 moved the window to B3 (trig 1 sent 3b); ROLL 32 drew
with trig 5 held; YES on step 1 opened STEP 01's window; knob D +1 / -3 moved the rows.

Build 130 -- the step's window opened with YES in the pitch view comes with the panel's state (sg_mode,
sg_prm on NOTE), so LEVEL and the arrows edit it; and in the full view the window's values are made by
the panel's draw run under it (they stayed those of the window's opening: a LEVEL edit wrote the lock
but the window kept showing the old note). NO's "CLEAR? YES" in the pitch view: YES clears the step (the
pitch view's YES took it before). The trig keys play the note NOTE SETUP's TRAN makes it (the live
record 0x46c76dc0 + 0x44 t + 35, 64 none), as the sequencer plays a step's, and stop the note they sent
(sg_pko). ROLL 16's names are a keyboard (x 0-6, its edge x 7): a sharp a black key filling its row, the
E|F edge under F, in each C its octave 2 rows down; the cursor's note, the note playing and a held
trig's note light their key; the trig keys' 16 notes are marked at x 8. Under the port: YES on step 1
then LEVEL +3 showed A4 (the lock 0x42 -> 0x45); DOWN and LEVEL -20 showed VEL 80; TRAN poked to 52
(-12) made trig 1 send 24 (C2) for C3.

Build 131 -- ROLL 16's keyboard is 130's mockup A (a sharp a black key x 4-8, rows + 1 .. + 3, a tick
through it at x 9-10; the edge under C and F), its octave numbers left of it at x 0 on each C's row;
the grid moved 4 px right (x 14 + 7 c) and the scroll bar is 2 px at the screen's edge (x 126-127; 3
px at 124-126 before), the trig keys' mark at x 12. Encoder A pressed in ROLL 16: the cursor on the
lowest note of the page shown and that note on the bottom row (the range's A at or under it); encoder
C: the highest, on the top row (the key table's 0x38 / 0x3a entries ours while the pitch view is up, the
stock's in the other layouts). FUNC + knob E moves the trig keys' notes an octave. ROLL 32's title: the
page playing (stopped: the cursor's) of the pair blinks with the flashes' phase. Leaving the pitch view
or the page: our trig LEDs cleared and the stock's set again (0x400486cc), the key handlers put back
from the page poll too (the trig LEDs stayed lit on the stock's pages until a key). Under the port:
encoder A put B2 (step 7) on the bottom row, C put F+4 (step 1) on the top; FUNC + E +1 made trig 1 send
3c; ROLL 32 playing page 2 showed it filled, then hollow; SRC from the pitch view left LEDs 00000000.

Build 132 -- the pitch views' cursor is an outline a pixel round the cell (it was the cell inverted),
with a square inside on a note at the cursor (ROLL 16 3 x 3, its middle out when trigless; ROLL 32 1 x
2; KEYS 16 2 x 2; ROLL 16's dot on none; one drawer, .Lpcur). Knob E's range follows the trig keys'
16 notes an octave only once they are all in the next octave's range (their first at the range's 13th
or over, or their last under it), not as soon as one leaves. KEYS 16: a column of the 16 steps at the
left (a dot each at x 1, the step playing a 3 x 2 bar), the notes out of the range marked at the
right (above: the row's top, below: its foot; below was at the left); a lit key (a held trig's, the
note playing's) is the whole key (sg_pk2: a white key filled, a black key's body hollow and its foot as
wide as it). Encoder F's press steps the layout (ROLL 16 -> ROLL 32 -> KEYS 16 -> ROLL 16; the key
table's 0x3d ours while the pitch view is up); turning F does nothing there now. Under the port: the
outline with its square on step 1's F+4 and the dot on empty step 2; three presses of F back to ROLL 16;
knob E +12 from C3 moved the range from A2 to A3 only at A3 (the 13th).

Build 133 -- the pitch view's trig LEDs show the cursor step's note and the note playing (the second
colour) only while playing; stopped or paused, the 16 notes' naturals alone. The cursor's outline
leaves a cell without its note as drawn, so an other octave's arrow (or the dot) shows inside it.
KEYS 16: the steps' column is 2 x 2 squares (dots in 132); a note out of the range is an arrow on its
letter's key, up on the upper octave's for one above, down on the lower's for one below (the edge
marks of 123-132 gone); LEFT / RIGHT a semitone as before, FUNC + LEFT / RIGHT the range an octave,
FUNC + UP / DOWN a page. Knob A (its shared encoder table entry, 0x400c085c, now sg_kenc's) turns the
cursor a semitone in every pitch layout, with FUNC the range an octave; elsewhere the stock's.
Encoder A / C pressed in ROLL 32 (its 32 steps) and KEYS 16 too: the cursor on the lowest / highest
note, the range's lower octave on the lowest, its upper octave on the highest. Under the port: LEDs
stopped 11454411 (naturals only); the arrow inside the outline at step 5; KEYS 16 after FUNC + RIGHT
showed down arrows for the notes under A3; knob A -2 in ROLL 16 moved F+4 to E4, +1 in KEYS 16 and
FUNC + A +1 put pb at A3; ROLL 32 A put B2 (step 7) on row 2, C put F+4 (step 1) on row 21.

Build 134 -- the pitch views' range may start on any note (sg_pb 0-104; an A, A0-A7, until 133): the
keys' colours and the edges come from the note's class (sg_pkk) in ROLL 32 and KEYS 16 as ROLL 16's
did. KEYS 16: LEFT / RIGHT (and knob A) past the range's end scroll it a semitone, the cursor on the
edge key (an octave before; octaves are FUNC + LEFT / RIGHT's and FUNC + A's); the step rows' two dot
columns mark the trig keys' first note and its octave, moving with knob E (the range's two C's until
133); a note in another octave is a chevron over its row and the gap under it, < on the lower octave's
key, > on the upper's (up / down in 133). Under the port: five RIGHTs from F+4 put the cursor on the
top key and the range from A2 to C3; knob E +2 moved the dots to D3; FUNC + RIGHT drew < for the
notes under A3; ROLL 32 from a C3 range drew its keyboard and octave numbers from C3.

Build 135 -- KEYS 16's two dot columns (the trig keys' first note and its octave) sit in the gap left
of that key's notes, x 3 + 5 k, on the keyboard's key edges (through the notes at x 5 + 5 k in 134).
Under the port: a C3 root put the column on x 18, the keyboard's B|C edge.

Build 136 -- one set of navigation rules across the pitch views: the cursor past the range's end
moves the range a semitone (sg_pmv, all three layouts; ROLL 16 and ROLL 32 moved it an octave), the
octaves are FUNC's; knob D scrolls a semitone everywhere (ROLL 16 its rows, then the range; ROLL 32
and KEYS 16 the range, sg_prsc -- it reached the hidden PAGES spacing, "SPACE 15", before); FUNC +
LEFT / RIGHT in ROLL 16 a page of 16 (ROLL 32 32; it took the full view's zoom, 32 in ROLL 16);
encoder A / C in ROLL 32 and KEYS 16 put the note exactly on the range's first / last note. The trig
keys' first note's octaves: KEYS 16's columns at every octave on the range (sg_pm12), dotted lines on
the foot row of each one's row in ROLL 16 and ROLL 32. ROLL 32's other-octave notes: a 3-px arrow on
their letter's row, the upper octave's pointing up, the lower's down (a dash at the grid's edge until
135). Under the port: four UPs from F+4 in ROLL 32 moved the range A2 -> B2; knob D +2 there kept F+4;
FUNC + RIGHT in ROLL 16 went to step 17; ROLL 32 A put B2 (step 7) at the range's first note, C put
F+4 at its last.

Build 137 -- the step editor's views are saved with the project: ten PROJECT settings of STEP VIEW in
BRAIN's value table (store octabam.step-view: FULL, PAGES, PITCH, LAYOUT, RANGE, ROW, ROLL16 BASE,
TRIG ROOT, FULL ZOOM, ZOOM), so SAVE PROJECT writes them to the project's brain.work and LOAD PROJECT
reads them (as TRIG MODES' do); BRAIN > SETTINGS lists them under STEP VIEW. sg_bsync, each tick from
sg_poll: a table value not the one last seen (a load, a SETTINGS edit) puts the table into the views
(the pitch view on brings the full view with it); otherwise a view's change goes into the table.
Under the port: KEYS 16 with knob E +2 and an UP put FULL 1, PAGES 1, PITCH 1, LAYOUT 2, RANGE 45,
TRIG ROOT 49 in the table; LAYOUT 2, PITCH 1, FULL 1, RANGE 48 poked into it opened KEYS 16 from C3 on
the page. The save and load themselves are BRAIN's (verify_brain); not run end to end with these.

Build 138 -- PATTERN or BANK held in the pitch view: the trig keys are the stock's (sg_ptkh hands the
press and the release to the key's stock handler, sg_ptsv), so PATTERN + a trig selects the pattern
and BANK + a trig the bank as on any page; our trig LEDs are cleared while either is held, so the
stock's blinking pattern shows. A release with no note of ours goes to the stock's handler too. Under
the port: PATTERN + trig 4 from A03 went to A04 and sent no note; the next trig 4 played again; with
PATTERN held the LEDs were the stock's (0x460ba9ae 0, blink 9a000200).

Build 140 -- the stock ARP page back (Zach: MIXER + MIDI is the way in). sg_vis, the one test every
drawer, key and poll entry goes through, is true only while MIXER + MIDI's view is open (sg_own), so
on the ARP page by its key the stock draws and its knobs edit; FUNC + the ARP page key opens ARP SETUP
(sg_vtog falls through to the stock's dispatch). Every poke is gone (the ARP page and ARP SETUP drawn
and staged again, their value counts the stock's, NOTE SETUP's fourth slot unused again, the note path's
KEY read the stock's -- SCALES' KEY now works in this remix), and so is sv_snap (the engine reads TRAN,
LEG and MODE from the Part). The pitch view's TRAN is the ARP page's (live record + 12, sg_ptr).
Track names: sg_names, 12 bytes for each bank, Part and MIDI track, in `names.work` (header 'SGNM',
version 1, 6144, CRC-32; written at the bank writer and before SAVE PROJECT when a name changed,
names.strd at the project store, copied back at a project reload, emptied by Part Clear; an unreadable
file is left alone and not written this session, without a prompt: no STORE client id). A Part saved
up to 139: sv_mig, at the Part validator's NOTE SETUP check (0x400029b4, the site sv_valtran held),
once per MIDI track (d4 = 0; d5 the track, the Part at the validator's 100(sp), measured under the port)
moves a TRAN in NOTE SETUP + 3 to the ARP page's TRAN and clears it, and a track whose ARP SETUP + 13 or
LEG byte holds a name character (32-95; stock keeps 0 and 0/1) gets the ARP page's and ARP SETUP's
defaults (the descriptor's, 0x400d3f98 + 0x96) and CTRL1 SETUP + 18..19 zero, before the validator
checks them: the old names are dropped. Under the port (RIG): the stock ARP page by its key, ARP SETUP
by FUNC + it, SCALES' chooser by encoder F's push there, MIXER + MIDI's view, a name poked into
sg_names shown in its header.

