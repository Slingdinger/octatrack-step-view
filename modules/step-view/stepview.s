| STEP VIEW -- a step editor and pitch view for the 8 MIDI tracks, drawn over the MIDI ARP page in MIXER + MIDI's view
| (manifest.py and README.md say what and why).

        .text
        .global sg_page, sg_poll, sg_info, sg_ptn, sg_beat
        .global sg_pkey, sg_kscale, sg_kcopy, sg_kclear, sg_kpaste, sg_kfscale, sg_kenc, sg_kptrig, sg_kfarp
        .global sg_klr, sg_kud, sg_kyes, sg_kno, sg_lvl, sg_tmp, sg_trn, sg_kfl, sg_vtog, sg_kfud, sg_lvlh, sg_kundo

| ---- STEP VIEW: the MIDI ARP page is a step editor for the 8 MIDI tracks.
|      Grid (x 49-117, rows 1-63): a row of 16 steps per MIDI track (tops 10 + 7 m: the foot of rows 2-9 of nine 7-px rows,
|      the first left for a title), the page the cursor
|      is on, the track's number 1-8 at x 45 (its foot level with the steps'); step columns x 49 + 4 col (+2 per group of 4), 3 px wide. Full bar = trig, lower half =
|      trigless trig, a line at the foot = no trig, nothing = past that track's length; a line over a
|      step = the step that track is playing; a line under one, as wide, = the cursor. LEFT/RIGHT move the cursor
|      along the 64 steps (the page follows), UP/DOWN between the tracks.
|      The first row: the track's name from x 49 (twelve characters, sg_noff; "T<n>" until set). A note
|      trig's LEN runs right from the top of its bar (sg_tail).
|      Panel (x 10-42, the small font): the pattern and the page, the arrangement row and pattern, the
|      pattern to come and the steps till it (sg_queue), the step playing, STEP nn,
|      then the cursor's step: its four notes by name (NOTE, NOT2-4 as notes; - off) in 8 px slots with
|      their octaves a row below, "V 100", then "L 24 1/4" a line below: LEN and its note fraction (the
|      nearest of sg_lt) --
|      its lock where it has one, the Part's NOTE page value where not. YES on a step goes to the panel
|      (an empty step gets a note trig first, on NOTE): LEFT/RIGHT move along a line (name / notes /
|      VEL / LEN), UP/DOWN between them, the LEVEL knob changes the value -- a step value as a lock on
|      that step (the stock p-lock store's MIDI branch, 0x4004f7ba, without its held-trig loop), LEN
|      through its fractions only, a name character through 32-95 -- and NO goes back to the grid. Arrows, YES and
|      NO with FUNC, a trig or a track key held, and every key on other pages reach the stock as before.
|      LEVEL in the grid moves the cursor's step (1-64); FUNC + LEVEL and FUNC + LEFT/RIGHT a page.
|      The ARP page's own drawers -- the info box (0x4004c0a8, also a soft timer), the pattern field
|      (0x400418e0), the beat boxes (0x400373dc, every step) -- return; the rest of the stock's drawing
|      there (the page draw, tempo, the transport icons) is drawn over: the poll redraws when its inputs
|      change or a checksum of the plane it owns (x 9-118, rows 0-63: the bottom bar's title and scene
|      indicator are gone from this page) no longer matches.
|      The page plane at 0x400bf10a takes (x, y from the bottom, inclusive); its buffer (the pointer at
|      +12) is 8 bytes per screen column x, byte y/8 of the bottom-up y, bit 7 - y%8. UI task only. A DRAM
|      unit: under the port octabam's loader depacks the runtime (0x400e0aca at 6.7 M cycles) before the
|      power-up load (the Part validator, 29.9 M) and the first main view draw (57.8 M).
        .set    SG_FB, 0x400bf10a
        .set    SG_FILL, 0x40012254             | (fb, x0, y0, x1, y1, colour 0 clear / 1 set / -1 invert)
        .set    SG_RECT, 0x40012170             | the same, outline
        .set    SG_TEXT, 0x40013904             | (font, fb, x, y, align, invert, template, fmt, ...)
        .set    SG_SPRINTF, 0x40013a08          | (buf, fmt, ...)
        .set    SG_BIG, 0x400ba862              | the pattern field's font, 6 px a character
        .set    SG_SMALL, 0x400ba876            | the info box's, 4 px
        .set    SG_FNOTE, 0x4003b9c4            | NOTE's formatter (buf, value)
        .set    SG_FVEL, 0x4003bb40             | VEL's
        .set    SG_FLEN, 0x4003bb28             | LEN's
        .set    SG_HELD, 0x46c7d8ee             | + code * 24: the key is down (0x4003171c)
        .set    SG_FLD, 6                       | its track number, x 6-8 (build 100; 26 after "A01:" in 99)
        .set    SG_FTX, 16                      | the full 8-track window's first column: x 16-111 between two
                                                | 16-px columns (build 100; x 32 to the edge in 99)
        .set    SG_GX, 64                       | the grid's first column (49 until 80, 51 in 81 before the panel widened, 55 in 81)
        .set    SG_NX, 58                       | the name's first column (build 68: after TRK / PG at x 45; 59 in 68-69)

| Detour 0x4004e936 (jsr, 8 bytes: `moveq #1,%d3` ; `movel %d3,0x46c7c72c`), the main view draw
| (0x4004d948(page)) after the page is drawn; a6 is its frame, 8(a6) the page drawn.
sg_page:
        move.l  8(%a6),%d0
        bsr     sg_vis
        bne.s   2f
        moveq   #1,%d0
        tst.l   sg_on                   | the page just opened: the arrangement row read afresh (sg_platch)
        bne.s   3f
        move.l  %d0,sg_pnew
3:      move.l  %d0,sg_on
        moveq   #1,%d1                  | always draw: the page under it was just drawn
        bsr     sg_run
        bra.s   1f
2:      tst.l   sg_on                   | the first page drawn after the ARP page: the stock's left side back
        beq.s   1f
        bsr     sg_rest
1:      moveq   #1,%d3                  | displaced
        move.l  %d3,0x46c7c72c          | displaced
        rts

| Leaving the ARP page (from sg_page, a6 = the main view draw's frame): the stock draws its left side
| (tempo, transport, beat boxes, the pattern field) only when they change, and the page draw leaves
| the grid's pixels in its gaps, so the panel and the grid would stay. Clear x 9-118 rows 1-63, run
| the frame's line at x 42 (the main screen frame, 0x4004b284, draws it once), the main view draw again
| for the page (the page, the LEV column, the info box, the bottom bar; sg_on is clear, so its sg_page
| does nothing), then each left-side drawer once.
sg_rest:
        lea     -8(%sp),%sp
        movem.l %d2-%d3,(%sp)
        clr.l   sg_on
        clr.l   sg_hk
        clr.l   sg_kb
        clr.l   sg_cpat                 | the timeline's cursor back to the current pattern
        clr.l   sg_tfree
        clr.l   sg_tlast
        clr.l   sg_win                  | our window closed (build 82)
        moveq   #-1,%d0                 | the undo history starts again on the next visit
        move.l  %d0,sg_ukey
        move.l  %d0,sg_sela
        moveq   #0,%d0
        moveq   #1,%d1
        moveq   #127,%d2
        moveq   #63,%d3
        bsr     sg_clr
        moveq   #42,%d0                 | the frame's line right of the tempo, rows 0-30 (0x4004b31c's)
        moveq   #0,%d1
        moveq   #42,%d2
        moveq   #30,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
        moveq   #8,%d0                  | the frame's left edge, rows 0-62 (build 142: cleared above and
        moveq   #0,%d1                  | never drawn again, 0x4004b284 draws the frame once), and row 0
        moveq   #8,%d2                  | outside x 8-119, where the full view's top line runs (x 0-127)
        moveq   #62,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
        moveq   #0,%d0
        moveq   #0,%d1
        moveq   #7,%d2
        moveq   #0,%d3
        bsr     sg_clr
        moveq   #120,%d0
        moveq   #0,%d1
        moveq   #127,%d2
        moveq   #0,%d3
        bsr     sg_clr
        move.l  8(%a6),-(%sp)
        jsr     0x4004d948              | the main view draw (page)
        addq.l  #4,%sp
        jsr     0x4004581c              | the trig mode's area (CHROMATIC, QUICK MUTE: the mode change's own
        jsr     0x4003ced4              | call, 0x40051f40) and the arrangement box (build 55)
        jsr     0x4004b08c              | the tempo (or EXT)
        jsr     0x4003722c              | the transport icon, the beat boxes' frames
        pea     -1.w                    | playing (0x4009b290(-1) = 1, as 0x4003722c reads it): the beat
        jsr     0x4009b290              | boxes' fill
        addq.l  #4,%sp
        subq.l  #1,%d0
        bne.s   1f
        jsr     0x400373dc
1:
        jsr     0x400418e0              | the pattern field
        moveq   #-1,%d0                 | the track strips either side (build 90; blank on the stock's pages
        move.l  %d0,0x400c0c50          | after a visit since 82): their two drawers, which the periodic
        move.l  %d0,0x400c0c94          | handler runs (0x40052200: 0x4003fed8 the tracks' entries,
        lea     0x400c0c54,%a0          | 0x4004bd48 their boxes), draw only what changed since their
        lea     0x400c0cb8,%a1          | caches; the caches made stale, the next tick draws all 8: the
        moveq   #8,%d1                  | MIDI mode's copy (+0x80000012 last seen), each track's value
1:      move.l  %d0,(%a0)+              | and its selected flag (0 / 1: 2 never matches)
        move.l  %d0,(%a1)+
        subq.l  #1,%d1
        bne.s   1b
        lea     0x400c0c74,%a0
        lea     0x400c0c98,%a1
        moveq   #2,%d0
        moveq   #8,%d1
1:      move.l  %d0,(%a0)+
        move.l  %d0,(%a1)+
        subq.l  #1,%d1
        bne.s   1b
        movem.l (%sp),%d2-%d3
        addq.l  #8,%sp
        rts

| UI message 5 (the periodic one, 0x40061e8e, every 16.7 ms under the port) calls this instead of
| 0x40052200. On the page it also repeats a held arrow: SG_RD ticks after the press, then one move
| every SG_RR ticks (the stock repeats every 500 ms) until the key is up, or FUNC, a trig or a track
| key is down.
        .set    SG_RD, 18               | 300 ms
        .set    SG_RR, 3                | 50 ms
        .set    SG_IDLE, 90             | 1.5 s hands off: the window follows the playing page
        .set    SG_NN, 12               | the name's characters (build 60: 5 -> 7, ARP SETUP + 13..17 and
                                        | CTRL1 SETUP's unused + 18..19; build 64: 12, the ARP page's LEG MODE
                                        | SPD RNGE NLEN, + 13..17 of its page-1 record; sg_noff)
        .set    SG_PR, 12               | the panel's ROW value, arranging only (build 69)
        .set    SG_PM, 13               | M (line 1, left): the row's mutes window, arranging (build 81)
        .set    SG_PA, 14               | the pattern playing (line 1), arranging (build 78)
        .set    SG_PB, 15               | the pattern to come (line 2), arranging (build 78)
        .set    SG_PV, 16               | SAVE (line 3), the arrangement unsaved (build 78)
        .set    SG_PS, 17               | the panel's STEP value (build 63; 13 until 77, 16 in 78-80)
        .set    SG_PN, 18               | the panel's first note value: NOTE NOT2-4 18-21, VEL 22, LEN 23
        .set    SG_HOLD, 24             | 400 ms: a trig key held this long opens the panel (sg_thold)
        .set    SG_UN, 10               | undo: states kept (nine steps back)
        .set    SG_PSZ, 0x8ed8          | a pattern (STEP_LOCKS.md section 1)
        .set    SG_WST, 4               | sg_win: the step's window (build 90; SG_WSC 3 the scale window)
        .set    SG_SY0, 50              | its lines' bottom y (from the bottom): STEP, the notes' labels,
        .set    SG_SY1, 41              | the notes, VEL / LEN's labels, their values
        .set    SG_SY2, 32
        .set    SG_SY3, 22
        .set    SG_SY4, 13
        .set    SG_UQ, 30               | ticks without a change that close an edit (500 ms)
        .set    SG_UDIV, 6              | the pattern is summed every 6 ticks
        .weak   tm_poll                 | TRIG MODES (build 102), when the remix carries it
sg_poll:
        jsr     0x40052200
        move.l  #tm_poll,%d0            | (its per-track trig mode after a load)
        beq.s   0f
        jsr     tm_poll
0:      bsr     sg_bsync                | the views' settings and BRAIN's table (build 137)
        bsr     sg_clock
        bsr     sg_here
        beq     0f
        bsr     sg_ptoff                | (the pitch view's trig keys the stock's again, build 131)
        bsr     sg_fkout                | (encoder F's press the stock's again, build 143)
        bsr     sg_ekout                | (A-E's presses the stock's again)
        tst.l   sg_own                  | the page left another way (a page key, MIDI): MIXER + MIDI's
        beq     9f                      | view is over, nothing put back (build 108) -- once the page
        tst.l   sg_ownw                 | the combo asked for has come (the page key's switch lands a
        ble.s   1f                      | tick or more later: up to 60 ticks' grace)
        subq.l  #1,sg_ownw
        bra     9f
1:      clr.l   sg_own
        bsr     sg_aoff
        clr.l   sg_pv
        move.l  sg_ofull,%d0
        move.l  %d0,sg_full
        bra     9f
0:      clr.l   sg_ownw
        bsr     sg_free                 | a menu or popup open (build 75): the page keeps still and the
        beq.s   0f                      | screen-changed flag is set every tick, as the stock's tempo
        moveq   #1,%d0                  | drawer does on the other pages (it is off on this one), so the
        move.l  %d0,0x46c7c72c          | window's own redraws reach the panel
        moveq   #0,%d1                  | -- and the page redrawn if the stock drew on it under the window
        bsr     sg_run                  | (build 145: RELOAD's popup left the ARP page's bottom bar, its
        bra     9f                      | title and scenes, under it; sg_run's plane checksum sees that)
0:      bsr     sg_vwin                 | the panel view's window: the arranger's (build 141; AUDIO: the
                                        | MIDI key's and trig keys' LEDs the stock's, audio mode's, build 149)
        bsr     sg_drest                | the MIDI activity dots: the page's pixels back (build 71)
        addq.l  #1,sg_bk                | the cursor's blink
        bsr     sg_flash                | its bits 4 and 5 from the tempo (build 126)
        tst.l   sg_nconf                | NO's question: gone with the cursor moved (build 91)
        beq.s   1f
        bsr     sg_nask
1:      tst.l   sg_umt                  | the undo message's time
        ble.s   1f
        subq.l  #1,sg_umt
1:
        addq.l  #1,sg_idle              | hands off: the window follows the playing page (sg_run)
        tst.l   SG_HELD+0x2d*24         | FUNC let go: the run marked goes (build 82)
        bne.s   1f
        moveq   #-1,%d0
        move.l  %d0,sg_sela
1:
        bsr     sg_tkey
        bsr     sg_kpage
        bsr     sg_thold
        bsr     sg_ptrg                 | the pitch view's trig keys and their LEDs (build 126)
        bsr     sg_fkin                 | encoder F's press ours (build 143)
        bsr     sg_ekin                 | and A-E's: the hidden page's reset
        tst.l   sg_tnum                 | the track number: only in TRKS, on step 1 (build 143)
        beq.s   .Lpl_t
        bsr     sg_tnv
        bne.s   .Lpl_c
        tst.l   sg_step
        beq.s   .Lpl_t
.Lpl_c: clr.l   sg_tnum
.Lpl_t:
        bsr     sg_fkb
        bsr     sg_utick
        bsr     sg_stopk
        tst.l   sg_hk
        beq.s   2f
        bsr     sg_keyok
        bne.s   1f
        move.l  sg_hk,%d0
        moveq   #24,%d1
        muls.l  %d0,%d1
        lea     SG_HELD,%a0
        tst.l   (0,%a0,%d1.l)
        beq.s   1f                      | up (its release went elsewhere)
        subq.l  #1,sg_ht
        bgt.s   2f
        moveq   #SG_RR,%d0
        move.l  %d0,sg_ht
        moveq   #1,%d0
        move.l  %d0,sg_rep              | a repeat: it stops at an edge
        move.l  sg_hk,%d0
        bra     sg_mv                   | moves and draws
1:      clr.l   sg_hk
2:      move.l  sg_vwch,%d1             | draw if it changed (or the panel view's window did, sg_vwin)
        clr.l   sg_vwch
        bra     sg_run
9:      rts

| The time since play started (build 82): every tick, on any page, DTCN3 (DMA timer 3, free-running at
| the 132 MHz bus clock; docs/firmware/PANEL.md) read and its advance added while the sequencer plays
| (0x800065b8); 00:00 when it starts, held when it stops. The unsigned difference of two reads is
| right across the counter's wrap (32.5 s) as long as ticks come oftener than that. Uses d0 d1.
        .set    SG_HZ, 132000000
sg_clock:
        move.l  0xfc07c00c,%d0
        move.l  %d0,%d1
        sub.l   sg_ckl,%d1              | d1: counts since the last tick
        move.l  %d0,sg_ckl
        tst.l   0x800065b8
        beq.s   8f
        tst.l   sg_ckp
        bne.s   1f
        moveq   #1,%d0                  | just started: 00:00
        move.l  %d0,sg_ckp
        clr.l   sg_cks
        clr.l   sg_ckf
        rts
1:      add.l   sg_ckf,%d1
2:      cmpi.l  #SG_HZ,%d1
        bcs.s   3f
        subi.l  #SG_HZ,%d1
        addq.l  #1,sg_cks
        bra.s   2b
3:      move.l  %d1,sg_ckf
        rts
8:      clr.l   sg_ckp
        rts

| A track key just pressed (T1-T8, 0x10-0x17; the stock selects the track as ever): the cursor to that
| track's row, its step kept. The poll's draw follows (sg_row is in its signature). Uses d0 d1 a0.
sg_tkey:
        moveq   #0,%d0                  | d0: the track keys down, T1 = bit 0
        moveq   #7,%d1
        lea     SG_HELD+0x17*24,%a0
1:      add.l   %d0,%d0
        tst.l   (%a0)
        beq.s   2f
        addq.l  #1,%d0
2:      lea     -24(%a0),%a0
        subq.l  #1,%d1
        bpl.s   1b
        move.l  sg_tk,%d1
        move.l  %d0,sg_tk
        not.l   %d1
        and.l   %d0,%d1                 | the ones down now and not a tick ago
        beq.s   9f
        moveq   #0,%d0
3:      btst    %d0,%d1
        bne.s   4f
        addq.l  #1,%d0
        bra.s   3b
4:      move.l  %d0,sg_row
        clr.l   sg_bk                   | the cursor shown at once
        clr.l   sg_idle
9:      rts

| d0 = MIDI track 0-7: make it the stock's active track (0x100b14cc), as a tap on its track key does
| -- the key handler's press (0x40083ab4(code, 1): the selection, 0x40083c2e) and release
| (0x40083e40(code, 0), 0x4007c264), without its double-press test (0x40040250). Uses d0 d1 a0 a1.
sg_tsel:
        moveq   #0,%d1
        move.b  0x100b14cc,%d1
        cmp.l   %d1,%d0
        beq.s   9f
        moveq   #0x10,%d1
        add.l   %d0,%d1
        move.l  %d1,-(%sp)              | kept for the release
        pea     1.w
        move.l  %d1,-(%sp)
        jsr     0x40083ab4
        addq.l  #8,%sp
        move.l  (%sp),%d1
        clr.l   -(%sp)
        move.l  %d1,-(%sp)
        jsr     0x40083e40
        addq.l  #8,%sp
        addq.l  #4,%sp
        jsr     0x4007c264
9:      rts

| Z clear when a trig key (codes 0x00-0x0f) is down. Uses d1 a0.
sg_tkd:
        lea     SG_HELD,%a0
        moveq   #16,%d1
1:      tst.l   (%a0)
        bne.s   9f
        lea     24(%a0),%a0
        subq.l  #1,%d1
        bne.s   1b
9:      rts

| The trig keys' page (0x460d1e04: the page PAGE steps in grid recording, the one a trig key edits;
| the stock never moves it while playing -- measured, 64-step tracks at step 38 left it at 0). PAGE
| moved it: the cursor goes to that page (its column kept). A trig key down counts as a touch. Uses d0
| d1 a0.
sg_kpage:
        lea     SG_HELD,%a0             | a trig key down: hands on
        moveq   #16,%d1
1:      tst.l   (%a0)
        bne.s   2f
        lea     24(%a0),%a0
        subq.l  #1,%d1
        bne.s   1b
        bra.s   3f
2:      clr.l   sg_idle
3:      move.l  0x460d1e04,%d0
        cmp.l   sg_kp,%d0
        beq.s   9f
        move.l  %d0,sg_kp
        moveq   #3,%d1
        and.l   %d1,%d0
        move.l  %d0,sg_pw               | the page the window and the keys agree on
        move.l  %d0,%d1
        bsr     sg_tlon                 | the timeline: the cursor stays (build 71)
        bne.s   9f
        move.l  %d1,%d0
        lsl.l   #4,%d0
        moveq   #15,%d1
        and.l   sg_step,%d1
        or.l    %d1,%d0
        move.l  %d0,sg_step
        clr.l   sg_idle
        clr.l   sg_bk
9:      rts

| The name's keyboard (build 60), as the stock's naming screens: FUNC pressed with a name character
| picked in the panel shows every character the name takes (32-95, eight rows of eight) over the grid,
| the picked one inverted; FUNC + the arrows (sg_kfl, sg_kfud) or FUNC + LEVEL (sg_lvl) move through
| them; FUNC's release writes the one chosen there and the panel moves to the next character (a release
| without a move changes nothing). Uses d0 d1 a0 a1.
sg_fkb:
        tst.l   SG_HELD+0x2d*24
        beq     5f
        tst.l   sg_kbf                  | held: a press only once
        bne     9f
        moveq   #1,%d0
        move.l  %d0,sg_kbf
        tst.l   sg_mode
        beq     9f
        moveq   #SG_NN-1,%d0
        cmp.l   sg_prm,%d0
        blt     9f                      | not a name character
        bsr     sg_free
        bne     9f
        bsr     sg_nget
        lea     sg_nm,%a0
        move.l  sg_prm,%d1
        moveq   #0,%d0
        move.b  (0,%a0,%d1.l),%d0
        moveq   #32,%d1
        sub.l   %d1,%d0
        moveq   #63,%d1
        and.l   %d1,%d0
        move.l  %d0,sg_ksel
        move.l  %d0,sg_ksel0
        moveq   #1,%d0
        move.l  %d0,sg_kb
        bra     sg_now
5:      tst.l   sg_kbf
        beq     9f
        clr.l   sg_kbf
        tst.l   sg_kb
        beq     9f
        clr.l   sg_kb
        move.l  sg_ksel,%d0
        cmp.l   sg_ksel0,%d0
        beq     sg_now                  | no move: the grid back, nothing written
        bsr     sg_nget
        lea     sg_nm,%a0
        move.l  sg_prm,%d0
        moveq   #0,%d1
        move.b  (0,%a0,%d0.l),%d1
        neg.l   %d1
        add.l   sg_ksel,%d1
        moveq   #32,%d0
        add.l   %d0,%d1                 | d1: the chosen one - the one there
        move.l  sg_prm,%d0
        bsr     sg_nset
        moveq   #SG_NN-1,%d0
        cmp.l   sg_prm,%d0
        ble     sg_now
        addq.l  #1,sg_prm
        bra     sg_now
9:      rts

| UNDO (build 60): the current pattern's states while the page is open, as a ring of SG_UN copies
| (sg_uh, .bss). Every SG_UDIV ticks the pattern is summed (s1 += long, s2 += s1); a change opens an
| edit, SG_UQ ticks without one close it and its result becomes the newest state (any states past the
| current one, undone, go). Another pattern or bank, a window over the page or leaving the page starts
| the history again from what is there. FUNC + NO (sg_kundo) goes a state back, FUNC + YES forward,
| through the stock pattern paste's writer (0x4002b9b0: the bank's copy, the CS1 copy, the tracks'
| refresh, the engine's). Uses d0 d1 a0 a1.
sg_utick:
        bsr     sg_free
        beq.s   1f
        moveq   #-1,%d0                 | a window: start again after it
        move.l  %d0,sg_ukey
        rts
1:      bsr     sg_upat                 | a0: the pattern, d0: its key
        cmp.l   sg_ukey,%d0
        beq.s   2f
        move.l  %d0,sg_ukey
        bra     sg_ureset
2:      subq.l  #1,sg_udv
        bgt.s   9f
        moveq   #SG_UDIV,%d0
        move.l  %d0,sg_udv
        bsr     sg_usum                 | d0 s1, d1 s2
        cmp.l   sg_us1,%d0
        bne.s   3f
        cmp.l   sg_us2,%d1
        bne.s   3f
        tst.l   sg_uq                   | unchanged: an open edit closes after SG_UQ
        beq.s   9f
        addq.l  #SG_UDIV,sg_uq
        moveq   #SG_UQ,%d0
        cmp.l   sg_uq,%d0
        bgt.s   9f
        bra     sg_ucommit
3:      move.l  %d0,sg_us1              | changed: the edit open
        move.l  %d1,sg_us2
        moveq   #1,%d0
        move.l  %d0,sg_uq
9:      rts

| a0 = the current pattern in the bank, d0 = a key for it (the bank pointer + the pattern). Uses d0 d1 a0.
sg_upat:
        movea.l 0x46c82456,%a0
        moveq   #0,%d0
        move.b  0x100b14d0,%d0
        move.l  #SG_PSZ,%d1
        muls.l  %d1,%d0
        adda.l  %d0,%a0
        move.l  %a0,%d0
        rts

| d0 s1, d1 s2 of the current pattern. Uses d0 d1 a0 a1.
sg_usum:
        move.l  %d2,-(%sp)
        bsr     sg_upat
        move.l  #SG_PSZ/4,%d2
        moveq   #0,%d0
        moveq   #0,%d1
1:      add.l   (%a0)+,%d0
        add.l   %d0,%d1
        subq.l  #1,%d2
        bne.s   1b
        move.l  (%sp)+,%d2
        rts

| a0 = state d0 (0 = the oldest) in the ring. Uses d0 d1 a0.
sg_uslot:
        add.l   sg_uold,%d0
        moveq   #SG_UN,%d1
        cmp.l   %d1,%d0
        blt.s   1f
        sub.l   %d1,%d0
1:      move.l  #SG_PSZ,%d1
        muls.l  %d1,%d0
        lea     sg_uh,%a0
        adda.l  %d0,%a0
        rts

| The current pattern into state d0. Uses d0 d1 a0 a1.
sg_ucopy:
        bsr     sg_uslot
        move.l  %a0,-(%sp)
        bsr     sg_upat
        movea.l (%sp)+,%a1
        pea     SG_PSZ
        move.l  %a0,-(%sp)              | src: the pattern
        move.l  %a1,-(%sp)              | dst: the state
        jsr     0x40020898
        lea     12(%sp),%sp
        rts

| The history from the pattern as it is: one state. Uses d0 d1 a0 a1.
sg_ureset:
        clr.l   sg_uold
        clr.l   sg_upos
        moveq   #1,%d0
        move.l  %d0,sg_ucnt
        clr.l   sg_uq
        moveq   #SG_UDIV,%d0
        move.l  %d0,sg_udv
        moveq   #0,%d0
        bsr     sg_ucopy
        bsr     sg_usum
        move.l  %d0,sg_us1
        move.l  %d1,sg_us2
        rts

| The pattern as it is becomes the newest state, after the current one. Uses d0 d1 a0 a1.
sg_ucommit:
        clr.l   sg_uq
        move.l  sg_upos,%d0             | undone states past the current one go
        addq.l  #1,%d0
        move.l  %d0,sg_ucnt
        moveq   #SG_UN,%d1
        cmp.l   %d1,%d0
        blt.s   1f
        move.l  sg_uold,%d0             | full: the oldest goes
        addq.l  #1,%d0
        cmp.l   %d1,%d0
        blt.s   2f
        moveq   #0,%d0
2:      move.l  %d0,sg_uold
        subq.l  #1,sg_ucnt
        subq.l  #1,sg_upos
1:      addq.l  #1,sg_upos
        addq.l  #1,sg_ucnt
        move.l  sg_upos,%d0
        bra     sg_ucopy

| FUNC + NO / FUNC + YES (FUNC's sub-map records, stock 0x4005e1fc / 0x4005e3d8): on the page, a state
| back / forward, on a press; with the name's keyboard up nothing. A short "UNDO 3/9" in the first row.
sg_kundo:
        bsr     sg_keyfn
        bne     8f
        moveq   #1,%d0
        cmp.l   8(%sp),%d0
        bne     7f
        tst.l   sg_kb
        bne     7f
        lea     -8(%sp),%sp
        movem.l %d2/%a2,(%sp)
        bsr     sg_upat
        cmp.l   sg_ukey,%d0
        beq     1f
        move.l  %d0,sg_ukey             | no history for this pattern yet
        bsr     sg_ureset
1:      bsr     sg_usum                 | an edit still open: it is a state first
        cmp.l   sg_us1,%d0
        bne     2f
        cmp.l   sg_us2,%d1
        bne     2f
        tst.l   sg_uq
        beq     3f
2:      move.l  %d0,sg_us1
        move.l  %d1,sg_us2
        bsr     sg_ucommit
3:      moveq   #0x32,%d0
        cmp.l   8+4(%sp),%d0
        bne     4f
        tst.l   sg_upos                 | NO: back
        beq     5f
        subq.l  #1,sg_upos
        lea     sg_fun,%a2
        bra     6f
4:      move.l  sg_upos,%d0             | YES: forward
        addq.l  #1,%d0
        cmp.l   sg_ucnt,%d0
        bge     5f
        move.l  %d0,sg_upos
        lea     sg_fre,%a2
6:      move.l  sg_upos,%d0             | write the state back
        bsr     sg_uslot
        moveq   #0,%d0
        move.b  0x100b14d0,%d0
        move.l  %d0,-(%sp)
        move.l  %a0,-(%sp)
        jsr     0x4002b9b0
        addq.l  #8,%sp
        bsr     sg_dirty
        bsr     sg_usum
        move.l  %d0,sg_us1
        move.l  %d1,sg_us2
        clr.l   sg_uq
        jsr     0x400486cc              | the page and trig LEDs, their caches (as sg_pgset)
        moveq   #0,%d0
        move.w  %d0,0x460d1a9e
        move.w  %d0,0x460d1aa0
        move.w  %d0,0x460d1aa2
        move.w  %d0,0x460d1aa4
        move.w  %d0,0x460d1aa6
        move.w  %d0,0x460d10dc
        jsr     0x400418e0
        move.l  sg_ucnt,%d0             | "UNDO 3/9": the state / the newest
        subq.l  #1,%d0
        move.l  %d0,-(%sp)
        move.l  sg_upos,-(%sp)
        move.l  %a2,-(%sp)
        pea     sg_umsg
        jsr     SG_SPRINTF
        lea     16(%sp),%sp
        bra     0f
5:      lea     sg_fnu,%a0              | nothing that way
        moveq   #0x32,%d0
        cmp.l   8+4(%sp),%d0
        beq.s   9f
        lea     sg_fnr,%a0
9:      lea     sg_umsg,%a1
1:      move.b  (%a0)+,(%a1)+
        bne.s   1b
0:      moveq   #90,%d0                 | shown 1.5 s
        move.l  %d0,sg_umt
        movem.l (%sp),%d2/%a2
        addq.l  #8,%sp
        bra     sg_now
7:      rts
8:      moveq   #0x32,%d0
        cmp.l   4(%sp),%d0
        bne.s   9f
        jmp     0x4005e1fc
9:      jmp     0x4005e3d8

| A trig key pressed in grid recording (0x460d1736): the cursor to its step (the trig keys' page,
| 0x460d1e04) on the active track (0x100b14cc) at once, so the panel shows that step's values while it
| is held; held SG_HOLD ticks, the panel open with NOTE picked, once per hold.
| The stock's own hold test is shorter (under the port a release after 250 ms removed an existing trig,
| one after 350 ms kept it), so a hold long enough to open the panel never deletes the trig on its
| release. LEVEL then changes the note while the key is still down (sg_lvl takes LEVEL in the panel
| whatever is held); the panel stays open after the release. Uses d0 d1 a0.
sg_thold:
        tst.l   0x460d1736
        beq.s   8f
        lea     SG_HELD,%a0             | d0: the first trig key down
        moveq   #0,%d0
1:      tst.l   (%a0)
        bne.s   2f
        lea     24(%a0),%a0
        addq.l  #1,%d0
        moveq   #16,%d1
        cmp.l   %d1,%d0
        blt.s   1b
8:      moveq   #-1,%d0                 | none
        move.l  %d0,sg_thk
        rts
2:      cmp.l   sg_thk,%d0
        beq.s   3f
        move.l  %d0,sg_thk              | another key: count again, and the cursor to its step at once
        clr.l   sg_th                   | (build 58): the panel shows the held step's values from the
        move.l  0x460d1e04,%d1          | press on
        moveq   #3,%d0
        and.l   %d0,%d1
        lsl.l   #4,%d1
        add.l   sg_thk,%d1
        move.l  %d1,sg_step
        moveq   #0,%d1
        move.b  0x100b14cc,%d1
        moveq   #7,%d0
        and.l   %d0,%d1
        move.l  %d1,sg_row
        moveq   #1,%d1                  | the timeline: the held step is the current pattern's, until
        move.l  %d1,sg_tfree            | the cursor moves (build 71)
        clr.l   sg_cpat
        clr.l   sg_idle
        clr.l   sg_bk
3:      tst.l   sg_aud                  | AUDIO: no panel -- the held trig is the stock's (its locks by the
        bne.s   9f                      | knobs, audio mode's; build 149)
        move.l  sg_th,%d1
        bmi.s   9f                      | opened this hold already
        addq.l  #1,%d1
        move.l  %d1,sg_th
        moveq   #SG_HOLD,%d1
        cmp.l   sg_th,%d1
        bgt.s   9f
        moveq   #-1,%d1
        move.l  %d1,sg_th
        moveq   #1,%d0
        move.l  %d0,sg_mode
        moveq   #SG_PN,%d0              | NOTE
        move.l  %d0,sg_prm
        clr.l   sg_idle
        clr.l   sg_bk
9:      rts

| The cursor's page to the trig keys, after the editor moved it to another page: 0x460d1e04, then
| what the stock's next page (0x40048844) does after its +1 -- the clamp to the active track's pages
| and the page and trig LEDs (0x400486cc), the trig LEDs' caches, the pattern field's tail (sg_ptn,
| the LED refresh), an open step window's redraw (0x4002f2f8). A page the active track does not have
| is clamped there; the window keeps the cursor's. Uses d0 d1 a0 a1.
sg_pgset:
        tst.l   sg_cpat                 | the cursor in another pattern (the timeline): the keys stay
        bne.s   9f
        move.l  sg_step,%d0
        lsr.l   #4,%d0
        cmp.l   sg_pw,%d0
        beq.s   9f
        move.l  %d0,sg_pw
        move.l  %d0,0x460d1e04
        jsr     0x400486cc
        moveq   #0,%d0
        move.w  %d0,0x460d1a9e
        move.w  %d0,0x460d1aa0
        move.w  %d0,0x460d1aa2
        move.w  %d0,0x460d1aa4
        move.w  %d0,0x460d1aa6
        move.w  %d0,0x460d10dc
        jsr     0x400418e0
        jsr     0x4002f2f8
        move.l  0x460d1e04,%d0          | as the poll will read it (clamped or not)
        move.l  %d0,sg_kp
9:      rts

| Detour 0x40032280 (6 bytes: `moveal 0x400cfeda,%a1`), the setup-window dispatch's MIDI page 2 --
| FUNC + the ARP page key: the stock's (ARP SETUP). In MIXER + MIDI's view FUNC + ARP does nothing
| (sg_kfarp) and never reaches it (build 141).
sg_vtog:
        movea.l 0x400cfeda,%a1          | displaced
        jmp     0x40032286

| The combo in the view (build 141): TRKS -> PAGES -> PITCH -> the panel view -> TRKS; in AUDIO
| TRKS -> PAGES -> TRKS (no pitch view, no panel). The panel view's window is the arranger's (sg_vwset).
sg_vflip:
        tst.l   sg_full
        bne.s   .Lvf_f
        moveq   #1,%d0                  | the panel view -> TRKS
        move.l  %d0,sg_full
        clr.l   sg_view
        bra.s   .Lvf_z
.Lvf_f: tst.l   sg_pv
        beq.s   .Lvf_t
        clr.l   sg_pv                   | PITCH -> the panel view
        clr.l   sg_full
        bsr     sg_vwset
        bra.s   .Lvf_z
.Lvf_t: tst.l   sg_view
        bne.s   .Lvf_p
        moveq   #1,%d0                  | TRKS -> PAGES
        move.l  %d0,sg_view
        bra.s   .Lvf_n
.Lvf_p: tst.l   sg_aud
        beq.s   .Lvf_h
        clr.l   sg_view                 | AUDIO: PAGES -> TRKS
        bra.s   .Lvf_n
.Lvf_h: moveq   #1,%d0                  | PAGES -> PITCH: its range, cursor note and trig keys as they
        move.l  %d0,sg_pv               | were (build 142: sg_pini re-centred them on the cursor step's
        clr.l   sg_mode                 | note each visit, so the range moved and the project's RANGE
        bra.s   .Lvf_n                  | was lost)
.Lvf_z: clr.l   sg_mode
        moveq   #-1,%d0
        move.l  %d0,sg_zlst
        bsr     sg_zset
        tst.l   sg_nlay
        beq.s   .Lvf_n
        bsr     sg_tupd
.Lvf_n: clr.l   sg_idle
        clr.l   sg_bk
        bra     sg_now

| The panel view's window: the timeline with the arranger on, the 8 tracks with it off (build 141).
| Uses d0.
sg_vwset:
        moveq   #0,%d0
        tst.l   0x460d1aec
        beq.s   1f
        moveq   #1,%d0
1:      move.l  %d0,sg_view
        rts

| Each tick: the panel view's window follows the arranger turned on or off (build 141). Uses d0 d1.
sg_vwin:
        tst.l   sg_full
        bne.s   9f
        tst.l   sg_aud
        bne.s   9f
        move.l  sg_view,%d1
        bsr     sg_vwset
        cmp.l   sg_view,%d1
        beq.s   9f
        moveq   #-1,%d0
        move.l  %d0,sg_zlst
        bsr     sg_zset
        tst.l   sg_nlay
        beq.s   1f
        bsr     sg_tupd
1:      moveq   #1,%d0
        move.l  %d0,sg_vwch
9:      rts

| Out of MIXER + MIDI's view by NO in the grid (build 141): as a page key leaves it, then the page
| drawn -- the one the view was opened from, or the ARP / AMP page by its key when it was opened there
| (nothing drawn by sg_mxout: sg_on still set; the stock's page now). Uses everything but a5 a6.
sg_nout:
        bsr     sg_mxout
        tst.l   sg_on
        beq.s   9f
        moveq   #-1,%d0
        move.l  %d0,0x400c0aac
        pea     1.w
        pea     0x23.w
        jsr     0x4005578c
        addq.l  #8,%sp
9:      rts

| Detour 0x4005578c (8 bytes: `movel %d3,%sp@-` ; `movel %d2,%sp@-` ; `moveal %sp@(12),%a1`), the
| page keys' handler (code, edge; PANEL.md): in MIXER + MIDI's view a page key's press, ARP's too
| (build 141), leaves the view first -- the MIDI side's page and audio mode back -- then the stock's.
sg_pkey:
        tst.l   sg_own
        beq.s   8f
        moveq   #1,%d0
        cmp.l   8(%sp),%d0
        bne.s   8f
        lea     -40(%sp),%sp
        movem.l %d2-%d7/%a2-%a5,(%sp)
        bsr     sg_mxout
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
8:      move.l  %d3,-(%sp)              | displaced
        move.l  %d2,-(%sp)              | displaced
        movea.l 12(%sp),%a1             | displaced
        jmp     0x40055794

| Detour 0x4004b08c (8 bytes: `linkw %fp,#-32` ; `moveml %d2-%d3/%a2,%sp@`), the tempo's drawer (the
| tempo, or EXT blinking with an external clock), run on transport changes and from the periodic
| handler (0x40052128).
sg_tmp:
        bsr     sg_here
        bne.s   1f
        rts
1:      link.w  %fp,#-32                | displaced
        movem.l %d2-%d3/%a2,(%sp)       | displaced
        jmp     0x4004b094

| Detour 0x4003722c (8 bytes: `movel %a2,%sp@-` ; `clrl %sp@-` ; `pea 0x2a`), the transport icon's
| drawer (play / stop, the beat boxes' frames).
sg_trn:
        bsr     sg_here
        bne.s   1f
        rts
1:      move.l  %a2,-(%sp)              | displaced
        clr.l   -(%sp)                  | displaced
        pea     0x2a.w                  | displaced
        jmp     0x40037234

| Detour 0x4004c0a8 (8 bytes: `linkw %fp,#-144` ; `moveml %d2-%d3/%a2-%a5,%sp@`), the info box's drawer
| (the part, the MIDI channel), run by the main view and by a soft timer (0x40031a0c(5, it)).
sg_info:
        bsr     sg_here
        bne.s   1f
        rts
1:      link.w  %fp,#-144               | displaced
        movem.l %d2-%d3/%a2-%a5,(%sp)   | displaced
        jmp     0x4004c0b0

| Detour 0x400418e0 (8 bytes: `movel %a2,%sp@-` ; `lea 0x40012254,%a0`), the pattern field's drawer;
| grid recording's trig entry (0x40051eca) calls it, and its tail refreshes the trig LEDs.
sg_ptn:
        bsr     sg_here
        bne.s   1f
        jsr     0x4007b780              | its tail without its drawing: the popup's refresh and
        clr.l   -(%sp)                  | 0x4007e998(0), the trig LEDs' (a grid-recorded trig lit
        jsr     0x4007e998              | only at the next REC or transport key without it)
        addq.l  #4,%sp
        rts
1:      move.l  %a2,-(%sp)              | displaced
        lea     SG_FILL,%a0             | displaced
        jmp     0x400418e8

| The step message (UI message 8, 0x40061ed4) calls this instead of 0x400373dc (the beat boxes).
sg_beat:
        bsr     sg_here
        bne.s   1f
        rts
1:      jmp     0x400373dc

| Z set when the MIDI ARP page is on screen (the drawers' and the poll's test: a window over the page
| does not stop them, the editor keeps its plane and the window composites over it). Uses d0 d1.
sg_here:
        move.l  0x460d1684,%d0
        bra.s   sg_vis

| Z set when the ARP page is on screen and no window is open over it: a menu or popup (PROJECT,
| TEMPO, PATTERN SCALE) is one of the five windows (0x46c7d34c, 56 bytes each, visible = bit 5 of
| +32). The keys' and LEVEL's test: with one open, the keys it does not take itself (RIGHT on TEMPO,
| measured) go to the stock, not to the editor under it. Uses d0 d1.
sg_free:
        bsr.s   sg_here
        bne.s   9f
        move.l  0x46c7d34c+32,%d1
        or.l    0x46c7d34c+88,%d1
        or.l    0x46c7d34c+144,%d1
        or.l    0x46c7d34c+200,%d1
        or.l    0x46c7d34c+256,%d1
        or.l    0x460d1e14+32,%d1       | the yes / no question's window (0x400581c4; build 78)
        moveq   #0x20,%d0
        and.l   %d0,%d1
        beq.s   9f                      | none open: Z set
        moveq   #1,%d1
9:      rts

| Z set when page d0 is the MIDI ARP page and MIXER + MIDI opened the view there (sg_own, build 140: the
| ARP page is the stock's again otherwise, the arpeggiator back) -- or, in AUDIO, the audio side's AMP
| page (page 2 too): the Octatrack is in audio mode under the audio views (build 149). Uses d1.
sg_vis:
        tst.l   sg_own
        beq.s   1f
        tst.l   0x80000012              | MIDI mode
        bne.s   2f
        tst.l   sg_aud                  | audio mode: the AUDIO views' (build 149)
        beq.s   1f
2:      moveq   #2,%d1
        cmp.l   %d1,%d0
        rts
1:      moveq   #1,%d1
        rts

| Z set when a key on the ARP page is the step editor's: no FUNC, trig or track key down.
sg_keyok:
        bsr     sg_free
        bne.s   9f
        lea     SG_HELD,%a0
        moveq   #24,%d1                 | codes 0x00-0x17
1:      tst.l   (%a0)
        bne.s   9f
        lea     24(%a0),%a0
        subq.l  #1,%d1
        bne.s   1b
        tst.l   SG_HELD+0x2d*24         | FUNC
        bne.s   9f
        rts
9:      moveq   #1,%d1
        rts

| Z set when FUNC is down on the ARP page and no trig or track key is. Uses d0 d1 a0.
sg_keyfn:
        bsr     sg_free
        bne.s   9f
        lea     SG_HELD,%a0
        moveq   #24,%d1                 | codes 0x00-0x17
1:      tst.l   (%a0)
        bne.s   9f
        lea     24(%a0),%a0
        subq.l  #1,%d1
        bne.s   1b
        tst.l   SG_HELD+0x2d*24         | FUNC
        beq.s   9f
        moveq   #0,%d1
        rts
9:      moveq   #1,%d1
        rts

| Key handlers, (code, state 1 press / 2 repeat / 0 release), patched into both keymaps' records.
sg_klr:                                 | LEFT 0x34, RIGHT 0x21 (stock 0x4004b970)
        bsr     sg_keyok
        bne.s   8f
        tst.l   sg_win                  | our window up: its keys (build 82)
        bne     sg_wkey
        bra     sg_karr
8:      jmp     0x4004b970

| FUNC + LEFT / RIGHT (FUNC's sub-map records, stock 0x400503e8 / 0x400503c4): the cursor a page (16
| steps) that way, on a press, in the grid and in the panel.
sg_kfl:
        bsr     sg_keyfn
        bne     8f
        bsr     sg_pkeys                | KEYS 16: FUNC + LEFT / RIGHT the octaves (build 133)
        beq.s   0f
        moveq   #1,%d0
        cmp.l   8(%sp),%d0
        bne     7f
        moveq   #12,%d0
        moveq   #0x21,%d1
        cmp.l   4(%sp),%d1
        beq     sg_poc
        moveq   #-12,%d0
        bra     sg_poc
0:
        tst.l   sg_kb                   | the name's keyboard: a character left / right
        beq.s   0f
        moveq   #1,%d0
        cmp.l   8(%sp),%d0
        bne     7f
        moveq   #1,%d1
        moveq   #0x34,%d0
        cmp.l   4(%sp),%d0
        bne.s   3f
        moveq   #-1,%d1
3:      add.l   sg_ksel,%d1
        moveq   #63,%d0
        and.l   %d0,%d1
        move.l  %d1,sg_ksel
        bra     sg_now
0:      moveq   #1,%d0
        cmp.l   8(%sp),%d0
        bne     7f                      | press only (in the panel too, build 55)
        tst.l   sg_mode                 | a pattern line picked: its row's pattern by one (build 78)
        beq.s   5f
        move.l  sg_prm,%d0
        subi.l  #SG_PA,%d0
        moveq   #1,%d1
        cmp.l   %d1,%d0
        bhi.s   5f
        move.l  %d0,%d1
        moveq   #0x34,%d0
        cmp.l   4(%sp),%d0
        beq.s   3f
        moveq   #1,%d0
        bra.s   4f
3:      moveq   #-1,%d0
4:      bsr     sg_patlv
        clr.l   sg_idle
        bra     sg_now
5:      moveq   #16,%d1                 | (the full view: its window, 16 or 32 steps, build 96)
        tst.l   sg_full
        beq.s   6f
        move.l  sg_zn,%d1
        tst.l   sg_pv                   | (the pitch view: its page, 16 -- ROLL 32's 32; build 136: the
        beq.s   6f                      | full view's zoom before, 32 in ROLL 16)
        moveq   #16,%d1
        moveq   #1,%d0
        cmp.l   sg_plo,%d0
        bne.s   6f
        moveq   #32,%d1
6:      moveq   #0x34,%d0
        cmp.l   4(%sp),%d0
        bne.s   1f
        neg.l   %d1
1:      bsr     sg_tlon                 | the timeline: a row (build 71)
        beq.s   2f
        move.l  %d1,%d0
        asr.l   #4,%d0
        bsr     sg_tmv
        bra.s   3f
2:      move.l  sg_step,%d0
        add.l   %d1,%d0
        moveq   #63,%d1
        and.l   %d1,%d0
        move.l  %d0,sg_step
3:      clr.l   sg_bk
        clr.l   sg_idle
        bsr     sg_pgset
        bra     sg_now
7:      rts
8:      moveq   #0x34,%d0
        cmp.l   4(%sp),%d0
        bne.s   9f
        jmp     0x400503e8
9:      jmp     0x400503c4

| FUNC + UP / DOWN (FUNC's sub-map records, stock 0x40051fc4: the trig mode): with a note picked in
| the panel (NOTE, NOT2-4), that note an octave up / down, on a press; a NOT2-4 that is off stays off.
| Anywhere else the trig mode as ever.
sg_kfud:
        bsr     sg_free
        bne     8f
        tst.l   SG_HELD+0x2d*24         | FUNC; a trig key may be down (a held step's note, build 61:
        beq     8f                      | with sg_keyfn a hold-to-edit's FUNC + UP went to the stock)
        tst.l   sg_full                 | the pitch view: the window an octave (build 109)
        beq.s   0f
        tst.l   sg_pv
        beq.s   0f
        tst.l   sg_mode
        bne.s   0f
        moveq   #2,%d0                  | KEYS 16: FUNC + UP / DOWN a page (build 133; the octaves are
        cmp.l   sg_plo,%d0              | FUNC + LEFT / RIGHT's there)
        bne     sg_pfud
        moveq   #1,%d0
        cmp.l   8(%sp),%d0
        bne 7f
        moveq   #16,%d0
        moveq   #0x20,%d1
        cmp.l   4(%sp),%d1
        beq.s   1f
        moveq   #-16,%d0
1:      add.l   sg_step,%d0
        moveq   #63,%d1
        and.l   %d1,%d0
        move.l  %d0,sg_step
        clr.l   sg_bk
        clr.l   sg_idle
        bsr     sg_pgset
        bra     sg_now
0:
        tst.l   sg_kb                   | the name's keyboard: a row up / down
        beq.s   0f
        moveq   #1,%d0
        cmp.l   8(%sp),%d0
        bne.s   7f
        moveq   #8,%d1
        moveq   #0x33,%d0
        cmp.l   4(%sp),%d0
        bne.s   3f
        moveq   #-8,%d1
3:      add.l   sg_ksel,%d1
        moveq   #63,%d0
        and.l   %d0,%d1
        move.l  %d1,sg_ksel
        bra     sg_now
0:      tst.l   sg_mode
        beq.s   8f
        move.l  sg_prm,%d0
        subi.l  #SG_PN,%d0
        moveq   #3,%d1
        cmp.l   %d1,%d0
        bhi.s   8f                      | not a note
        moveq   #1,%d1
        cmp.l   8(%sp),%d1
        bne.s   7f                      | press only
        tst.l   %d0
        beq.s   2f                      | NOTE
        move.l  %a2,-(%sp)              | a2 is the caller's (build 72: sg_sel takes it)
        bsr     sg_sel                  | NOT2-4: 64 = off
        move.l  sg_prm,%d0
        lea     sg_pk-SG_PN,%a1
        mvz.b   (0,%a1,%d0.l),%d0
        bsr     sg_val
        movea.l (%sp)+,%a2
        moveq   #64,%d1
        cmp.l   %d1,%d0
        beq.s   7f
2:      moveq   #12,%d0
        moveq   #0x33,%d1
        cmp.l   4(%sp),%d1
        beq.s   3f
        moveq   #-12,%d0
3:      move.l  %d0,-(%sp)              | as LEVEL turned 12 that way
        pea     6.w
        bsr     .Llv_ed
        addq.l  #8,%sp
7:      rts
8:      jmp     0x40051fc4

| SCALE (MKI) / PAGE (MKII) 0x1b (stock 0x4004ffc4), in the 8-track window: the cursor a page on,
| wrapping after the longest track's last page, as the trig keys' page (sg_pgset); build 81. The
| 4-page window shows every page: there, and with FUNC, the stock's.
sg_kscale:
        bsr     sg_keyok
        bne     8f
        tst.l   sg_view
        beq.s   0f
        tst.l   sg_pv                   | the pitch view: a page on too (ROLL 32: two; build 124)
        beq     8f
0:
        tst.l   SG_HELD+0x2d*24
        bne     8f
        moveq   #1,%d0
        cmp.l   8(%sp),%d0
        bne     7f                      | a press only
        lea     -20(%sp),%sp
        movem.l %d4-%d7/%a2,(%sp)
        movea.l 0x46c82456,%a2
        moveq   #0,%d0
        move.b  0x100b14d0,%d0
        move.l  #0x8ed8,%d1
        muls.l  %d1,%d0
        adda.l  %d0,%a2
        moveq   #0,%d7                  | d7: the longest track's length
        moveq   #0,%d4
1:      move.l  %d4,%d1
        bsr     sg_trk
        cmp.l   %d7,%d6
        ble.s   2f
        move.l  %d6,%d7
2:      addq.l  #1,%d4
        moveq   #8,%d0
        cmp.l   %d0,%d4
        blt.s   1b
        moveq   #16,%d4                 | d4: a page (ROLL 32's two)
        tst.l   sg_pv
        beq.s   4f
        moveq   #1,%d0
        cmp.l   sg_plo,%d0
        bne.s   4f
        moveq   #32,%d4
4:      move.l  %d4,%d0
        add.l   sg_step,%d0
        cmp.l   %d7,%d0
        blt.s   3f
        move.l  %d4,%d0                 | past the last page: the first, the column kept
        subq.l  #1,%d0
        and.l   sg_step,%d0
3:      move.l  %d0,sg_step
        movem.l (%sp),%d4-%d7/%a2
        lea     20(%sp),%sp
        clr.l   sg_idle
        clr.l   sg_bk
        bsr     sg_pgset
        bra     sg_now
7:      rts
8:      jmp     0x4004ffc4

sg_kud:                                 | UP 0x33, DOWN 0x20 (stock 0x400491a0)
        bsr     sg_keyok
        bne.s   8f
        tst.l   sg_win
        bne     sg_wkey
        bra     sg_karr
8:      jmp     0x400491a0

| An arrow (code, state) for the step editor: a press moves once and starts sg_poll's repeat; the
| stock's repeats are dropped; the release stops it.
sg_karr:
        move.l  4(%sp),%d0
        moveq   #1,%d1
        cmp.l   8(%sp),%d1
        bne.s   1f
        move.l  %d0,sg_hk
        moveq   #SG_RD,%d1
        move.l  %d1,sg_ht
        clr.l   sg_rep                  | a press: an edge opens the panel
        bra.s   sg_mv
1:      tst.l   8(%sp)
        bne.s   9f                      | a repeat
        cmp.l   sg_hk,%d0
        bne.s   9f
        clr.l   sg_hk
9:      rts

| d0 = an arrow's code (sg_rep 1 = the poll's repeat). The grid: UP/DOWN a track (wrapping; a page in
| the 4-page window), LEFT/RIGHT a step within the page -- a press past its first or last column
| opens the panel (on NOTE), a repeat stops there; pages are FUNC + LEFT/RIGHT's (build 53). The
| panel: UP/DOWN a line, LEFT/RIGHT along it (wrapping left), RIGHT past a line's end back to the grid.
| Then the redraw.
sg_mv:
        tst.l   sg_full                 | the pitch view's own (build 109)
        beq.s   0f
        tst.l   sg_pv
        beq.s   0f
        tst.l   sg_mode
        beq     sg_pmv
0:      moveq   #1,%d1                  | RIGHT, DOWN: +1
        cmp.l   #0x34,%d0
        beq     1f
        cmp.l   #0x33,%d0
        bne     2f
1:      moveq   #-1,%d1                 | LEFT, UP: -1
2:      cmp.l   #0x34,%d0
        beq     3f
        cmp.l   #0x21,%d0
        beq     3f
        tst.l   sg_mode                 | UP / DOWN
        bne     4f
        tst.l   sg_view
        beq     7f
        bsr     sg_tlon                 | the timeline: a row (build 71)
        beq.s   0f
        move.l  %d1,%d0
        tst.l   sg_full                 | (the full timeline: straight up / down, build 100)
        beq.s   .Lsg_udn
        bsr     sg_tmvv
        bra     6f
.Lsg_udn:
        bsr     sg_tmv
        bra     6f
0:      move.l  sg_zn,%d0               | the 4-page window: a row (16 steps; the zoom's, build 84)
        muls.l  %d0,%d1
        bra     8f
7:      move.l  sg_row,%d0              | the cursor's track, 0-7
        add.l   %d1,%d0
        moveq   #7,%d1
        and.l   %d1,%d0
        move.l  %d0,sg_row
        bsr     sg_tsel                 | the stock's track follows: trig keys, LEDs, the info box (53)
        bra     6f
4:      moveq   #1,%d0                  | the panel: to the line above / below
        bsr     sg_pmove
        bra     6f
3:      tst.l   sg_mode                 | LEFT / RIGHT
        bne     5f
        bsr     sg_tlon                 | the timeline: its column (build 71)
        beq.s   0f
        tst.l   sg_full                 | (the full timeline's own, no edge opening the panel: build 100)
        beq.s   .Lsg_lrn
        move.l  %d1,%d0
        bsr     sg_tlr
        bra     6f
.Lsg_lrn:
        move.l  sg_tcol,%d0
        add.l   %d1,%d0
        bmi     9f
        move.l  %d0,-(%sp)              | (a readout row: its 6 fields, build 98)
        bsr     sg_trd
        movem.l (%sp),%d0
        addq.l  #4,%sp
        beq.s   .Lsg_lr15
        cmp.l   #5,%d0
        bgt     9f
        bra.s   .Lsg_lrok
.Lsg_lr15:
        cmp.l   #15,%d0
        bgt     9f
.Lsg_lrok:
        move.l  %d0,sg_tcol
        clr.l   sg_tfree
        bsr     sg_tupd
        bra     6f
0:      tst.l   sg_full                 | the full view: along all 64, wrapping (build 92)
        beq.s   0f
        bsr     sg_tnv                  | TRKS: the track number left of step 1 (build 143)
        bne.s   .Lmv_w
        tst.l   sg_tnum
        beq.s   .Lmv_l
        tst.l   %d1                     | on the number: RIGHT back to step 1, LEFT nothing
        bmi     6f
        clr.l   sg_tnum
        bra     6f
.Lmv_l: tst.l   %d1
        bpl.s   .Lmv_w
        tst.l   sg_step
        bne.s   .Lmv_w
        moveq   #1,%d0                  | LEFT from step 1: onto the track number
        move.l  %d0,sg_tnum
        bra     6f
.Lmv_w: add.l   %d1,sg_step
        moveq   #63,%d0
        and.l   %d0,sg_step
        bra     6f
0:      bsr     sg_zset                 | the column (of 16, or the zoom's, build 84)
        move.l  sg_zn,%d0
        subq.l  #1,%d0
        and.l   sg_step,%d0
        add.l   %d1,%d0
        bmi     9f                      | past the first
        cmp.l   sg_zn,%d0
        bge     9f                      | past the last
        add.l   %d1,sg_step             | within the page
        bra     6f
9:      tst.l   sg_rep                  | an edge: a repeat stops, a press opens the panel
        bne     sg_now
        moveq   #1,%d0
        move.l  %d0,sg_mode
        moveq   #SG_PN,%d0
        move.l  %d0,sg_prm
        clr.l   sg_hk
        bra     6f
8:      move.l  sg_step,%d0             | the 4-page window's UP/DOWN: a page
        add.l   %d1,%d0
        moveq   #63,%d1
        and.l   %d1,%d0
        move.l  %d0,sg_step
        bra     6f
5:      moveq   #-1,%d0                 | the panel: RIGHT past a line's end, back to the grid
        cmp.l   %d0,%d1
        beq     1f
        move.l  sg_prm,%d0
        cmp.l   #SG_NN-1,%d0
        beq     2f                      | the name's last character
        cmp.l   #SG_PM,%d0
        beq.s   1f                      | M: along to its pattern
        cmp.l   #SG_PR,%d0
        blt.s   3f
        cmp.l   #SG_PS,%d0
        ble     2f                      | ROW, the patterns, SAVE, STEP: their lines' ends
3:
        cmp.l   #SG_PN+3,%d0
        bge     2f                      | NOT4, VEL, LEN: the ends
1:      moveq   #0,%d0                  | along its line
        bsr     sg_pmove
        bra     6f
2:      tst.l   sg_rep
        bne     sg_now
        clr.l   sg_mode
        clr.l   sg_hk
6:      clr.l   sg_bk                   | the cursor shown at once
        clr.l   sg_idle
        bsr     sg_pgset                | a new page: the trig keys go with it
        bra     sg_now

sg_kyes:                                | YES (stock 0x4005e4c8)
        tst.l   sg_ptg                  | the pitch view, a trig key held: the cursor's note on its step
        bmi.s   0f                      | (build 126; sg_keyok refuses with a trig key down)
        moveq   #1,%d0
        cmp.l   8(%sp),%d0
        bne.s   0f
        bra     sg_pyes
0:      bsr     sg_keyok
        bne     8f
        tst.l   sg_win
        bne     sg_wkey
        moveq   #1,%d0
        cmp.l   8(%sp),%d0
        bne     7f                      | press only
        tst.l   sg_tnum                 | on the track number: nothing (build 143)
        bne     7f
        tst.l   sg_aud                  | AUDIO: the step's trig cycled (build 110); NO's "CLEAR? YES" up:
        beq.s   0f                      | the step cleared (build 116, as on a MIDI track)
        bsr     sg_nask
        beq     sg_atog
        clr.l   sg_nconf
        clr.l   sg_umt
        bra     sg_aclr
0:
        tst.l   sg_full                 | the pitch view: the note at the cursor on or off (build 109)
        beq.s   0f
        tst.l   sg_pv
        beq.s   0f
        tst.l   sg_mode
        beq     sg_pyw
0:
        tst.l   sg_mode
        beq     1f
        move.l  0x460d5de0,%d0          | a second YES within 20 ticks (~330 ms) of the one that opened the
        sub.l   sg_ytk,%d0              | panel from the grid: the step's window over the screen (build 90;
        moveq   #20,%d1                 | sg_stdraw)
        cmp.l   %d1,%d0
        bgt.s   0f
        move.l  #-1000000,%d0
        move.l  %d0,sg_ytk
        moveq   #SG_WST,%d0
        move.l  %d0,sg_win
        clr.l   sg_idle
        bra     sg_now
0:      moveq   #SG_PM,%d0              | on M: the arranger editor's MUTE ROW window for the row playing
        cmp.l   sg_prm,%d0              | (its M column's YES, 0x40058e18, on the row at 0x460d16e4; build 81)
        bne.s   3f
        bsr     sg_arr
        tst.l   %d1
        bmi     7f
        move.l  %d1,0x460d16e4
        clr.l   sg_idle
        jsr     0x40058e18
        rts
3:      moveq   #SG_PV,%d0              | on SAVE: the ARR menu's SAVE (0x40058250: its name asked for
        cmp.l   sg_prm,%d0              | first when it has none, then SAVE ARRANGEMENT? YES / NO; build 78)
        bne.s   2f
        moveq   #SG_PS,%d0
        move.l  %d0,sg_prm
        clr.l   sg_idle
        jsr     0x40058250              | (no redraw after: the question is drawn on the page's plane)
        rts
2:      moveq   #SG_PN+5,%d0            | in the panel on LEN: the grid's note-length lines hidden / shown
        cmp.l   sg_prm,%d0              | (build 67)
        bne     7f
        move.l  sg_lhide,%d0
        eori.l  #1,%d0
        move.l  %d0,sg_lhide
        clr.l   sg_idle
        bra     sg_now
1:      bsr     sg_trd                  | a readout row: the arranger's editor at its row (build 100;
        beq.s   0f                      | nothing in 98-99): the editor's row 0x460d16e4, which its EDIT
        move.l  sg_trow,%d0             | handler opens on (0x400336bc(it) at 0x40058d56)
        lsl.l   #4,%d0
        lea     sg_tl,%a0
        move.w  12(%a0,%d0.l),%d0
        ext.l   %d0
        move.l  %d0,0x460d16e4
        clr.l   sg_idle
        pea     1.w
        pea     0x1f.w
        jsr     0x40058c14
        addq.l  #8,%sp
        rts
0:      bsr     sg_nask                 | NO's "CLEAR? YES" up for this step: deleted (build 91)
        beq.s   0f
        clr.l   sg_nconf
        clr.l   sg_umt
        clr.l   sg_idle
        bsr     sg_ndel
        bra     sg_now
0:      lea     -8(%sp),%sp
        movem.l %d2/%a2,(%sp)
        bsr     sg_sel                  | a1 = the cursor's record, d0 = its step
        move.l  %d0,%d1
        asr.l   #3,%d1
        moveq   #7,%d2
        sub.l   %d1,%d2
        btst    %d0,(0,%a1,%d2.l)
        bne.s   2f
        btst    %d0,(16,%a1,%d2.l)
        bne.s   2f
        bsr     sg_trig                 | empty: a note trig first
2:      movem.l (%sp),%d2/%a2
        addq.l  #8,%sp
        move.l  0x460d5de0,%d0          | (the time, for a second press: build 90)
        move.l  %d0,sg_ytk
        moveq   #1,%d0
        move.l  %d0,sg_mode
        moveq   #SG_PN,%d0              | the panel starts on NOTE
        move.l  %d0,sg_prm
        clr.l   sg_idle
        bsr     sg_now
7:      rts
8:      jmp     0x4005e4c8

sg_kno:                                 | NO (stock 0x4005e25c)
        bsr     sg_keyok
        bne     8f
        tst.l   sg_win
        bne     sg_wkey
        moveq   #1,%d0
        cmp.l   8(%sp),%d0
        bne     7f
        tst.l   sg_mode                 | in the grid: out of MIXER + MIDI's view (build 141; deleting a
        bne.s   1f                      | step is FUNC + PLAY's now); in the panel: back to the grid
        clr.l   sg_nconf
        tst.l   sg_own
        beq.s   7f
        lea     -40(%sp),%sp
        movem.l %d2-%d7/%a2-%a5,(%sp)
        bsr     sg_nout
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        rts
1:      clr.l   sg_mode
        clr.l   sg_idle
        bsr     sg_now
7:      rts
8:      jmp     0x4005e25c

| LEVEL with a trig key held (the held-trig layer's encoder record, stock 0x400434d8, which does nothing
| on a MIDI track): with the panel open on the page (a hold opens it, sg_thold) the picked value changes
| as LEVEL alone changes it, on the cursor's step -- the held trig's.
sg_lvlh:
        bsr     sg_free
        bne.s   8f
        tst.l   sg_mode
        bne     .Llv_ed
8:      jmp     0x400434d8

| The LEVEL encoder (enc, delta) (stock 0x4004eb24): in the panel the value picked changes (a lock);
| in the grid the cursor's step scrolls 1-64; with FUNC the page changes.
sg_lvl:
        tst.l   sg_swp                  | (knob A in ROLL 32: LEVEL's own work, build 148)
        bne.s   .Llv_w
        bsr     sg_pl32                 | ROLL 32: LEVEL turns the cursor's note, as knob A elsewhere
        beq.s   .Llv_0
        move.l  8(%sp),%d1
        bra     sg_pka
.Llv_w: clr.l   sg_swp
.Llv_0: bsr     sg_free
        bne     8f
        tst.l   sg_win                  | our window up: its PAGES (build 82)
        bne     sg_wlvl
        move.l  8(%sp),%d0              | the delta
        tst.l   SG_HELD+0x2d*24         | FUNC + LEVEL: pages, as FUNC + LEFT/RIGHT (build 55; the stock's
        beq     1f                      | main volume is not on this page)
        tst.l   sg_mode                 | (in the panel on LEN: by one, build 80)
        beq.s   0f
        moveq   #SG_PN+5,%d1
        cmp.l   sg_prm,%d1
        beq     .Llv_ed
0:
        tst.l   sg_kb                   | the name's keyboard: through the characters
        beq.s   4f
        add.l   sg_ksel,%d0
        bpl.s   3f
        moveq   #0,%d0
3:      moveq   #63,%d1
        cmp.l   %d1,%d0
        ble.s   3f
        move.l  %d1,%d0
3:      move.l  %d0,sg_ksel
        bra     sg_now
4:      move.l  %d0,%d1                 | FUNC + LEVEL: pages (the timeline: rows, build 71)
        bsr     sg_tlon
        beq.s   5f
        tst.l   sg_mode                 | (in the grid, build 84: a run marked along the cursor's row, the
        bne.s   0f                      | column 0-15; rows in the panel)
        tst.l   sg_sela
        bpl.s   7f
        move.l  sg_step,%d0
        move.l  %d0,sg_sela
7:      move.l  %d1,%d0
        add.l   sg_tcol,%d0
        bpl.s   7f
        moveq   #0,%d0
7:      moveq   #15,%d1
        cmp.l   %d1,%d0
        ble.s   7f
        move.l  %d1,%d0
7:      move.l  %d0,sg_tcol
        clr.l   sg_tfree
        bsr     sg_tupd
        bra 3f
0:      move.l  %d1,%d0
        bsr     sg_tmvn
        bra     3f
5:      tst.l   sg_mode                 | the grid: a run of steps marked from the cursor, the cursor its
        bne.s   6f                      | other end, 1-64 (build 82: pages before, still in the panel)
        tst.l   sg_sela
        bpl.s   7f
        move.l  sg_step,%d0
        move.l  %d0,sg_sela
7:      move.l  %d1,%d0
        add.l   sg_step,%d0
        bpl.s   7f
        moveq   #0,%d0
7:      moveq   #63,%d1
        cmp.l   %d1,%d0
        ble.s   2f
        move.l  %d1,%d0
        bra.s   2f
6:      move.l  %d1,%d0
        lsl.l   #4,%d0
        add.l   sg_step,%d0
        moveq   #63,%d1
        and.l   %d1,%d0
        bra.s   2f
1:      tst.l   sg_mode
        bne     .Llv_ed
        move.l  %d0,-(%sp)              | the full timeline's cursor on a readout row: its field by the
        bsr     sg_trd                  | delta (build 98)
        movem.l (%sp),%d0
        addq.l  #4,%sp
        beq.s   0f
        bsr     sg_aedit
        clr.l   sg_idle
        bra     sg_now
0:      move.l  %d0,%d1                 | the grid: LEVEL scrolls the step, 1-64 (build 55), wrapping
        bsr     sg_tlon                 | 64 -> 1 and back (build 63); the timeline: along it (build 71)
        beq.s   5f
        move.l  %d1,%d0
        bsr     sg_tlvl
        bra.s   3f
5:      move.l  %d1,%d0
        add.l   sg_step,%d0
        moveq   #63,%d1
        and.l   %d1,%d0
2:      move.l  %d0,sg_step
3:      clr.l   sg_idle
        clr.l   sg_bk
        bsr     sg_pgset
        bra     sg_now
.Llv_ed:
        lea     -16(%sp),%sp
        movem.l %d2-%d4/%a2,(%sp)
        clr.l   sg_idle
        move.l  sg_prm,%d0
        moveq   #SG_PS,%d1
        cmp.l   %d1,%d0
        bne.s   5f
        bsr     sg_tlon                 | STEP: the cursor's step by the delta, wrapping (build 63); the
        beq.s   4f                      | timeline: along it (build 71)
        move.l  16+8(%sp),%d0
        bsr     sg_tlvl
        clr.l   sg_bk
        bsr     sg_pgset
        bra     3f
4:      move.l  16+8(%sp),%d0
        add.l   sg_step,%d0
        moveq   #63,%d1
        and.l   %d1,%d0
        move.l  %d0,sg_step
        clr.l   sg_bk
        bsr     sg_pgset
        bra     3f
5:      moveq   #SG_PR,%d1
        cmp.l   %d1,%d0
        bne.s   5f
        move.l  16+8(%sp),%d0           | ROW: the arrangement row to go to (build 69)
        bsr     sg_rowlv
        bra     3f
5:      moveq   #SG_PV,%d1              | the patterns: their rows' patterns (build 78); SAVE, M: nothing
        cmp.l   %d1,%d0
        beq     3f
        moveq   #SG_PM,%d1
        cmp.l   %d1,%d0
        beq     3f
        moveq   #SG_PA,%d1
        cmp.l   %d1,%d0
        blt.s   7f
        moveq   #SG_PB,%d1
        cmp.l   %d1,%d0
        bgt.s   7f
        subi.l  #SG_PA,%d0
        move.l  %d0,%d1
        move.l  16+8(%sp),%d0
        bsr     sg_patlv
        bra     3f
7:      moveq   #SG_PN,%d1
        cmp.l   %d1,%d0
        bge.s   2f
        move.l  16+8(%sp),%d1           | the name: character d0 by the delta
        bsr     sg_nset
        bra.s   3f
2:      bsr     sg_sel                  | a1 record, a2 the step's locks, d0 step
        move.l  %d0,%d1                 | an empty step (reached by an arrow, build 53): a note
        asr.l   #3,%d1                  | trig first, as YES gives one
        moveq   #7,%d2
        sub.l   %d1,%d2
        btst    %d0,(0,%a1,%d2.l)
        bne.s   6f
        btst    %d0,(16,%a1,%d2.l)
        bne.s   6f
        bsr     sg_trig
        bsr     sg_sel
6:      move.l  sg_prm,%d3
        lea     sg_pk-SG_PN,%a1
        mvz.b   (0,%a1,%d3.l),%d3       | the slot
        move.l  %d3,%d0
        bsr     sg_val                  | d0 = its value now
        moveq   #2,%d1
        cmp.l   %d1,%d3
        bne.s   4f
        tst.l   SG_HELD+0x2d*24         | LEN: alone through its subdivisions (the next one past the
        bne.s   4f                      | value either way), with FUNC by one (build 80; the other way
        move.l  16+8(%sp),%d1           | round in 79)
        bsr     sg_lstep
        bra.s   1f
4:      add.l   16+8(%sp),%d0           | + delta
        bpl.s   1f
        moveq   #0,%d0
1:      moveq   #127,%d1
        cmp.l   %d1,%d0
        ble.s   1f
        move.l  %d1,%d0
1:      move.l  %d3,%d1
        bsr     sg_lock
3:      bsr     sg_now
        movem.l (%sp),%d2-%d4/%a2
        lea     16(%sp),%sp
        rts
8:      jmp     0x4004eb24

| The panel's value (sg_prm): 0-11 the name's characters, 12 ROW (arranging only: skipped otherwise), 13
| STEP, 14-17 NOTE NOT2 NOT3 NOT4, 18 VEL, 19 LEN, six lines. d0 = 0: d1 = +1 / -1 along the line (wrapping); d0 = 1: to the next / previous line.
        .set    SG_NL, 9
sg_pmove:
        lea     -12(%sp),%sp
        movem.l %d2-%d4,(%sp)
        move.l  sg_prm,%d2
        moveq   #SG_NL-1,%d3            | d3: the line, the last whose first value is <= sg_prm
        lea     sg_ls,%a0
1:      mvz.b   (0,%a0,%d3.l),%d4
        cmp.l   %d4,%d2
        bge.s   1f
        subq.l  #1,%d3
        bra.s   1b
1:      sub.l   %d4,%d2                 | d2: the position on it
        tst.l   %d0
        bne.s   3f
        add.l   %d1,%d2                 | along
        lea     sg_ll,%a0
        mvz.b   (0,%a0,%d3.l),%d4
        tst.l   %d2
        bpl.s   2f
        move.l  %d4,%d2
        subq.l  #1,%d2
2:      cmp.l   %d4,%d2
        blt.s   5f
        moveq   #0,%d2
        bra.s   5f
3:      add.l   %d1,%d3                 | across
6:      tst.l   %d3
        bpl.s   4f
        moveq   #SG_NL-1,%d3
4:      moveq   #SG_NL-1,%d4
        cmp.l   %d4,%d3
        ble.s   4f
        moveq   #0,%d3
4:      bsr     sg_lhid                 | past the lines not shown (ROW, the patterns, SAVE)
        beq.s   4f
        add.l   %d1,%d3
        bra.s   6b
4:      lea     sg_ll,%a0
        mvz.b   (0,%a0,%d3.l),%d4
        cmp.l   %d4,%d2
        blt.s   5f
        move.l  %d4,%d2
        subq.l  #1,%d2
5:      lea     sg_ls,%a0
        mvz.b   (0,%a0,%d3.l),%d4
        add.l   %d4,%d2
        move.l  %d2,sg_prm
        movem.l (%sp),%d2-%d4
        lea     12(%sp),%sp
        rts

| d3 = a panel line: Z clear when it is not shown: ROW and the two pattern lines need the arrangement
| on (ROW since build 69, the patterns since 78), SAVE an unsaved arrangement (78). Uses d0 a0.
sg_lhid:
        moveq   #1,%d0
        cmp.l   %d0,%d3
        blt.s   8f
        moveq   #3,%d0
        cmp.l   %d0,%d3
        bgt.s   2f
        tst.l   0x460d1aec
        beq.s   9f
        bra.s   8f
2:      moveq   #4,%d0
        cmp.l   %d0,%d3
        bne.s   8f
        bsr     sg_adirty
        beq.s   9f
8:      moveq   #0,%d0
        rts
9:      moveq   #1,%d0
        rts

| Z clear when the arrangement in use has changes not saved: bit 0 of its record's + 16 word, which
| the ARR menu's SAVE clears (0x400614e4, after copying the 0x1614-byte record to its saved copy at
| 0x1000b0a4 + 0x1614 n) and an edit sets (build 78). Uses d0 a0.
sg_adirty:
        movea.l 0x10000000,%a0
        move.w  16(%a0),%d0
        btst    #0,%d0
        rts

| The pattern of the arrangement row on panel line d1 (0: the row playing, 1: the row to come) by d0
| (build 78): its byte (+ 21 from the row's + 20: bank << 4 | pattern) by the delta, kept to 0-255
| (A01-P16); the arrangement marked unsaved, as the arranger's own editor does. Only on a pattern row.
| Uses d0 d1 a0 a1.
sg_patlv:
        lea     -8(%sp),%sp
        movem.l %d2-%d3,(%sp)
        move.l  %d0,%d2                 | d2: the delta
        move.l  %d1,%d3                 | d3: which line
        bsr     sg_arr
        move.l  %d1,%d0
        bmi.s   9f
        tst.l   %d3
        beq.s   1f
        bsr     sg_tnr                  | the row to come
        tst.l   %d0
        bmi.s   9f
1:      bsr     sg_trrow
        tst.l   %d0
        beq.s   9f                      | not a pattern row
        moveq   #0,%d0
        move.b  21(%a0),%d0
        add.l   %d2,%d0
        bpl.s   2f
        moveq   #0,%d0
2:      cmp.l   #255,%d0
        ble.s   3f
        move.l  #255,%d0
3:      move.b  %d0,21(%a0)
        movea.l 0x10000000,%a0          | unsaved
        moveq   #0,%d0
        move.w  16(%a0),%d0
        moveq   #1,%d1
        or.l    %d1,%d0
        move.w  %d0,16(%a0)
9:      movem.l (%sp),%d2-%d3
        addq.l  #8,%sp
        rts

| a0 = the cursor track's name in sg_names (build 140: bank * 384 + Part * 96 + track * 12, saved with the
| project in names.work, sgn_st_*; in the Part's ARP bytes until 139). Uses d0 d1 a0.
sg_noff:
        moveq   #0,%d0
        move.b  0x80000002,%d0          | the bank
        moveq   #15,%d1
        and.l   %d1,%d0
        lsl.l   #2,%d0
        moveq   #0,%d1
        move.b  0x100b14cf,%d1          | the part
        andi.l  #3,%d1
        add.l   %d1,%d0
        lsl.l   #3,%d0
        add.l   sg_row,%d0              | (bank * 4 + part) * 8 + track
        moveq   #12,%d1
        muls.l  %d1,%d0
        lea     sg_names,%a0
        adda.l  %d0,%a0
        rts

| The cursor track's name for the screen into sg_nm (SG_NN characters + NUL): its bytes (32-95; others
| shown as spaces) when the first is a character, else "T<n>". Uses d0 d1 a0 a1.
sg_nget:
        lea     -8(%sp),%sp
        movem.l %d2/%a2,(%sp)
        lea     sg_nm,%a2
        tst.l   sg_aud                  | AUDIO: "T<n>" (build 110)
        bne     5f
        bsr     sg_noff
        movea.l %a0,%a1
        moveq   #0,%d1
        move.b  (%a1),%d1
        moveq   #32,%d0
        cmp.l   %d0,%d1
        blt.s   5f
        moveq   #95,%d0
        cmp.l   %d0,%d1
        bgt.s   5f
        moveq   #SG_NN-1,%d2
1:      move.b  (%a1)+,%d0
        cmp.b   #32,%d0
        blt.s   2f
        cmp.b   #95,%d0
        ble.s   3f
2:      moveq   #32,%d0
3:      move.b  %d0,(%a2)+
        subq.l  #1,%d2
        bpl.s   1b
        bra.s   7f
5:      move.b  #84,(%a2)+              | "T<n>" and spaces
        move.l  sg_row,%d0
        add.l   #49,%d0
        move.b  %d0,(%a2)+
        moveq   #32,%d0
        moveq   #SG_NN-2,%d1
6:      move.b  %d0,(%a2)+
        subq.l  #1,%d1
        bne.s   6b
7:      clr.b   (%a2)
        movem.l (%sp),%d2/%a2
        addq.l  #8,%sp
        rts

| d0 = character 0-11 of the cursor track's name, d1 = the knob's delta: the character steps through
| 32-95 (space, digits, A-Z ...), wrapping; the whole name written to sg_names, names.work due. A name not
| yet set is first written as shown ("T<n>").
sg_nset:
        lea     -16(%sp),%sp
        movem.l %d2-%d4/%a2,(%sp)
        move.l  %d0,%d2
        move.l  %d1,%d3
        bsr     sg_nget                 | sg_nm: the name as shown
        lea     sg_nm,%a0
        moveq   #0,%d0
        move.b  (0,%a0,%d2.l),%d0
        add.l   %d3,%d0
        moveq   #32,%d1
        sub.l   %d1,%d0
        moveq   #64,%d1                 | 64 characters, wrapping
        move.l  %d0,%d4
        divs.l  %d1,%d4
        muls.l  %d1,%d4
        sub.l   %d4,%d0
        bpl.s   1f
        add.l   %d1,%d0
1:      moveq   #32,%d1
        add.l   %d1,%d0
        move.b  %d0,(0,%a0,%d2.l)
        bsr     sg_noff                 | write them all
        lea     sg_nm,%a2
        moveq   #SG_NN-1,%d4
2:      move.b  (%a2)+,(%a0)+
        subq.l  #1,%d4
        bpl.s   2b
        moveq   #1,%d0
        move.l  %d0,sgn_dirty
        bsr     sg_dirty
        movem.l (%sp),%d2-%d4/%a2
        lea     16(%sp),%sp
        rts

| Redraw now (a key or the knob moved).
sg_now:
        moveq   #1,%d1
        bra     sg_run

| The cursor's record: a1 = the MIDI track's record, a2 = its step's 32 lock bytes (0xff = none),
| a0 = the Part's NOTE page values for that track, d0 = the step. Uses d0 d1 a0 a1 a2.
sg_sel:
        move.l  sg_cpat,%d0             | the timeline's row's pattern (build 71)
        beq.s   1f
        movea.l %d0,%a1
        bra.s   2f
1:      movea.l 0x46c82456,%a1          | the bank
        moveq   #0,%d0
        move.b  0x100b14d0,%d0          | the pattern (the p-lock store's)
        move.l  #0x8ed8,%d1
        muls.l  %d1,%d0
        adda.l  %d0,%a1
2:      tst.l   sg_aud                  | AUDIO (build 110): the audio track's record, its step's locks
        beq.s   3f                      | at +0x59 + 32 s, no Part values (a0 = a2: a lock or 0xff)
        move.l  sg_row,%d0
        move.l  #0x91a,%d1
        muls.l  %d1,%d0
        adda.l  %d0,%a1
        move.l  sg_step,%d0
        lsl.l   #5,%d0
        lea     (0x59,%a1,%d0.l),%a2
        movea.l %a2,%a0
        move.l  sg_step,%d0
        rts
3:      move.l  sg_row,%d0
        move.l  #0x8b0,%d1
        muls.l  %d1,%d0
        adda.l  %d0,%a1
        adda.l  #0x48d0,%a1
        move.l  sg_step,%d0
        lsl.l   #5,%d0
        lea     (0x30,%a1,%d0.l),%a2
        movea.l 0x46c82456,%a0
        moveq   #0,%d0
        move.b  0x100b14cf,%d0          | the part
        move.l  #0x18b2,%d1
        muls.l  %d1,%d0
        adda.l  %d0,%a0
        move.l  sg_row,%d0
        lsl.l   #5,%d0
        adda.l  %d0,%a0
        adda.l  #0x8f162,%a0            | the Part's MIDI page-1 values (NOT2's formatter reads NOTE here)
        move.l  sg_step,%d0
        rts

| d0 = slot: d0 = the step's value, its lock (a2) or the Part's (a0). Uses d0 d1.
sg_val:
        moveq   #0,%d1
        move.b  (0,%a2,%d0.l),%d1
        cmp.b   #0xff,%d1
        bne.s   1f
        move.b  (0,%a0,%d0.l),%d1
1:      move.l  %d1,%d0
        rts

| d0 = value, d1 = slot: the lock on the cursor's step (after sg_sel; the bank's copy, the CS1 copy,
| the dirty flags, the step's track bit, the engine's refresh -- 0x4004f7ba's body for one step).
sg_lock:
        bsr     sg_cedit                | another bank's pattern: not written (build 71)
        beq.s   0f
        rts
0:      lea     -12(%sp),%sp
        movem.l %d2-%d3/%a3,(%sp)
        move.b  %d0,(0,%a2,%d1.l)
        movea.l %a2,%a3
        suba.l  0x46c82456,%a3
        adda.l  #0x1001614e,%a3         | the CS1 copy
        move.b  %d0,(0,%a3,%d1.l)
        bsr     sg_dirty
        lea     0x46c7d2e4,%a0          | the step's MIDI-track bits
        move.l  sg_step,%d0
        move.l  sg_row,%d1
        bset    %d1,(0,%a0,%d0.l)
        moveq   #0,%d0
        move.w  %d0,0x460d1a9e
        move.w  %d0,0x460d1aa0
        move.w  %d0,0x460d1aa2
        move.w  %d0,0x460d1aa4
        move.w  %d0,0x460d1aa6
        move.w  %d0,0x460d10dc
        move.l  sg_row,%d0
        addq.l  #8,%d0
        move.l  %d0,-(%sp)
        jsr     0x4009da20
        addq.l  #4,%sp
        movem.l (%sp),%d2-%d3/%a3
        lea     12(%sp),%sp
        rts

| The project's dirty flags (as every stock pattern edit).
sg_dirty:
        movea.l 0x46c82456,%a0
        adda.l  #0x9b332,%a0
        moveq   #1,%d0
        move.l  %d0,(%a0)
        move.l  %d0,0x100f8598
        jmp     0x40027e00

| A note trig on the cursor's step (after sg_sel: a1 = record, d0 = step), as GRID RECORDING's: the
| trig bit in both copies, the trig word's micro timing and count cleared (0x400514e0..0x40051600).
sg_trig:
        bsr     sg_cedit
        beq.s   0f
        rts
0:      lea     -12(%sp),%sp
        movem.l %d2-%d3/%a3,(%sp)
        movea.l %a1,%a3
        suba.l  0x46c82456,%a3
        adda.l  #0x1001614e,%a3         | the CS1 copy of the record
        move.l  %d0,%d1
        asr.l   #3,%d1
        moveq   #7,%d2
        sub.l   %d1,%d2
        bset    %d0,(0,%a1,%d2.l)
        bset    %d0,(0,%a3,%d2.l)
        move.l  %d0,%d1
        add.l   %d1,%d1
        addi.l  #0x830,%d1              | the trig word
        move.w  (0,%a1,%d1.l),%d2
        andi.l  #0x7f,%d2               | the condition kept
        move.w  %d2,(0,%a1,%d1.l)
        move.w  %d2,(0,%a3,%d1.l)
        bsr     sg_dirty
        lea     0x46c7d2e4,%a0
        move.l  sg_step,%d0
        move.l  sg_row,%d1
        bset    %d1,(0,%a0,%d0.l)
        move.l  sg_row,%d0
        addq.l  #8,%d0
        move.l  %d0,-(%sp)
        jsr     0x4009da20
        addq.l  #4,%sp
        movem.l (%sp),%d2-%d3/%a3
        lea     12(%sp),%sp
        rts

| ---- The drawing. d1 = 1: draw; 0: only if the inputs or the plane changed.
sg_run:
        lea     -48(%sp),%sp
        movem.l %d1-%d7/%a2-%a6,(%sp)
        tst.l   sg_aud                  | AUDIO: no panel, no step's window (build 110)
        beq.s   0f
        clr.l   sg_mode
        moveq   #SG_WST,%d0
        cmp.l   sg_win,%d0
        bne.s   0f
        clr.l   sg_win
0:
        bsr     sg_zset                 | the zoom's columns, pitch and rows (build 84)
        bsr     sg_platch
        movea.l 0x46c82456,%a2          | a2: the pattern
        moveq   #0,%d0
        move.b  0x100b14d0,%d0
        move.l  #0x8ed8,%d1
        muls.l  %d1,%d0
        adda.l  %d0,%a2
        moveq   #0x30,%d0               | a5: the page in view, as its first step: the cursor's, or
        and.l   sg_step,%d0             | hands off, the panel shut, the page the cursor's track is
        tst.l   sg_mode                 | playing (the trig keys stay put); in the 4-page window the
        bne.s   1f                      | cursor itself goes to that page, its column kept (build 62);
        tst.l   sg_view                 | the 8-track window follows at once, hands on too (build 78)
        beq.s   2f
        moveq   #SG_IDLE,%d1
        cmp.l   sg_idle,%d1
        bgt.s   1f
2:      move.l  %d0,%d4
        move.l  sg_row,%d1
        bsr     sg_trk                  | d5: the step it plays, -1 stopped
        move.l  %d4,%d0
        tst.l   %d5
        bmi.s   1f
        moveq   #0x30,%d0
        and.l   %d5,%d0
        tst.l   sg_view
        beq.s   1f
        moveq   #15,%d1
        and.l   sg_step,%d1
        or.l    %d0,%d1
        move.l  %d1,sg_step
1:      tst.l   sg_full                 | the full 8-track window (build 94): 32 columns of the pattern's
        beq.s   0f                      | count, playing (0x800065b4; each track's steps repeated to fill
        move.l  sg_zn,%d1               | them), the window on at each 32 (16 at 16 a row, build 95); else
        neg.l   %d1                     | the cursor's
        moveq   #63,%d0
        and.l   sg_step,%d0
        and.l   %d1,%d0
        tst.l   0x800065b8
        bne.s   .Lsg_fwp
        tst.l   sg_fwv                  | stopped: the window play stopped in while the cursor is still
        beq.s   0f                      | on the step it stopped on (build 98)
        move.l  %d0,-(%sp)
        move.l  sg_step,%d0
        cmp.l   sg_fws,%d0
        movem.l (%sp),%d0
        addq.l  #4,%sp
        beq.s   .Lsg_fwk
        clr.l   sg_fwv
        bra.s   0f
.Lsg_fwk:
        move.l  sg_fsc,%d0
        and.l   %d1,%d0
        bra.s   0f
.Lsg_fwp:
        tst.l   sg_mode
        bne.s   0f
        move.l  %d2,-(%sp)              | (hands off only, build 96: the cursor's window while it moves)
        moveq   #SG_IDLE,%d2
        cmp.l   sg_idle,%d2
        movem.l (%sp),%d2
        addq.l  #4,%sp
        bgt.s   0f
        moveq   #0,%d0
        move.w  0x800065b4,%d0
        and.l   %d1,%d0
0:      movea.l %d0,%a5
        move.l  %d0,sg_fwin             | (the full view's title shows it, build 96)
        lsr.l   #4,%d0
        move.l  %d0,sg_vpg
        clr.l   sg_np                   | the 4-page window in arrangement mode: the next row's pattern
        clr.l   sg_nlay                 | under the current one (build 62)
        tst.l   sg_view
        beq.s   1f
        tst.l   sg_pv                   | (not in the pitch view, build 109)
        bne.s   1f
        tst.l   0x460d1aec
        beq.s   1f
        moveq   #1,%d0
        move.l  %d0,sg_nlay
        bsr     sg_nxt
        move.l  %d0,sg_np
1:      tst.l   sg_nlay                 | the timeline (build 71): not in it, the cursor's step is in the
        bne.s   2f                      | current pattern
        clr.l   sg_cpat
        clr.l   sg_tfree
        clr.l   sg_tlast
        bra.s   1f
2:      tst.l   sg_tlast                | entered: its cursor on the first row, the step's column
        bne.s   3f
        moveq   #1,%d0
        move.l  %d0,sg_tlast
        moveq   #15,%d0
        and.l   sg_step,%d0
        move.l  %d0,sg_tcol
        clr.l   sg_trow
        clr.l   sg_tsv
        clr.l   sg_tplv
3:      bsr     sg_tupd
1:      bsr     sg_zset                 | (the full view's figures, build 92)
        tst.l   sg_full                 | the full view has no panel: the panel opened (YES, a held trig, an
        beq.s   0f                      | edge) is the step's window (build 92)
        tst.l   sg_mode
        beq.s   0f
        tst.l   sg_win
        bne.s   0f
        moveq   #SG_WST,%d0
        move.l  %d0,sg_win
0:      moveq   #4,%d0                  | the rows: 8 tracks 4 px tall every 7, or 4 pages 8 px every 14
        moveq   #7,%d1                  | (nine 7-px rows down the screen, the first left for a title;
        tst.l   sg_view                 | the panel's lines share them); in arrangement mode 4 pages of
        beq.s   1f                      | this pattern and 4 of the next, a row each
        tst.l   sg_nlay
        bne.s   1f
        moveq   #4,%d2                  | the 4-page window zoomed (build 84): up to 4 rows tall ones,
        cmp.l   sg_zr,%d2               | 8 rows the short ones
        blt.s   1f
        moveq   #8,%d0
        moveq   #14,%d1
1:      tst.l   sg_full                 | the full view's steps 3 px tall, the guides between the rows a
        beq.s   2f                      | pixel clear of them (build 101)
        moveq   #3,%d0
2:      move.l  %d0,sg_rh
        bsr     sg_fstr                 | (the full 4-page grid's own stride, knob D: build 107)
        move.l  %d1,sg_rs
        bsr     sg_f2l                  | the full 8-track window's two lines a track: 2 px tall (build 93)
        beq.s   .Lsg_rh2
        moveq   #2,%d0
        move.l  %d0,sg_rh
.Lsg_rh2:
        bsr     sg_zfol                 | the cursor's row in view (build 84)

        move.l  %a2,%d0                 | d0: what the drawing depends on
        move.l  %a5,%d1
        bsr     sg_mx
        move.l  sg_row,%d1
        bsr     sg_mx
        move.l  sg_step,%d1
        bsr     sg_mx
        move.l  sg_mode,%d1
        bsr     sg_mx
        move.l  sg_prm,%d1
        bsr     sg_mx
        moveq   #48,%d1                 | the blink phases (bits 4 and 5)
        and.l   sg_bk,%d1
        bsr     sg_mx
        moveq   #32,%d1                 | the mutes' flash (build 125)
        and.l   sg_mbk,%d1
        bsr     sg_mx
        bsr     sg_cvis                 | the cursor shown (build 74)
        bsr     sg_mx
        move.l  sg_view,%d1
        bsr     sg_mx
        move.l  sg_kb,%d1
        lsl.l   #8,%d1
        or.l    sg_ksel,%d1
        bsr     sg_mx
        move.l  sg_np,%d1               | the next pattern, its masks for the cursor's track
        add.l   sg_nlay,%d1
        bsr     sg_mx
        tst.l   sg_np
        beq.s   1f
        move.l  %d0,%d3                 | (sg_nrec takes d0: the signature kept, build 81 -- until then
        bsr     sg_nrec                 | everything mixed in before it was lost while arranging in the
        move.l  %d3,%d0                 | 4-page window: stopped, the timeline never redrew)
        move.l  (%a0),%d1
        bsr     sg_mx
        move.l  4(%a0),%d1
        bsr     sg_mx
        move.l  16(%a0),%d1
        bsr     sg_mx
        move.l  20(%a0),%d1
        bsr     sg_mx
1:      tst.l   sg_nlay                 | the timeline's rows and cursor
        beq.s   1f
        bsr     sg_tsig
1:
        move.l  sg_umt,%d1              | the undo message up or not, and which
        sne     %d1
        add.l   sg_upos,%d1
        bsr     sg_mx
        moveq   #0,%d1                  | the MIDI tracks muted, as the MIDI engine reads them (0x4009f804):
        move.b  0x46c78d6a,%d1          | (0x46c78d6a << 8 | 0x8000000c): bits 0-7 solo, 8-15 mute; with a
        lsl.l   #8,%d1                  | solo the others are muted and the soloed play
        or.l    0x8000000c,%d1
        moveq   #0,%d2
        move.b  %d1,%d2                 | d2: solos
        lsr.l   #8,%d1                  | d1: mutes
        tst.l   %d2
        beq.s   1f
        moveq   #-1,%d3
        or.l    %d3,%d1
1:      eor.l   %d2,%d1
        and.l   #0xff,%d1
        tst.l   sg_aud                  | (not shown in AUDIO, build 110)
        beq.s   0f
        moveq   #0,%d1
0:      move.l  %d1,sg_mm
        bsr     sg_mx
        moveq   #0,%d7
1:      move.l  %d7,%d1                 | each track: its length, step playing, its masks
        bsr     sg_trk                  | a3 record, d6 length, d5 step playing
        move.l  %d6,%d1
        bsr     sg_mx
        move.l  %d5,%d1
        bsr     sg_mx
        move.l  (%a3),%d1
        bsr     sg_mx
        move.l  4(%a3),%d1
        bsr     sg_mx
        move.l  16(%a3),%d1
        bsr     sg_mx
        move.l  20(%a3),%d1
        bsr     sg_mx
        addq.l  #1,%d7
        moveq   #8,%d1
        cmp.l   %d1,%d7
        blt.s   1b
        bsr     sg_arr                  | d1 = the arrangement row, -1 off
        bsr     sg_mx
        bsr     sg_mstep                | d1 = the step playing, -1 stopped
        bsr     sg_mx
        move.l  0x8000669c,%d1          | the row asked for (build 69)
        bsr     sg_mx
        move.l  %d0,%d3                 | the pattern to come
        bsr     sg_queue
        move.l  %d0,%d1
        move.l  %d3,%d0
        bsr     sg_mx
        move.l  0x80000000,%d1          | bank letter (+2)
        bsr     sg_mx
        move.l  sg_cks,%d1              | the time (build 82)
        bsr     sg_mx
        move.l  sg_sela,%d1             | the run marked, our window and its state, the message (build 82)
        bsr     sg_mx
        move.l  sg_win,%d1
        bsr     sg_mx
        move.l  sg_wl,%d1
        bsr     sg_mx
        move.l  sg_wpc,%d1
        bsr     sg_mx
        move.l  sg_wpm,%d1
        bsr     sg_mx
        move.l  sg_w3t,%d1              | (build 107)
        bsr     sg_mx
        move.l  sg_pv,%d1               | the pitch view, its range and row (build 109), layout and window
        lsl.l   #8,%d1                  | (build 123)
        add.l   sg_pb,%d1
        lsl.l   #5,%d1
        add.l   sg_pr,%d1
        bsr     sg_mx
        move.l  sg_plo,%d1
        lsl.l   #8,%d1
        add.l   sg_pwr,%d1
        bsr     sg_mx
        move.l  sg_pkn,%d1              | the notes the trig keys play, their base (build 129)
        bsr     sg_mx
        move.l  sg_pkn+4,%d1
        bsr     sg_mx
        move.l  sg_pkn+8,%d1
        bsr     sg_mx
        move.l  sg_pkn+12,%d1
        bsr     sg_mx
        move.l  sg_pkb0,%d1
        bsr     sg_mx
        move.l  sg_umsg,%d1
        bsr     sg_mx
        move.l  sg_umsg+4,%d1
        bsr     sg_mx
        move.l  sg_zm,%d1               | the zoom and the scrolls (build 84)
        bsr     sg_mx
        move.l  sg_zs,%d1
        bsr     sg_mx
        move.l  sg_tsc,%d1
        bsr     sg_mx
        move.l  sg_spat,%d1             | the scale window's pattern (build 85)
        bsr     sg_mx
        move.l  sg_srow,%d1             | the scale window's pick (build 83)
        lsl.l   #2,%d1
        add.l   sg_scol,%d1
        bsr     sg_mx
        move.l  sg_snum,%d1             | its row's number picked (build 106)
        bsr     sg_mx
        moveq   #0,%d1                  | the active track (its number inverted, build 82)
        move.b  0x100b14cc,%d1
        bsr     sg_mx
        move.l  %d0,%d3
        bsr     sg_nget                 | the cursor track's name
        move.l  %d3,%d0
        lea     sg_nm,%a0
        move.l  (%a0),%d1
        bsr     sg_mx
        move.l  4(%a0),%d1
        bsr     sg_mx
        move.l  8(%a0),%d1
        bsr     sg_mx
        move.l  %d0,%d3
        bsr     sg_sel                  | the cursor's step: its locks and the Part's values
        move.l  %d3,%d0
        move.l  (%a2),%d1
        bsr     sg_mx
        move.l  4(%a2),%d1
        bsr     sg_mx
        move.l  (%a0),%d1
        bsr     sg_mx
        move.l  4(%a0),%d1
        bsr     sg_mx
        move.l  %d0,%d4                 | d4: the inputs' signature
        movea.l 0x46c82456,%a2          | a2 back to the pattern
        moveq   #0,%d0
        move.b  0x100b14d0,%d0
        move.l  #0x8ed8,%d1
        muls.l  %d1,%d0
        adda.l  %d0,%a2

        tst.l   (%sp)
        bne.s   .Lsg_draw
        cmp.l   sg_sig,%d4
        bne.s   .Lsg_draw
        bsr     sg_sum
        cmp.l   sg_psum,%d0
        bne.s   .Lsg_draw
        bra     .Lsg_done
.Lsg_draw:
        move.l  %d4,sg_sig
        clr.l   sg_fband                | (no readout rows yet, build 97)
        clr.l   sg_tnc                  | no names at the panel's edge until the timeline notes them
        moveq   #SG_WSC,%d0             | the scale window: the whole screen (build 83)
        cmp.l   sg_win,%d0
        bne.s   1f
        bsr     sg_sdraw
        bra     .Lsg_fin
1:      tst.l   sg_full                 | the pitch view: the whole screen (build 109)
        beq.s   1f
        tst.l   sg_pv
        beq.s   1f
        tst.l   sg_win
        bne.s   1f
        bsr     sg_pdraw
        bra     .Lsg_fin
1:
        moveq   #0,%d0                  | clear the whole area, the bottom bar's rows too
        moveq   #1,%d1
        moveq   #127,%d2
        moveq   #63,%d3
        bsr     sg_clr
        tst.l   sg_full                 | (none in the full view, build 92)
        bne.s   2f
        moveq   #58,%d0                 | the divider, from the top (build 73; under the first row in
        moveq   #1,%d1                  | 60-72)
        moveq   #58,%d2
        moveq   #63,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
2:

        move.l  sg_win,%d0              | our window over the grid (build 82; the step's window, build
        beq.s   0f                      | 90, after the panel instead)
        moveq   #SG_WST,%d1
        cmp.l   %d1,%d0
        bne     .Lsg_wn
0:
        tst.l   sg_kb
        bne     .Lsg_kb
        tst.l   sg_nlay
        bne     .Lsg_tlx
        bsr     sg_pbar                 | (the full 4-page grid's pattern bar, build 113)
        moveq   #0,%d7                  | the grid, row by row: a track (8-track window) or a page of
.Lsg_t:                                 | the cursor's track (4-page window)
        move.l  %d7,%d1
        movea.l %a5,%a6                 | a6: the row's first step
        tst.l   sg_view
        beq.s   1f
        move.l  sg_row,%d1              | the 4-page window: row (r + the scroll) x the steps a row (build
        move.l  %d7,%d0                 | 84: zoomed; 16 a row before, and rows 5-8 the next pattern's,
        add.l   sg_zs,%d0               | which the timeline took over in build 71)
        move.l  sg_zn,%d2
        muls.l  %d2,%d0
        movea.l %d0,%a6
1:      bsr     sg_trk                  | a3 record, d6 length, d5 step playing
        bsr     sg_fpcs                 | (the full view's play column, build 94)
        move.l  sg_rs,%d0               | a4: the row's top, 7 + stride (r + 1) - height: the steps sit
        muls.l  %d7,%d0                 | at the foot of their 7-px row (or pair of rows), the play line
        add.l   sg_rs,%d0               | on the row's last line right under them (build 73)
        sub.l   sg_rh,%d0
        addq.l  #7,%d0
        movea.l %d0,%a4
        bsr     sg_fbof                 | (under the pattern's bar, build 113; by sg_frow, centred,
        tst.l   %d0                     | build 114)
        beq.s   .Lsg_a4n
        move.l  %d7,%d0
        bsr     sg_frow
        movea.l %d0,%a4
.Lsg_a4n:
        clr.l   sg_half
        tst.l   sg_full                 | (no numbers in the full view, build 92; the 8-track window's
        beq.s   0f                      | label, build 99)
        tst.l   sg_view
        bne.s   2f
        bsr     sg_flab
2:      bsr     sg_f2l                  | (its first line 3 rows up: the second under it, build 93)
        beq     1f
        subq.l  #3,%a4
        bra     1f
0:
        lea     sg_b2,%a1               | its number (the track, or the page) at x 45, its foot on the steps';
        moveq   #49,%d1                 | M for a muted track in the 8-track window (0x8000000c bit 8 + t,
        add.l   %d7,%d1                 | as FUNC + a track key and the arranger set it)
        tst.l   sg_view                 | the 4-page window: the page's number on the row a page starts, a
        beq.s   5f                      | blank on the rest (build 84, zoomed)
        moveq   #32,%d1
        moveq   #15,%d0
        move.l  %a6,%d2
        and.l   %d2,%d0
        bne.s   5f
        lsr.l   #4,%d2
        moveq   #49,%d1
        add.l   %d2,%d1
5:      move.l  %d7,%d2                 | muted: the number and M in turn, with the blink (build 75; M
        tst.l   sg_view                 | alone in the 8-track window before); the 4-page window's
        beq.s   4f                      | page numbers likewise for the cursor's track
        move.l  sg_row,%d2
4:      move.l  sg_mm,%d0
        btst    %d2,%d0
        beq.s   6f
        moveq   #32,%d0                 | (bit 5: slower, with the pattern's flash; build 76)
        and.l   sg_mbk,%d0
        beq.s   6f
        moveq   #32,%d0
        cmp.l   %d0,%d1                 | (a blank stays blank)
        beq.s   6f
        moveq   #77,%d1                 | "M"
6:      move.b  %d1,(%a1)
        clr.b   1(%a1)
        lea     SG_SMALL,%a0
        moveq   #60,%d0
        moveq   #64,%d1
        sub.l   %a4,%d1
        sub.l   sg_rh,%d1               | y = 63 - (top + height - 1)
        moveq   #0,%d2
        bsr     sg_tx
        tst.l   sg_view                 | the 8-track window: the active track's number inverted, x 59-63,
        bne.s   1f                      | the glyph's rows and one round them (build 82)
        moveq   #0,%d0
        move.b  0x100b14cc,%d0
        cmp.l   %d7,%d0
        bne.s   1f
        moveq   #59,%d0
        move.l  sg_rh,%d3
        add.l   %a4,%d3                 | the foot + 1
        moveq   #-6,%d1
        add.l   %d3,%d1
        moveq   #63,%d2
        bsr     sg_inv
1:      moveq   #0,%d4                  | d4: the column
.Lsg_c:
        bsr     sg_fstep                | the step: drawn as ever (the flashing marks after it, build 76)
        cmp.l   %d6,%d3
        bge     .Lsg_cm                 | past the length: no step (the cursor's frame only)
        move.l  %d4,%d0
        bsr     sg_colx                 | d0 = x0
        move.l  %d3,%d1
        asr.l   #3,%d1
        moveq   #7,%d2
        sub.l   %d1,%d2
        move.l  sg_rh,%d1
        subq.l  #1,%d1                  | none: the foot
        btst    %d3,(0,%a3,%d2.l)
        bne.s   5f
        btst    %d3,(16,%a3,%d2.l)
        beq.s   6f
        move.l  sg_rh,%d1               | trigless: the lower half
        lsr.l   #1,%d1
        bra.s   6f
5:      movea.l %d0,%a1                 | trig: the whole height; on a muted track an x (build 75)
        move.l  sg_mm,%d0
        move.l  %d7,%d1
        tst.l   sg_view
        beq.s   7f
        move.l  sg_row,%d1
7:      btst    %d1,%d0
        beq.s   8f
        move.l  %a1,%d0
        bsr     sg_xm
        bra.s   .Lsg_pm
8:      move.l  %a1,%d0
        moveq   #0,%d1
6:      add.l   %a4,%d1
        move.l  %d0,%d2
        add.l   sg_zbw,%d2              | 3 px wide (the pitch less one, build 84)
        move.l  sg_rh,%d3
        subq.l  #1,%d3
        add.l   %a4,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
.Lsg_pm:                                | the step playing (build 76): inverted in the blink's off phase
        bsr     sg_selc                 | (first, the run marked: its steps inverted, build 82)
        tst.l   sg_full                 | (the full view: the column sg_fpc, build 94)
        beq.s   .Lsg_pmn
        move.l  %a6,%d3
        add.l   %d4,%d3
        cmp.l   sg_fpc,%d3
        bne.s   .Lsg_cm
        bsr     sg_mark
        bra.s   .Lsg_cm
.Lsg_pmn:
        move.l  %a6,%d3
        add.l   %d4,%d3
        cmp.l   %d5,%d3
        bne.s   .Lsg_cm
        bsr     sg_mark                 | the cursor's filled box, steady (build 77: no blink)
.Lsg_cm:                                | the cursor (build 76): a frame round its step, the on phase
        bsr     sg_fstep
        bsr     sg_gcur
        beq.s   .Lsg_ph
        bsr     sg_fcur1                | (the full view: its first column only, build 98)
        beq.s   .Lsg_ph
        moveq   #32,%d0
        and.l   sg_bk,%d0
        bne.s   .Lsg_ph
        bsr     sg_mark
.Lsg_ph:
.Lsg_nc:
        addq.l  #1,%d4
        cmp.l   sg_zn,%d4               | (16 columns, or the zoom's, build 84)
        blt     .Lsg_c
        tst.l   sg_half                 | the full 8-track window's 64: steps 33-64 on a second line, 3
        bne.s   0f                      | rows down (build 93)
        bsr     sg_f2l
        beq.s   0f
        moveq   #1,%d0
        move.l  %d0,sg_half
        lea     32(%a6),%a6
        addq.l  #3,%a4
        moveq   #0,%d4
        bra     .Lsg_c
0:
        tst.l   sg_full                 | (not in the full view, build 92)
        bne.s   2f
        moveq   #4,%d0                  | the notes' lengths over the row (build 64; not zoomed, 84)
        cmp.l   sg_zp,%d0
        bne.s   2f
        move.l  %d7,%d1
        tst.l   sg_view
        beq.s   1f
        move.l  sg_row,%d1
1:      bsr     sg_tail
2:      addq.l  #1,%d7
        moveq   #8,%d0                  | 8 rows, or the 4-page window's (4; zoomed 1-8, build 84)
        tst.l   sg_view
        beq.s   1f
        move.l  sg_zr,%d0
1:      cmp.l   %d0,%d7
        blt     .Lsg_t
        tst.l   sg_nlay                 | a dotted line between the two patterns (row 36)
        beq.s   1f
        move.l  sg_gx,%d7
2:      move.l  %d7,%d0
        moveq   #36,%d1
        move.l  %d7,%d2
        moveq   #36,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
        addq.l  #2,%d7
        moveq   #126,%d0
        cmp.l   %d0,%d7
        ble.s   2b
1:

        moveq   #59,%d0                 | the frame's top line over the "1": its text cell (a row above
        moveq   #0,%d1                  | the glyph) cleared it
        moveq   #63,%d2
        moveq   #0,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1

        bra     .Lsg_ncur               | (the cursor: its step flashes in the columns, build 73)
.Lsg_tlx:                               | the timeline (build 71): 8 rows, a page each -- the page playing
        moveq   #0,%d7                  | at the top (stopped, sg_ttop), the pages after it down the rows
.Lsg_tr:                                | (sg_tl), a dotted line over a new arrangement row. Zoomed (build
        move.l  %d7,%d0                 | 84) a page is a segment of sg_tcn columns: sg_tm segments to a
        lsl.l   #4,%d0                  | page (zoomed in, a page over 2 or 4 rows), sg_tpk pages to a row
        lea     sg_tl,%a0               | (zoomed out, 2 or 4 pages side by side); d7 = the page
        adda.l  %d0,%a0
        btst    #3,15(%a0)              | the full view's readout row (build 95)
        beq.s   .Lsg_tni
        bsr     sg_tinfo
        bra     .Lsg_tn
.Lsg_tni:
        tst.l   (%a0)
        beq     .Lsg_tn
        move.l  %a0,sg_tsl
        move.w  12(%a0),%d0             | its row's offset: the count from it (build 100)
        ext.l   %d0
        bsr     sg_trrow
        move.l  sg_trof,%d0
        move.l  %d0,sg_tof
        movea.l sg_tsl,%a0
        move.l  %a2,-(%sp)
        movea.l (%a0),%a2
        move.l  sg_row,%d1
        bsr     sg_trk                  | a3: the cursor track's record in the row's pattern, d6 its length
        movea.l (%sp)+,%a2
        clr.l   sg_tseg
.Lsg_tsg:                               | segment sg_tseg of page d7: q = d7 m + s, its row q / k, its slot
        move.l  %d7,%d0                 | q mod k
        move.l  sg_tm,%d1
        muls.l  %d1,%d0
        add.l   sg_tseg,%d0             | q
        move.l  sg_tpk,%d1
        move.l  %d0,%d2
        divu.l  %d1,%d2                 | the row
        move.l  %d2,%d3
        muls.l  %d1,%d3
        sub.l   %d3,%d0                 | the slot
        move.l  sg_tcn,%d1
        muls.l  %d1,%d0
        move.l  %d0,sg_tsc0             | its first screen column: slot x sg_tcn
        add.l   %d1,%d0
        move.l  %d0,sg_tce              | and past its last
        move.l  sg_tseg,%d0
        muls.l  %d1,%d0                 | the page's column there: s x sg_tcn
        sub.l   sg_tsc0,%d0
        move.l  %d0,sg_tdc              | page column = screen column + sg_tdc
        move.l  sg_tp,%d0               | a4: the row's top, 7 r + 14 - the height (its foot 7 r + 13;
        muls.l  %d2,%d0                 | 7 r + 10 before build 101; the pitch sg_tp, build 107)
        addi.l  #14,%d0
        sub.l   sg_rh,%d0
        movea.l %d0,%a4
        tst.l   sg_tseg                 | the dotted line over a new arrangement row, 2 rows over the steps,
        bne     2f                      | across its first segment
        movea.l sg_tsl,%a0
        btst    #0,15(%a0)
        beq.s   2f
        move.l  sg_tce,%d0
        bsr     sg_colx
        move.l  %d0,%d5                 | d5: past its end
        move.l  sg_tsc0,%d0
        bsr     sg_colx
        move.l  %d0,%d4
        move.l  %a4,%d3
        subq.l  #2,%d3
1:      move.l  %d4,%d0
        move.l  %d3,%d1
        move.l  %d4,%d2
        lea     SG_FILL,%a0
        bsr     sg_r1
        addq.l  #2,%d4
        cmp.l   %d5,%d4
        blt.s   1b
        tst.l   sg_full                 | (the full view: no panel, no names; build 92)
        bne.s   2f
        tst.l   sg_tsc0                 | a row starting at the grid's left: its pattern's name noted for
        bne.s   2f                      | the panel's edge, level with it (build 89; sg_tnames)
        move.l  sg_tnc,%d0
        moveq   #8,%d1
        cmp.l   %d1,%d0
        bge.s   2f
        lsl.l   #3,%d0
        lea     sg_tnl,%a0
        adda.l  %d0,%a0
        move.l  %a4,(%a0)
        move.l  %a0,-(%sp)
        movea.l sg_tsl,%a0
        move.w  12(%a0),%d0             | the arrangement row
        ext.l   %d0
        move.l  %d0,-(%sp)
        bsr     sg_trrow
        moveq   #0,%d0
        move.b  21(%a0),%d0             | its bank << 4 | pattern, the row << 8 (build 90)
        move.l  (%sp)+,%d1
        lsl.l   #8,%d1
        or.l    %d1,%d0
        movea.l (%sp)+,%a0
        move.l  %d0,4(%a0)
        addq.l  #1,sg_tnc
2:      tst.l   sg_full                 | (none in the full view, build 92)
        bne     3f
        tst.l   sg_tseg                 | its page number at x 60, on a row's first segment
        bne     3f
        tst.l   sg_tsc0
        bne     3f
        movea.l sg_tsl,%a0              | the pattern page the row shows
        move.l  4(%a0),%d0
        move.l  %d0,%d1
        divu.l  %d6,%d1
        muls.l  %d6,%d1
        sub.l   %d1,%d0
        lsr.l   #4,%d0
        add.l   #49,%d0
        bsr     sg_tmut                 | the cursor's track muted in the row: M in turn (build 75; the
        beq.s   4f                      | row's own mutes, build 81)
        moveq   #32,%d1                 | (bit 5, build 76)
        and.l   sg_mbk,%d1
        beq.s   4f
        moveq   #77,%d0
4:      lea     sg_b2,%a1
        move.b  %d0,(%a1)
        clr.b   1(%a1)
        lea     SG_SMALL,%a0
        moveq   #60,%d0
        moveq   #64,%d1
        sub.l   %a4,%d1
        sub.l   sg_rh,%d1
        moveq   #0,%d2
        bsr     sg_tx
3:      move.l  sg_tsc0,%d4             | d4: the screen column
.Lsg_tc:
        movea.l sg_tsl,%a0
        move.l  4(%a0),%d5
        add.l   %d4,%d5
        add.l   sg_tdc,%d5              | d5: the row's step
        cmp.l   8(%a0),%d5
        bge     .Lsg_tcm                | past the row's end: no step (the cursor's frame only)
        move.l  %d5,%d3                 | d3: the track's step, the row's mod its length
        move.l  %d3,%d1
        divu.l  %d6,%d1
        muls.l  %d6,%d1
        sub.l   %d1,%d3
        move.l  %d4,%d0
        bsr     sg_colx
        move.l  %d3,%d1
        asr.l   #3,%d1
        moveq   #7,%d2
        sub.l   %d1,%d2
        move.l  sg_rh,%d1
        subq.l  #1,%d1                  | none: the foot
        btst    %d3,(0,%a3,%d2.l)
        bne.s   5f
        btst    %d3,(16,%a3,%d2.l)
        beq.s   6f
        move.l  sg_rh,%d1               | trigless: the lower half
        lsr.l   #1,%d1
        bra.s   6f
5:      move.l  %d0,-(%sp)              | trig: the whole height; the cursor's track muted in the row, an x
        bsr     sg_tmut
        movem.l (%sp),%d0
        addq.l  #4,%sp
        beq.s   8f
        bsr     sg_xm
        bra.s   .Lsg_tpm
8:      moveq   #0,%d1
6:      add.l   %a4,%d1
        move.l  %d0,%d2
        add.l   sg_zbw,%d2
        move.l  sg_rh,%d3
        subq.l  #1,%d3
        add.l   %a4,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
.Lsg_tpm:                               | the page playing's step playing (the count): inverted, off phase
        bsr     sg_selt                 | (first the run marked, build 84)
        movea.l sg_tsl,%a0
        btst    #1,15(%a0)
        beq.s   .Lsg_tcm
        moveq   #0,%d0
        move.w  0x800065b4,%d0
        add.l   sg_tof,%d0              | (the count runs from 0 at the offset, measured: build 100)
        cmp.l   %d0,%d5
        bne.s   .Lsg_tcm
        bsr     sg_mark                 | the cursor's filled box, steady (build 77: no blink)
.Lsg_tcm:                               | the cursor: a frame round its step, the on phase (build 76)
        cmp.l   sg_trow,%d7
        bne.s   .Lsg_tcn
        move.l  %d4,%d0
        add.l   sg_tdc,%d0
        cmp.l   sg_tcol,%d0
        bne.s   .Lsg_tcn
        bsr     sg_cvis
        beq.s   .Lsg_tcn
        moveq   #32,%d0
        and.l   sg_bk,%d0
        bne.s   .Lsg_tcn
        bsr     sg_mark
.Lsg_tcn:
        addq.l  #1,%d4
        cmp.l   sg_tce,%d4
        blt     .Lsg_tc
        moveq   #4,%d0                  | the notes' lengths (not zoomed, build 84): the row's steps as one
        cmp.l   sg_zp,%d0               | run, each the track's step mod its length (sg_tnote, sg_tlen)
        bne.s   1f
        movea.l sg_tsl,%a0
        move.l  %d6,sg_tmod
        move.l  %d6,-(%sp)
        movea.l 4(%a0),%a6
        move.l  8(%a0),%d6
        move.l  sg_row,%d1
        bsr     sg_tail
        clr.l   sg_tmod
        move.l  (%sp)+,%d6
1:      addq.l  #1,sg_tseg              | the page's next segment
        move.l  sg_tseg,%d0
        cmp.l   sg_tm,%d0
        blt     .Lsg_tsg
.Lsg_tn:
        addq.l  #1,%d7
        cmp.l   sg_tne,%d7
        blt     .Lsg_tr
        moveq   #59,%d0                 | the frame's top line over the numbers
        moveq   #0,%d1
        moveq   #63,%d2
        moveq   #0,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
        bra     .Lsg_ncur               | (the cursor: its step flashes in the columns, build 73)
.Lsg_kb:                                | the name's keyboard over the grid: characters 32-95, rows 1-8
        moveq   #0,%d7                  | of the screen's nine, eight a row 8 px apart from x 50
1:      lea     sg_b2,%a1
        moveq   #32,%d0
        add.l   %d7,%d0
        move.b  %d0,(%a1)
        clr.b   1(%a1)
        moveq   #7,%d0
        and.l   %d7,%d0
        lsl.l   #3,%d0
        add.l   #59,%d0                 | x
        move.l  %d7,%d1
        lsr.l   #3,%d1
        move.l  %d1,%d2
        lsl.l   #3,%d2
        sub.l   %d1,%d2                 | 7 row
        moveq   #50,%d1
        sub.l   %d2,%d1                 | y: the row's glyph rows, as the panel's lines
        moveq   #0,%d2
        cmp.l   sg_ksel,%d7
        bne.s   2f
        moveq   #1,%d2
2:      lea     SG_SMALL,%a0
        bsr     sg_tx
        addq.l  #1,%d7
        moveq   #64,%d0
        cmp.l   %d0,%d7
        blt.s   1b
.Lsg_wn: bsr     sg_wdraw
.Lsg_ncur:
        tst.l   sg_full                 | the full view: its title row instead of the panel (build 92)
        beq.s   0f
        bsr     sg_fdots
        bsr     sg_fhdr
        bra.s   1f
0:      bsr     sg_panel
        bsr     sg_tnames               | (after the panel: they are on its edge, build 89)
1:
        moveq   #0,%d0                  | the frame's top line across the whole screen (build 91: the
        moveq   #0,%d1                  | stock's x 8-119 since the strips went in 82; last, as the top
        moveq   #127,%d2                | line's text cells clear row 0)
        moveq   #0,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
        bsr     sg_stdraw               | the step's window over it all (build 90)
.Lsg_fin:
        bsr     sg_dsave
        bsr     sg_sum
        move.l  %d0,sg_psum
        moveq   #1,%d0                  | the screen changed: the UI loop sends the plane to the panel
        move.l  %d0,0x46c7c72c          | (0x40062d1c; every stock drawer sets it, build 49 did not)
.Lsg_done:
        movem.l (%sp),%d1-%d7/%a2-%a6
        lea     48(%sp),%sp
        rts

| d3 = a step, d7 = the grid's row: Z clear when it is the cursor's step (build 73): the 8-track
| window, the cursor's track and step (its page in view); the 4-page window, its step in one of the
| first four rows (rows 5-8 are the next pattern's); not while hidden (sg_cvis). Uses d0 d1.
sg_gcur:
        cmp.l   sg_step,%d3
        bne.s   8f
        bsr     sg_cvis
        beq.s   8f
        tst.l   sg_view                 | (the 4-page window: any of its rows, build 84)
        bne.s   9f
        cmp.l   sg_row,%d7
        bne.s   8f
9:      moveq   #1,%d0
        rts
8:      moveq   #0,%d0
        rts

| A muted track's note trig (build 123; an x 75-122): the step drawn as a trig in the blink's M phase
| (sg_bk bit 5, as the track's M) and as an empty step (its foot line) in the other -- in every window
| and zoom. a4 the row's top, sg_rh its height, d0 = x0. Uses d0 d1 a0 a1; keeps d2 d3.
sg_xm:
        lea     -8(%sp),%sp
        movem.l %d2-%d3,(%sp)
        move.l  sg_rh,%d1
        subq.l  #1,%d1                  | the foot
        moveq   #32,%d2
        and.l   sg_mbk,%d2
        beq.s   1f
        moveq   #0,%d1                  | the M phase: the whole height
1:      add.l   %a4,%d1
        move.l  %d0,%d2
        add.l   sg_zbw,%d2
        move.l  sg_rh,%d3
        subq.l  #1,%d3
        add.l   %a4,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
        movem.l (%sp),%d2-%d3
        addq.l  #8,%sp
        rts
sg_xp2:                                 | columns x0 (d0) and x0 + 2 of row d1
        move.l  %d4,-(%sp)
        move.l  %d1,-(%sp)
        move.l  %d0,%d4
        bsr     sg_xp
        move.l  %d4,%d0
        addq.l  #2,%d0
        move.l  (%sp),%d1
        bsr     sg_xp
        addq.l  #4,%sp
        move.l  (%sp)+,%d4
        rts
sg_xp:                                  | one pixel: d0 x, d1 row; keeps d2 d3
        lea     -8(%sp),%sp
        movem.l %d2-%d3,(%sp)
        move.l  %d0,%d2
        move.l  %d1,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
        movem.l (%sp),%d2-%d3
        addq.l  #8,%sp
        rts

| The cursor's and the step playing's mark (build 77): the step's cell and a pixel round it (x0 - 1
| .. x0 + 3, the row's top - 1 .. its foot + 1) filled solid in the on phase; the step shows in the
| off phase. d4 = the column, a4 = the row's top. Uses d0 d1 a0 a1.
sg_mark:
        lea     -8(%sp),%sp
        movem.l %d2-%d3,(%sp)
        move.l  %d4,%d0
        bsr     sg_colx
        subq.l  #1,%d0
        move.l  %a4,%d1
        subq.l  #1,%d1
        move.l  %d0,%d2
        add.l   sg_zp,%d2               | x0 - 1 .. x0 + 3 (the pitch less one, build 84)
        move.l  sg_rh,%d3
        add.l   %a4,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
        movem.l (%sp),%d2-%d3
        addq.l  #8,%sp
        rts

| Playing: the play triangle, 3 x 5 px, rows 9-13 (line 1), from x d0 (build 73 left of the pattern
| playing; over line 2's countdown or infinity since 76). Uses d0 d1 a0 a1.
sg_ptri:
        tst.l   0x800065b8
        beq.s   9f
        lea     -12(%sp),%sp
        movem.l %d2-%d4,(%sp)
        move.l  %d0,%d4
        moveq   #9,%d1
        move.l  %d4,%d2
        moveq   #13,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
        addq.l  #1,%d4
        move.l  %d4,%d0
        moveq   #10,%d1
        move.l  %d4,%d2
        moveq   #12,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
        addq.l  #1,%d4
        move.l  %d4,%d0
        moveq   #11,%d1
        move.l  %d4,%d2
        moveq   #11,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
        movem.l (%sp),%d2-%d4
        lea     12(%sp),%sp
9:      rts

| The timeline row being drawn (sg_tsl): Z clear when the cursor's track is muted in it (build 81):
| the row playing, as the engine plays it (sg_mm: mutes, the arranger's, solo); any other row, or
| stopped, its arrangement row's MIDI mutes (+ 5 from the row's + 20, which the arranger copies to
| 0x46c78d6a when the row starts, 0x4004a16e). Uses d1 d2 a1.
| The panel's M (build 101): d0.w = "M" (0x4d00), or a space in the blink's off phase while a track is
| muted -- the engine's mutes (sg_mm) or, arranging, the row playing's own (+24, a word). Uses d0 d1 a0.
sg_mch:
        moveq   #0,%d1
        tst.l   0x460d1aec
        beq.s   1f
        move.l  sg_prow,%d0
        bmi.s   1f
        movea.l 0x10000000,%a0
        moveq   #0,%d1
        move.w  18(%a0),%d1
        cmp.l   %d1,%d0
        bge.s   0f
        moveq   #22,%d1
        muls.l  %d0,%d1
        adda.l  %d1,%a0
        moveq   #0,%d1
        move.w  24(%a0),%d1
        bra.s   1f
0:      moveq   #0,%d1
1:      or.l    sg_mm,%d1
        beq.s   2f
        moveq   #32,%d1
        and.l   sg_mbk,%d1
        beq.s   2f
        move.l  #0x2000,%d0
        rts
2:      move.l  #0x4d00,%d0
        rts

sg_tmut:
        movea.l sg_tsl,%a1
        tst.l   0x800065b8
        beq.s   1f
        btst    #1,15(%a1)
        beq.s   1f
        move.l  sg_mm,%d1
        bra.s   2f
1:      moveq   #0,%d2
        move.w  12(%a1),%d2             | its arrangement row
        moveq   #22,%d1
        muls.l  %d2,%d1
        movea.l 0x10000000,%a1
        adda.l  %d1,%a1
        moveq   #0,%d1
        move.b  25(%a1),%d1
2:      move.l  sg_row,%d2
        btst    %d2,%d1
        rts

| Z clear when the cursor is shown (build 74): stopped, or the panel open, or a touch in the last
| 1.5 s (SG_IDLE); playing hands off the steps playing flash instead. Uses d1.
sg_cvis:
        tst.l   0x800065b8
        beq.s   9f
        tst.l   sg_mode
        bne.s   9f
        moveq   #SG_IDLE,%d1
        cmp.l   sg_idle,%d1
        bgt.s   9f
        moveq   #0,%d1
        rts
9:      moveq   #1,%d1
        rts

| STOP (build 74): playing, the cursor track's step playing (and the timeline's count) kept each tick;
| when the transport stops the cursor goes to that step (the timeline's to its column on the first
| row); STOP pressed again while stopped, to step 1. Uses d0 d1 a0 a1.
sg_stopk:
        lea     -16(%sp),%sp
        movem.l %d5-%d6/%a2-%a3,(%sp)
        tst.l   0x800065b8
        beq.s   2f
        movea.l 0x46c82456,%a2
        moveq   #0,%d0
        move.b  0x100b14d0,%d0
        move.l  #0x8ed8,%d1
        muls.l  %d1,%d0
        adda.l  %d0,%a2
        move.l  sg_row,%d1
        bsr     sg_trk
        move.l  %d5,sg_lps
        moveq   #0,%d0
        move.w  0x800065b4,%d0
        move.l  %d0,sg_lcnt
        moveq   #1,%d0
        move.l  %d0,sg_wasp
        move.l  sg_tpl,%d0              | the timeline's page playing, kept here for the stop (build
        move.l  %d0,sg_tps              | 100: sg_tupd stopped clears its own before this sees the
        move.l  sg_tpl+4,%d0            | stop when it runs first)
        move.l  %d0,sg_tps+4
        move.l  sg_tpl+8,%d0
        move.l  %d0,sg_tps+8
        move.l  sg_tplv,%d0
        move.l  %d0,sg_tpsv
        bra     8f
2:      tst.l   sg_wasp
        beq.s   3f
        clr.l   sg_wasp                 | just stopped: the cursor where it stopped
        move.l  sg_lps,%d0
        bmi.s   8f
        move.l  %d0,sg_step
        move.l  %d0,sg_fws              | (the full view: the window it stopped in, kept until the
        move.l  sg_lcnt,%d0             | cursor moves; the timeline: its page, sg_tupd; build 98)
        move.l  %d0,sg_fsc
        moveq   #1,%d0
        move.l  %d0,sg_fwv
        move.l  %d0,sg_tstop
        moveq   #15,%d0
        and.l   sg_lcnt,%d0
        move.l  %d0,sg_tcol
        clr.l   sg_trow
        clr.l   sg_bk
        bra.s   8f
3:      tst.l   SG_HELD+0x27*24         | STOP down while stopped: step 1
        beq.s   8f
        tst.l   SG_HELD+0x2d*24         | (not FUNC + STOP: PASTE, build 82)
        bne.s   8f
        tst.l   sg_stk
        bne.s   8f
        clr.l   sg_step
        clr.l   sg_tcol
        clr.l   sg_trow
        clr.l   sg_bk
        moveq   #1,%d0                  | (the timeline back to its first row, build 100)
        move.l  %d0,sg_tbeg
8:      move.l  SG_HELD+0x27*24,%d0
        move.l  %d0,sg_stk
        movem.l (%sp),%d5-%d6/%a2-%a3
        lea     16(%sp),%sp
        rts

| A row's note lengths (build 64): from the top row of a note trig's bar a 1-px line runs right as far
| as its LEN reaches -- LEN is in 1/96 notes, so 6 a step: a column's 3 px are 2 units each, the step's
| own bar the first 6; INF to the next note -- stopping short of the next note trig (a gap of the
| columns' spacing before it) and of the track's end. A note on an earlier page that reaches into the
| row starts its line at the row's left. LEN: the step's lock, else the Part's NOTE page value. a3 =
| the record, d6 = its length, a6 = the row's first step, a4 = the row's top, d1 = the track. Uses d0
| d1 a0 a1.
sg_tail:
        tst.l   sg_aud                  | (none in AUDIO, build 110)
        bne.s   1f
        tst.l   sg_lhide                | hidden (YES on LEN in the panel, build 67)
        beq.s   0f
1:      rts
0:      lea     -32(%sp),%sp
        movem.l %d2-%d7/%a2/%a5,(%sp)
        movea.l 0x46c82456,%a5          | a5: the Part's page-1 record for the track (LEN at + 2)
        moveq   #0,%d0
        move.b  0x100b14cf,%d0
        move.l  #0x18b2,%d2
        muls.l  %d2,%d0
        adda.l  %d0,%a5
        lsl.l   #5,%d1
        adda.l  %d1,%a5
        adda.l  #0x8f162,%a5
        move.l  %a6,%d5                 | the last note before the row
1:      subq.l  #1,%d5
        bmi.s   3f
        cmp.l   %d6,%d5
        bge.s   1b
        move.l  %d5,%d0
        bsr     sg_tnote
        beq.s   1b
        bsr     sg_tdraw
3:      moveq   #0,%d4                  | then each note in the row
4:      move.l  %a6,%d5
        add.l   %d4,%d5
        cmp.l   %d6,%d5
        bge.s   9f
        move.l  %d5,%d0
        bsr     sg_tnote
        beq.s   5f
        bsr     sg_tdraw
5:      addq.l  #1,%d4
        moveq   #16,%d0
        cmp.l   %d0,%d4
        blt.s   4b
9:      movem.l (%sp),%d2-%d7/%a2/%a5
        lea     32(%sp),%sp
        rts

| d5 = a note's step: its line (sg_tail's registers). Uses d0-d3 d7 a0 a1.
sg_tdraw:
        move.l  %d5,%d0
        bsr     sg_tlen                 | its length in sixths of a step
        move.l  %d5,%d3
        moveq   #6,%d1
        muls.l  %d1,%d3
        add.l   %d0,%d3                 | d3: where it ends, in sixths
        move.l  %d5,%d2                 | the next note, or the track's end
1:      addq.l  #1,%d2
        cmp.l   %d6,%d2
        bge.s   2f
        move.l  %d2,%d0
        bsr     sg_tnote
        beq.s   1b
2:      moveq   #6,%d0
        muls.l  %d0,%d2
        cmp.l   %d2,%d3
        ble.s   3f
        move.l  %d2,%d3
3:      move.l  %a6,%d7                 | d7: the row's first step in sixths
        moveq   #6,%d0
        muls.l  %d0,%d7
        cmp.l   %d7,%d3
        ble     9f                      | ends before the row
        moveq   #96,%d0
        add.l   %d7,%d0                 | the row's end
        cmp.l   %d0,%d3
        blt.s   4f
        moveq   #15,%d0                 | past it: to the last column's end
        bsr     sg_colx
        addq.l  #2,%d0
        move.l  %d0,%d2
        bra.s   6f
4:      sub.l   %d7,%d3                 | in the row: column k, r sixths into it
        move.l  %d3,%d2
        moveq   #6,%d0
        divu.l  %d0,%d2                 | k
        move.l  %d2,%d1
        muls.l  %d0,%d1
        sub.l   %d1,%d3                 | r
        bne.s   5f
        move.l  %d2,%d0                 | r = 0: the end of column k - 1
        subq.l  #1,%d0
        bsr     sg_colx
        addq.l  #2,%d0
        move.l  %d0,%d2
        bra.s   6f
5:      move.l  %d2,%d0                 | else (r + 1) / 2 px of column k
        bsr     sg_colx
        addq.l  #1,%d3
        asr.l   #1,%d3
        add.l   %d3,%d0
        subq.l  #1,%d0
        move.l  %d0,%d2
6:      move.l  %d5,%d0                 | d2: x1. x0: right of its bar, or the row's left
        sub.l   %a6,%d0
        bmi.s   7f
        bsr     sg_colx
        addq.l  #3,%d0
        bra.s   8f
7:      moveq   #0,%d0
        bsr     sg_colx
8:      cmp.l   %d0,%d2
        blt.s   9f
        move.l  %a4,%d1                 | the bar's top row only (build 65; two rows in 64)
        move.l  %a4,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
9:      rts

| d0 = step: Z clear when it has a note trig (a3 = the record). Uses d0 d1.
sg_tnote:
        move.l  sg_tmod,%d1             | the timeline: the track's step, mod its length (build 71)
        beq.s   1f
        move.l  %d2,-(%sp)
        move.l  %d0,%d2
        divu.l  %d1,%d2
        muls.l  %d1,%d2
        sub.l   %d2,%d0
        move.l  (%sp)+,%d2
1:      move.l  %d0,%d1
        asr.l   #3,%d1
        neg.l   %d1
        addq.l  #7,%d1
        btst    %d0,(0,%a3,%d1.l)
        rts

| d0 = step: d0 = its note's LEN, sixths of a step (1/96 notes); INF 768 (a3 = the record, a5 = the Part's
| page-1 record). Uses d0 d1.
sg_tlen:
        move.l  sg_tmod,%d1             | the timeline: the track's step (build 71)
        beq.s   0f
        move.l  %d2,-(%sp)
        move.l  %d0,%d2
        divu.l  %d1,%d2
        muls.l  %d1,%d2
        sub.l   %d2,%d0
        move.l  (%sp)+,%d2
0:      lsl.l   #5,%d0
        moveq   #0,%d1
        move.b  (0x32,%a3,%d0.l),%d1    | the step's LEN lock (+0x30 + 32 step + slot 2)
        cmpi.l  #0xff,%d1
        bne.s   1f
        move.b  2(%a5),%d1              | none: the Part's
1:      move.l  %d1,%d0
        cmpi.l  #127,%d0
        blt.s   2f
        move.l  #768,%d0                | INF
2:      rts

| ---- THE TIMELINE (build 71). In the 4-page window while arranging the rows are the arrangement's
|      pages in time, a page a row: the page playing at the top (stopped: where the window was put),
|      then the pages after it -- the rest of its row, the row's repetitions, the next rows through the
|      arranger's resolver (LOOP / JUMP / REM). A position is (row, pass, page): d2 the arrangement row,
|      d3 its pass (0 .. +2, its repetitions), d4 the page in it (16 steps; a row has LEN / 16 pages,
|      rounded up). A row's step is its pattern's track step mod the track's length. The cursor is a
|      row of the window and a column (sg_trow, sg_tcol); its step and pattern follow (sg_tsync), and
|      LEVEL, the lock store, YES work there (sg_sel, sg_cpat): another pattern of the current bank is
|      edited as the current one (its bank and CS1 copies), another bank's is not (sg_cedit).

| d0 = 1 (Z clear) in the timeline: the 4-page window while arranging. Uses d0.
sg_tlon:
        moveq   #0,%d0
        tst.l   sg_view
        beq.s   1f
        tst.l   sg_pv                   | (not the pitch view: LEVEL there went to the hidden timeline
        bne.s   1f                      | with the arranger on, build 124)
        tst.l   0x460d1aec
        beq.s   1f
        moveq   #1,%d0
1:      tst.l   %d0
        rts

| d0 = an arrangement row: a0 = the row's record + 22 row (its bytes from + 20), d0 = its pattern's
| address (0: past the end, or not a pattern row), d1 = its LEN in steps (+12, the end: the offset plus
| the length; 0: the pattern's length), sg_trof its offset (+10; build 100). Uses d0 d1 a0.
sg_trrow:
        clr.l   sg_trof
        movea.l 0x10000000,%a0
        tst.l   %d0
        bmi.s   8f
        moveq   #0,%d1
        move.w  18(%a0),%d1
        cmp.l   %d1,%d0
        bge.s   8f
        moveq   #22,%d1
        muls.l  %d0,%d1
        adda.l  %d1,%a0
        tst.b   20(%a0)
        bne.s   8f
        move.l  %d2,-(%sp)
        moveq   #0,%d0
        move.b  21(%a0),%d0
        moveq   #15,%d1
        and.l   %d0,%d1
        lsr.l   #4,%d0
        move.l  #0x9b340,%d2
        muls.l  %d2,%d0                 | the bank
        move.l  #0x8ed8,%d2
        muls.l  %d2,%d1                 | the pattern
        add.l   %d1,%d0
        add.l   #0x400e21e0,%d0
        moveq   #0,%d1                  | (its offset, +10: sg_trof, build 100)
        move.w  30(%a0),%d1
        move.l  %d1,sg_trof
        moveq   #0,%d1
        move.w  32(%a0),%d1             | LEN
        bgt.s   1f
        move.l  %a2,-(%sp)
        movea.l %d0,%a2
        move.l  %d0,%d2
        bsr     sg_plen
        move.l  %d0,%d1
        move.l  %d2,%d0
        movea.l (%sp)+,%a2
1:      move.l  (%sp)+,%d2
        rts
8:      moveq   #0,%d0
        moveq   #0,%d1
        rts

| d0 = an arrangement row: d0 = the playable row after it, -1 none. After the row playing as sg_nxt
| (the arranger's row once it has moved on, or the row asked for); else the next, through the
| arranger's resolver (0x4009aed0). Uses d0 d1 a0 a1.
sg_tnr:
        move.l  %d0,%d1
        cmp.l   sg_prow,%d1
        bne.s   2f
        tst.l   0x800065b8
        beq.s   2f
        move.l  0x80006698,%d0
        cmp.l   %d0,%d1
        bne.s   3f                      | moved on: that row
        move.l  0x8000669c,%d0
        bpl.s   4f                      | asked for
2:      addq.l  #1,%d1
        move.l  %d1,%d0
4:      tst.l   %d0
        bmi.s   8f
        movea.l 0x10000000,%a0
        moveq   #0,%d1
        move.w  18(%a0),%d1
        cmp.l   %d1,%d0
        bge.s   8f
        move.l  %d0,-(%sp)
        jsr     0x4009aed0
        addq.l  #4,%sp
3:      tst.l   %d0
        bmi.s   8f
        movea.l 0x10000000,%a0
        moveq   #0,%d1
        move.w  18(%a0),%d1
        cmp.l   %d1,%d0
        bge.s   8f
        rts
8:      moveq   #-1,%d0
        rts

| One page on from (d2, d3, d4): d0 = 0 (Z) where the arrangement ends (d2-d4 kept). Uses d0 d1 a0 a1.
sg_tfwd:
        move.l  %d2,%d0
        bsr     sg_trrow
        sub.l   sg_trof,%d1             | (its LN steps from the offset, build 100)
        moveq   #15,%d0
        add.l   %d0,%d1
        lsr.l   #4,%d1                  | its pages
        move.l  %d4,%d0
        addq.l  #1,%d0
        cmp.l   %d1,%d0
        bge.s   1f
        move.l  %d0,%d4                 | the row's next page
        bra.s   9f
1:      moveq   #0,%d1                  | its next pass
        move.b  22(%a0),%d1
        cmp.l   %d1,%d3
        bge.s   2f
        addq.l  #1,%d3
        moveq   #0,%d4
        bra.s   9f
2:      move.l  %d2,%d0                 | the next row
        bsr     sg_tnr
        tst.l   %d0
        bmi.s   8f
        move.l  %d0,%d2
        moveq   #0,%d3
        moveq   #0,%d4
9:      moveq   #1,%d0
        rts
8:      moveq   #0,%d0
        rts

| One page back from (d2, d3, d4), stopped: the row's page before, its pass before, or the last page of
| the pattern row before it (by index, past LOOP / JUMP / REM rows): d0 = 0 (Z) at the start. Uses d0 d1
| a0 a1.
sg_tback:
        tst.l   %d4
        beq.s   1f
        subq.l  #1,%d4
        bra.s   9f
1:      tst.l   %d3
        beq.s   2f
        subq.l  #1,%d3
        bra.s   3f
2:      move.l  %d2,-(%sp)
5:      subq.l  #1,(%sp)
        bmi.s   7f
        move.l  (%sp),%d0
        bsr     sg_trrow
        tst.l   %d0
        beq.s   5b
        move.l  (%sp)+,%d2
        moveq   #0,%d3
        move.b  22(%a0),%d3             | its last pass
3:      move.l  %d2,%d0                 | the row's last page
        bsr     sg_trrow
        sub.l   sg_trof,%d1
        moveq   #15,%d0
        add.l   %d0,%d1
        lsr.l   #4,%d1
        subq.l  #1,%d1
        bpl.s   4f
        moveq   #0,%d1
4:      move.l  %d1,%d4
9:      moveq   #1,%d0
        rts
7:      addq.l  #4,%sp
        moveq   #0,%d0
        rts

| The page playing: d2 the row (sg_prow), d3 its pass (its repetitions, +2, less those left,
| 0x800066a4, while the arranger is still on it; its last once it has moved on), d4 the step count /
| 16 (within its pages). Uses d0 d1 a0.
sg_tnow:
        move.l  sg_prow,%d2
        move.l  %d2,%d0
        bsr     sg_trrow
        moveq   #0,%d3
        move.b  22(%a0),%d3
        cmp.l   0x80006698,%d2
        bne.s   1f
        sub.l   0x800066a4,%d3
        bpl.s   1f
        moveq   #0,%d3
1:      moveq   #0,%d4
        move.w  0x800065b4,%d4
        lsr.l   #4,%d4
        sub.l   sg_trof,%d1
        moveq   #15,%d0
        add.l   %d0,%d1
        lsr.l   #4,%d1
        subq.l  #1,%d1
        bpl.s   2f
        moveq   #0,%d1
2:      cmp.l   %d1,%d4
        ble.s   3f
        move.l  %d1,%d4
3:      rts

| sg_tl from (d2, d3, d4): 8 rows of 16 bytes -- +0 the pattern (0: blank), +4 the row's step of its first
| column (page x 16), +8 the row's steps, +12 the arrangement row (word), +14 flags (word: 1 a new
| arrangement row starts here, 2 the page playing, 4 a pad). Zoomed out (2 or 4 pages to a screen row,
| build 90) a pass's first page starts a screen row -- its pages 1 and 3 at the left, as in the 4-page
| window -- the slots before it pads (blank, flag 4, the row before's number), which the cursor passes
| over (sg_tmv); in 84-89 the pages ran on, a row's page 1 at the right half. Uses d0-d4 a0 a1.
sg_tfill:
        lea     -8(%sp),%sp
        movem.l %d5/%a2,(%sp)
        lea     sg_tl,%a2
        moveq   #0,%d5
1:      tst.l   %d5
        beq.s   5f
        tst.l   %d4
        bne.s   5f
4:      move.l  sg_tpk,%d1              | (1, 2 or 4)
        subq.l  #1,%d1
        and.l   %d5,%d1
        beq.s   5f
        clr.l   (%a2)
        move.w  -4(%a2),%d0
        move.w  %d0,12(%a2)
        moveq   #4,%d0
        move.w  %d0,14(%a2)
        lea     16(%a2),%a2
        addq.l  #1,%d5
        cmp.l   sg_tne,%d5
        bge     9f
        bra.s   4b
5:      tst.l   sg_full                 | the full view (build 95): an arrangement row's start (its first
        beq.s   6f                      | pass, first page) gets a screen row of its own first, its
        tst.l   %d3                     | readout (flag 8, sg_tinfo), the rest of that row pads
        bne.s   6f
        tst.l   %d4
        bne.s   6f
        clr.l   (%a2)
        clr.l   4(%a2)
        clr.l   8(%a2)
        move.w  %d2,12(%a2)
        moveq   #8,%d0
        move.w  %d0,14(%a2)
        lea     16(%a2),%a2
        addq.l  #1,%d5
        cmp.l   sg_tne,%d5
        bge     9f
7:      move.l  sg_tpk,%d1
        subq.l  #1,%d1
        and.l   %d5,%d1
        beq.s   6f
        clr.l   (%a2)
        move.w  -4(%a2),%d0
        move.w  %d0,12(%a2)
        moveq   #4,%d0
        move.w  %d0,14(%a2)
        lea     16(%a2),%a2
        addq.l  #1,%d5
        cmp.l   sg_tne,%d5
        bge     9f
        bra.s   7b
6:      move.l  %d2,%d0
        bsr     sg_trrow
        move.l  %d0,(%a2)
        move.l  %d4,%d0
        lsl.l   #4,%d0
        add.l   sg_trof,%d0             | (from its offset: its LN steps only, build 100)
        move.l  %d0,4(%a2)
        move.l  %d1,8(%a2)
        move.w  %d2,12(%a2)
        moveq   #0,%d0
        tst.l   %d5
        beq.s   2f
        move.w  -4(%a2),%d1
        ext.l   %d1
        cmp.l   %d2,%d1
        beq.s   2f
        moveq   #1,%d0
2:      move.w  %d0,14(%a2)
        lea     16(%a2),%a2
        addq.l  #1,%d5
        cmp.l   sg_tne,%d5              | (8 pages, or the zoom's, build 84)
        bge.s   9f
        bsr     sg_tfwd
        tst.l   %d0
        bne 1b
3:      clr.l   (%a2)                   | the rest blank
        lea     16(%a2),%a2
        addq.l  #1,%d5
        cmp.l   sg_tne,%d5
        blt.s   3b
9:      movem.l (%sp),%d5/%a2
        addq.l  #8,%sp
        rts

| The timeline now: the window's first page -- playing, the page playing (the cursor's row up a row as
| its page moves up, to the first row hands off with the panel shut); stopped, sg_ttop (from the
| arranger's row when that moves, or the timeline was entered) -- sg_tl from it, and the cursor's step
| (sg_tsync, not while a trig key's step has it, sg_tfree). Uses d0 d1 a0 a1.
sg_tupd:
        lea     -12(%sp),%sp
        movem.l %d2-%d4,(%sp)
        bsr     sg_zset
        tst.l   0x800065b8
        beq     5f
        clr.l   sg_tsv
        bsr     sg_tnow
        moveq   #2,%d1                  | a whole arrangement row in view (its 4 pages at most: a page a
        cmp.l   sg_tm,%d1               | screen row or two, or two to a screen row): the window from its
        blt.s   0f                      | first page until it has played (build 101), the page playing
        move.l  %d4,sg_tpo              | that far into it
        moveq   #0,%d4
        bra.s   .Lsg_tp0
0:      move.l  sg_tpk,%d1              | zoomed out (2 pages a screen row, build 93): the window from the
        subq.l  #1,%d1                  | first page of the screen row the page playing is on, which then
        and.l   %d4,%d1                 | plays across the row (92: the window moved on each page, the
        move.l  %d1,sg_tpo              | play line only crossing the row's first half); zoomed in to 4
        sub.l   %d1,%d4                 | a row (16 screen rows to a row) still so
.Lsg_tp0:
        tst.l   sg_tplv
        beq.s   2f
        cmp.l   sg_tpl,%d2
        bne.s   1f
        cmp.l   sg_tpl+4,%d3
        bne.s   1f
        cmp.l   sg_tpl+8,%d4
        beq.s   3f
1:      move.l  sg_trow,%d0             | a page on: the cursor up with its page (a screen row's pages
        sub.l   sg_tpk,%d0              | zoomed out, build 93; not past the first row)
        smi     %d1
        extb.l  %d1
        not.l   %d1
        and.l   %d1,%d0
        move.l  %d0,sg_trow
2:      move.l  %d2,sg_tpl
        move.l  %d3,sg_tpl+4
        move.l  %d4,sg_tpl+8
        moveq   #1,%d0
        move.l  %d0,sg_tplv
3:      moveq   #SG_IDLE,%d0
        cmp.l   sg_idle,%d0
        bgt     6f
        tst.l   sg_mode
        bne     6f
        clr.l   sg_trow
        bra     6f
5:      tst.l   sg_tbeg                 | STOP again: the window from the arrangement's first row
        beq.s   .Lsg_tb0                | (build 100)
        clr.l   sg_tbeg
        clr.l   sg_tstop
        clr.l   sg_tsfix
        moveq   #-1,%d0
        bsr     sg_tnr
        move.l  %d0,sg_ttop
        clr.l   sg_ttop+4
        clr.l   sg_ttop+8
        move.l  0x80006698,%d0
        move.l  %d0,sg_t698
        moveq   #1,%d0
        move.l  %d0,sg_tsv
        bra.s   .Lsg_ts0
.Lsg_tb0:
        tst.l   sg_tstop                | just stopped (build 98): the window stays on the screen row
        beq.s   .Lsg_ts0                | that was playing, the cursor on its page (sg_tsfix); the
        clr.l   sg_tstop                | page as sg_stopk kept it (build 100)
        tst.l   sg_tpsv
        beq.s   .Lsg_ts0
        move.l  sg_tps,%d0
        move.l  %d0,sg_ttop
        move.l  sg_tps+4,%d0
        move.l  %d0,sg_ttop+4
        move.l  sg_tps+8,%d0
        move.l  %d0,sg_ttop+8
        move.l  0x80006698,%d0
        move.l  %d0,sg_t698
        moveq   #1,%d0
        move.l  %d0,sg_tsv
        move.l  %d0,sg_tsfix
.Lsg_ts0:
        clr.l   sg_tplv
        move.l  0x80006698,%d0
        tst.l   sg_tsv
        beq.s   4f
        cmp.l   sg_t698,%d0
        beq.s   7f
4:      move.l  %d0,sg_t698
        moveq   #1,%d1
        move.l  %d1,sg_tsv
        tst.l   %d0
        bpl.s   8f
        moveq   #-1,%d0                 | not started: the first playable row
        bsr     sg_tnr
8:      move.l  %d0,sg_ttop
        clr.l   sg_ttop+4
        clr.l   sg_ttop+8
7:      move.l  sg_ttop,%d2
        move.l  sg_ttop+4,%d3
        move.l  sg_ttop+8,%d4
6:      move.l  sg_tsc,%d0              | knob E's scroll: the window that many pages further on, as far
        beq.s   11f                     | as the arrangement goes (build 84)
        move.l  %d5,-(%sp)
        move.l  %d0,%d5
        moveq   #0,%d0
        move.l  %d0,sg_tsc
12:     bsr     sg_tfwd
        tst.l   %d0
        beq.s   13f
        addq.l  #1,sg_tsc
        subq.l  #1,%d5
        bne.s   12b
13:     move.l  (%sp)+,%d5
11:     bsr     sg_tfill
        tst.l   sg_tsfix                | (just stopped: the cursor on the page that was playing)
        beq.s   .Lsg_tf0
        clr.l   sg_tsfix
        lea     sg_tl,%a0
        moveq   #0,%d0
.Lsg_tf1:
        tst.l   (%a0)
        bne.s   .Lsg_tf2
        lea     16(%a0),%a0
        addq.l  #1,%d0
        cmp.l   sg_tne,%d0
        blt.s   .Lsg_tf1
        moveq   #0,%d0
.Lsg_tf2:
        add.l   sg_tpo,%d0
        move.l  %d0,sg_trow
.Lsg_tf0:
        tst.l   0x800065b8
        beq.s   9f
        tst.l   sg_tsc                  | (scrolled on: the first row is not the page playing)
        bne.s   9f
        lea     sg_tl,%a0               | the page playing: the first row (zoomed out its place in the
        move.l  sg_tne,%d1              | first screen row, build 93; after a readout row, 95)
12:     tst.l   (%a0)
        bne.s   13f
        lea     16(%a0),%a0
        subq.l  #1,%d1
        bgt.s   12b
13:     move.l  sg_tpo,%d0
        lsl.l   #4,%d0
        adda.l  %d0,%a0
        move.w  14(%a0),%d0
        moveq   #2,%d1
        or.l    %d1,%d0
        move.w  %d0,14(%a0)
9:      tst.l   sg_tfree
        bne.s   10f
        bsr     sg_tsync
10:     movem.l (%sp),%d2-%d4
        lea     12(%sp),%sp
        rts

| The cursor's step from its row and column: sg_cpat its row's pattern (0: the current one), sg_step
| (the row's step of the column) mod the cursor track's length there. On a blank row, the last row with a
| pattern. Uses d0 d1 a0 a1.
sg_tsync:
        lea     -24(%sp),%sp
        movem.l %d2/%d5-%d6/%a2-%a4,(%sp)
        move.l  sg_trow,%d2
        move.l  %d2,%d0                 | on a readout row: the step stays (build 98)
        lsl.l   #4,%d0
        lea     sg_tl,%a4
        adda.l  %d0,%a4
        btst    #3,15(%a4)
        bne     9f
1:      move.l  %d2,%d0
        lsl.l   #4,%d0
        lea     sg_tl,%a4
        adda.l  %d0,%a4
        tst.l   (%a4)
        bne.s   2f
        subq.l  #1,%d2
        bpl.s   1b
        clr.l   sg_trow
        clr.l   sg_cpat
        bra.s   9f
2:      move.l  %d2,sg_trow
        movea.l (%a4),%a2
        move.l  sg_row,%d1
        bsr     sg_trk                  | d6: the track's length
        move.l  4(%a4),%d0
        add.l   sg_tcol,%d0
        move.l  %d0,%d1
        divu.l  %d6,%d1
        muls.l  %d6,%d1
        sub.l   %d1,%d0
        move.l  %d0,sg_step
        movea.l 0x46c82456,%a3          | the current pattern?
        moveq   #0,%d0
        move.b  0x100b14d0,%d0
        move.l  #0x8ed8,%d1
        muls.l  %d1,%d0
        adda.l  %d0,%a3
        move.l  %a2,%d0
        cmp.l   %a3,%d0
        bne.s   3f
        moveq   #0,%d0
3:      move.l  %d0,sg_cpat
9:      movem.l (%sp),%d2/%d5-%d6/%a2-%a4
        lea     24(%sp),%sp
        rts

| d0 = +1 / -1: the cursor a row down / up the timeline. Past the window's edge, stopped, the window
| moves a page (sg_ttop; not past the arrangement's ends); playing, the cursor stays (the window
| follows the page playing). A blank row is not entered. d0 = 1 when it moved. Uses d0 d1 a0 a1.
sg_tmv:
        lea     -20(%sp),%sp
        movem.l %d2-%d6,(%sp)
        clr.l   sg_tfree
        moveq   #0,%d6                  | moved
        move.l  %d0,%d5
        move.l  sg_trow,%d0
0:      add.l   %d5,%d0
        bmi.s   1f
        move.l  sg_tne,%d1              | (8 pages, or the zoom's, build 84)
        subq.l  #1,%d1
        cmp.l   %d1,%d0
        bgt.s   2f
        move.l  %d0,%d1
        lsl.l   #4,%d1
        lea     sg_tl,%a0
        adda.l  %d1,%a0
        tst.l   (%a0)
        bne.s   4f
        btst    #3,15(%a0)              | a readout (95) is a row for the cursor (build 98: its fields)
        bne.s   4f
        btst    #2,15(%a0)              | a pad (build 90): on past it
        bne.s   0b
        bra.s   9f
4:      move.l  %d0,sg_trow
        moveq   #1,%d6
        bra.s   9f
1:      tst.l   0x800065b8              | over the first row
        bne.s   9f
        move.l  sg_ttop,%d2
        move.l  sg_ttop+4,%d3
        move.l  sg_ttop+8,%d4
        bsr     sg_tback
        bra.s   3f
2:      tst.l   0x800065b8              | under the last
        bne.s   9f
        move.l  sg_tne,%d1
        subq.l  #1,%d1
        lsl.l   #4,%d1
        lea     sg_tl,%a0
        adda.l  %d1,%a0
        tst.l   (%a0)
        bne.s   4f
        move.w  14(%a0),%d1             | (a pad or a readout: the arrangement goes on, build 90)
        andi.l  #12,%d1
        beq.s   9f
4:
        move.l  sg_ttop,%d2
        move.l  sg_ttop+4,%d3
        move.l  sg_ttop+8,%d4
        bsr     sg_tfwd
3:      tst.l   %d0
        beq.s   9f
        move.l  %d2,sg_ttop
        move.l  %d3,sg_ttop+4
        move.l  %d4,sg_ttop+8
        moveq   #1,%d6
9:      bsr     sg_tupd
        move.l  %d6,%d0
        movem.l (%sp),%d2-%d6
        lea     20(%sp),%sp
        rts

| The full timeline's LEFT / RIGHT (build 100; d0 = -1 / +1): on a readout row its fields 0-6 (the row,
| pattern, X, OF, LN, scenes A / B), stopping at the ends; on the steps the column, on past a page's end
| into the page beside it on the same screen row (zoomed out), else stopping there -- no edge opens the
| panel (the step's window) in the full view. Uses d0 d1 a0 a1.
sg_tlr:
        move.l  %d2,-(%sp)
        move.l  %d0,%d2
        clr.l   sg_tfree
        bsr     sg_trd
        beq.s   1f
        move.l  sg_tcol,%d0
        add.l   %d2,%d0
        bmi.s   9f
        moveq   #6,%d1
        cmp.l   %d1,%d0
        bgt.s   9f
        move.l  %d0,sg_tcol
        bra.s   9f
1:      move.l  sg_tcol,%d0
        add.l   %d2,%d0
        bmi.s   2f
        moveq   #15,%d1
        cmp.l   %d1,%d0
        bgt.s   2f
        move.l  %d0,sg_tcol
        bra.s   9f
2:      move.l  sg_trow,%d0             | the page beside it, the same screen row
        move.l  %d0,%d1
        add.l   %d2,%d1
        bmi.s   9f
        cmp.l   sg_tne,%d1
        bge.s   9f
        move.l  %d3,-(%sp)
        move.l  sg_tpk,%d3
        divu.l  %d3,%d0
        move.l  %d1,-(%sp)
        divu.l  %d3,%d1
        cmp.l   %d0,%d1
        movem.l (%sp),%d1
        addq.l  #4,%sp
        movem.l (%sp),%d3
        addq.l  #4,%sp
        bne.s   9f
        move.l  %d1,%d0
        lsl.l   #4,%d0
        lea     sg_tl,%a0
        tst.l   (%a0,%d0.l)
        beq.s   9f
        move.l  %d1,sg_trow
        moveq   #0,%d0
        tst.l   %d2
        bpl.s   3f
        moveq   #15,%d0
3:      move.l  %d0,sg_tcol
9:      bsr     sg_tupd
        move.l  (%sp)+,%d2
        rts

| The full timeline's UP / DOWN (build 100; d0 = -1 / +1): to the screen row above / below, at the
| cursor's x -- onto a readout row the field nearest it (sg_fxc), onto the steps the column under it
| (from a readout, under the field's middle); a page that is not there (a pad, the blank after the end)
| the nearest page on that row, a row with none passed over. Past the window's first / last row,
| stopped, the window moves a screen row's pages (sg_tback / sg_tfwd) and the cursor lands on the new
| first / last row. Uses d0 d1 a0 a1.
sg_tmvv:
        lea     -24(%sp),%sp
        movem.l %d2-%d7,(%sp)
        clr.l   sg_tfree
        move.l  %d0,%d5                 | d5: the direction
        moveq   #0,%d7                  | d7: 1 once the window has moved
        move.l  sg_trow,%d0             | d6: the cursor's x
        move.l  %d0,%d1
        lsl.l   #4,%d1
        lea     sg_tl,%a0
        adda.l  %d1,%a0
        btst    #3,15(%a0)
        beq.s   1f
        lsl.l   #3,%d0                  | a readout: its field's middle
        add.l   sg_tcol,%d0
        lea     sg_fxc,%a0
        moveq   #0,%d6
        move.b  (%a0,%d0.l),%d6
        bra.s   2f
1:      move.l  sg_tpk,%d1              | the steps: the screen column (its slot x sg_tcn + the column)
        move.l  %d0,%d2
        divu.l  %d1,%d2
        muls.l  %d1,%d2
        sub.l   %d2,%d0
        move.l  sg_tcn,%d1
        muls.l  %d1,%d0
        add.l   sg_tcol,%d0
        bsr     sg_colx
        move.l  sg_zp,%d1
        lsr.l   #1,%d1
        add.l   %d1,%d0
        move.l  %d0,%d6
2:      move.l  sg_trow,%d4             | d4: the screen row
        move.l  sg_tpk,%d1
        divu.l  %d1,%d4
3:      add.l   %d5,%d4                 | the next one
        bmi     .Lsg_vtop
        move.l  sg_tne,%d0
        move.l  sg_tpk,%d1
        divu.l  %d1,%d0
        cmp.l   %d0,%d4
        bge     .Lsg_vbot
.Lsg_vrow:                              | screen row d4: its first entry d3
        move.l  %d4,%d3
        move.l  sg_tpk,%d1
        muls.l  %d1,%d3
        move.l  %d3,%d0
        lsl.l   #4,%d0
        lea     sg_tl,%a0
        adda.l  %d0,%a0
        btst    #3,15(%a0)
        beq.s   4f
        move.l  %d3,sg_trow             | a readout: the field nearest x
        move.l  %d3,%d0
        lsl.l   #3,%d0
        lea     sg_fxc,%a1
        adda.l  %d0,%a1
        moveq   #1,%d2                  | (the pattern when none noted)
        move.l  #1000,%d1               | d1: the nearest distance
        moveq   #0,%d0
5:      moveq   #0,%d4                  | (d4 free from here)
        move.b  (%a1,%d0.l),%d4
        beq.s   6f
        sub.l   %d6,%d4
        bpl.s   7f
        neg.l   %d4
7:      cmp.l   %d1,%d4
        bge.s   6f
        move.l  %d4,%d1
        move.l  %d0,%d2
6:      addq.l  #1,%d0
        moveq   #7,%d4
        cmp.l   %d4,%d0
        blt.s   5b
        move.l  %d2,sg_tcol
        bra     .Lsg_v9
4:      move.l  %d6,%d0                 | the steps: the screen column under x
        sub.l   sg_gx,%d0
        bpl.s   4f
        moveq   #0,%d0
4:      move.l  sg_zp,%d1
        divu.l  %d1,%d0
        move.l  %d0,%d2
        move.l  sg_tcn,%d1
        divu.l  %d1,%d2                 | d2: its slot
        move.l  sg_tpk,%d1
        subq.l  #1,%d1
        cmp.l   %d1,%d2
        ble.s   4f
        move.l  %d1,%d2
4:      move.l  sg_tcn,%d1
        muls.l  %d2,%d1
        sub.l   %d1,%d0                 | d0: the column in it
        moveq   #15,%d1
        cmp.l   %d1,%d0
        ble.s   4f
        move.l  %d1,%d0
4:      move.l  %d3,%d1                 | the entry there
        add.l   %d2,%d1
        lsl.l   #4,%d1
        lea     sg_tl,%a0
        tst.l   (%a0,%d1.l)
        beq.s   8f
        add.l   %d2,%d3
        move.l  %d3,sg_trow
        move.l  %d0,sg_tcol
        bra     .Lsg_v9
8:      moveq   #0,%d2                  | not there: the row's other pages (d2: the slot looked at, d1:
        moveq   #-1,%d1                 | the last found, -1 none)
8:      move.l  %d3,%d0
        add.l   %d2,%d0
        lsl.l   #4,%d0
        lea     sg_tl,%a0
        tst.l   (%a0,%d0.l)
        beq.s   7f
        move.l  %d2,%d1                 | (the last found: the page nearest the end)
7:      addq.l  #1,%d2
        cmp.l   sg_tpk,%d2
        blt.s   8b
        tst.l   %d1
        bmi     3b                      | none on this row: the one after
        add.l   %d1,%d3
        move.l  %d3,sg_trow
        moveq   #15,%d0
        move.l  %d0,sg_tcol
        bra.s   .Lsg_v9
.Lsg_vtop:                              | over the first row: stopped, the window a screen row back
        tst.l   %d7
        bne.s   .Lsg_v9
        tst.l   0x800065b8
        bne.s   .Lsg_v9
        moveq   #-1,%d0
        bsr     sg_tscr
        tst.l   %d0
        beq.s   .Lsg_v9
        moveq   #1,%d7
        bsr     sg_tupd
        moveq   #0,%d4
        bra     .Lsg_vrow
.Lsg_vbot:                              | under the last: on a screen row
        tst.l   %d7
        bne.s   .Lsg_v9
        tst.l   0x800065b8
        bne.s   .Lsg_v9
        moveq   #1,%d0
        bsr     sg_tscr
        tst.l   %d0
        beq.s   .Lsg_v9
        moveq   #1,%d7
        bsr     sg_tupd
        move.l  sg_tne,%d4
        move.l  sg_tpk,%d1
        divu.l  %d1,%d4
        subq.l  #1,%d4
        bra     .Lsg_vrow
.Lsg_v9:
        bsr     sg_tupd
        movem.l (%sp),%d2-%d7
        lea     24(%sp),%sp
        rts

| d0 = +1 / -1: the timeline's window (sg_ttop) a screen row's pages on / back (sg_tpk; build 100), as
| far as the arrangement goes: d0 = 1 when it moved. Uses d0 d1 a0 a1.
sg_tscr:
        lea     -20(%sp),%sp
        movem.l %d2-%d6,(%sp)
        move.l  %d0,%d5
        moveq   #0,%d6
        move.l  sg_tpk,%d1
        move.l  %d1,-(%sp)
        move.l  sg_ttop,%d2
        move.l  sg_ttop+4,%d3
        move.l  sg_ttop+8,%d4
1:      tst.l   %d5
        bmi.s   2f
        bsr     sg_tfwd
        bra.s   3f
2:      bsr     sg_tback
3:      tst.l   %d0
        beq.s   4f
        moveq   #1,%d6
        subq.l  #1,(%sp)
        bgt.s   1b
4:      addq.l  #4,%sp
        move.l  %d2,sg_ttop
        move.l  %d3,sg_ttop+4
        move.l  %d4,sg_ttop+8
        move.l  %d6,%d0
        movem.l (%sp),%d2-%d6
        lea     20(%sp),%sp
        rts

| d0 = rows (signed): sg_tmv that many times. Uses d0 d1 a0 a1.
sg_tmvn:
        move.l  %d2,-(%sp)
        move.l  %d0,%d2
1:      tst.l   %d2
        beq.s   9f
        bmi.s   2f
        moveq   #1,%d0
        bsr     sg_tmv
        subq.l  #1,%d2
        bra.s   1b
2:      moveq   #-1,%d0
        bsr     sg_tmv
        addq.l  #1,%d2
        bra.s   1b
9:      move.l  (%sp)+,%d2
        rts

| d0 = the knob's delta: the cursor that many steps along the timeline, across its rows (sg_tmv's
| edges stop it). Uses d0 d1 a0 a1.
sg_tlvl:
        move.l  %d2,-(%sp)
        move.l  %d0,%d2
1:      tst.l   %d2
        beq.s   9f
        bmi.s   3f
        move.l  sg_tcol,%d0             | on
        addq.l  #1,%d0
        moveq   #15,%d1
        cmp.l   %d1,%d0
        ble.s   2f
        moveq   #1,%d0
        bsr     sg_tmv
        tst.l   %d0
        beq.s   9f
        moveq   #0,%d0
2:      move.l  %d0,sg_tcol
        subq.l  #1,%d2
        bra.s   1b
3:      move.l  sg_tcol,%d0             | back
        subq.l  #1,%d0
        bpl.s   4f
        moveq   #-1,%d0
        bsr     sg_tmv
        tst.l   %d0
        beq.s   9f
        moveq   #15,%d0
4:      move.l  %d0,sg_tcol
        addq.l  #1,%d2
        bra.s   1b
9:      clr.l   sg_tfree
        bsr     sg_tupd
        move.l  (%sp)+,%d2
        rts

| d0 = d0 mixed with the timeline: the cursor's row and column, each row's pattern, first step and flags
| and the cursor track's masks there. Uses d0 d1 a0.
sg_tsig:
        lea     -12(%sp),%sp
        movem.l %d2-%d3/%a2,(%sp)
        move.l  sg_trow,%d1
        bsr     sg_mx
        move.l  sg_tcol,%d1
        bsr     sg_mx
        lea     sg_tl,%a2
        move.l  sg_tne,%d2              | (8 pages, or the zoom's, build 84)
        subq.l  #1,%d2
1:      move.l  (%a2),%d1
        bsr     sg_mx
        tst.l   (%a2)
        beq.s   2f
        move.l  4(%a2),%d1
        bsr     sg_mx
        move.l  12(%a2),%d1
        bsr     sg_mx
        movea.l (%a2),%a0
        move.l  %d0,%d3
        move.l  sg_row,%d0
        bsr     sg_tofd0
        adda.l  %d0,%a0
        move.l  %d3,%d0
        move.l  (%a0),%d1
        bsr     sg_mx
        move.l  4(%a0),%d1
        bsr     sg_mx
        move.l  16(%a0),%d1
        bsr     sg_mx
        move.l  20(%a0),%d1
        bsr     sg_mx
2:      lea     16(%a2),%a2
        subq.l  #1,%d2
        bpl.s   1b
        movem.l (%sp),%d2-%d3/%a2
        lea     12(%sp),%sp
        rts

| Z set when the cursor's pattern may be written: the current one, or another in the current bank (its
| CS1 copy is there). Uses a0.
sg_cedit:
        tst.l   sg_cpat
        beq.s   9f
        movea.l sg_cpat,%a0
        suba.l  0x46c82456,%a0
        cmpa.l  #0x9b33f,%a0
        bhi.s   9f                      | outside: Z clear (not equal)
        cmpa.l  %a0,%a0
9:      rts

| The stock's MIDI activity dots at (10, 2) and (40, 2) (the periodic message, 0x40052328) are not shown
| on this page: those two pixels as the page last drew them, put back after it (build 71: the one at x
| 40 blinked in ROW's last digit). sg_dsave after a draw, sg_drest after 0x40052200. Uses d0 a0.
sg_dsave:
        movea.l SG_FB+12,%a0
        moveq   #0,%d0
        btst    #2,87(%a0)
        beq.s   1f
        moveq   #1,%d0
1:      btst    #2,327(%a0)
        beq.s   2f
        addq.l  #2,%d0
2:      move.l  %d0,sg_dots
        rts
sg_drest:
        movea.l SG_FB+12,%a0
        move.l  sg_dots,%d0
        btst    #0,%d0
        beq.s   1f
        bset    #2,87(%a0)
        bra.s   2f
1:      bclr    #2,87(%a0)
2:      btst    #1,%d0
        beq.s   3f
        bset    #2,327(%a0)
        rts
3:      bclr    #2,327(%a0)
        rts

| d0 = column 0-15: d0 = its x. Uses d0 d1.
sg_colx:
        move.l  sg_zp,%d1               | 4 col, no gap between groups of four (build 81; + 2 (col / 4)
        muls.l  %d1,%d0                 | before); the zoom's pitch col (build 84)
        add.l   sg_gx,%d0               | (x 0 in the full view, build 92)
        rts

| d1 = MIDI track 0-7 (a2 = the pattern): a3 = its record, d6 = its length (1-64: the pattern's, or
| the track's in PER TRACK scale, as 0x40032100 picks), d5 = the step it plays, -1 stopped.
sg_trk:
        lea     -8(%sp),%sp
        movem.l %d0/%a0,(%sp)
        move.l  %d1,%d0
        bsr     sg_tofd0                | the record (an audio track's in AUDIO, build 110)
        lea     (0,%a2,%d0.l),%a3
        move.l  %d1,%d0
        movea.l %a2,%a0
        adda.l  #0x8e53,%a0             | +0x8e53 the pattern's length, +0x8e55 its scale mode
        tst.b   2(%a0)
        bne.s   1f
        move.b  (%a0),%d6
        bra.s   2f
1:      move.b  0x28(%a3),%d6
        tst.l   sg_aud                  | (an audio track's own LEN, build 110)
        beq.s   2f
        move.b  0x50(%a3),%d6
2:      extb.l  %d6
        moveq   #1,%d5
        cmp.l   %d5,%d6
        bge.s   1f
        move.l  %d5,%d6
1:      moveq   #64,%d5
        cmp.l   %d5,%d6
        ble.s   1f
        move.l  %d5,%d6
1:      lea     0x80006508,%a0          | running (0x4009b290: 1)
        tst.l   sg_aud                  | (audio tracks' 8 entries before, build 110)
        beq.s   0f
        subq.l  #8,%a0
0:
        mvz.b   (0,%a0,%d0.l),%d5
        subq.l  #1,%d5
        bne.s   3f
        lea     0x800064e8,%a0          | the step (0x4009b2b0)
        tst.l   sg_aud
        beq.s   0f
        subq.l  #8,%a0
0:
        mvz.b   (0,%a0,%d0.l),%d5
        moveq   #63,%d0
        and.l   %d0,%d5
        bra.s   4f
3:      moveq   #-1,%d5
4:      movem.l (%sp),%d0/%a0
        addq.l  #8,%sp
        rts

| d0 = the next arrangement row's pattern, its address in its bank's blob, 0 when there is none (not
| arranging, the last row, or the next row not a pattern row); sg_npn its byte (bank << 4 | pattern).
| The arrangement in use: 0x10000000 -> its record (0x10000004 + 0x1614 index, 0x400a024e), the row
| count at +18, rows of 22 bytes from +20: +0 0 = a pattern row (1 LOOP / JUMP to the row at +3,
| 2 skipped), +1 bank << 4 | pattern, +5 the mutes (0x4004a100's and 0x4009aed0's reads; a LOOP row
| read under the port). Uses d0 d1 a0 a1.
sg_nxt:
        tst.l   0x460d1aec
        beq     8f
        move.l  sg_prow,%d1
        bmi     8f
        tst.l   0x800065b8
        beq.s   2f
        move.l  0x80006698,%d0          | playing: the arranger already on the next row (sg_platch,
        cmp.l   %d0,%d1                 | build 69)
        beq.s   1f
        move.l  %d0,%d1
        bmi     8f
        bra.s   3f
1:      move.l  0x8000669c,%d0          | a row asked for (sg_rowlv, the arranger's YES)
        bmi.s   2f
        move.l  %d0,%d1
        bra.s   3f
2:      addq.l  #1,%d1
3:      movea.l 0x10000000,%a0
        moveq   #0,%d0
        move.w  18(%a0),%d0
        cmp.l   %d0,%d1
        bge     8f
        move.l  %d1,-(%sp)              | through LOOP / JUMP rows and past REM rows as the arranger
        jsr     0x4009aed0              | does (its row resolver, 0x400a0266's call; build 63)
        addq.l  #4,%sp
        move.l  %d0,%d1
        movea.l 0x10000000,%a0
        moveq   #0,%d0
        move.w  18(%a0),%d0
        cmp.l   %d0,%d1
        bge.s   8f
        tst.l   %d1
        bmi.s   8f
        moveq   #22,%d0
        muls.l  %d1,%d0
        adda.l  %d0,%a0
        tst.b   20(%a0)
        bne.s   8f
        move.l  %d1,sg_nrow             | (the row, for the timeline's names: build 90)
        moveq   #0,%d0
        move.b  21(%a0),%d0
        move.l  %d0,sg_npn
        move.l  %d2,-(%sp)
        moveq   #15,%d1
        and.l   %d0,%d1
        lsr.l   #4,%d0
        move.l  #0x9b340,%d2
        muls.l  %d2,%d0                 | the bank
        move.l  #0x8ed8,%d2
        muls.l  %d2,%d1                 | the pattern
        add.l   %d1,%d0
        add.l   #0x400e21e0,%d0
        move.l  (%sp)+,%d2
        rts
8:      move.l  %d1,-(%sp)
        moveq   #-1,%d1
        move.l  %d1,sg_nrow
        move.l  (%sp)+,%d1
        moveq   #0,%d0
        rts

| a0 = the cursor track's record in the next pattern (sg_np). Uses d0 a0.
sg_nrec:
        move.l  sg_row,%d0
        bsr     sg_tofd0
        movea.l sg_np,%a0
        adda.l  %d0,%a0
        rts

| d0 = a track: d0 = its record's offset in a pattern -- a MIDI track's, 0x48d0 + 0x8b0 t, or in AUDIO
| (build 110) an audio track's, 0x91a t. Keeps everything else.
sg_tofd0:
        move.l  %d1,-(%sp)
        tst.l   sg_aud
        bne.s   1f
        move.l  #0x8b0,%d1
        muls.l  %d1,%d0
        addi.l  #0x48d0,%d0
        bra.s   2f
1:      move.l  #0x91a,%d1
        muls.l  %d1,%d0
2:      move.l  (%sp)+,%d1
        rts

| d1 = the arrangement row playing (sg_prow), -1 off.
sg_arr:
        moveq   #-1,%d1
        tst.l   0x460d1aec
        beq.s   1f
        move.l  sg_prow,%d1
1:      rts

| The arrangement row playing, sg_prow (build 64). The arranger's row (0x80006698) moves to the next row
| a step or two before that row starts (measured under the port: 0 -> 1 between steps 14 and 15 of a
| 16-step row, 1 -> 2 between 62 and 63 of a 64-step one), while the step count (0x800065b4) starts
| again at 0 with each row; so the row is read when the count goes back, when stopped, and when the page
| opens (sg_pnew). Uses d0 d1.
sg_platch:
        moveq   #0,%d1
        move.w  0x800065b4,%d1
        move.l  sg_pcnt,%d0
        move.l  %d1,sg_pcnt
        tst.l   0x800065b8
        beq.s   1f                      | stopped
        tst.l   sg_pnew
        bne.s   1f
        cmp.l   %d0,%d1
        bcc.s   9f                      | the count went on: the same row
1:      clr.l   sg_pnew
        move.l  0x80006698,%d0
        bpl.s   2f
        moveq   #-1,%d0                 | no row yet (arrangement mode on, never played): the first row
        bsr     sg_tnr                  | that will play, as the timeline takes it (build 88; ROW and the
2:      move.l  %d0,sg_prow             | row's lines were missing until play started)
9:      rts

| d0 = the knob's delta with ROW picked (build 69): the arrangement row to go to, from the one already
| asked for (0x8000669c, playing) or the one playing, kept within the rows; through the arranger's own
| call for YES in arrangement mode (0x4004903c: 0x400a013c(row) -- stopped, that row at once; playing,
| it is next: the row playing ends this pass, 0x4004a668 takes it), the arranger's cursor (0x460d16e4)
| and its list's top (0x460d16e8) with it, as UP/DOWN keep them (0x40049114). Uses d0 d1 a0 a1.
sg_rowlv:
        tst.l   0x460d1aec
        beq     9f
        move.l  %d2,-(%sp)
        move.l  %d0,%d2
        move.l  sg_prow,%d1
        tst.l   0x800065b8
        beq.s   1f
        move.l  0x8000669c,%d0
        bmi.s   1f
        move.l  %d0,%d1
1:      add.l   %d2,%d1
        bpl.s   2f
        moveq   #0,%d1
2:      movea.l 0x10000000,%a0
        moveq   #0,%d0
        move.w  18(%a0),%d0
        subq.l  #1,%d0
        bmi.s   8f                      | no rows: nothing (build 72)
        cmp.l   %d0,%d1
        ble.s   3f
        move.l  %d0,%d1
3:      move.l  %d1,0x460d16e4
        move.l  0x460d16e8,%d0          | the list's top: at most the cursor, at least 3 above it
        cmp.l   %d1,%d0
        ble.s   4f
        move.l  %d1,%d0
4:      move.l  %d1,%d2
        subq.l  #3,%d2
        cmp.l   %d2,%d0
        bge.s   5f
        move.l  %d2,%d0
5:      move.l  %d0,0x460d16e8
        move.l  %d1,-(%sp)
        jsr     0x400a013c
        addq.l  #4,%sp
        moveq   #1,%d0                  | as the stock's YES
        move.l  %d0,0x400be87e
8:      move.l  (%sp)+,%d2
9:      rts

| The arrangement row, "ROW01", against the divider at bottom y d1 (build 68), inverted while picked;
| with a row asked for (0x8000669c, playing) it shows that row and the one playing in turn, with the
| cursor's blink (build 69). Uses d0 d1 a0 a1.
sg_rowtx:
        lea     -8(%sp),%sp
        movem.l %d2-%d3,(%sp)
        move.l  %d1,%d3
        bsr     sg_arr
        tst.l   0x800065b8
        beq.s   1f
        move.l  0x8000669c,%d0
        bmi.s   1f
        moveq   #16,%d2
        and.l   sg_bk,%d2
        beq.s   1f
        move.l  %d0,%d1
1:      move.l  %d1,-(%sp)
        pea     sg_frw
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     12(%sp),%sp
        moveq   #SG_PR,%d0
        bsr     sg_hl
        move.l  %d3,%d1
        bsr     sg_rlin2
        movem.l (%sp),%d2-%d3
        addq.l  #8,%sp
        rts

| d0 = the pattern's length as the step count wraps it (a2 = the pattern): its length (NORMAL scale),
| its master length (PER TRACK), 64 for INF. Uses d0.
sg_plen:
        move.l  %a0,-(%sp)
        movea.l %a2,%a0
        adda.l  #0x8e50,%a0
        tst.b   5(%a0)                  | +0x8e55 the scale mode
        bne.s   1f
        move.b  3(%a0),%d0              | +0x8e53 the length
        extb.l  %d0
        bra.s   2f
1:      move.w  (%a0),%d0               | +0x8e50 the master length
        ext.l   %d0
2:      tst.l   %d0
        bgt.s   3f
        moveq   #64,%d0                 | INF: the longest a track can be
3:      movea.l (%sp)+,%a0
        rts

| d0 = the pattern to come (bank << 4 | pattern), -1 none (this one repeats); d1 = the steps until it
| starts, -1 stopped (a2 = the pattern; build 64). Arranging: the next row's pattern (sg_nxt), and the
| steps the row playing has left: its LEN (+12) times the repetitions left (0x800066a4) and its LEN less
| the step count. Else the pattern chosen to come (0x800065bf bank,
| 0x800065c0 pattern, which the pattern field shows, 0x400418e0) when it is not this one, and the
| steps to this one's end. Uses d0 d1 a0 a1.
sg_queue:
        lea     -12(%sp),%sp
        movem.l %d2-%d4,(%sp)
        bsr     sg_arr
        tst.l   %d1
        bmi     5f
        bsr     sg_nxt
        tst.l   %d0
        beq     8f                      | the last row: nothing comes
        move.l  sg_npn,%d2
        moveq   #-1,%d3
        tst.l   0x800065b8
        beq     9f
        movea.l 0x10000000,%a0          | the row playing
        move.l  sg_prow,%d0
        moveq   #22,%d1
        muls.l  %d1,%d0
        adda.l  %d0,%a0
        moveq   #0,%d4
        move.w  32(%a0),%d4             | its LEN: the end less the offset (build 100)
        bgt.s   0f
        bsr     sg_plen
        move.l  %d0,%d4
        bra.s   1f
0:      moveq   #0,%d0
        move.w  30(%a0),%d0
        sub.l   %d0,%d4
1:      moveq   #0,%d1                  | its repetitions left: the counter (0x800066a4 counts down from
        move.l  sg_prow,%d0             | +2 to 0, measured), which the next row's already holds once the
        cmp.l   0x80006698,%d0          | arranger has moved on (sg_platch)
        bne.s   2f
        move.l  0x800066a4,%d1
        bpl.s   2f
        moveq   #0,%d1
2:      muls.l  %d4,%d1
        add.l   %d4,%d1
        moveq   #0,%d0
        move.w  0x800065b4,%d0
        sub.l   %d0,%d1
        bgt.s   3f
        moveq   #1,%d1
3:      move.l  %d1,%d3
        bra     9f
5:      moveq   #0,%d2                  | the pattern chosen to come
        move.b  0x800065bf,%d2
        moveq   #0,%d0
        move.b  0x80000002,%d0
        cmp.l   %d0,%d2
        bne.s   6f
        move.b  0x800065c0,%d0
        cmp.b   0x100b14d0,%d0
        beq     8f                      | this one
6:      lsl.l   #4,%d2
        moveq   #0,%d0
        move.b  0x800065c0,%d0
        moveq   #15,%d1
        and.l   %d1,%d0
        or.l    %d0,%d2
        moveq   #-1,%d3
        tst.l   0x800065b8
        beq     9f
        bsr     sg_plen                 | the steps to this one's end
        move.l  %d0,%d4
        moveq   #0,%d1
        move.w  0x800065b4,%d1
        divu.l  %d4,%d1                 | the quotient; less it times the length: the step
        muls.l  %d4,%d1
        moveq   #0,%d0
        move.w  0x800065b4,%d0
        sub.l   %d1,%d0
        move.l  %d4,%d3
        sub.l   %d0,%d3
        bra     9f
8:      moveq   #-1,%d2
        moveq   #-1,%d3
9:      move.l  %d2,%d0
        move.l  %d3,%d1
        movem.l (%sp),%d2-%d4
        lea     12(%sp),%sp
        rts

| d1 = the pattern's step playing, 0-based, -1 stopped (a2 = the pattern): the sequencer's step count
| (0x800065b4) modulo the pattern's length (NORMAL scale) or its master length (PER TRACK; INF: as counted).
sg_mstep:
        moveq   #-1,%d1
        tst.l   0x800065b8
        beq.s   9f
        lea     -12(%sp),%sp
        movem.l %d0/%d2/%a0,(%sp)
        bsr     sg_plen
        moveq   #0,%d1
        move.w  0x800065b4,%d1
        move.l  %d1,%d2
        divu.l  %d0,%d2
        muls.l  %d0,%d2
        sub.l   %d2,%d1
        movem.l (%sp),%d0/%d2/%a0
        lea     12(%sp),%sp
9:      rts

| d0 = d0 * 33 ^ d1.
sg_mx:
        move.l  %d0,-(%sp)
        lsl.l   #5,%d0
        add.l   (%sp)+,%d0
        eor.l   %d1,%d0
        rts

| d0 = a checksum of the plane the step view owns: columns 0-127 (9-118 until 81: the stock's MIDI
| track strips either side are the page's since 82), rows 0-63 but row 2.
sg_sum:
        lea     -8(%sp),%sp
        movem.l %d2-%d3,(%sp)
        movea.l SG_FB+12,%a0
        movea.l %a0,%a1                 | column 0 (build 82: 9-118 before)
        moveq   #0,%d0
        move.l  #128,%d2
1:      move.l  (%a1),%d1
        move.l  %d0,%d3
        lsl.l   #5,%d0
        sub.l   %d3,%d0
        add.l   %d1,%d0
        move.l  4(%a1),%d1
        andi.l  #0xfffffffb,%d1         | not row 2: the stock's MIDI activity dots (0x40052328: (10, 2), (40, 2))
        move.l  %d0,%d3
        lsl.l   #5,%d0
        sub.l   %d3,%d0
        add.l   %d1,%d0
        addq.l  #8,%a1
        subq.l  #1,%d2
        bne.s   1b
        movem.l (%sp),%d2-%d3
        addq.l  #8,%sp
        rts

| d0 x0, d1 top row, d2 x1, d3 bottom row: clear (colour 0).
sg_clr:
        movea.l %d0,%a1
        clr.l   -(%sp)
        lea     SG_FILL,%a0
        bra.s   sg_rx
| a0 = SG_FILL or SG_RECT; d0 x0, d1 top row, d2 x1, d3 bottom row (screen rows); colour 1.
| Uses d0 d1 a0 a1; keeps d2 d3 (the drawing routines keep d2-d7/a2-a5).
sg_r1:
        movea.l %d0,%a1
        pea     1.w
sg_rx:  moveq   #63,%d0
        sub.l   %d1,%d0
        move.l  %d0,-(%sp)              | y1 = 63 - top
        move.l  %d2,-(%sp)              | x1
        moveq   #63,%d0
        sub.l   %d3,%d0
        move.l  %d0,-(%sp)              | y0 = 63 - bottom
        move.l  %a1,-(%sp)              | x0
        pea     SG_FB
        jsr     (%a0)
        lea     24(%sp),%sp
        rts

| Text: a0 font, d0 x, d1 bottom y (from the bottom), d2 = 1 highlighted (inverted, a pixel round it),
| a1 string. d0 = its width.
sg_tx:
        lea     -20(%sp),%sp
        movem.l %d2-%d4/%a2-%a3,(%sp)
        move.l  %d0,%d3                 | x
        move.l  %d1,%d4                 | y
        movea.l %a0,%a2                 | font
        movea.l %a1,%a3                 | string
        move.l  %a3,-(%sp)
        pea     sg_fs
        move.l  %a3,-(%sp)              | the template: the string itself
        clr.l   -(%sp)
        clr.l   -(%sp)                  | left
        move.l  %d4,-(%sp)
        move.l  %d3,-(%sp)
        pea     SG_FB
        move.l  %a2,-(%sp)
        jsr     SG_TEXT
        lea     36(%sp),%sp
        movea.l %a2,%a0
        movea.l %a3,%a1
        bsr     sg_wid
        tst.l   (%sp)                   | highlighted: invert x-1 .. x+w, rows bottom-5 .. bottom+1
        beq.s   9f
        move.l  %d0,-(%sp)
        pea     -1.w                    | colour -1: invert (as 0x40013904's own box)
        move.l  %d4,%d1
        addq.l  #5,%d1
        move.l  %d1,-(%sp)              | y1
        move.l  %d3,%d1
        add.l   %d0,%d1
        move.l  %d1,-(%sp)              | x1
        move.l  %d4,%d1
        subq.l  #1,%d1
        move.l  %d1,-(%sp)              | y0
        move.l  %d3,%d1
        subq.l  #1,%d1
        move.l  %d1,-(%sp)              | x0
        pea     SG_FB
        jsr     SG_FILL
        lea     24(%sp),%sp
        move.l  (%sp)+,%d0
9:      movem.l (%sp),%d2-%d4/%a2-%a3
        lea     20(%sp),%sp
        rts

| d0 = the width in pixels of the string a1 in font a0 (0x40012f30).
sg_wid:
        move.l  %a1,-(%sp)
        pea     -1.w
        move.l  %a0,-(%sp)
        jsr     0x40012f30
        lea     12(%sp),%sp
        rts

| d0 = slot: the cursor's step value, its lock (a3) or the Part's (a4).
sg_v34:
        moveq   #0,%d1
        move.b  (0,%a3,%d0.l),%d1
        cmp.l   #0xff,%d1
        bne.s   1f
        move.b  (0,%a4,%d0.l),%d1
1:      move.l  %d1,%d0
        rts

| d0 = note 0-127 into the 8-byte token at a1: its name at +0 ("F+" for F#, "D"), its octave at +4 ("4"), from
| NOTE's formatter ("F#4", "D 3").
sg_name:
        lea     -8(%sp),%sp
        movem.l %a2-%a3,(%sp)
        movea.l %a1,%a2                 | the token
        move.l  %d0,-(%sp)
        pea     sg_b3
        jsr     SG_FNOTE
        addq.l  #8,%sp
        lea     sg_b3,%a0
        move.b  (%a0)+,(%a2)            | the letter
        moveq   #35,%d1                 | then '#' (drawn as '+', narrower: build 54), or the padding space
        move.b  (%a0),%d0
        cmp.b   %d1,%d0
        bne.s   1f
        move.b  #43,1(%a2)
        clr.b   2(%a2)
        addq.l  #1,%a0
        bra.s   2f
1:      clr.b   1(%a2)
        moveq   #32,%d1
        cmp.b   %d1,%d0
        bne.s   2f
        addq.l  #1,%a0
2:      lea     4(%a2),%a3              | the octave: the rest, up to 3 characters
        moveq   #3,%d1
3:      move.b  (%a0)+,%d0
        move.b  %d0,(%a3)+
        beq.s   4f
        subq.l  #1,%d1
        bne.s   3b
        clr.b   (%a3)
4:      movem.l (%sp),%a2-%a3
        addq.l  #8,%sp
        rts

| d2 = 1 when the panel is on and value d0 (0-5) is the one picked.
sg_hl:
        moveq   #0,%d2
        tst.l   sg_mode
        beq.s   1f
        cmp.l   sg_prm,%d0
        bne.s   1f
        moveq   #1,%d2
1:      rts

| The panel, x 10-42, the small font (a2 = the pattern). Nine 7-px rows down the screen (rows 1-7,
| 8-14 .. 57-63), shared with the grid (a glyph on a row's rows 2-6): the first row across both, the
| name from x 11 and the pattern and page from x 45 (build 60); then level with tracks 1-8 the step
| playing, two blank lines, STEP, the note names, the octaves, VEL, LEN. A picked value's box is its
| whole row.
| a2 = the pattern.
        .set    SG_PX, 1                | (10 until 81: the stock's MIDI track strip at x 0-8 is drawn over since 82)
        .set    SG_SVX, 0               | SAVE's button, x 0-20 over STEP (build 100; x 36-56 from 82)
sg_panel:
        lea     -40(%sp),%sp
        movem.l %d2-%d7/%a2-%a5,(%sp)
        move.l  sg_prm,%d3              | a picked line no longer shown (the arrangement off, saved):
        subi.l  #SG_PR-1,%d3            | the panel to STEP (build 78); M and the pattern share line 2
        moveq   #SG_PA,%d0
        cmp.l   sg_prm,%d0
        bgt.s   2f
        subq.l  #1,%d3
2:
        moveq   #1,%d0
        cmp.l   %d0,%d3
        blt.s   1f
        moveq   #4,%d0
        cmp.l   %d0,%d3
        bgt.s   1f
        bsr     sg_lhid
        beq.s   1f
        moveq   #SG_PS,%d0
        move.l  %d0,sg_prm
1:
        bsr     sg_nget                 | the track's name in the first row (build 64; it was in the panel
        lea     sg_ftk,%a1              | from x 11), a character every 4 px, a space after TRKS: or
        tst.l   sg_view                 | PAGES: (build 75)
        beq.s   1f
        lea     sg_fpg,%a1
1:      lea     SG_SMALL,%a0
        bsr     sg_wid
        moveq   #64,%d5
        add.l   %d0,%d5                 | d5: the name's x, 45 + the label + 4
        moveq   #0,%d4
1:      lea     sg_nm,%a0
        move.b  (0,%a0,%d4.l),%d0
        lea     sg_b2,%a1
        move.b  %d0,(%a1)
        clr.b   1(%a1)
        move.l  %d4,%d0
        bsr     sg_hl
        move.l  %d4,%d0
        lsl.l   #2,%d0
        add.l   %d5,%d0
        tst.l   %d2                     | picked: a box even round a space
        beq.s   2f
        move.l  %d0,%d6
        lea     SG_SMALL,%a0
        moveq   #57,%d1                 | rows 2-6: the first row (build 60)
        moveq   #0,%d2
        bsr     sg_tx
        move.l  %d6,%d0
        subq.l  #1,%d0
        moveq   #1,%d1
        move.l  %d6,%d2
        addq.l  #3,%d2
        moveq   #7,%d3
        bsr     sg_inv
        bra.s   3f
2:      lea     SG_SMALL,%a0
        moveq   #57,%d1
        bsr     sg_tx
3:      addq.l  #1,%d4
        moveq   #SG_NN,%d0
        cmp.l   %d0,%d4
        blt.s   1b
        lea     sg_ftk,%a1              | over the rows' numbers at x 45: TRK (8-track window) or PAGE (the
        tst.l   sg_view                 | 4-page window; PG in 68-72); the name after it (build 68)
        beq.s   1f
        lea     sg_fpg,%a1
1:      lea     SG_SMALL,%a0
        moveq   #60,%d0
        moveq   #57,%d1
        moveq   #0,%d2
        bsr     sg_tx
        bsr     sg_tlon                 | (the timeline: M before the pattern playing, build 90)
        bne.s   1f
        moveq   #0,%d2
        tst.l   0x460d1aec              | arranging: M always there, a value: YES opens the row's mutes
        beq.s   2f                      | window (build 81)
        moveq   #SG_PM,%d0
        bsr     sg_hl
        bra.s   3f
2:      move.l  sg_mm,%d0               | the cursor's track muted: M at the left of line 1 (build 68;
        move.l  sg_row,%d1              | after its name before)
        btst    %d1,%d0
        beq.s   1f
3:      bsr     sg_mch                  | "M" (flashing while a track is muted, build 101)
        lea     sg_b2,%a1
        move.w  %d0,(%a1)
        lea     SG_SMALL,%a0
        moveq   #SG_PX,%d0
        moveq   #50,%d1
        bsr     sg_tx
1:
        tst.l   sg_umt                  | an undo / redo just now: its message at the panel's top, inverted,
        ble.s   1f                      | the whole line its own
        lea     SG_SMALL,%a0
        moveq   #SG_PX+1,%d0
        moveq   #57,%d1
        moveq   #1,%d2
        lea     sg_umsg,%a1
        bsr     sg_tx
        bra     2f
1:      bsr     sg_ckdraw               | else the time in the top-left corner (build 88; line 3 in 82-87),
        moveq   #57,%d5                 | the row against the divider and the step count left of it (the
        bsr     sg_arr                  | count top left in 73-87): d5 the count's right edge
        tst.l   %d1
        bmi.s   5f
        moveq   #57,%d1
        bsr     sg_rowtx
        move.l  %d0,%d5
        subq.l  #3,%d5
5:      bsr     sg_mstep                | the step playing; stopped, the cursor's step (build 75: "--"
        move.l  %d1,%d4                 | before)
        bpl.s   4f
        move.l  sg_step,%d4
4:      addq.l  #1,%d4
        lea     sg_f3c,%a0
        move.l  %d4,-(%sp)
        move.l  %d4,-(%sp)
        tst.l   %d4
        bne.s   3f
        lea     sg_f3d,%a0              | --
3:      move.l  %a0,-(%sp)
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     16(%sp),%sp
        lea     SG_SMALL,%a0
        lea     sg_b1,%a1
        bsr     sg_wid
        move.l  %d5,%d1
        sub.l   %d0,%d1
        move.l  %d1,%d0
        lea     SG_SMALL,%a0
        moveq   #57,%d1
        moveq   #0,%d2
        lea     sg_b1,%a1
        bsr     sg_tx
2:      bsr     sg_arr                  | the page / pages (the longest track's), "1/4", at the first row's
        tst.l   %d1                     | far right (build 70), but not in the 4-page window while arranging
        bmi.s   1f
        tst.l   sg_view
        bne     8f
1:      moveq   #0,%d4
        moveq   #0,%d3
1:      move.l  %d4,%d1
        bsr     sg_trk
        cmp.l   %d3,%d6
        ble.s   2f
        move.l  %d6,%d3
2:      addq.l  #1,%d4
        moveq   #8,%d0
        cmp.l   %d0,%d4
        blt.s   1b
        moveq   #15,%d0
        add.l   %d0,%d3
        asr.l   #4,%d3
        move.l  %d3,-(%sp)
        move.l  sg_vpg,%d0              | the page in view (the cursor's in the 4-page window)
        tst.l   sg_view
        beq.s   1f
        move.l  sg_step,%d0
        lsr.l   #4,%d0
1:      addq.l  #1,%d0
        move.l  %d0,-(%sp)
        pea     sg_ftp
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     16(%sp),%sp
        lea     SG_SMALL,%a0
        lea     sg_b1,%a1
        bsr     sg_wid
        moveq   #127,%d1                | its last column x 126
        sub.l   %d0,%d1
        move.l  %d1,%d5
        move.l  %d1,%d0                 | its box cleared: a 12-character name's last runs under it
        subq.l  #1,%d0                  | after PAGE (build 73)
        moveq   #1,%d1
        moveq   #126,%d2
        moveq   #7,%d3
        bsr     sg_clr
        move.l  %d5,%d0
        lea     SG_SMALL,%a0
        moveq   #57,%d1
        moveq   #0,%d2
        lea     sg_b1,%a1
        bsr     sg_tx
8:      tst.l   sg_view                 | the 4-page window and the timeline: the zoom, "16/R" (steps
        beq     8f                      | a row, build 90), at the first row's far right, 3 px before the
        move.l  sg_zn,-(%sp)            | page ("1/4", not arranging)
        pea     sg_fzz
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     12(%sp),%sp
        moveq   #127,%d4
        bsr     sg_arr
        tst.l   %d1
        bpl.s   1f
        move.l  %d5,%d4
        subq.l  #3,%d4
1:      lea     SG_SMALL,%a0
        lea     sg_b1,%a1
        bsr     sg_wid
        move.l  %d4,%d2                 | its box cleared (a long name's last runs under it)
        sub.l   %d0,%d4                 | d4: its x
        move.l  %d4,%d0
        subq.l  #1,%d0
        moveq   #1,%d1
        moveq   #7,%d3
        bsr     sg_clr
        move.l  %d4,%d0
        lea     SG_SMALL,%a0
        moveq   #57,%d1
        moveq   #0,%d2
        lea     sg_b1,%a1
        bsr     sg_tx
8:
        moveq   #0,%d0                  | line 1, level with the grid's first row: the pattern playing,
        move.b  0x80000002,%d0          | against the divider (build 66; both windows since 70);
        lsl.l   #4,%d0                  | arranging, its row's pattern, which LEVEL and FUNC + LEFT /
        moveq   #0,%d1                  | RIGHT change when picked (build 78)
        move.b  0x100b14d0,%d1
        or.l    %d1,%d0
        move.l  %d0,%d4
        bsr     sg_arr
        move.l  %d1,%d0
        bmi.s   1f
        bsr     sg_trrow
        tst.l   %d0
        beq.s   1f
        moveq   #0,%d4
        move.b  21(%a0),%d4
1:      moveq   #15,%d0
        and.l   %d4,%d0
        addq.l  #1,%d0
        move.l  %d0,-(%sp)
        move.l  %d4,%d0
        lsr.l   #4,%d0
        moveq   #65,%d1
        add.l   %d1,%d0
        move.l  %d0,-(%sp)
        pea     sg_fpt
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     16(%sp),%sp
        moveq   #SG_PA,%d0
        bsr     sg_hl
        moveq   #50,%d1
        bsr     sg_rlin2
        move.l  %d0,-(%sp)              | the timeline (build 90): the play triangle 1 px before the
        bsr     sg_tlon                 | pattern playing, M before it (81-89: M at the left, the
        beq.s   1f                      | triangle over the countdown)
        move.l  (%sp),%d0
        subq.l  #4,%d0
        bsr     sg_ptri
        moveq   #SG_PM,%d0
        bsr     sg_hl
        lea     sg_b2,%a1
        move.w  #0x4d00,(%a1)           | "M" (its width; then flashing, build 101)
        lea     SG_SMALL,%a0
        bsr     sg_wid
        move.l  (%sp),%d1
        subq.l  #6,%d1
        sub.l   %d0,%d1
        move.l  %d1,-(%sp)
        bsr     sg_mch
        lea     sg_b2,%a1
        move.w  %d0,(%a1)
        move.l  (%sp)+,%d0
        lea     SG_SMALL,%a0
        moveq   #50,%d1
        lea     sg_b2,%a1
        bsr     sg_tx
1:      addq.l  #4,%sp
        bsr     sg_queue                | line 2, against the divider: the bars (16 steps) until the
        move.l  %d1,%d5                 | pattern to come starts and that pattern, "3 A03"; this one after
        moveq   #0,%d7                  | an infinity when it repeats (build 64; bars since 66)
        tst.l   %d0
        bpl.s   1f
        moveq   #1,%d7                  | d7: 1 = it repeats
        moveq   #0,%d0
        move.b  0x80000002,%d0
        lsl.l   #4,%d0
        moveq   #0,%d1
        move.b  0x100b14d0,%d1
        or.l    %d1,%d0
1:      move.l  %d0,%d6                 | d6: bank << 4 | pattern
        bsr     sg_tl2set               | the timeline: the next row's name may carry it (build 90)
        moveq   #2,%d0
        cmp.l   sg_tl2,%d0
        beq     .Lsg_l2x
        move.l  %d6,%d1
        moveq   #15,%d2
        and.l   %d1,%d2
        addq.l  #1,%d2
        move.l  %d2,-(%sp)              | the pattern 1-16
        lsr.l   #4,%d1
        moveq   #65,%d2
        add.l   %d2,%d1
        move.l  %d1,-(%sp)              | its bank's letter
        tst.l   sg_tl2                  | the timeline, no name for it: the count alone, from x 12
        beq.s   0f                      | (build 89)
        tst.l   %d7
        bne.s   2f
        tst.l   %d5
        bpl.s   3f
        pea     sg_f3d                  | stopped: "--"
        bra.s   5f
0:      tst.l   %d7
        bne.s   2f
        tst.l   %d5
        bpl.s   3f
        pea     sg_fcs                  | stopped: "-- A03"
        bra.s   5f
2:      pea     sg_fpt                  | repeating: "A02" after the infinity
5:      pea     sg_b1
        jsr     SG_SPRINTF
        lea     16(%sp),%sp
        bra.s   6f
3:      moveq   #15,%d2                 | the steps in bars, rounded up: 16 .. 1 steps left = 1
        add.l   %d2,%d5
        asr.l   #4,%d5
        move.l  #999,%d2
        cmp.l   %d2,%d5
        ble.s   4f
        move.l  %d2,%d5
4:      move.l  %d5,-(%sp)
        pea     sg_fcd
        tst.l   sg_tl2
        beq.s   9f
        addq.l  #4,%sp
        pea     sg_fsd                  | (the timeline's: "3")
9:      pea     sg_b1
        jsr     SG_SPRINTF
        lea     20(%sp),%sp
6:      moveq   #SG_PB,%d0              | (picked: inverted, build 78)
        bsr     sg_hl
        move.l  %d2,%d3                 | d3: picked
        tst.l   sg_tl2
        beq.s   9f
        tst.l   %d7                     | the timeline's: from x 12 (the infinity alone repeating)
        bne.s   8f
        lea     SG_SMALL,%a0
        moveq   #12,%d0
        moveq   #43,%d1
        lea     sg_b1,%a1
        bsr     sg_tx
        moveq   #12,%d0
        bra.s   7f
9:      moveq   #43,%d1                 | line 2, rows 16-20
        bsr     sg_rlin2
        tst.l   %d7
        beq.s   7f
        subi.l  #10,%d0                 | the infinity 3 px left of the pattern
        move.l  %d0,-(%sp)
        bsr     sg_inf
        move.l  (%sp)+,%d4
        addq.l  #2,%d4                  | (the triangle over its middle; not in the timeline, build 90)
        bsr     sg_tlon
        bne.s   8f
        move.l  %d4,%d0
        bsr     sg_ptri
        bra.s   8f
7:      move.l  %d0,%d4                 | d4: the line's x
        bsr     sg_tlon                 | the play triangle over the countdown's first digit (build 76;
        bne.s   0f                      | by the pattern playing in the timeline, build 90)
        move.l  %d4,%d0
        bsr     sg_ptri
0:      tst.l   %d3                     | picked: no flash
        bne     8f
        moveq   #32,%d0                 | a pattern to come flashes, its countdown with it (build 73: the
        and.l   sg_bk,%d0               | name alone until 81; bit 5, with the M flash, since 76): the
        beq.s   8f                      | line's box cleared in the off phase
        move.l  %d4,%d0
        moveq   #15,%d1
        moveq   #56,%d2
        moveq   #21,%d3
        bsr     sg_clr
8:      tst.l   sg_tl2                  | the timeline repeating: the infinity at x 12
        beq.s   9f
        tst.l   %d7
        beq.s   9f
        moveq   #12,%d0
        bsr     sg_inf
9:
.Lsg_l2x:

        bsr     sg_adirty               | line 3: SAVE, the arrangement unsaved (build 78; empty in 73-77):
        beq.s   1f                      | YES there saves it (the ARR menu's SAVE)
        moveq   #SG_PV,%d0
        bsr     sg_hl
        lea     sg_fsv,%a1
        lea     SG_SMALL,%a0
        moveq   #SG_SVX+2,%d0
        moveq   #36,%d1
        bsr     sg_tx
        moveq   #SG_SVX,%d0             | its button's outline, rows 22-28, over STEP (build 100; against
        moveq   #22,%d1                 | the divider in 82-99, at the panel's left before)
        moveq   #SG_SVX+20,%d2
        moveq   #28,%d3
        lea     SG_RECT,%a0
        bsr     sg_r1
1:      move.l  sg_step,%d0             | STEP nn (in the panel too, build 55)
        addq.l  #1,%d0
        move.l  %d0,-(%sp)
        pea     sg_f4
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     12(%sp),%sp
        moveq   #SG_PS,%d0              | picked (build 63): LEVEL moves the cursor's step
        bsr     sg_hl
        lea     SG_SMALL,%a0
        moveq   #SG_PX,%d0
        moveq   #29,%d1                 | line 4, rows 30-34
        lea     sg_b1,%a1
        bsr     sg_tx

        bsr     sg_sel                  | the cursor step's values
        movea.l %a2,%a3                 | a3: its locks
        movea.l %a0,%a4                 | a4: the Part's
        moveq   #0,%d0
        bsr     sg_v34
        move.l  %d0,%d5                 | d5: NOTE
        lea     sg_nb,%a1
        bsr     sg_name
        moveq   #1,%d4                  | NOT2-4: NOTE + (v - 64), 64 = none
1:      move.l  %d4,%d0
        addq.l  #2,%d0
        bsr     sg_v34
        lea     sg_nb,%a1
        move.l  %d4,%d1
        lsl.l   #3,%d1
        adda.l  %d1,%a1
        moveq   #64,%d1
        cmp.l   %d1,%d0
        bne.s   2f
        move.b  #45,(%a1)               | "-", no octave
        clr.b   1(%a1)
        clr.b   4(%a1)
        bra.s   3f
2:      sub.l   %d1,%d0
        add.l   %d5,%d0
        bpl.s   4f
        moveq   #0,%d0
4:      moveq   #127,%d1
        cmp.l   %d1,%d0
        ble.s   4f
        move.l  %d1,%d0
4:      bsr     sg_name
3:      addq.l  #1,%d4
        moveq   #4,%d0
        cmp.l   %d0,%d4
        blt.s   1b
        moveq   #SG_PX,%d6              | d6: x -- four fixed slots 8 px apart (build 55: a sharp's +
        moveq   #0,%d4                  | no longer moves the notes after it)
1:      lea     SG_SMALL,%a0            | the octave, a row below
        lea     sg_nb+4,%a1
        move.l  %d4,%d1
        lsl.l   #3,%d1
        adda.l  %d1,%a1
        move.l  %d6,%d0
        moveq   #15,%d1                 | line 6, rows 44-48
        moveq   #0,%d2
        bsr     sg_tx
        lea     SG_SMALL,%a0            | the name
        lea     sg_nb,%a1
        move.l  %d4,%d1
        lsl.l   #3,%d1
        adda.l  %d1,%a1
        move.l  %d6,%d0
        moveq   #22,%d1                 | line 5, rows 37-41
        moveq   #0,%d2
        bsr     sg_tx
        move.l  %d4,%d0                 | picked: the slot inverted, both rows
        addi.l  #SG_PN,%d0
        bsr     sg_hl
        tst.l   %d2
        beq.s   2f
        move.l  %d6,%d0
        subq.l  #1,%d0
        moveq   #36,%d1                 | lines 5 and 6 whole, rows 36-49
        move.l  %d6,%d2
        addq.l  #6,%d2
        moveq   #49,%d3
        bsr     sg_inv
2:      addq.l  #8,%d6
        addq.l  #1,%d4
        moveq   #4,%d0
        cmp.l   %d0,%d4
        blt.s   1b

        moveq   #1,%d0                  | VEL: "V", its value 1 px after (build 90: "V 100", a space,
        bsr     sg_v34                  | before); the value kept for the step's window (sg_pvb)
        move.l  %d0,-(%sp)
        pea     sg_pvb
        jsr     SG_FVEL
        addq.l  #8,%sp
        lea     sg_b2,%a1
        move.w  #0x5600,(%a1)           | "V"
        lea     SG_SMALL,%a0
        moveq   #SG_PX,%d0
        moveq   #8,%d1                  | line 7, rows 51-55
        moveq   #0,%d2
        bsr     sg_tx                   | d0: its width
        addq.l  #SG_PX+2,%d0
        lea     SG_SMALL,%a0
        moveq   #8,%d1
        moveq   #0,%d2
        lea     sg_pvb,%a1
        bsr     sg_tx
        moveq   #SG_PN+4,%d0            | picked: the whole row inverted, as LEN's (build 90)
        bsr     sg_hl
        tst.l   %d2
        beq.s   1f
        moveq   #0,%d0
        moveq   #50,%d1
        moveq   #57,%d2
        moveq   #56,%d3
        bsr     sg_inv
1:
        moveq   #2,%d0                  | LEN, a line below: its value 0-127 and its subdivision,
        bsr     sg_v34                  | "L 24 1/4"; a value between subdivisions the nearest's;
        move.l  %d0,%d7                 | the value alone if that is wider than the panel's 32 px
        bsr     sg_lnear                | (build 55)
        lea     sg_lv,%a0               | d6: the value against that subdivision (build 79)
        mvz.b   (0,%a0,%d0.l),%d6
        sub.l   %d7,%d6
        neg.l   %d6
        move.l  %d0,%d1                 | its label, sg_lt + 6 index
        add.l   %d0,%d0
        add.l   %d1,%d0
        add.l   %d0,%d0
        lea     sg_lt,%a0
        adda.l  %d0,%a0
        movea.l %a0,%a5                 | a5: the label alone
        move.l  %a0,-(%sp)              | d5: the label, "-" before it when the value is under the
        lea     sg_fs,%a0               | subdivision, "+" after when over (build 79)
        tst.l   %d6
        beq.s   6f
        lea     sg_flm,%a0
        bmi.s   6f
        lea     sg_flp,%a0
6:      move.l  %a0,-(%sp)
        pea     sg_b3
        jsr     SG_SPRINTF
        lea     12(%sp),%sp
        move.l  #sg_b3,%d5
        lea     sg_b3,%a0               | the value and the fraction kept for the step's window (build 90)
        lea     sg_plf,%a1
        moveq   #11,%d0
0:      move.b  (%a0)+,(%a1)+
        subq.l  #1,%d0
        bne.s   0b
        clr.b   (%a1)
        move.l  %d7,sg_plv
        move.l  %d7,-(%sp)              | "L", the value 1 px after it (build 90: "L 24", a space), at the
        pea     sg_fsd                  | left; the fraction after (build 87; right-aligned against the
        pea     sg_b2                   | divider in 58-86), left out when it would touch the divider
        jsr     SG_SPRINTF
        lea     12(%sp),%sp
        lea     sg_lbl,%a1
        move.w  #0x4c00,(%a1)           | "L"
        lea     SG_SMALL,%a0
        moveq   #SG_PX,%d0
        moveq   #1,%d1                  | line 8, rows 58-62
        moveq   #0,%d2
        bsr     sg_tx                   | d0: its width
        move.l  %d0,%d6
        addq.l  #2,%d6
        moveq   #SG_PX,%d0
        add.l   %d6,%d0
        lea     SG_SMALL,%a0
        moveq   #1,%d1
        moveq   #0,%d2
        lea     sg_b2,%a1
        bsr     sg_tx
        add.l   %d0,%d6                 | d6: "L" and the value, wide
        lea     SG_SMALL,%a0
        movea.l %d5,%a1
        bsr     sg_wid
        moveq   #57,%d1
        sub.l   %d0,%d1                 | d1: the fraction's last x (a column clear of the divider)
        moveq   #SG_PX+3,%d0            | d0: its x, 3 px after "L 24" (build 87: right-aligned against
        add.l   %d6,%d0                 | the divider before)
        cmp.l   %d1,%d0
        ble.s   7f
        cmpa.l  %d5,%a5                 | too wide with its + / -: the label alone, if that fits
        beq.s   4f
        move.l  %a5,%d5
        lea     SG_SMALL,%a0
        movea.l %d5,%a1
        bsr     sg_wid
        moveq   #57,%d1
        sub.l   %d0,%d1
        moveq   #SG_PX+3,%d0
        add.l   %d6,%d0
        cmp.l   %d1,%d0
        bgt.s   4f
7:      lea     SG_SMALL,%a0
        moveq   #1,%d1
        moveq   #0,%d2
        movea.l %d5,%a1
        bsr     sg_tx
4:      moveq   #SG_PN+5,%d0            | picked: the whole row inverted
        bsr     sg_hl
        tst.l   %d2
        beq.s   5f
        moveq   #0,%d0
        moveq   #57,%d1
        moveq   #57,%d2
        moveq   #63,%d3
        bsr     sg_inv
5:
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        rts

| ---- COPY / CLEAR / PASTE (build 82): FUNC + REC (COPY), FUNC + PLAY (CLEAR), FUNC + STOP (PASTE),
|      the transport keys' FUNC functions, on the cursor's track. FUNC + LEVEL in the grid marks a run of
|      steps from the cursor (sg_sela the anchor, the cursor the other end; gone when FUNC is let go);
|      with one marked, COPY copies it, CLEAR clears it and PASTE fills it with the clip, repeated.
|      With none, COPY and CLEAR open their window (sg_win: TRIG, ROW -- the cursor's page of the track
|      --, PAGES 1-4, each page on or off) and PASTE puts the clip back: a run of steps at the cursor, a
|      row at the cursor's page, pages at the pages they came from. Not in the timeline (the stock's).
|      A step is the stock MIDI trig paste's (0x4002c4d4): the three trig masks' bits (+0x00, +0x08,
|      +0x10), the 32 lock bytes (+0x30 + 32 s) and the trig word (+0x830 + 2 s), written to the bank
|      and its CS1 copy, the step's track bit (0x46c7d2e4) set for a lock, then the track's refresh
|      (0x40029b9c(t): the dirty flags, 0x4009da20(t) and (8 + t), the LEDs), as that paste ends.
        .set    SG_CSZ, 36              | a step in the clip: +0 the masks' bits, +2 the trig word, +4 the locks

| a3 = the cursor track's record in the bank, a4 = its CS1 copy. Uses d0 d1 a0.
sg_crec:
        bsr     sg_upat
        move.l  sg_cpat,%d0             | the timeline: the cursor's row's pattern (build 84)
        beq.s   1f
        movea.l %d0,%a0
1:      move.l  sg_row,%d0
        move.l  #0x8b0,%d1
        muls.l  %d1,%d0
        adda.l  %d0,%a0
        adda.l  #0x48d0,%a0
        movea.l %a0,%a3
        movea.l %a0,%a4
        suba.l  0x46c82456,%a4
        adda.l  #0x1001614e,%a4
        rts

| d0 = step: its byte index into a mask (7 - s / 8) in d1. Uses d1.
sg_cbyte:
        move.l  %d0,%d1
        asr.l   #3,%d1
        neg.l   %d1
        addq.l  #7,%d1
        rts

| d0 = step, a1 = a clip slot: the step of the record at a3 into it. Uses d0 d1 a0.
sg_cget:
        lea     -12(%sp),%sp
        movem.l %d2-%d3/%a2,(%sp)
        bsr     sg_cbyte
        moveq   #0,%d3
        btst    %d0,(0,%a3,%d1.l)
        beq.s   1f
        bset    #0,%d3
1:      btst    %d0,(8,%a3,%d1.l)
        beq.s   2f
        bset    #1,%d3
2:      btst    %d0,(16,%a3,%d1.l)
        beq.s   3f
        bset    #2,%d3
3:      move.b  %d3,(%a1)
        clr.b   1(%a1)
        move.l  %d0,%d1
        add.l   %d1,%d1
        lea     (0,%a3,%d1.l),%a0
        move.w  0x830(%a0),2(%a1)       | the trig word
        move.l  %d0,%d1
        lsl.l   #5,%d1
        lea     (0x30,%a3,%d1.l),%a0    | the locks
        lea     4(%a1),%a2
        moveq   #32,%d2
4:      move.b  (%a0)+,(%a2)+
        subq.l  #1,%d2
        bne.s   4b
        movem.l (%sp),%d2-%d3/%a2
        lea     12(%sp),%sp
        rts

| d0 = step, a1 = a clip slot: written to the step of the record (a3) and its CS1 copy (a4). Uses d0 d1 a0.
sg_cput:
        lea     -20(%sp),%sp
        movem.l %d2-%d5/%a2,(%sp)
        move.l  %d0,%d4                 | d4: the step
        bsr     sg_cbyte
        move.l  %d1,%d2                 | d2: its mask byte
        moveq   #0,%d3
        move.b  (%a1),%d3               | d3: the masks' bits
        moveq   #0,%d5                  | d5: the mask (0, 8, 16)
1:      lea     (0,%a3,%d5.l),%a0
        lea     (0,%a4,%d5.l),%a2
        btst    #0,%d3
        beq.s   2f
        bset    %d4,(0,%a0,%d2.l)
        bset    %d4,(0,%a2,%d2.l)
        bra.s   3f
2:      bclr    %d4,(0,%a0,%d2.l)
        bclr    %d4,(0,%a2,%d2.l)
3:      lsr.l   #1,%d3
        addq.l  #8,%d5
        moveq   #24,%d0
        cmp.l   %d0,%d5
        blt.s   1b
        move.l  %d4,%d1                 | the trig word
        add.l   %d1,%d1
        lea     (0,%a3,%d1.l),%a0
        move.w  2(%a1),0x830(%a0)
        lea     (0,%a4,%d1.l),%a0
        move.w  2(%a1),0x830(%a0)
        move.l  %d4,%d1                 | the locks; d3: a lock among them
        lsl.l   #5,%d1
        lea     (0x30,%a3,%d1.l),%a0
        lea     (0x30,%a4,%d1.l),%a2
        moveq   #0,%d3
        moveq   #0,%d5
4:      move.b  (4,%a1,%d5.l),%d0
        move.b  %d0,(%a0)+
        move.b  %d0,(%a2)+
        cmp.b   #0xff,%d0
        beq.s   5f
        moveq   #1,%d3
5:      addq.l  #1,%d5
        moveq   #32,%d0
        cmp.l   %d0,%d5
        blt.s   4b
        tst.l   %d3
        beq.s   6f
        lea     0x46c7d2e4,%a0          | the step's MIDI-track bits (as the paste and the lock store)
        move.l  sg_row,%d1
        bset    %d1,(0,%a0,%d4.l)
6:      movem.l (%sp),%d2-%d5/%a2
        lea     20(%sp),%sp
        rts

| d0 = step: cleared -- no trig, no locks, the trig word's condition kept (as sg_trig keeps it). Uses
| d0 d1 a0 a1.
sg_cclr:
        lea     sg_cblk,%a1
        clr.w   (%a1)
        move.l  %d0,%d1
        add.l   %d1,%d1
        lea     (0,%a3,%d1.l),%a0
        move.w  0x830(%a0),%d1
        andi.l  #0x7f,%d1
        move.w  %d1,2(%a1)
        moveq   #-1,%d1
        move.l  %d1,4(%a1)
        move.l  %d1,8(%a1)
        move.l  %d1,12(%a1)
        move.l  %d1,16(%a1)
        move.l  %d1,20(%a1)
        move.l  %d1,24(%a1)
        move.l  %d1,28(%a1)
        move.l  %d1,32(%a1)
        bra     sg_cput

| After writing the track: the LED caches cleared (as sg_lock) and the track's refresh. Uses d0 d1 a0 a1.
sg_cdone:
        moveq   #0,%d0
        move.w  %d0,0x460d1a9e
        move.w  %d0,0x460d1aa0
        move.w  %d0,0x460d1aa2
        move.w  %d0,0x460d1aa4
        move.w  %d0,0x460d1aa6
        move.w  %d0,0x460d10dc
        move.l  sg_row,-(%sp)
        jsr     0x40029b9c
        addq.l  #4,%sp
        rts

| d4 = the marked run's first step, d5 its last. Uses d0.
sg_crun:
        move.l  sg_sela,%d4
        move.l  sg_step,%d5
        cmp.l   %d4,%d5
        bge.s   1f
        move.l  %d4,%d0
        move.l  %d5,%d4
        move.l  %d0,%d5
1:      rts

| a1 = clip slot d0. Uses d0 d1.
sg_cslot:
        moveq   #SG_CSZ,%d1
        muls.l  %d1,%d0
        lea     sg_clip,%a1
        adda.l  %d0,%a1
        rts

| The message "<what> <n>" (a0 = what, d0 = n) at the panel's top for 1.5 s, as the undo's. Uses d0 d1
| a0 a1.
sg_cmsg:
        move.l  %d0,-(%sp)
        move.l  %a0,-(%sp)
        pea     sg_fcm
        pea     sg_umsg
        jsr     SG_SPRINTF
        lea     16(%sp),%sp
        moveq   #90,%d0
        move.l  %d0,sg_umt
        rts

| The message a0 (up to 15 characters) at the panel's top for 1.5 s. Uses d0 a0 a1.
sg_cmsg0:
        lea     sg_umsg,%a1
        moveq   #15,%d0
1:      move.b  (%a0)+,(%a1)+
        beq.s   2f
        subq.l  #1,%d0
        bne.s   1b
        clr.b   (%a1)
2:      moveq   #90,%d0
        move.l  %d0,sg_umt
        rts

| The timeline's step (d5 the row's step, d6 the track's length, d7 the page, d4 the screen column, a4
| the row's top): inverted when the cursor's row and in the run marked (build 84). Uses d0 d1 a0 a1.
sg_selt:
        tst.l   sg_sela
        bmi.s   9f
        cmp.l   sg_trow,%d7
        bne.s   9f
        lea     -16(%sp),%sp
        movem.l %d2-%d5,(%sp)
        move.l  %d5,%d0                 | the track's step
        move.l  %d0,%d1
        divu.l  %d6,%d1
        muls.l  %d6,%d1
        sub.l   %d1,%d0
        move.l  %d0,%d2
        bsr     sg_crun
        cmp.l   %d4,%d2
        blt.s   8f
        cmp.l   %d5,%d2
        bgt.s   8f
        move.l  8(%sp),%d0              | (d4 saved: the screen column)
        bsr     sg_colx
        subq.l  #1,%d0
        move.l  %a4,%d1
        subq.l  #1,%d1
        move.l  sg_zp,%d2
        subq.l  #1,%d2
        add.l   %d0,%d2
        move.l  sg_rh,%d3
        add.l   %a4,%d3
        bsr     sg_inv
8:      movem.l (%sp),%d2-%d5
        lea     16(%sp),%sp
9:      rts

| d6 = 0 copy / 1 clear, d4..d5 the steps (0-63): the clip (sg_cn d5 - d4 + 1, as a run) or the steps
| cleared. Uses d0 d1 a0 a1 d7.
sg_cdo:
        moveq   #0,%d7
1:      move.l  %d4,%d0
        add.l   %d7,%d0
        cmp.l   %d5,%d0
        bgt.s   3f
        addq.l  #1,sg_ccnt
        tst.l   %d6
        bne.s   2f
        move.l  %d0,-(%sp)
        move.l  %d7,%d0
        add.l   sg_cn,%d0
        bsr     sg_cslot
        move.l  (%sp)+,%d0
        bsr     sg_cget
        addq.l  #1,%d7
        bra.s   1b
2:      bsr     sg_cclr
        addq.l  #1,%d7
        bra.s   1b
3:      tst.l   %d6
        bne.s   4f
        add.l   %d7,sg_cn
        rts
4:      bra     sg_cdone

| d6 = 0 COPY / 1 CLEAR, d3 = the window's line (0 TRIG, 1 ROW, 2 PAGES with sg_wpm), or -1 the run
| marked: the copy or the clear, its message. Uses everything but a5 a6.
sg_cop:
        moveq   #3,%d0                  | COPY's 303 line (build 107)
        cmp.l   %d0,%d3
        beq     sg_c303
        clr.l   sg_ccnt
        bsr     sg_crec
        tst.l   %d6
        bne.s   1f
        clr.l   0x460d0ffa              | (the stock's clipboard no longer the latest: build 113)
        clr.l   sg_cn                   | a copy: the clip starts again
        clr.l   sg_ctrk                 | (not a whole track's, sg_ktrk sets it after)
        move.l  %d3,sg_ck
        moveq   #0,%d0
        move.l  %d0,sg_cpm
1:      tst.l   %d3
        bpl.s   2f
        clr.l   sg_ck                   | the run marked: a run
        bsr     sg_crun
        bsr     sg_cdo
        bra.s   8f
2:      bne.s   3f
        move.l  sg_step,%d4             | TRIG: the cursor's step (a run of one)
        move.l  %d4,%d5
        bsr     sg_cdo
        bra.s   8f
3:      subq.l  #1,%d3
        bne.s   4f
        moveq   #-16,%d4                | ROW: the cursor's page
        and.l   sg_step,%d4
        moveq   #15,%d5
        add.l   %d4,%d5
        bsr     sg_cdo
        bra.s   8f
4:      move.l  sg_wpm,%d2              | PAGES: each one on, in order
        tst.l   %d6
        bne.s   5f
        move.l  %d2,sg_cpm
5:      moveq   #0,%d3
6:      btst    %d3,%d2
        beq.s   7f
        move.l  %d3,%d4
        lsl.l   #4,%d4
        moveq   #15,%d5
        add.l   %d4,%d5
        bsr     sg_cdo
7:      addq.l  #1,%d3
        moveq   #4,%d0
        cmp.l   %d0,%d3
        blt.s   6b
8:      lea     sg_fcp,%a0              | "COPY 16" / "CLEAR 16": the steps
        tst.l   %d6
        beq.s   9f
        lea     sg_fcc,%a0
9:      move.l  sg_ccnt,%d0
        bra     sg_cmsg

| PASTE: the clip into the run marked (repeated through it), else at its own place: a run at the
| cursor, a row at the cursor's page, pages at theirs. Uses everything but a5 a6.
sg_cpaste:
        tst.l   sg_cn
        bne.s   0f
        lea     sg_fce,%a0              | "EMPTY 0"... the clip is: "CLIP 0"
        moveq   #0,%d0
        bra     sg_cmsg
0:      bsr     sg_crec
        moveq   #0,%d6                  | d6: the steps written
        tst.l   sg_sela
        bmi.s   2f
        bsr     sg_crun                 | the run: the clip repeated through it
        move.l  %d4,%d7
        bra.s   .Lcp_r
2:      move.l  sg_ck,%d0
        subq.l  #1,%d0
        beq.s   4f
        bpl.s   6f
        move.l  sg_step,%d4             | a run, at the cursor
        bra.s   5f
4:      moveq   #-16,%d4                | a row, at the cursor's page
        and.l   sg_step,%d4
5:      moveq   #0,%d7                  | clip step d7 to d4 + d7, to the last step
3:      cmp.l   sg_cn,%d7
        bge     .Lcp_e
        move.l  %d4,%d0
        add.l   %d7,%d0
        moveq   #63,%d1
        cmp.l   %d1,%d0
        bgt     .Lcp_e
        move.l  %d0,-(%sp)
        move.l  %d7,%d0
        bsr     sg_cslot
        move.l  (%sp)+,%d0
        bsr     sg_cput
        addq.l  #1,%d6
        addq.l  #1,%d7
        bra.s   3b
6:      moveq   #0,%d3                  | pages: the clip's pages in order, to the pages they came from
        moveq   #0,%d5                  | d5: the clip's step
7:      move.l  sg_cpm,%d0
        btst    %d3,%d0
        beq.s   9f
        moveq   #0,%d7
8:      move.l  %d5,%d0
        bsr     sg_cslot
        move.l  %d3,%d0
        lsl.l   #4,%d0
        add.l   %d7,%d0
        bsr     sg_cput
        addq.l  #1,%d6
        addq.l  #1,%d5
        addq.l  #1,%d7
        moveq   #16,%d0
        cmp.l   %d0,%d7
        blt.s   8b
9:      addq.l  #1,%d3
        moveq   #4,%d0
        cmp.l   %d0,%d3
        blt.s   7b
        bra.s   .Lcp_e
.Lcp_r:                                 | the run (d4..d5, d7 the step): repeat the clip through it
        moveq   #0,%d3                  | d3: the clip's step
1:      cmp.l   %d5,%d7
        bgt.s   .Lcp_e
        move.l  %d3,%d0
        bsr     sg_cslot
        move.l  %d7,%d0
        bsr     sg_cput
        addq.l  #1,%d6
        addq.l  #1,%d7
        addq.l  #1,%d3
        cmp.l   sg_cn,%d3
        blt.s   1b
        moveq   #0,%d3
        bra.s   1b
.Lcp_e:
        bsr     sg_cdone
        lea     sg_fcs2,%a0             | "PASTE 16"
        move.l  %d6,%d0
        bra     sg_cmsg

| Z set when FUNC + REC / PLAY / STOP are the step editor's: FUNC down on the page (no trig or track
| key, no stock window), not the name's keyboard, not the timeline, no window of ours. Uses d0 d1 a0.
sg_cok:
        bsr     sg_keyfn
        bne.s   9f
        tst.l   sg_kb
        bne.s   9f
        tst.l   sg_win
        bne.s   9f
        moveq   #0,%d0                  | (the timeline too, build 84)
9:      rts

| The handlers: FUNC's sub-map records of REC 0x29 (stock 0x40060f34 COPY), PLAY 0x28 (0x40060eb4
| CLEAR) and STOP 0x27 (0x40060db0 PASTE), (code, state); a press only.
sg_kcopy:
        bsr     sg_cok
        bne.s   8f
        moveq   #0,%d0
        bra.s   sg_kcop
8:      jmp     0x40060f34
sg_kclear:
        bsr     sg_cok
        bne.s   8f
        moveq   #1,%d0
        bra.s   sg_kcop
8:      jmp     0x40060eb4
sg_kpaste:
        bsr     sg_cok
        bne.s   8f
        moveq   #2,%d0
        bra.s   sg_kcop
8:      jmp     0x40060db0
sg_kcop:
        moveq   #1,%d1
        cmp.l   8(%sp),%d1
        bne     9f
        tst.l   sg_tnum                 | on the track number: the whole track (build 143)
        bne     sg_ktrk
        tst.l   sg_aud                  | AUDIO: CLEAR the cursor's step only (sg_aclr, the audio track's
        beq.s   .Lkc_m                  | record; 141-142 cleared the MIDI track's step through sg_ndel),
        moveq   #1,%d1                  | COPY / PASTE nothing (build 110)
        cmp.l   %d1,%d0
        bne     9f
        bra     sg_aclr
.Lkc_m: lea     -40(%sp),%sp
        movem.l %d2-%d7/%a2-%a5,(%sp)
        clr.l   sg_idle
        move.l  %d0,%d6
        beq.s   0f                      | CLEAR / PASTE on a timeline row of another bank: nothing, a
        bsr     sg_cedit                | message (build 84)
        beq.s   0f
        lea     sg_fob,%a0
        bsr     sg_cmsg0
        bra     3f
0:      move.l  %d6,%d0
        subq.l  #2,%d0
        bne     1f
        tst.l   sg_aud                  | AUDIO, a MIDI track in the stock's clipboard: it into the
        beq.s   5f                      | cursor's audio track (build 116)
        moveq   #8,%d0
        cmp.l   0x460d0ffa,%d0
        bne.s   0f
        tst.l   sg_cpat
        bne.s   0f
        move.l  sg_row,-(%sp)           | (the stock's undo snapshot, as its audio paste takes one)
        moveq   #0,%d0
        move.b  0x100b14d0,%d0
        move.l  %d0,-(%sp)
        pea     7.w
        jsr     0x400298d0
        lea     12(%sp),%sp
        moveq   #0,%d0
        move.b  0x100b14d0,%d0
        move.l  sg_row,%d1
        lea     0x460c8122,%a0
        bsr     sg_m2a
        lea     sg_fpat,%a0
        bsr     sg_cmsg0
        bra     3f
5:      moveq   #4,%d0                  | an audio track in the stock's clipboard, the latest copy: it
        cmp.l   0x460d0ffa,%d0          | into the cursor's MIDI track, as the stock's MIDI track paste
        bne.s   0f                      | with it (build 113)
        tst.l   sg_cpat
        bne.s   0f
        move.l  sg_row,-(%sp)
        moveq   #0,%d0
        move.b  0x100b14d0,%d0
        move.l  %d0,-(%sp)
        bsr     sg_mpst
        addq.l  #8,%sp
        lea     sg_fpat,%a0
        bsr     sg_cmsg0
        bra     3f
0:      bsr     sg_cpaste
        bra     3f
1:      tst.l   sg_sela                 | a run marked: copy / clear it
        bmi.s   2f
        moveq   #-1,%d3
        bsr     sg_cop
        bra.s   3f
2:      moveq   #1,%d0                  | CLEAR without a run: the cursor's step (build 141)
        cmp.l   %d0,%d6
        bne.s   4f
        moveq   #0,%d3
        bsr     sg_cop
        bra.s   3f
4:      moveq   #1,%d0                  | else the window: COPY 1, PAGES picked, all four on
        add.l   %d6,%d0
        move.l  %d0,sg_win
        moveq   #2,%d0
        move.l  %d0,sg_wl
        moveq   #15,%d0
        move.l  %d0,sg_wpm
        clr.l   sg_wpc
        move.l  sg_row,%d0              | COPY's 303 line: the same-numbered audio track (build 107)
        move.l  %d0,sg_w3t
3:      movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        bra     sg_now
9:      rts

| A key while our window is up (from sg_klr, sg_kud, sg_kyes, sg_kno: code, state): UP / DOWN a line,
| LEFT / RIGHT a page on PAGES, YES does it, NO closes. Press only.
sg_wkey:
        moveq   #1,%d0
        cmp.l   8(%sp),%d0
        bne     9f
        clr.l   sg_idle
        move.l  4(%sp),%d0
        moveq   #SG_WSC,%d1             | the scale window's (build 83)
        cmp.l   sg_win,%d1
        beq     sg_skey
        moveq   #SG_WST,%d1             | the step's window's (build 90)
        cmp.l   sg_win,%d1
        beq     sg_stkey
        moveq   #0x32,%d1               | NO
        cmp.l   %d1,%d0
        bne.s   1f
        clr.l   sg_win
        bra     sg_now
1:      moveq   #0x31,%d1               | YES
        cmp.l   %d1,%d0
        bne.s   2f
        lea     -40(%sp),%sp
        movem.l %d2-%d7/%a2-%a5,(%sp)
        move.l  sg_win,%d6
        subq.l  #1,%d6
        move.l  sg_wl,%d3
        tst.l   %d6                     | CLEAR on another bank's row: the message (build 84)
        beq.s   0f
        bsr     sg_cedit
        beq.s   0f
        lea     sg_fob,%a0
        bsr     sg_cmsg0
        bra.s   1f
0:      bsr     sg_cop
1:
        clr.l   sg_win
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        bra     sg_now
2:      moveq   #-1,%d1                 | UP / LEFT: -1
        cmpi.l  #0x33,%d0
        beq.s   3f
        cmpi.l  #0x34,%d0
        beq.s   3f
        moveq   #1,%d1
3:      cmpi.l  #0x33,%d0
        beq.s   4f
        cmpi.l  #0x20,%d0
        beq.s   4f
        moveq   #2,%d0                  | LEFT / RIGHT: PAGES only
        cmp.l   sg_wl,%d0
        bne.s   8f
        add.l   sg_wpc,%d1
        bmi.s   8f
        moveq   #3,%d0
        cmp.l   %d0,%d1
        bgt.s   8f
        move.l  %d1,sg_wpc
        bra.s   8f
4:      add.l   sg_wl,%d1
        bmi.s   8f
        moveq   #2,%d0                  | (build 113: the 303 line gone, three lines again)
        cmp.l   %d0,%d1
        bgt.s   8f
        move.l  %d1,sg_wl
8:      bra     sg_now
9:      rts

| LEVEL with our window up (from sg_lvl, delta at 8(sp)): on PAGES the page picked on (right) or off.
sg_wlvl:
        moveq   #SG_WSC,%d0             | the scale window's value (build 83)
        cmp.l   sg_win,%d0
        bne.s   0f
        move.l  8(%sp),%d0
        bra     sg_slvl
0:      moveq   #SG_WST,%d0             | the step's window: the panel's value picked, as LEVEL changes it
        cmp.l   sg_win,%d0              | there (build 90; sg_lvl's frame, the delta at 8(sp))
        beq     .Llv_ed
        moveq   #3,%d0                  | COPY's 303 line: the audio track (build 107)
        cmp.l   sg_wl,%d0
        bne.s   1f
        clr.l   sg_idle
        moveq   #1,%d0
        tst.l   8(%sp)
        bgt.s   2f
        moveq   #-1,%d0
2:      add.l   sg_w3t,%d0
        bmi.s   9f
        moveq   #7,%d1
        cmp.l   %d1,%d0
        bgt.s   9f
        move.l  %d0,sg_w3t
        bra     sg_now
1:      moveq   #2,%d0
        cmp.l   sg_wl,%d0
        bne.s   9f
        clr.l   sg_idle
        move.l  sg_wpc,%d1
        move.l  sg_wpm,%d0
        tst.l   8(%sp)
        bmi.s   1f
        bset    %d1,%d0
        bra.s   2f
1:      bclr    %d1,%d0
2:      move.l  %d0,sg_wpm
        bra     sg_now
9:      rts

| Our window over the grid (from sg_run): a frame, its title inverted, TRIG / ROW / PAGES 1 2 3 4 (X for
| a page off), the line picked inverted, on PAGES the page picked shown back the other way. Uses d0-d7
| a0 a1 (sg_run's own).
        .set    SG_WX0, 60
        .set    SG_WX1, 126
sg_wdraw:
        moveq   #SG_WX0,%d0
        moveq   #9,%d1
        moveq   #SG_WX1,%d2
        moveq   #43,%d3
        lea     SG_RECT,%a0
        bsr     sg_r1
        lea     sg_fwc,%a1              | the title
        moveq   #1,%d0
        cmp.l   sg_win,%d0
        beq.s   1f
        lea     sg_fwl,%a1
1:      lea     SG_SMALL,%a0
        moveq   #SG_WX0+3,%d0
        moveq   #48,%d1                 | rows 11-15
        moveq   #0,%d2
        bsr     sg_tx
        moveq   #SG_WX0,%d0
        moveq   #9,%d1
        moveq   #SG_WX1,%d2
        moveq   #16,%d3
        bsr     sg_inv
        moveq   #0,%d7                  | the lines: d7 = 0-2, bottom rows 24 / 32 / 40
.Lwd_l:
        move.l  %d7,%d6
        lsl.l   #3,%d6
        addi.l  #24,%d6                 | d6: the line's bottom row
        lea     sg_fwt,%a1
        tst.l   %d7
        beq.s   1f
        lea     sg_fwr,%a1
        cmpi.l  #1,%d7
        beq.s   1f
        lea     sg_fwp,%a1
        cmpi.l  #3,%d7
        bne.s   1f
        lea     sg_fw3,%a1
1:      lea     SG_SMALL,%a0
        moveq   #SG_WX0+4,%d0
        moveq   #63,%d1
        sub.l   %d6,%d1
        moveq   #0,%d2
        bsr     sg_tx
        cmpi.l  #2,%d7
        beq.s   0f
        cmpi.l  #3,%d7
        bne.s   4f
        bsr     sg_w3d
        bra.s   4f
0:      moveq   #0,%d5                  | PAGES: the four, 8 px apart from x 88
2:      lea     sg_b2,%a1
        moveq   #49,%d0
        add.l   %d5,%d0
        move.l  sg_wpm,%d1
        btst    %d5,%d1
        bne.s   3f
        moveq   #88,%d0                 | "X": off
3:      move.b  %d0,(%a1)
        clr.b   1(%a1)
        move.l  %d5,%d0
        lsl.l   #3,%d0
        addi.l  #88,%d0
        moveq   #63,%d1
        sub.l   %d6,%d1
        moveq   #0,%d2
        lea     SG_SMALL,%a0
        bsr     sg_tx
        addq.l  #1,%d5
        moveq   #4,%d0
        cmp.l   %d0,%d5
        blt.s   2b
4:      cmp.l   sg_wl,%d7               | picked: the line inverted
        bne.s   5f
        moveq   #SG_WX0+1,%d0
        moveq   #-5,%d1
        add.l   %d6,%d1
        moveq   #SG_WX1-1,%d2
        move.l  %d6,%d3
        addq.l  #1,%d3
        bsr     sg_inv
        cmpi.l  #2,%d7                  | PAGES: the page picked back the other way
        bne.s   5f
        move.l  sg_wpc,%d0
        lsl.l   #3,%d0
        addi.l  #87,%d0
        moveq   #-5,%d1
        add.l   %d6,%d1
        moveq   #5,%d2
        add.l   %d0,%d2
        move.l  %d6,%d3
        addq.l  #1,%d3
        bsr     sg_inv
5:      addq.l  #1,%d7
        moveq   #3,%d0
        cmp.l   %d0,%d7
        blt     .Lwd_l
        rts

| COPY's 303 line (build 107; d6 its bottom row): "T3 OK" -- the audio track the copy reads, OK when it
| is an OCTA-303 track in the current Part (NO otherwise). Uses d0-d3 a0 a1.
sg_w3d:
        move.l  sg_w3t,%d0
        bsr     sg_o3s
        pea     sg_fw3y
        bne.s   1f
        addq.l  #4,%sp
        pea     sg_fw3n
1:      move.l  sg_w3t,%d0
        addq.l  #1,%d0
        move.l  %d0,-(%sp)
        pea     sg_fw3t
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     16(%sp),%sp
        lea     sg_b1,%a1
        lea     SG_SMALL,%a0
        moveq   #88,%d0
        moveq   #63,%d1
        sub.l   %d6,%d1
        moveq   #0,%d2
        bra     sg_tx

| d0 = audio track 0-7: d0 = 1 (Z clear) when it is an OCTA-303 track in the current Part -- FLEX
| (Part' + 0x22 + t = 1) signed 'T' 'B' 1 at Part' + 0x3c + 30 t, as OCTA303's o3_sig / 303 FOLLOW's
| o3f_signed --, a0 = that Part' (bank + 0x8ed80 + Part x 6322). Uses d0 d1 a0 a1.
sg_o3s:
        movea.l 0x46c82456,%a0
        adda.l  #0x8ed80,%a0
        moveq   #0,%d1
        move.b  0x100b14cf,%d1
        andi.l  #3,%d1
        move.l  %d0,-(%sp)
        move.l  #6322,%d0
        muls.l  %d0,%d1
        adda.l  %d1,%a0
        move.l  (%sp)+,%d0
        moveq   #0,%d1
        move.b  (0x22,%a0,%d0.l),%d1
        subq.l  #1,%d1
        bne.s   8f
        moveq   #30,%d1
        muls.l  %d0,%d1
        lea     (0x3c,%a0,%d1.l),%a1
        moveq   #0,%d1
        move.b  (%a1)+,%d1
        cmpi.l  #0x54,%d1
        bne.s   8f
        move.b  (%a1)+,%d1
        cmpi.l  #0x42,%d1
        bne.s   8f
        move.b  (%a1),%d1
        subq.l  #1,%d1
        bne.s   8f
        moveq   #1,%d0
        rts
8:      moveq   #0,%d0
        rts

| COPY on the 303 line (build 107): audio track sg_w3t's sequence, an OCTA-303 track's, into the clip as
| MIDI steps -- its pages (its length: the pattern's, or its own in PER TRACK; +0x50 of its record,
| pattern + 0x91a t) as a PAGES clip, so PASTE puts them on the same pages. A trig (mask +0x00) becomes a
| note trig with a NOTE lock (lock 0): its TUNE lock (the record's +0x59 + 32 s, flat 0), or the Part's
| TUNE (Part' + 0x30 + 30 t) without one, as MIDI TUNE - 16 (TUNE C3 = raw 64 = MIDI 48, as 303
| FOLLOW plays a MIDI note on OCTA-303); an ACC lock above 0 a VEL lock 101-127 (an accent); a trigless
| step after a note (OCTA-303's slide) a note too, the note before it given a LEN lock reaching past it
| so 303 FOLLOW slides into it. The trig word 0. Not an OCTA-303 track: "NOT OCTA-303", the clip kept. Uses everything but a5 a6.
sg_c303:
        move.l  sg_w3t,%d7              | d7: the audio track
        move.l  %d7,%d0
        bsr     sg_o3s
        bne.s   1f
        lea     sg_fno3,%a0
        bra     sg_cmsg0
1:      moveq   #30,%d1                 | d5: the Part's TUNE
        muls.l  %d7,%d1
        moveq   #0,%d5
        move.b  (0x30,%a0,%d1.l),%d5
        bsr     sg_upat                 | a2: the pattern (the timeline row's, as sg_crec)
        tst.l   sg_cpat
        beq.s   2f
        movea.l sg_cpat,%a0
2:      movea.l %a0,%a2
        move.l  #0x91a,%d0              | a3: the audio track's record
        muls.l  %d7,%d0
        lea     (0,%a2,%d0.l),%a3
        move.l  #0x8e53,%d0             | d6: its length
        moveq   #0,%d6
        move.b  (0,%a2,%d0.l),%d6
        tst.b   (2,%a2,%d0.l)
        beq.s   3f
        move.b  0x50(%a3),%d6
3:      moveq   #1,%d0
        cmp.l   %d0,%d6
        bge.s   4f
        move.l  %d0,%d6
4:      moveq   #64,%d0
        cmp.l   %d0,%d6
        ble.s   5f
        move.l  %d0,%d6
5:      addi.l  #15,%d6                 | its pages
        lsr.l   #4,%d6
        moveq   #1,%d0
        lsl.l   %d6,%d0
        subq.l  #1,%d0
        move.l  %d0,sg_cpm
        moveq   #2,%d0
        move.l  %d0,sg_ck
        lsl.l   #4,%d6                  | d6: the steps
        move.l  %d6,sg_cn
        clr.l   sg_ccnt
        moveq   #0,%d3                  | d3: a note seen (a trigless step after one is a slide)
        moveq   #0,%d4                  | d4: the step
.Lc3_s:
        move.l  %d4,%d0
        bsr     sg_cslot
        clr.l   (%a1)                   | no trig, the trig word 0, no locks
        moveq   #-1,%d0
        move.l  %d0,4(%a1)
        move.l  %d0,8(%a1)
        move.l  %d0,12(%a1)
        move.l  %d0,16(%a1)
        move.l  %d0,20(%a1)
        move.l  %d0,24(%a1)
        move.l  %d0,28(%a1)
        move.l  %d0,32(%a1)
        move.l  %d4,%d0
        bsr     sg_cbyte
        btst    %d0,(0,%a3,%d1.l)
        bne.s   0f
        tst.l   %d3                     | a trigless step after a note: a note too, marked a slide
        beq     8f
        btst    %d0,(8,%a3,%d1.l)
        beq     8f
        move.b  #1,1(%a1)
0:      moveq   #1,%d3
        move.b  #5,(%a1)                | a trig, with locks
        move.l  %d4,%d0
        lsl.l   #5,%d0
        moveq   #0,%d1
        move.b  (0x59,%a3,%d0.l),%d1    | its TUNE lock
        cmpi.l  #0xff,%d1
        bne.s   6f
        move.l  %d5,%d1
6:      subi.l  #16,%d1
        bpl.s   7f
        moveq   #0,%d1
7:      cmpi.l  #127,%d1
        ble.s   9f
        moveq   #127,%d1
9:      move.b  %d1,4(%a1)              | the NOTE lock
        moveq   #0,%d1                  | its ACC lock (flat 5), above 0: VEL 101-127, an accent as
        move.b  (0x5e,%a3,%d0.l),%d1    | 303 FOLLOW reads one
        cmpi.l  #0xff,%d1
        beq.s   5f
        tst.l   %d1
        beq.s   5f
        moveq   #101,%d0
        cmp.l   %d0,%d1
        bge.s   4f
        move.l  %d0,%d1
4:      move.b  %d1,5(%a1)              | the VEL lock
5:      addq.l  #1,sg_ccnt
8:      addq.l  #1,%d4
        cmp.l   %d6,%d4
        blt     .Lc3_s
        moveq   #0,%d4                  | a note slid into: the note before it held over it, a LEN lock
.Lc3_l:                                 | of its distance + 1/2 step (6 a step, 126 at most)
        cmp.l   %d6,%d4
        bge.s   .Lc3_e
        move.l  %d4,%d0
        bsr     sg_cslot
        movea.l %a1,%a2
        tst.b   (%a2)
        beq.s   3f
        move.l  %d4,%d2
1:      addq.l  #1,%d2
        cmp.l   %d6,%d2
        bge.s   3f
        move.l  %d2,%d0
        bsr     sg_cslot
        tst.b   (%a1)
        beq.s   1b
        tst.b   1(%a1)
        beq.s   3f
        move.l  %d2,%d0
        sub.l   %d4,%d0
        moveq   #6,%d1
        mulu.l  %d1,%d0
        addq.l  #3,%d0
        cmpi.l  #126,%d0
        ble.s   2f
        moveq   #126,%d0
2:      move.b  %d0,6(%a2)              | the LEN lock
3:      clr.b   1(%a2)                  | (the mark gone)
        addq.l  #1,%d4
        bra.s   .Lc3_l
.Lc3_e:
        lea     sg_fcp3,%a0             | "303 NOTES 12"
        move.l  sg_ccnt,%d0
        bra     sg_cmsg

| d4 = the column, d7 = the grid's row, a6 = the row's first step, a4 its top: the step inverted when it is
| in the run marked (the cursor's track: its row in the 8-track window, the first four in the 4-page
| one), x0 - 1 .. x0 + 2 so a run's cells touch. Uses d0 d1 a0 a1.
sg_selc:
        tst.l   sg_sela
        bmi.s   9f
        tst.l   sg_view                 | (the 4-page window: every row is the cursor track's, build 84)
        bne.s   2f
        cmp.l   sg_row,%d7
        bne.s   9f
2:      lea     -16(%sp),%sp
        movem.l %d2-%d5,(%sp)
        bsr     sg_crun
        move.l  %a6,%d0
        add.l   8(%sp),%d0              | (d4, saved: the column)
        cmp.l   %d4,%d0
        blt.s   8f
        cmp.l   %d5,%d0
        bgt.s   8f
        move.l  8(%sp),%d0
        bsr     sg_colx
        subq.l  #1,%d0
        move.l  %a4,%d1
        subq.l  #1,%d1
        move.l  sg_zp,%d2               | x0 - 1 .. x0 + pitch - 2 (build 84)
        subq.l  #1,%d2
        add.l   %d0,%d2
        move.l  sg_rh,%d3
        add.l   %a4,%d3
        bsr     sg_inv
8:      movem.l (%sp),%d2-%d5
        lea     16(%sp),%sp
9:      rts

| ---- ZOOM AND SCROLL (build 84): the 4-page window and the timeline, as the audio editor's knobs: F
|      (encoder 5) zooms -- 4, 8, 16, 32 or 64 steps a row (sg_zm 0-4; 16 at boot) at a pitch of 16, 8, 4,
|      2 or 1 px --, E (encoder 4) scrolls: the 4-page window's rows when they do not all fit (16 rows of
|      4 steps, 8 shown), the timeline further on through the arrangement (sg_tsc pages past its first;
|      sg_tupd). Both knobs are SymbolRefs on the shared encoder table (0x400c085a, 0x16 a record: E's
|      handler at 0x400c08b4, F's at 0x400c08ca; stock 0x40055008, the page's knob); in the 8-track view,
|      the panel's keyboard, a window or off the page the stock's. The timeline zoomed: a page in 2 or 4
|      segments down 2 or 4 rows (4 and 8 steps a row), or 2 or 4 pages side by side (32 and 64). The
|      note-length lines only at 16 a row.

| The zoom's figures for the view (Uses d0 d1): sg_zn columns a row, sg_zp the pitch, sg_zbw a bar's
| width less one, sg_zrt the 4-page window's rows, sg_zr those shown (up to 8), the timeline's pages
| sg_tne (8 at 16 a row), sg_tm segments to a page, sg_tpk pages to a row, sg_tcn columns a segment; the
| timeline's cursor kept on a page shown.
sg_zset:
        moveq   #SG_GX,%d0              | the grid's first column: x 64, the full view's x 0 (build 92);
        tst.l   sg_full                 | the full 8-track window's x 32, its labels left of it (build 99)
        beq.s   0f
        moveq   #0,%d0
        tst.l   sg_view
        bne.s   0f
        moveq   #SG_FTX,%d0
0:      move.l  %d0,sg_gx
        tst.l   sg_full                 | the full view: 16 or 32 columns (sg_fzr 2 / 3), 8 or 4 px (build
        beq.s   0f                      | 95; 32 only in 93-94, 32 or 64 at 2 px in 92); the 8-track
        moveq   #4,%d0                  | window's 6 or 3 px in the 96 right of its labels (build 99)
        move.l  sg_fzr,%d1
        lsl.l   %d1,%d0
        move.l  #128,%d1
        sub.l   sg_gx,%d1
        sub.l   sg_gx,%d1               | (the same column right of it, build 100)
        divu.l  %d0,%d1
        bra.s   1f
0:      moveq   #16,%d0
        moveq   #4,%d1
        tst.l   sg_view
        beq.s   1f
        moveq   #4,%d0                  | 4 << zoom
        move.l  sg_zm,%d1
        lsl.l   %d1,%d0
        moveq   #64,%d1
        divu.l  %d0,%d1                 | the pitch
1:      move.l  %d0,sg_zn
        move.l  %d1,sg_zp
        subq.l  #2,%d1                  | a bar: the pitch less one, 1 px at the least
        bpl.s   2f
        moveq   #0,%d1
2:      move.l  %d1,sg_zbw
        moveq   #64,%d1                 | the 4-page window's rows: 64 / columns, 8 shown at most
        divu.l  %d0,%d1
        move.l  %d1,sg_zrt
        moveq   #8,%d0
        cmp.l   %d0,%d1
        ble.s   3f
        move.l  %d0,%d1
3:      bsr     sg_fgrid                | the full 4-page grid at its own stride (knob D, build 107): the
        bne.s   4f                      | rows that fit in 56 px
        tst.l   sg_full
        beq.s   4f
        bsr     sg_fbof                 | under the bar: the rows that fit (build 114)
        tst.l   %d0
        beq.s   0f
        bsr     sg_fzfit
        bra.s   4f
0:      move.l  sg_fps,%d0
        beq.s   4f
        move.l  %d1,-(%sp)
        moveq   #56,%d1
        move.l  sg_fps,%d0
        divu.l  %d0,%d1
        move.l  %d1,%d0
        move.l  (%sp)+,%d1
        cmp.l   %d0,%d1
        ble.s   4f
        move.l  %d0,%d1
4:      move.l  %d1,sg_zr
        move.l  sg_zn,%d0               | the timeline: pages = columns / 2 (2-32), segments and pages a row
        lsr.l   #1,%d0
        move.l  %d0,sg_tne
        moveq   #1,%d0
        move.l  %d0,sg_tm
        move.l  %d0,sg_tpk
        moveq   #16,%d1
        move.l  sg_zn,%d0
        cmp.l   %d1,%d0
        bgt.s   4f
        move.l  %d0,sg_tcn              | 16 or fewer a row: sg_tm = 16 / columns
        divu.l  %d0,%d1
        move.l  %d1,sg_tm
        bra.s   5f
4:      move.l  %d1,sg_tcn              | more: sg_tpk = columns / 16
        lsr.l   #4,%d0
        move.l  %d0,sg_tpk
5:      moveq   #7,%d0                  | the timeline's row pitch: 7, the full timeline's knob D's (build
        tst.l   sg_full                 | 107): rows 50 / pitch + 1 (8 at 7, 3 at 17), its pages = rows
        beq.s   7f                      | x sg_tpk / sg_tm
        tst.l   sg_view
        beq.s   7f
        tst.l   sg_nlay
        beq.s   7f
        move.l  sg_ftpi,%d0             | (48 / pitch + 1 past 7: a readout row's band whole on the
        moveq   #50,%d1                 | screen)
        cmpi.l  #7,%d0
        beq.s   9f
        moveq   #48,%d1
9:      divu.l  %d0,%d1
        addq.l  #1,%d1
        move.l  %d0,-(%sp)
        moveq   #8,%d0
        cmp.l   %d0,%d1
        ble.s   8f
        move.l  %d0,%d1
8:      move.l  sg_tpk,%d0
        muls.l  %d0,%d1
        move.l  sg_tm,%d0
        divu.l  %d0,%d1
        move.l  %d1,sg_tne
        move.l  (%sp)+,%d0
7:      move.l  %d0,sg_tp
        move.l  sg_tne,%d0              | the timeline's cursor on a page shown
        subq.l  #1,%d0
        cmp.l   sg_trow,%d0
        bge.s   6f
        move.l  %d0,sg_trow
6:      rts

| The 4-page window: when the cursor's step moved, its row brought into view; the scroll kept within the
| rows. Uses d0 d1.
sg_zfol:
        tst.l   sg_view
        beq.s   9f
        tst.l   sg_nlay
        bne.s   9f
        move.l  sg_step,%d0
        cmp.l   sg_zlst,%d0
        beq.s   5f
        move.l  %d0,sg_zlst
        move.l  sg_zn,%d1
        divu.l  %d1,%d0                 | the cursor's row
        cmp.l   sg_zs,%d0
        bge.s   1f
        move.l  %d0,sg_zs
        bra.s   5f
1:      move.l  sg_zs,%d1
        add.l   sg_zr,%d1
        cmp.l   %d1,%d0
        blt.s   5f
        sub.l   sg_zr,%d0
        addq.l  #1,%d0
        move.l  %d0,sg_zs
5:      move.l  sg_zrt,%d0              | 0 .. rows - shown
        sub.l   sg_zr,%d0
        cmp.l   sg_zs,%d0
        bge.s   6f
        move.l  %d0,sg_zs
6:      tst.l   sg_zs
        bpl.s   9f
        clr.l   sg_zs
9:      rts

| Knobs E and F (enc, delta): see above.
sg_kenc:
        bsr     sg_free
        bne     8f
        moveq   #2,%d0                  | A B C in AUDIO (build 149): the page under the view is the audio
        cmp.l   4(%sp),%d0              | track's AMP page (audio mode), so only with a trig key down (a
        bcs.s   .Lke_f                  | lock, as the stock's), else nothing; B C in the MIDI views the
        tst.l   sg_aud                  | B C in the MIDI views: nothing (they were the stock's in 149 and
        bne.s   0f                      | changed the hidden ARP page's LEG and MODE)
        tst.l   4(%sp)
        bne     .Lke_eat
        bra.s   .Lke_f
0:      bsr     sg_tkd
        bne     8f
        rts
.Lke_f:
        moveq   #5,%d0                  | turning F: nothing in the view (build 143: F's press zooms,
        cmp.l   4(%sp),%d0              | sg_fkp, which comes through here with sg_fkx set)
        bne.s   .Lke_0
        tst.l   sg_fkx
        bne.s   .Lke_0
        rts
.Lke_0:
        tst.l   sg_full                 | the full view: both windows (build 92)
        bne.s   0f
        tst.l   sg_view
        beq     .Lke_eat
0:      tst.l   sg_win
        bne     .Lke_eat
        tst.l   sg_kb
        bne     .Lke_eat
        clr.l   sg_idle
        move.l  8(%sp),%d1              | the delta
        tst.l   4(%sp)                  | A in the pitch view: the cursor's note (build 133); else the stock's
        bne.s   0f
        tst.l   sg_pv
        beq     .Lke_eat
        tst.l   sg_mode
        beq     sg_pkaa
        bra     .Lke_eat
0:
        moveq   #2,%d0                  | B and C: nothing in the view. Every knob A-F comes here while the
        cmp.l   4(%sp),%d0              | view is up, and none falls through to the page underneath: the ARP
        bge     .Lke_eat                | page's TRAN..NLEN changed unseen (8 Nov 2026, the port)
        moveq   #3,%d0                  | D: the full timeline's row pitch (build 107)
        cmp.l   4(%sp),%d0
        beq     .Lke_d
        moveq   #5,%d0
        cmp.l   4(%sp),%d0
        bne 2f
        moveq   #1,%d0                  | F: the zoom a step that way
        tst.l   %d1
        bgt.s   1f
        moveq   #-1,%d0
1:      tst.l   sg_pv                   | the pitch view: nothing (build 132: encoder F's press steps the
        bne     7f                      | layout, sg_pfk; turning F did in 123-131)
        tst.l   sg_full                 | the full view: 16 or 32 a row, every window (build 95; 32 only in
        beq.s   0f                      | 94, 93's 64 in two lines unreachable)
        add.l   sg_fzr,%d0
        moveq   #2,%d1
        cmp.l   %d1,%d0
        blt     7f
        moveq   #3,%d1
        cmp.l   %d1,%d0
        bgt     7f
        move.l  %d0,sg_fzr
        moveq   #-1,%d0
        move.l  %d0,sg_zlst
        bsr     sg_zset
        lea     sg_fzm,%a0
        move.l  sg_zn,%d0
        bsr     sg_cmsg
        tst.l   sg_nlay
        beq.s   6f
        bsr     sg_tupd
        bra.s   6f
0:      add.l   sg_zm,%d0
        bmi.s   7f
        moveq   #2,%d1                  | 4, 8, 16 a row (build 91; 32 and 64 too in 84-90, for a view of
        cmp.l   %d1,%d0                 | their own later)
        bgt.s   7f
        move.l  %d0,sg_zm
        moveq   #-1,%d0                 | the cursor's row into view again
        move.l  %d0,sg_zlst
        bsr     sg_zset
        lea     sg_fzm,%a0              | "ZOOM 16" at the panel's top for 1.5 s (build 90)
        move.l  sg_zn,%d0
        bsr     sg_cmsg
        tst.l   sg_nlay
        beq.s   6f
        bsr     sg_tupd
        bra.s   6f
2:      tst.l   sg_pv                   | the pitch view: E moves the trig keys' notes (build 129)
        bne     sg_prng
        tst.l   sg_nlay                 | E: the timeline further on / back, or the rows
        beq.s   4f
        add.l   sg_tsc,%d1
        bpl.s   3f
        moveq   #0,%d1
3:      move.l  %d1,sg_tsc
        bsr     sg_tupd
        bra.s   6f
4:      add.l   %d1,sg_zs
6:      bra     sg_now
7:      rts
8:      jmp     0x40055008              | the view not up, or a stock window over it: the stock's knob
.Lke_eat:
        rts                             | the view is up: a knob it does not use does nothing
.Lke_d: tst.l   sg_pv                   | the pitch view's ROLL 16: its window a semitone (build 129)
        beq.s   0f
        tst.l   sg_plo
        beq     sg_pscr
        bra     sg_prsc                 | ROLL 32, KEYS 16: the range a semitone (build 136)
0:      tst.l   sg_full                 | only in the full view's PAGES: the timeline 7-17 px a row, fewer
        beq     .Lke_eat                      | rows the wider (sg_zset); the 4-page grid its rows 5 px apart up
        tst.l   sg_view                 | to the screen's height (sg_fstr); "SPACE 7"
        beq     .Lke_eat
        tst.l   sg_nlay
        bne.s   0f
        moveq   #1,%d0                  | the 4-page grid
        tst.l   %d1
        bgt.s   1f
        moveq   #-1,%d0
1:      add.l   sg_rs,%d0
        moveq   #5,%d1
        cmp.l   %d1,%d0
        blt     7b
        moveq   #28,%d1
        cmp.l   %d1,%d0
        bgt     7b
        move.l  %d0,sg_fps
        moveq   #-1,%d1                 | (the cursor's row into view again)
        move.l  %d1,sg_zlst
        bsr     sg_zset
        lea     sg_fsq,%a0
        move.l  sg_fps,%d0
        bsr     sg_cmsg
        bra     6b
0:      moveq   #1,%d0
        tst.l   %d1
        bgt.s   1f
        moveq   #-1,%d0
1:      add.l   sg_ftpi,%d0
        moveq   #7,%d1
        cmp.l   %d1,%d0
        blt     7b
        moveq   #17,%d1
        cmp.l   %d1,%d0
        bgt     7b
        move.l  %d0,sg_ftpi
        bsr     sg_zset
        lea     sg_fsq,%a0
        move.l  sg_ftpi,%d0
        bsr     sg_cmsg
        bsr     sg_tupd
        bra     6b

| ---- THE SCALE WINDOW (build 83): FUNC + SCALE (MKI) / FUNC + PAGE (MKII) on the page, in place of the
|      stock's PATTERN SCALE window (0x40059f88, the FUNC sub-map's 0x1b record): the whole screen, every
|      track's LEN and SCALE at once. PER TRACK (+0x8e55 set): the first row MASTER -- its LEN (+0x8e50,
|      a word: 2-1024, -1 INF, as 0x40038bc4 and the window's field 3 take it) and SCALE (+0x8e52) --,
|      then T1-T8: LEN (+0x48f8 of the track's record, 2-64, as 0x4004c6e0) and SCALE (+0x48f9, 0-6:
|      2X 3/2X 1X 3/4X 1/2X 1/4X 1/8X, as 0x40038b10; LEVEL right is faster, index down, as field 2),
|      each with a bar its LEN long. NORMAL: one row, the pattern's LEN (+0x8e53) and SCALE (+0x8e54).
|      UP / DOWN a row, LEFT / RIGHT LEN or SCALE (LEFT of LEN the row's number: YES there opens the
|      stock window for that track, build 106), LEVEL the value (with FUNC a LEN by 16), NO / YES or
|      FUNC + SCALE again close it. A value is written to the bank and its CS1 copy (0x1001614e + the
|      same offset), then the dirty flags (sg_dirty), 0x400339d8, 0x4009da20(-1) and the LEDs
|      (0x400486cc), as the LEN setter ends; its page copy into a newly reached empty page (0x4009a4fc)
|      is not done.
        .set    SG_WSC, 3               | sg_win: the scale window
| Build 85: any pattern of the bank -- the title row's first value is the pattern (sg_spat, the current
| one when the window opens; LEVEL steps through A01-A16), its scales shown and written. On the title row
| sg_scol 0 is the pattern, 1 MASTER's LEN, 2 its SCALE; on the tracks' rows 0 LEN, 1 SCALE (sg_svc).

| a0 = the pattern the window shows (sg_spat in the bank). Uses d0 d1 a0.
sg_spa:
        movea.l 0x46c82456,%a0
        move.l  sg_spat,%d0
        move.l  #SG_PSZ,%d1
        muls.l  %d1,%d0
        adda.l  %d0,%a0
        rts

| d0 = the value picked: -1 the pattern, 0 a LEN, 1 a SCALE (sg_scol less one on the title row). Uses d0.
sg_svc:
        move.l  sg_scol,%d0
        tst.l   sg_srow
        bne.s   1f
        subq.l  #1,%d0
1:      rts

| a0 = the window's pattern, d0 = its scale mode (+0x8e55: 0 NORMAL). Uses d0 d1 a0.
sg_smode:
        bsr     sg_spa
        move.l  #0x8e55,%d1
        moveq   #0,%d0
        move.b  (0,%a0,%d1.l),%d0
        rts

| d0 = a byte, d1 = its offset in the current pattern: written to the bank and the CS1 copy. Uses d1 a0 a1.
sg_swb:
        move.l  %d1,-(%sp)
        move.l  %d0,-(%sp)
        bsr     sg_spa
        move.l  (%sp)+,%d0
        move.l  (%sp)+,%d1
        adda.l  %d1,%a0
        move.b  %d0,(%a0)
        movea.l %a0,%a1
        suba.l  0x46c82456,%a1
        adda.l  #0x1001614e,%a1
        move.b  %d0,(%a1)
        rts

| d0 = a track: d0 = its LEN's offset in a pattern -- a MIDI track's 0x48f8 + 0x8b0 t, in AUDIO an audio
| track's 0x50 + 0x91a t (SCALE at + 1; build 116). Uses d1.
sg_sto:
        move.l  #0x8b0,%d1
        tst.l   sg_aud
        beq.s   1f
        move.l  #0x91a,%d1
1:      muls.l  %d1,%d0
        moveq   #0x50,%d1
        tst.l   sg_aud
        bne.s   2f
        move.l  #0x48f8,%d1
2:      add.l   %d1,%d0
        rts

| The window opened (build 116: from the stock SCALE window's SCALE, or its own key): the current
| pattern, the active track's row, LEN. Uses d0 d1 a0.
sg_sopen:
        moveq   #SG_WSC,%d0
        move.l  %d0,sg_win
        moveq   #0,%d0
        move.b  0x100b14d0,%d0
        move.l  %d0,sg_spat
        moveq   #0,%d0
        move.b  0x100b14cc,%d0
        addq.l  #1,%d0
        move.l  %d0,sg_srow
        bsr     sg_smode
        tst.l   %d0
        bne.s   3f
        moveq   #1,%d0
        move.l  %d0,sg_srow
3:      clr.l   sg_scol
        clr.l   sg_snum
        clr.l   sg_idle
        rts

| The window closed; opened from a stock page (sg_scret), back there (sg_mxout). Uses everything.
sg_sclose:
        clr.l   sg_win
        tst.l   sg_scret
        beq.s   9f
        clr.l   sg_scret
        bra     sg_mxout
9:      rts

| ---- FUNC + BANK twice (build 120): with the arranger on, FUNC + BANK opens the ARRANGER menu (stock,
|      the MKI FUNC sub-map's BANK record 0x400bf4a4, 0x40058a64), its cursor on EDIT; BANK again with
|      that menu still open (the popup slot 0x460d175c set) presses its YES for it (the key layer's 0x31
|      handler, 0x46c7d8de + 0x31 * 24): EDIT, the active arrangement. Anything else as the stock's.
sg_kfbank:
        moveq   #1,%d0
        cmp.l   8(%sp),%d0
        bne.s   8f
        tst.l   0x460d1aec              | the arranger off: the stock's (PATTERN SETTINGS)
        beq.s   8f
        tst.l   sg_abk                  | the second press, the menu still open: its YES
        beq.s   1f
        clr.l   sg_abk
        tst.l   0x460d175c
        beq.s   1f
        pea     1.w
        pea     0x31.w
        movea.l 0x46c7d8de+0x31*24,%a0
        jsr     (%a0)
        addq.l  #8,%sp
        rts
1:      moveq   #1,%d0                  | the first: noted, then the stock's menu
        move.l  %d0,sg_abk
8:      jmp     0x40058a64

| ---- THE STOCK SCALE WINDOW (build 116; its own keymap, MKI 0x400cb5b4..: SymbolRefs here)
|      SCALE (0x1b, stock 0x40056994: the length's pages cycled): the window closed (0x4005695c) and
|      ALL TRACK SCALES opened -- from a stock page in MIXER + MIDI's view (sg_mxin; AUDIO when the
|      Octatrack was in audio mode), NO / YES there back to that page. FUNC + SCALE closes it as ever.
|      UP / DOWN (stock 0x4004cca0 / 0x4004cf34: the value up / down): the row -- its fields 0-2 (LEN,
|      its pages, SCALE) and 3-4 (MASTER LEN and SCALE) in 0x460d1e00; DOWN from 0 / 1 to 3, 2 to 4, UP
|      from 3 to 0, 4 to 2 -- by the stock's RIGHT / LEFT (0x40048628 / 0x4004867c), so it redraws as
|      ever. LEVEL changes the values.
sg_scsc:
        moveq   #1,%d0
        cmp.l   8(%sp),%d0
        bne.s   9f
        tst.l   0x46c7dd26              | FUNC held: the stock's (it closes the window)
        bne.s   8f
        lea     -44(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        jsr     0x4005695c
        tst.l   sg_own
        bne.s   1f
        moveq   #0,%d0                  | AUDIO in audio mode (sg_mxin keeps the mode, build 149)
        tst.l   0x80000012
        bne.s   2f
        moveq   #1,%d0
2:      move.l  %d0,sg_aud
        bsr     sg_mxin
        bsr     sg_alab
        moveq   #1,%d0
        move.l  %d0,sg_scret
1:      bsr     sg_sopen
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     44(%sp),%sp
        bra     sg_now
8:      jmp     0x40056994
9:      rts
sg_scdn:
        moveq   #1,%d1
        bra.s   sg_scud
sg_scup:
        moveq   #0,%d1
sg_scud:
        tst.l   8(%sp)                  | a release: nothing
        beq.s   9f
        lea     -12(%sp),%sp
        movem.l %d2-%d4,(%sp)
        move.l  0x460d1e00,%d2          | d2: the field, d3: the field wanted
        moveq   #3,%d0
        tst.l   %d1
        beq.s   1f
        cmp.l   %d0,%d2                 | DOWN: on the first row
        bge.s   7f
        moveq   #3,%d3
        moveq   #2,%d0
        cmp.l   %d0,%d2
        bne.s   3f
        moveq   #4,%d3
        bra.s   3f
1:      cmp.l   %d0,%d2                 | UP: on the second row
        blt.s   7f
        moveq   #0,%d3
        moveq   #4,%d0
        cmp.l   %d0,%d2
        bne.s   3f
        moveq   #2,%d3
3:      move.l  %d3,%d4
        sub.l   %d2,%d4
        beq.s   7f
        bmi.s   5f
4:      pea     1.w                     | RIGHT d4 times
        pea     0x21.w
        jsr     0x40048628
        addq.l  #8,%sp
        subq.l  #1,%d4
        bne.s   4b
        bra.s   7f
5:      pea     1.w                     | LEFT -d4 times
        pea     0x34.w
        jsr     0x4004867c
        addq.l  #8,%sp
        addq.l  #1,%d4
        bne.s   5b
7:      movem.l (%sp),%d2-%d4
        lea     12(%sp),%sp
9:      rts

| The refresh after a scale value (the LEN setter's ending). Uses d0 d1 a0 a1.
sg_sref:
        bsr     sg_dirty
        jsr     0x400339d8
        pea     -1.w
        jsr     0x4009da20
        addq.l  #4,%sp
        jmp     0x400486cc

| FUNC + SCALE / PAGE (FUNC's sub-map 0x1b record, stock 0x40059f88; code, state): the window opens on
| the page (the active track's row), or closes. Anywhere else, or over the name's keyboard or a copy
| window, the stock's.
sg_kfscale:
        bsr     sg_keyfn
        bne.s   8f
        tst.l   sg_kb
        bne.s   8f
        move.l  sg_win,%d0
        beq.s   1f
        moveq   #SG_WSC,%d1
        cmp.l   %d1,%d0
        bne.s   8f
1:      tst.l   %d0                     | the window not open: the stock's SCALE window, as anywhere
        beq.s   8f                      | (build 116; its SCALE opens this one)
        moveq   #1,%d1
        cmp.l   8(%sp),%d1
        bne.s   9f
        clr.l   sg_idle
        tst.l   %d0
        beq.s   2f
        bsr     sg_sclose               | open: close
        tst.l   sg_own
        beq.s   9f
        bra     sg_now
2:      moveq   #SG_WSC,%d0
        move.l  %d0,sg_win
        moveq   #0,%d0                  | the current pattern (build 85)
        move.b  0x100b14d0,%d0
        move.l  %d0,sg_spat
        moveq   #0,%d0                  | the active track's row, LEN (NORMAL: its one row)
        move.b  0x100b14cc,%d0
        addq.l  #1,%d0
        move.l  %d0,sg_srow
        bsr     sg_smode
        tst.l   %d0
        bne.s   3f
        moveq   #1,%d0
        move.l  %d0,sg_srow
3:
        clr.l   sg_scol
        clr.l   sg_snum
        bra     sg_now
8:      jmp     0x40059f88
9:      rts

| The scale window's keys (from sg_wkey: code d0, a press): UP / DOWN a row (MASTER and T1-T8 in PER
| TRACK, the one row in NORMAL), LEFT / RIGHT the column, YES / NO close.
sg_skey:
        move.l  %d2,-(%sp)              | (d2 is the caller's, build 85)
        bsr.s   .Lsk_b
        move.l  (%sp)+,%d2
        tst.l   sg_own                  | (back on a stock page, sg_sclose: no redraw over it, build 116)
        beq.s   .Lsk_x
        bra     sg_now
.Lsk_x: rts
.Lsk_b:
        moveq   #0x31,%d1
        cmp.l   %d1,%d0
        bne.s   0f
        tst.l   sg_snum                 | YES on a row's number: the stock window for it (build 106)
        beq.s   7f
        bra     sg_sstk
0:      moveq   #0x32,%d1
        cmp.l   %d1,%d0
        bne.s   1f
7:      bra     sg_sclose
1:      moveq   #-1,%d1                 | UP / LEFT -1, DOWN / RIGHT +1
        cmpi.l  #0x33,%d0
        beq.s   2f
        cmpi.l  #0x34,%d0
        beq.s   2f
        moveq   #1,%d1
2:      cmpi.l  #0x33,%d0
        beq.s   3f
        cmpi.l  #0x20,%d0
        beq.s   3f
        tst.l   sg_snum                 | on a row's number (build 106): RIGHT back to its LEN
        beq.s   0f
        tst.l   %d1
        bmi     8f
        clr.l   sg_snum
        bra     8f
0:      add.l   sg_scol,%d1             | LEFT / RIGHT: LEN 0, SCALE 1; the title row the pattern 0, MASTER
        bpl.s   0f                      | 1-2 (NORMAL: the pattern only)
        tst.l   sg_srow                 | LEFT of a LEN: the row's number (build 106)
        beq     8f
        moveq   #1,%d1
        move.l  %d1,sg_snum
        bra     8f
0:
        move.l  %d1,-(%sp)
        bsr     sg_smode
        move.l  (%sp)+,%d1
        moveq   #1,%d2
        tst.l   sg_srow
        bne.s   4f
        moveq   #0,%d2
        tst.l   %d0
        beq.s   4f
        moveq   #2,%d2
4:      cmp.l   %d2,%d1
        bgt     8f
        move.l  %d1,sg_scol
        bra     8f
3:      move.l  %d1,-(%sp)              | UP / DOWN: 0-8 (NORMAL: 0-1), the value kept across the title row
        bsr     sg_smode
        move.l  (%sp)+,%d1
        moveq   #8,%d2
        tst.l   %d0
        bne.s   4f
        moveq   #1,%d2
4:      add.l   sg_srow,%d1
        bmi     8f
        cmp.l   %d2,%d1
        bgt     8f
        bsr     sg_svc                  | the value picked, then the row
        move.l  %d1,sg_srow
        tst.l   %d1
        bne.s   5f
        clr.l   sg_snum                 | (no number there, build 106)
        addq.l  #1,%d0                  | onto the title row: LEN / SCALE -> MASTER's (NORMAL: the pattern)
        cmpi.l  #1,%d2
        bne.s   6f
        moveq   #0,%d0
        bra.s   6f
5:      tst.l   %d0                     | onto a track's row: the pattern -> LEN
        bpl.s   6f
        moveq   #0,%d0
6:      move.l  %d0,sg_scol
8:      rts

| YES on a row's number (build 106): the window closes and the stock PATTERN SCALE window opens (FUNC +
| SCALE's 0x40059f88; its LEN / TOTAL fields, 1-16/16 ..), a track's row making that track the active
| one first (0x40083bf8). Uses d0 d1 a0 a1 (and what the stock's use).
sg_sstk:
        clr.l   sg_win
        clr.l   sg_snum
        bsr     sg_smode
        tst.l   %d0
        beq.s   1f
        move.l  sg_srow,%d0
        subq.l  #1,%d0
        bmi.s   1f
        move.l  %d0,sg_row              | (the cursor's track too, build 107)
        move.l  %d0,-(%sp)
        jsr     0x40083bf8
        addq.l  #4,%sp
1:      pea     1.w
        pea     0x2e.w
        jsr     0x40059f88
        addq.l  #8,%sp
        rts

| LEVEL in the scale window (from sg_wlvl, delta at 8(sp) of the handler's frame, passed in d0): the
| value picked. Uses everything but a5 a6 (saved here).
sg_slvl:
        lea     -24(%sp),%sp
        movem.l %d2-%d6/%a2,(%sp)
        move.l  %d0,%d2                 | d2: the delta
        clr.l   sg_idle
        tst.l   sg_snum                 | a row's number: no value (build 106)
        bne     .Lsl_x
        bsr     sg_svc
        move.l  %d0,%d5                 | d5: the value picked (-1 the pattern, 0 LEN, 1 SCALE)
        bpl.s   7f
        moveq   #1,%d0                  | the pattern: the next / the one before, A01-A16 (build 85)
        tst.l   %d2
        bgt.s   1f
        moveq   #-1,%d0
1:      add.l   sg_spat,%d0
        bmi     .Lsl_x
        moveq   #15,%d1
        cmp.l   %d1,%d0
        bgt     .Lsl_x
        move.l  %d0,sg_spat
        bra     .Lsl_x
7:      tst.l   SG_HELD+0x2d*24         | FUNC: a LEN by 16
        beq.s   0f
        tst.l   %d5
        bne.s   0f
        lsl.l   #4,%d2
0:      bsr     sg_smode
        movea.l %a0,%a2                 | a2: the pattern
        tst.l   %d0
        bne.s   .Lsl_pt
        move.l  #0x8e53,%d3             | NORMAL: the pattern's LEN / SCALE
        tst.l   %d5
        beq     .Lsl_len
        move.l  #0x8e54,%d3
        bra     .Lsl_scl
.Lsl_pt:
        move.l  sg_srow,%d0
        bne.s   2f
        tst.l   %d5                     | MASTER
        bne.s   1f
        movea.l %a2,%a0                 | its LEN: 2-1024 with INF (-1) between the ends, as field 3
        adda.l  #0x8e50,%a0
        move.w  (%a0),%d0
        ext.l   %d0
        add.l   %d2,%d0
        tst.l   %d2
        ble.s   3f
        cmpi.l  #1024,%d0               | up: past 1024 INF; from INF 2
        bgt.s   5f
        moveq   #1,%d1
        cmp.l   %d0,%d1
        blt.s   6f
        moveq   #2,%d0
        bra.s   6f
3:      moveq   #-1,%d1                 | down: below 2 INF; from INF 1024
        cmp.l   %d0,%d1
        ble.s   4f
        move.l  #1024,%d0
        bra.s   6f
4:      moveq   #1,%d1
        cmp.l   %d0,%d1
        blt.s   6f
5:      moveq   #-1,%d0
6:      move.l  %d0,%d4                 | the word, both copies
        move.l  #0x8e50,%d1
        lsr.l   #8,%d0
        bsr     sg_swb
        move.l  %d4,%d0
        move.l  #0x8e51,%d1
        bsr     sg_swb
        bra     .Lsl_ref
1:      move.l  #0x8e52,%d3             | its SCALE
        bra.s   .Lsl_scl
2:      subq.l  #1,%d0                  | a track: its record's +0x28 / +0x29 (an audio track's +0x50 /
        bsr     sg_sto                  | +0x51 in AUDIO, build 116)
        move.l  %d0,%d3
        tst.l   %d5
        beq.s   .Lsl_len
        addq.l  #1,%d3
.Lsl_scl:                               | d3: a SCALE's offset: 0-6, the index less the delta
        moveq   #0,%d0
        move.b  (0,%a2,%d3.l),%d0
        sub.l   %d2,%d0
        bpl.s   1f
        moveq   #0,%d0
1:      moveq   #6,%d1
        cmp.l   %d1,%d0
        ble.s   2f
        move.l  %d1,%d0
2:      move.l  %d3,%d1
        bsr     sg_swb
        bra.s   .Lsl_ref
.Lsl_len:                               | d3: a LEN's offset: 2-64
        move.b  (0,%a2,%d3.l),%d0
        extb.l  %d0
        add.l   %d2,%d0
        moveq   #2,%d1
        cmp.l   %d1,%d0
        bge.s   1f
        move.l  %d1,%d0
1:      moveq   #64,%d1
        cmp.l   %d1,%d0
        ble.s   2f
        move.l  %d1,%d0
2:      move.l  %d3,%d1
        bsr     sg_swb
.Lsl_ref:
        bsr     sg_sref
.Lsl_x:
        movem.l (%sp),%d2-%d6/%a2
        lea     24(%sp),%sp
        bra     sg_now

| d0 = a scale index 0-6: a1 = its label. Uses d0 a1.
sg_slab:
        lea     sg_sltab,%a1
        lsl.l   #2,%d0
        movea.l (0,%a1,%d0.l),%a1
        rts

| The scale window over the whole screen (from sg_run; a2 = the pattern): the title row, then MASTER
| and the tracks (PER TRACK) or the pattern's row (NORMAL). Rows of 7 px; a value picked inverted.
| Uses d0-d7 a0 a1 a3 (sg_run's own).
sg_sdraw:
        moveq   #0,%d0                  | the whole screen
        moveq   #0,%d1
        move.l  #127,%d2
        moveq   #63,%d3
        bsr     sg_clr
        moveq   #0,%d0                  | the pattern, "A01" (build 85; "SCALE" before), picked inverted
        move.b  0x80000002,%d0
        addi.l  #65,%d0
        move.l  sg_spat,%d1
        addq.l  #1,%d1
        move.l  %d1,-(%sp)
        move.l  %d0,-(%sp)
        pea     sg_fpt
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     16(%sp),%sp
        moveq   #0,%d2
        tst.l   sg_srow
        bne.s   1f
        tst.l   sg_scol
        bne.s   1f
        moveq   #1,%d2
1:      lea     sg_b1,%a1
        lea     SG_SMALL,%a0
        moveq   #2,%d0
        moveq   #58,%d1
        bsr     sg_tx
        bsr     sg_smode                | then PER TRK / NORMAL
        movea.l %a0,%a3                 | a3: the pattern
        lea     sg_fspt,%a1
        tst.l   %d0
        bne.s   1f
        lea     sg_fsnm,%a1
1:      move.l  %d0,%d7                 | d7: the mode
        lea     SG_SMALL,%a0
        moveq   #20,%d0
        moveq   #58,%d1
        moveq   #0,%d2
        bsr     sg_tx
        tst.l   %d7
        bne.s   .Lsd_pt
        moveq   #1,%d6                  | NORMAL: the pattern's row (row 1)
        lea     sg_fsal,%a1
        movea.l %a3,%a0
        adda.l  #0x8e50,%a0
        moveq   #0,%d0
        move.b  3(%a0),%d0
        moveq   #0,%d5
        move.b  4(%a0),%d5
        bsr     sg_srowd
        bra     .Lsd_e
.Lsd_pt:
        moveq   #8,%d6                  | T8 up to T1, then MASTER (build 86: bottom up, a text's cell
1:      lea     sg_b2,%a1               | clears a row over its glyphs, 6 px rows apart)
        move.b  #84,(%a1)
        moveq   #48,%d0
        add.l   %d6,%d0
        move.b  %d0,1(%a1)
        clr.b   2(%a1)
        move.l  %d6,%d0
        subq.l  #1,%d0
        bsr     sg_sto
        lea     (0,%a3,%d0.l),%a0
        moveq   #0,%d0
        move.b  (%a0),%d0
        moveq   #0,%d5
        move.b  1(%a0),%d5
        bsr     sg_srowd
        subq.l  #1,%d6
        bgt.s   1b
        moveq   #0,%d6                  | MASTER (row 0)
        lea     sg_fsms,%a1
        movea.l %a3,%a0
        adda.l  #0x8e50,%a0
        move.w  (%a0),%d0
        ext.l   %d0
        moveq   #0,%d5
        move.b  2(%a0),%d5
        bsr     sg_srowd
.Lsd_e: moveq   #0,%d0                  | a line under the title (row 6; 7 until 84), last (build 86)
        moveq   #6,%d1
        move.l  #127,%d2
        moveq   #6,%d3
        lea     SG_FILL,%a0
        bra     sg_r1

| One row of the scale window: d6 = its row (0 MASTER, 1-8 the tracks; NORMAL's one row is 1), a1 =
| its name, d0 = its LEN (-1 INF), d5 = its SCALE index. A track's row: the name at x 1, LEN
| right-aligned to x 22, SCALE from x 28, a bar its LEN long from x 60 (rows top + 2 .. top + 4); MASTER
| on the title's row from x 60, LEN to x 106, SCALE from x 110 (sg_srtop, sg_sxl, sg_sxs). Uses d0-d4
| a0 a1.
sg_srowd:
        lea     -12(%sp),%sp
        movem.l %d5-%d6/%a2,(%sp)
        move.l  %d0,%d4                 | d4: the LEN
        movea.l %a1,%a2
        bsr     sg_srtop                | d3: the row's top, d2: its name's x
        move.l  %d2,%d0
        lea     SG_SMALL,%a0
        movea.l %a2,%a1
        moveq   #58,%d1
        sub.l   %d3,%d1                 | y = 63 - (top + 5)
        moveq   #0,%d2                  | the name inverted when picked (build 106)
        cmp.l   sg_srow,%d6
        bne.s   0f
        move.l  sg_snum,%d2
0:      bsr     sg_tx
        move.l  %d4,-(%sp)              | the LEN, "INF" for -1
        pea     sg_fsd
        tst.l   %d4
        bpl.s   1f
        addq.l  #4,%sp
        pea     sg_fsin
1:      pea     sg_b1
        jsr     SG_SPRINTF
        lea     12(%sp),%sp
        lea     SG_SMALL,%a0
        lea     sg_b1,%a1
        bsr     sg_wid
        moveq   #0,%d2                  | picked?
        cmp.l   sg_srow,%d6
        bne.s   2f
        tst.l   sg_snum
        bne.s   2f
        move.l  %d0,-(%sp)
        bsr     sg_svc
        tst.l   %d0
        movem.l (%sp),%d0
        addq.l  #4,%sp
        bne.s   2f
        moveq   #1,%d2
2:      bsr     sg_sxl                  | d1: the LEN's right edge
        sub.l   %d0,%d1
        move.l  %d1,%d0
        moveq   #58,%d1
        sub.l   %d3,%d1
        lea     SG_SMALL,%a0
        lea     sg_b1,%a1
        bsr     sg_tx
        move.l  %d5,%d0                 | the SCALE
        bsr     sg_slab
        moveq   #0,%d2
        cmp.l   sg_srow,%d6
        bne.s   3f
        move.l  %a1,-(%sp)
        bsr     sg_svc
        movea.l (%sp)+,%a1
        subq.l  #1,%d0
        bne.s   3f
        moveq   #1,%d2
3:      bsr     sg_sxs                  | d0: the SCALE's x
        moveq   #58,%d1
        sub.l   %d3,%d1
        lea     SG_SMALL,%a0
        bsr     sg_tx
        tst.l   %d6                     | a bar for a track's (or the pattern's) LEN: from x 47 (60 until
        beq.s   9f                      | 85), 5 px for 4 steps, a page a segment of 20 px less a gap
        tst.l   %d4                     | (build 86)
        ble.s   9f
        move.l  %d3,%d1
        addq.l  #2,%d1                  | rows top + 2 .. top + 4
        addq.l  #4,%d3
        moveq   #0,%d5                  | d5: the page
1:      move.l  %d5,%d0
        lsl.l   #4,%d0
        cmp.l   %d4,%d0
        bge.s   9f
        move.l  %d4,%d2                 | its steps: LEN - 16 page, at most 16
        sub.l   %d0,%d2
        moveq   #16,%d0
        cmp.l   %d0,%d2
        ble.s   2f
        move.l  %d0,%d2
2:      move.l  %d2,%d0                 | its width: steps x 5 / 4, the gap off a full page
        add.l   %d0,%d0
        add.l   %d0,%d0
        add.l   %d2,%d0
        asr.l   #2,%d0
        moveq   #20,%d2
        cmp.l   %d2,%d0
        blt.s   3f
        moveq   #19,%d0
3:      move.l  %d5,%d2                 | x0 = 47 + 20 page
        lsl.l   #2,%d2
        add.l   %d5,%d2
        lsl.l   #2,%d2
        addi.l  #47,%d2
        move.l  %d1,-(%sp)
        movea.l %d2,%a1
        add.l   %d0,%d2
        subq.l  #1,%d2                  | x1
        move.l  %a1,%d0
        move.l  (%sp),%d1
        lea     SG_FILL,%a0
        bsr     sg_r1
        move.l  (%sp)+,%d1
        addq.l  #1,%d5
        moveq   #4,%d0
        cmp.l   %d0,%d5
        blt.s   1b
9:      movem.l (%sp),%d5-%d6/%a2
        lea     12(%sp),%sp
        rts

| d6 = a row: d3 = its top, d2 = its name's x. MASTER (0) shares the title's row from x 60; track row r
| (1-8) has its top at 7 r + 1 (rows 8-14 .. 57-63).
sg_srtop:
        move.l  %d6,%d3                 | rows of 6 px under the title: MASTER (0) at 7, its LEN and SCALE
        add.l   %d3,%d3                 | over the tracks' (build 85: on the title's row from x 60 before,
        move.l  %d3,%d2                 | the tracks 7 px apart); track r at 7 + 6 r (13 .. 55)
        add.l   %d2,%d3
        add.l   %d2,%d3
        addq.l  #7,%d3
        moveq   #1,%d2
        rts

| d6 = a row: d1 = its LEN's right edge (MASTER x 107 .. the tracks x 22). Uses d1.
sg_sxl:
        moveq   #22,%d1                 | (MASTER's too, build 85)
        rts

| d6 = a row: d0 = its SCALE's x (MASTER x 110, the tracks x 28). Uses d0.
sg_sxs:
        moveq   #28,%d0                 | (MASTER's too, build 85)
        rts

| The timeline's arrangement rows' patterns (sg_tnl, noted as the timeline drew: each row's top and its
| row << 8 | bank << 4 | pattern) on the panel's edge, right-aligned against the divider level with the
| row where that pattern begins (build 89; on line 2 before). The next row's (sg_tqx, sg_tl2set) carries
| the countdown before it, "3 A02" / "-- A02" (build 90; on line 2 in 89), flashes with the blink as
| line 2 did, and is inverted when line 2 is picked (LEVEL changes it there); the others are steady
| (89: the first flashed). Uses d0 d1 a0 a1.
sg_tnames:
        lea     -16(%sp),%sp
        movem.l %d2-%d5,(%sp)
        moveq   #0,%d5
1:      cmp.l   sg_tnc,%d5
        bge     9f
        lea     sg_tnl,%a0
        move.l  %d5,%d0
        lsl.l   #3,%d0
        adda.l  %d0,%a0
        move.l  (%a0),%d4               | d4: the row's top (SAVE at the panel's left since build 100:
2:      move.l  4(%a0),%d0              | no name left out for it)
        moveq   #15,%d1
        and.l   %d0,%d1
        addq.l  #1,%d1
        move.l  %d1,-(%sp)              | the pattern 1-16
        lsr.l   #4,%d0
        moveq   #15,%d1
        and.l   %d1,%d0
        addi.l  #65,%d0
        move.l  %d0,-(%sp)              | its bank's letter
        cmp.l   sg_tqx,%d5
        beq.s   5f
        pea     sg_fpt                  | "A03"
        bra.s   6f
5:      move.l  sg_tqs,%d0              | the next row's: "-- A02" stopped, "3 A02" the bars to come
        bpl.s   7f
        pea     sg_fcs
6:      pea     sg_b1
        jsr     SG_SPRINTF
        lea     16(%sp),%sp
        bra.s   8f
7:      moveq   #15,%d1                 | (the steps in bars, rounded up, 999 at most)
        add.l   %d1,%d0
        asr.l   #4,%d0
        move.l  #999,%d1
        cmp.l   %d1,%d0
        ble.s   6f
        move.l  %d1,%d0
6:      move.l  %d0,-(%sp)
        pea     sg_fcd
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     20(%sp),%sp
8:      lea     SG_SMALL,%a0
        lea     sg_b1,%a1
        bsr     sg_wid
        moveq   #57,%d3
        sub.l   %d0,%d3                 | d3: its x
        move.l  %d3,%d0                 | its cell cleared: x - 1 .. 57, the glyph's rows and one round
        subq.l  #1,%d0
        move.l  %d4,%d1
        subq.l  #2,%d1
        moveq   #57,%d2
        move.l  %d4,-(%sp)
        move.l  sg_rh,%d3
        add.l   %d4,%d3
        bsr     sg_clr
        move.l  (%sp)+,%d4
        lea     SG_SMALL,%a0
        lea     sg_b1,%a1
        bsr     sg_wid
        moveq   #57,%d3
        sub.l   %d0,%d3
        moveq   #0,%d2
        cmp.l   sg_tqx,%d5              | the next row's: picked inverted, else the flash
        bne.s   3f
        moveq   #SG_PB,%d0
        bsr     sg_hl
        tst.l   %d2
        bne.s   3f
        moveq   #32,%d0
        and.l   sg_bk,%d0
        bne.s   4f                      | the off phase: left out
3:      move.l  %d3,%d0
        moveq   #60,%d1
        sub.l   %d4,%d1                 | y = 64 - top - 4
        lea     SG_SMALL,%a0
        lea     sg_b1,%a1
        bsr     sg_tx
4:      addq.l  #1,%d5
        bra     1b
9:      movem.l (%sp),%d2-%d5
        lea     16(%sp),%sp
        rts

| Line 2 in the timeline (build 90, from sg_panel after sg_queue: d5 its steps, d7 1 = this row
| repeats): sg_tqx = the noted name (sg_tnl) whose row is the next row (sg_nrow, which sg_queue's sg_nxt
| just set), -1 none; sg_tl2 = 0 no names noted (Tracks view, the timeline at 64 a row), 1 no such name
| (repeating, scrolled past it): the count alone on line 2 from x 12 (as 89), 2 that name carries the
| count, line 2 empty; sg_tqs = d5. Uses nothing.
sg_tl2set:
        lea     -16(%sp),%sp
        movem.l %d0-%d2/%a0,(%sp)
        move.l  %d5,sg_tqs
        moveq   #-1,%d0
        move.l  %d0,sg_tqx
        clr.l   sg_tl2
        tst.l   sg_tnc
        beq.s   9f
        moveq   #1,%d0
        move.l  %d0,sg_tl2
        tst.l   %d7
        bne.s   9f
        move.l  sg_nrow,%d1
        bmi.s   9f
        lea     sg_tnl,%a0
        moveq   #0,%d0
1:      cmp.l   sg_tnc,%d0
        bge.s   9f
        move.l  4(%a0),%d2
        lsr.l   #8,%d2
        cmp.l   %d1,%d2
        beq.s   2f
        addq.l  #8,%a0
        addq.l  #1,%d0
        bra.s   1b
2:      move.l  %d0,sg_tqx
        moveq   #2,%d0
        move.l  %d0,sg_tl2
9:      movem.l (%sp),%d0-%d2/%a0
        lea     16(%sp),%sp
        rts

| PATTERN + a trig (the PATTERN layer's 16 records at 0x400bef04, 0x1a apart, their press handler
| 0x40056b2c; the one layer both models push, 0x4004346c): with the scale window up, that pattern of the
| bank is the window's (build 90; LEVEL on the title row as well), the stock's pattern change not made;
| the trig marked as gone with PATTERN (0x460d173e) so PATTERN's release closes the layer without its
| pattern window (0x4005a044). Elsewhere the stock's.
sg_kptrig:
        moveq   #SG_WSC,%d0
        cmp.l   sg_win,%d0
        bne.s   8f
        moveq   #1,%d0
        cmp.l   8(%sp),%d0
        bne.s   7f
        move.l  4(%sp),%d0
        moveq   #15,%d1
        and.l   %d1,%d0
        move.l  %d0,sg_spat
        moveq   #-1,%d0
        move.l  %d0,0x460d173e
        clr.l   sg_idle
        bra     sg_now
7:      rts
8:      jmp     0x40056b2c

| ---- THE STEP'S WINDOW (build 90): a second YES within 20 ticks of the one that opened the panel from
|      the grid (sg_kyes, sg_ytk) opens it over the whole screen: the cursor's step -- STEP, its four notes
|      with their octaves, VEL, LEN with its fraction -- in the big font. The panel stays open beneath and
|      the window shows its pick: UP / DOWN a line (STEP, the notes, VEL, LEN; wrapping), LEFT / RIGHT
|      along the notes, LEVEL the value as in the panel (sg_wlvl -> .Llv_ed), FUNC + UP / DOWN a note's
|      octave (sg_kfud), YES or NO close it and the panel (back to the grid). Drawn after the panel
|      (.Lsg_ncur), from its values (sg_nb, sg_pvb, sg_plv, sg_plf).

| The step's window's keys (from sg_wkey: code d0, a press).
sg_stkey:
        moveq   #0x31,%d1
        cmp.l   %d1,%d0
        beq.s   7f
        moveq   #0x32,%d1
        cmp.l   %d1,%d0
        bne.s   1f
7:      clr.l   sg_win
        clr.l   sg_mode
        bra     sg_now
1:      moveq   #-1,%d1                 | UP / LEFT -1, DOWN / RIGHT +1
        cmpi.l  #0x33,%d0
        beq.s   2f
        cmpi.l  #0x34,%d0
        beq.s   2f
        moveq   #1,%d1
2:      cmpi.l  #0x33,%d0
        beq.s   3f
        cmpi.l  #0x20,%d0
        beq.s   3f
        moveq   #0,%d0                  | LEFT / RIGHT: along the line (the notes')
        bsr     sg_pmove
        bra     sg_now
3:      move.l  %d1,-(%sp)              | UP / DOWN: across, kept to STEP .. LEN
        moveq   #1,%d0
        bsr     sg_pmove
        move.l  (%sp)+,%d1
        moveq   #SG_PS,%d0
        cmp.l   sg_prm,%d0
        ble.s   4f
        tst.l   %d1                     | off the top: LEN; off the bottom (past LEN to the name): STEP
        bpl.s   5f
        moveq   #SG_PN+5,%d0
5:      move.l  %d0,sg_prm
4:      bra     sg_now

| The step's window (sg_win = SG_WST): drawn last. Uses d0 d1 a0 a1.
        .set    SG_SWX, 8               | its first column
sg_stdraw:
        moveq   #SG_WST,%d0
        cmp.l   sg_win,%d0
        bne     9f
        lea     -24(%sp),%sp
        movem.l %d2-%d6/%a2,(%sp)
        tst.l   sg_full                 | the full view has no panel, and the panel's draw makes the values
        beq.s   0f                      | shown (sg_nb, sg_pvb, sg_plv, sg_plf): run it under the window, so
        bsr     sg_panel                | an edit shows (build 130; they stayed the opening's)
0:      moveq   #0,%d0                  | the screen cleared, the frame last (a text cell clears a row or
        moveq   #0,%d1                  | two above its glyph)
        moveq   #127,%d2
        moveq   #63,%d3
        bsr     sg_clr
        move.l  sg_step,%d0             | "STEP 05"
        addq.l  #1,%d0
        move.l  %d0,-(%sp)
        pea     sg_f4
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     12(%sp),%sp
        moveq   #SG_PS,%d0
        bsr     sg_hl
        lea     SG_BIG,%a0
        moveq   #SG_SWX,%d0
        moveq   #SG_SY0,%d1
        lea     sg_b1,%a1
        bsr     sg_tx
        moveq   #0,%d4                  | the notes: a label over each, NOTE NOT2 NOT3 NOT4, 28 px apart
        moveq   #SG_SWX,%d6
1:      lea     sg_fnl,%a1
        move.l  %d4,%d0
        lsl.l   #3,%d0
        adda.l  %d0,%a1
        lea     SG_SMALL,%a0
        move.l  %d6,%d0
        moveq   #SG_SY1,%d1
        moveq   #0,%d2
        bsr     sg_tx
        lea     sg_nb,%a0               | its name and octave together ("F+4", "D3"; "-" off)
        move.l  %d4,%d0
        lsl.l   #3,%d0
        adda.l  %d0,%a0
        lea     sg_b1,%a1
        movea.l %a0,%a2
2:      move.b  (%a2)+,%d0
        beq.s   3f
        cmpi.b  #43,%d0                 | (the big font's sharp: "#" for the small one's "+")
        bne.s   4f
        moveq   #35,%d0
4:      move.b  %d0,(%a1)+
        bra.s   2b
3:      lea     4(%a0),%a2
2:      move.b  (%a2)+,(%a1)+
        bne.s   2b
        move.l  %d4,%d0
        addi.l  #SG_PN,%d0
        bsr     sg_hl
        lea     SG_BIG,%a0
        move.l  %d6,%d0
        moveq   #SG_SY2,%d1
        lea     sg_b1,%a1
        bsr     sg_tx
        moveq   #28,%d0
        add.l   %d0,%d6
        addq.l  #1,%d4
        moveq   #4,%d0
        cmp.l   %d0,%d4
        blt     1b
        lea     sg_fvl,%a1              | VEL and LEN: labels, then their values
        lea     SG_SMALL,%a0
        moveq   #SG_SWX,%d0
        moveq   #SG_SY3,%d1
        moveq   #0,%d2
        bsr     sg_tx
        lea     sg_fln,%a1
        lea     SG_SMALL,%a0
        moveq   #SG_SWX+28,%d0
        moveq   #SG_SY3,%d1
        moveq   #0,%d2
        bsr     sg_tx
        moveq   #SG_PN+4,%d0
        bsr     sg_hl
        lea     SG_BIG,%a0
        moveq   #SG_SWX,%d0
        moveq   #SG_SY4,%d1
        lea     sg_pvb,%a1
        bsr     sg_tx
        move.l  sg_plv,-(%sp)           | "58", and its subdivision ("-5/8", "INF") on the line below
        pea     sg_fdn
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     12(%sp),%sp
        moveq   #SG_PN+5,%d0
        bsr     sg_hl
        lea     SG_BIG,%a0
        moveq   #SG_SWX+28,%d0
        moveq   #SG_SY4,%d1
        lea     sg_b1,%a1
        bsr     sg_tx
        moveq   #SG_PN+5,%d0
        bsr     sg_hl
        lea     SG_BIG,%a0
        moveq   #SG_SWX+28,%d0
        moveq   #SG_SY4-9,%d1
        lea     sg_plf,%a1
        bsr     sg_tx
        moveq   #1,%d0                  | the frame
        moveq   #1,%d1
        moveq   #126,%d2
        moveq   #62,%d3
        lea     SG_RECT,%a0
        bsr     sg_r1
        movem.l (%sp),%d2-%d6/%a2
        lea     24(%sp),%sp
9:      rts

| Z clear when NO's question is up for the cursor's step (build 91): asked (sg_nconf), its message
| still showing (sg_umt), the cursor where it was (sg_ncs, sg_ncp). Uses d0.
sg_nask:
        tst.l   sg_nconf
        beq.s   8f
        tst.l   sg_umt
        ble.s   8f
        move.l  sg_step,%d0
        cmp.l   sg_ncs,%d0
        bne.s   8f
        move.l  sg_cpat,%d0
        cmp.l   sg_ncp,%d0
        bne.s   8f
        moveq   #1,%d0
        rts
8:      tst.l   sg_nconf                | (asked, the cursor moved: its message goes too)
        beq.s   9f
        clr.l   sg_umt
9:      clr.l   sg_nconf
        moveq   #0,%d0
        rts

| The cursor's step deleted, as CLEAR's TRIG ("CLEAR 1"; another bank's row in the timeline: OTHER
| BANK). Keeps everything.
sg_ndel:
        lea     -48(%sp),%sp
        movem.l %d0-%d7/%a2-%a5,(%sp)
        bsr     sg_cedit
        beq.s   2f
        lea     sg_fob,%a0
        bsr     sg_cmsg0
        bra.s   3f
2:      moveq   #1,%d6
        moveq   #0,%d3
        bsr     sg_cop
3:      movem.l (%sp),%d0-%d7/%a2-%a5
        lea     48(%sp),%sp
        rts

| ---- THE FULL VIEW (build 92): FUNC + ARP on the page (FUNC's sub-map 0x23 records' press handler,
|      stock 0x400322f0, the ARP SETUP menu's opener; SymbolRefs in both keymaps) turns it on and off, in
|      both windows (ARP still flips them). The grid takes the whole screen (sg_gx 0, no panel, divider or
|      row numbers): the 8-track window shows each track's 64 steps (2 px a step) or the cursor's 32 (4
|      px), the 4-page window and the timeline 32 or 64 a row (knob F, sg_fzr; "ZOOM 32" at the top for
|      1.5 s). LEFT / RIGHT go along all 64 steps, wrapping. The title row: TRKS: / PAGES: and the name
|      at the left (a message there while it shows), the pattern playing and the zoom ("64/R") at the
|      right. With no panel, opening it (YES, a held trig) opens the step's window.

| d3 = the step of column d4 (a6 + d4); in the full view (build 94) that mod the track's length (d6), its
| steps repeated across the 32 columns. Uses d0 d1.
sg_fstep:
        move.l  %a6,%d3
        add.l   %d4,%d3
        tst.l   sg_full
        beq.s   9f
        tst.l   %d6
        ble.s   9f
        move.l  %d3,%d0
        divu.l  %d6,%d0
        muls.l  %d6,%d0
        sub.l   %d0,%d3
9:      rts

| The full view's play column for the row's track (build 94; d5 its step playing, d6 its length): the
| last column at or before the pattern's count (0x800065b4; the 4-page window's 64 its count mod 64)
| whose step (mod d6) is the one playing, in the columns' numbering (a6 + column), -1 none. Uses d0 d1.
sg_fpcs:
        moveq   #-1,%d0
        move.l  %d0,sg_fpc
        tst.l   sg_full
        beq.s   9f
        tst.l   %d5
        bmi.s   9f
        tst.l   %d6
        ble.s   9f
        moveq   #0,%d0
        move.w  0x800065b4,%d0          | P
        tst.l   sg_view
        beq.s   1f
        moveq   #63,%d1
        and.l   %d1,%d0
1:      move.l  %d0,-(%sp)
        sub.l   %d5,%d0                 | (P - step) mod length, made positive
        move.l  %d0,%d1
        divs.l  %d6,%d1
        muls.l  %d6,%d1
        sub.l   %d1,%d0
        bpl.s   2f
        add.l   %d6,%d0
2:      move.l  (%sp)+,%d1
        sub.l   %d0,%d1                 | P less that
        move.l  %d1,sg_fpc
9:      rts

| Z clear in the full 8-track window's 64, two lines of 32 a track (build 93). Uses d0.
sg_f2l:
        bra.s   8f                      | (build 94: the full view is 32 a row only; 93's 64 in two
        tst.l   sg_full                 | lines unreachable, kept for later)
        beq.s   8f
        tst.l   sg_view
        bne.s   8f
        moveq   #4,%d0
        cmp.l   sg_fzr,%d0
        bne.s   8f
        moveq   #1,%d0
        rts
8:      moveq   #0,%d0
        rts

| The full timeline's readout of an arrangement row (build 95; sg_tl entry d7, flag 8, its row at +12),
| a screen row of its own over the row's pages, inverted across the screen. At the left the row (field
| 0, build 100), a flashing 4-3-2-1 over the last 4 steps before this row starts when it is the next
| (build 100), its pattern (1), repetitions (2, +2 plus one), M when it mutes (+4 / +5); right-aligned
| (build 100) its offset (3, +10, a word), length (4, the end at +12 less the offset) and scenes A / B
| (5 / 6, +8 / +9, 0xff none, 1-based as the ARR editor shows them): "R01 3 A01 X4 M ... OF3 LN16
| S3/12" (S-/- for none; "S03/03" in 95-99). Each field's middle x noted (sg_fxc) for UP / DOWN from
| the steps (sg_tmvv). Uses d0 d1 a0 a1.
sg_tinfo:
        lea     -36(%sp),%sp
        movem.l %d2-%d7/%a2-%a4,(%sp)
        move.l  %d7,%d0                 | its screen row: entry / pages a row; its top 7 r + 10
        move.l  sg_tpk,%d1
        divu.l  %d1,%d0
        move.l  sg_fband,%d1            | (noted for sg_fdots, build 97)
        bset    %d0,%d1
        move.l  %d1,sg_fband
        move.l  sg_tp,%d1               | (the pitch, build 107)
        muls.l  %d1,%d0
        addi.l  #10,%d0
        move.l  %d0,%d6                 | d6: the top
        moveq   #-9,%d5                 | d5: the field picked, -9 none (the cursor on this row, build 98)
        cmp.l   sg_trow,%d7
        bne.s   1f
        move.l  sg_tcol,%d5
1:      move.l  %d7,%d0
        lsl.l   #4,%d0
        lea     sg_tl,%a0
        move.w  12(%a0,%d0.l),%d0
        ext.l   %d0
        move.l  %d0,%d3                 | d3: the row
        bsr     sg_trrow
        movea.l %a0,%a3                 | a3: its record
        moveq   #1,%d4                  | d4: x
        move.l  %d3,-(%sp)              | "R01", field 0
        pea     sg_fr1
        moveq   #0,%d2
        bsr     sg_tip
        moveq   #0,%d0                  | "A01", field 1 (the count's place after the row gone: build 105)
        move.b  21(%a3),%d0
        moveq   #15,%d1
        and.l   %d0,%d1
        addq.l  #1,%d1
        move.l  %d1,-(%sp)
        lsr.l   #4,%d0
        addi.l  #65,%d0
        move.l  %d0,-(%sp)
        pea     sg_fpt
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     16(%sp),%sp
        moveq   #1,%d2
        bsr     sg_tip0
        moveq   #0,%d0                  | "X4", field 2
        move.b  22(%a3),%d0
        addq.l  #1,%d0
        move.l  %d0,-(%sp)
        pea     sg_fr2
        moveq   #2,%d2
        bsr     sg_tip
        tst.w   24(%a3)                 | "M" when it mutes
        beq.s   3f
        lea     sg_b1,%a1
        move.w  #0x4d00,(%a1)
        moveq   #-1,%d2
        bsr     sg_tip0
3:      bsr     sg_tmid                 | (the count in the middle, build 105)
        moveq   #127,%d4                | the right: d4 its right edge, from the scenes back
        lea     sg_b1,%a1               | "/12", field 6
        move.b  #47,(%a1)+
        moveq   #0,%d0
        move.b  29(%a3),%d0
        bsr     sg_tisc
        moveq   #6,%d2
        moveq   #1,%d3
        bsr     sg_tipr
        lea     sg_b1,%a1               | "S3", field 5
        move.b  #83,(%a1)+
        moveq   #0,%d0
        move.b  28(%a3),%d0
        bsr     sg_tisc
        moveq   #5,%d2
        moveq   #4,%d3
        bsr     sg_tipr
        moveq   #0,%d0                  | "LN16", field 4
        move.w  32(%a3),%d0
        moveq   #0,%d1
        move.w  30(%a3),%d1
        sub.l   %d1,%d0
        move.l  %d0,-(%sp)
        pea     sg_fr4
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     12(%sp),%sp
        moveq   #4,%d2
        moveq   #0,%d3                  | (the offset's colon against it, build 113)
        bsr     sg_tipr
        moveq   #0,%d0                  | "OF3", field 3
        move.w  30(%a3),%d0
        move.l  %d0,-(%sp)
        pea     sg_fr3
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     12(%sp),%sp
        moveq   #3,%d2
        moveq   #4,%d3
        bsr     sg_tipr
        moveq   #0,%d0                  | the row inverted across the screen
        move.l  %d6,%d1
        subq.l  #2,%d1
        moveq   #127,%d2
        move.l  %d6,%d3
        addq.l  #4,%d3
        bsr     sg_inv
        movem.l (%sp),%d2-%d7/%a2-%a4
        lea     36(%sp),%sp
        rts
| A readout piece (sg_tinfo's frame: d4 x, d5 the field picked, d6 the top, d7 the entry): the format
| and one argument on the stack (sg_tip, popped here) or sg_b1 ready (sg_tip0); d2 its field (-1 none),
| boxed (inverted before the row's inversion, so it shows light) when picked, its middle noted
| (sg_fxc); x moves on past it and 4 px.
sg_tip:
        move.l  8(%sp),-(%sp)
        move.l  8(%sp),-(%sp)
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     12(%sp),%sp
        move.l  (%sp)+,%a0              | (the return)
        addq.l  #8,%sp
        move.l  %a0,-(%sp)
sg_tip0:
        moveq   #0,%d0
        cmp.l   %d5,%d2
        bne.s   1f
        moveq   #1,%d0
1:      move.l  %d2,-(%sp)
        move.l  %d0,%d2
        lea     SG_SMALL,%a0
        move.l  %d4,%d0
        moveq   #60,%d1
        sub.l   %d6,%d1
        lea     sg_b1,%a1
        bsr     sg_tx
        move.l  (%sp)+,%d2
        bsr     sg_fxn
        add.l   %d0,%d4
        addq.l  #4,%d4
        rts
| Right-aligned (build 100): sg_b1 ending at x d4 - 1, d2 its field, d3 the gap before the next; d4
| moves back past it and the gap.
sg_tipr:
        lea     SG_SMALL,%a0
        lea     sg_b1,%a1
        bsr     sg_wid
        sub.l   %d0,%d4
        bsr     sg_tip0
        sub.l   %d0,%d4                 | (sg_tip0 moved d4 on by the width and 4)
        subq.l  #4,%d4
        sub.l   %d3,%d4
        rts
| Field d2's middle (d4 + width d0 / 2) noted for the entry d7 (sg_fxc + 8 d7 + d2). Uses a0.
sg_fxn:
        tst.l   %d2
        bmi.s   9f
        move.l  %d1,-(%sp)
        move.l  %d0,%d1
        lsr.l   #1,%d1
        add.l   %d4,%d1
        lea     sg_fxc,%a0
        adda.l  %d2,%a0
        move.l  %d7,-(%sp)
        lsl.l   #3,%d7
        move.b  %d1,(%a0,%d7.l)
        move.l  (%sp)+,%d7
        move.l  (%sp)+,%d1
9:      rts
| The next row's count in the middle of its readout (build 105; a 4-3-2-1 after the row number over the
| last 4 steps in 100-104): the bars left before it starts, rounded up, in a 4-place field at x 56-71
| whose place moves right as it falls -- "4...", ".3..", "..2.", "...1" (more than 4 at the 4's place),
| flashing with the beat (sg_bk bit 5). d3 the row, d5 d6 as sg_tinfo's; keeps d4. Uses d0 d1 a0 a1.
sg_tmid:
        tst.l   0x800065b8
        beq.s   9f
        bsr     sg_queue                | (it notes the next row, sg_nrow)
        tst.l   %d0
        bmi.s   9f
        cmp.l   sg_nrow,%d3
        bne.s   9f
        tst.l   %d1
        ble.s   9f
        moveq   #32,%d0
        and.l   sg_bk,%d0
        bne.s   9f
        moveq   #15,%d0
        add.l   %d0,%d1
        asr.l   #4,%d1                  | the bars
        move.l  %d2,-(%sp)
        move.l  %d4,-(%sp)
        move.l  %d1,-(%sp)
        pea     sg_fsd
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     8(%sp),%sp
        addq.l  #4,%sp
        bsr     sg_cmid                 | centred on x 64, a digit's place (build 113)
        moveq   #-1,%d2
        bsr     sg_tip0
        move.l  (%sp)+,%d4
        move.l  (%sp)+,%d2
9:      rts
| d4 = the x that centres sg_b1 on x 64 (build 113). Uses d0 d1 a0 a1.
sg_cmid:
        lea     SG_SMALL,%a0
        lea     sg_b1,%a1
        bsr     sg_wid
        moveq   #64,%d4
        lsr.l   #1,%d0
        sub.l   %d0,%d4
        rts
sg_tisc:                                | a scene d0 (0xff none) at a1: "-" or 1-16 (build 100; two
        cmpi.l  #0xff,%d0               | characters in 95-99); the string ended
        bne.s   1f
        move.b  #45,(%a1)+
        clr.b   (%a1)
        rts
1:      addq.l  #1,%d0
        moveq   #10,%d1
        cmp.l   %d1,%d0
        blt.s   2f
        move.b  #49,(%a1)+
        sub.l   %d1,%d0
2:      addi.l  #48,%d0
        move.b  %d0,(%a1)+
        clr.b   (%a1)
        rts

| The full view's guides down the grid (build 97): at 32 a row one down the middle, between steps 16
| and 17; at 16 a row one every 4 steps -- in the gap after a column's bar (x0 + 16 or 4 pitches - 1).
| Since build 101 only between the rows, 2 px midway between one row's foot and the next's (7 r + 9
| and 10 over screen row r's foot at 7 r + 13), none beside the steps; at 32 a row a single dot after
| every 4th step too (build 98), now at 7 r + 10, a pixel over the 3-px steps' tops. Not over or into
| a readout row (sg_fband, sg_tinfo). Uses d0 d1 a0 a1.
sg_fdots:
        lea     -24(%sp),%sp
        movem.l %d2-%d7,(%sp)
        moveq   #16,%d5                 | d5: the steps between the lines
        moveq   #32,%d0
        cmp.l   sg_zn,%d0
        beq.s   0f
        moveq   #4,%d5
        moveq   #16,%d0
        cmp.l   sg_zn,%d0
        bne     9f
0:      move.l  sg_zp,%d0               | d5 the lines' spacing, d6 the grid's end
        muls.l  %d0,%d5
        move.l  sg_zn,%d6
        muls.l  %d0,%d6
        add.l   sg_gx,%d6
        subq.l  #1,%d6
        moveq   #1,%d7                  | d7: the screen row under the gap, 1-7
.Lsg_fdr:
        bsr     sg_fgrid
        beq.s   0f
        move.l  sg_fband,%d0
        btst    %d7,%d0
        bne     .Lsg_fdn
        move.l  %d7,%d1                 | (nor under one, build 107)
        subq.l  #1,%d1
        btst    %d1,%d0
        bne     .Lsg_fdn
0:      bsr     sg_fgap                 | d3: the gap's lower row, 7 r + 10 (build 107: sg_fgap)
        move.l  sg_gx,%d4               | the lines: 2 px each
        add.l   %d5,%d4
        subq.l  #1,%d4
1:      cmp.l   %d6,%d4
        bge.s   2f
        move.l  sg_fl0,%d1              | (its rows: sg_fgap's, centred since build 114)
        cmp.l   sg_fl1,%d1
        bgt.s   5f
        move.l  %d4,%d0
        move.l  %d4,%d2
        move.l  %d3,-(%sp)
        move.l  sg_fl1,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
        move.l  (%sp)+,%d3
5:      add.l   %d5,%d4
        bra.s   1b
2:      moveq   #32,%d0                 | 32 a row: a dot after every 4th step, the middle's line left out
        cmp.l   sg_zn,%d0
        bne.s   .Lsg_fdn
        move.l  %d5,%d2
        lsr.l   #2,%d2                  | (4 pitches)
        move.l  sg_gx,%d4
        add.l   %d2,%d4
        subq.l  #1,%d4
3:      cmp.l   %d6,%d4
        bge.s   .Lsg_fdn
        move.l  sg_gx,%d0
        add.l   %d5,%d0
        subq.l  #1,%d0
        cmp.l   %d0,%d4
        beq.s   4f
        move.l  %d4,%d0
        move.l  %d3,%d1
        move.l  %d2,-(%sp)
        move.l  %d4,%d2
        move.l  %d3,-(%sp)
        move.l  sg_fd0,%d1              | (the dots' rows: sg_fgap's, build 114)
        move.l  sg_fd1,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
        move.l  (%sp)+,%d3
        move.l  (%sp)+,%d2
4:      add.l   %d2,%d4
        bra.s   3b
.Lsg_fdn:
        addq.l  #1,%d7
        bsr     sg_fgn                  | (the rows, build 107)
        cmp.l   %d0,%d7
        blt     .Lsg_fdr
9:      movem.l (%sp),%d2-%d7
        lea     24(%sp),%sp
        rts

| d1 = a 4-page row stride: the full 4-page grid's own (knob D, sg_fps) when set (build 107). Uses d1.
sg_fstr:
        tst.l   sg_full
        beq.s   9f
        bsr     sg_fgrid
        bne.s   9f
        tst.l   sg_fps
        beq.s   1f
        move.l  sg_fps,%d1
9:      rts
1:      move.l  %d0,-(%sp)              | (under the bar: sg_fzfit's, build 114)
        bsr     sg_fbof
        tst.l   %d0
        beq.s   2f
        move.l  sg_fdst,%d1
2:      move.l  (%sp)+,%d0
        rts

| Build 107: Z set in the full 4-page window's own grid (sg_view, not the timeline), its rows sg_rs apart
| (knob D). Uses nothing.
| d0 = the full 4-page grid's pattern bar's height (8; 0 elsewhere -- the timeline has its readouts;
| build 113). Uses d0.
sg_fbof:
        moveq   #0,%d0
        tst.l   sg_full
        beq.s   9f
        tst.l   sg_view
        beq.s   9f
        tst.l   sg_nlay
        bne.s   9f
        tst.l   sg_pv
        bne.s   9f
        moveq   #8,%d0
9:      rts

| The full 4-page grid's pattern bar (build 113; a2 the pattern): the arranger off, a band as the
| timeline's readout rows, inverted across the screen at rows 8-14 -- the pattern at the left ("A01"),
| when one is to come the bars left (rounded up, flashing as the readout's count) centred on x 64 and
| that pattern after it, the cursor's track's length at the right: "A01 ... 3 A02 ... 64".
| Uses d0 d1 a0 a1.
sg_pbar:
        bsr     sg_fbof
        tst.l   %d0
        beq     9f
        lea     -32(%sp),%sp
        movem.l %d2-%d7/%a3/%a6,(%sp)
        moveq   #0,%d0                  | the pattern
        move.b  0x100b14d0,%d0
        moveq   #15,%d1
        and.l   %d1,%d0
        addq.l  #1,%d0
        move.l  %d0,-(%sp)
        moveq   #0,%d0
        move.b  0x80000002,%d0
        addi.l  #65,%d0
        move.l  %d0,-(%sp)
        pea     sg_fpt
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     16(%sp),%sp
        lea     SG_SMALL,%a0
        moveq   #1,%d0
        moveq   #50,%d1
        moveq   #0,%d2
        lea     sg_b1,%a1
        bsr     sg_tx
        move.l  sg_row,%d1              | the cursor's track's length at the right
        bsr     sg_trk
        move.l  %d6,-(%sp)
        pea     sg_fsd
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     12(%sp),%sp
        lea     SG_SMALL,%a0
        lea     sg_b1,%a1
        bsr     sg_wid
        move.l  #127,%d4
        sub.l   %d0,%d4
        lea     SG_SMALL,%a0
        move.l  %d4,%d0
        moveq   #50,%d1
        moveq   #0,%d2
        lea     sg_b1,%a1
        bsr     sg_tx
        tst.l   0x800065b8              | one to come, playing: the count and it
        beq     8f
        bsr     sg_queue
        tst.l   %d0
        bmi     8f
        tst.l   %d1
        ble     8f
        move.l  %d0,%d5                 | d5: it
        moveq   #32,%d0
        and.l   sg_bk,%d0
        bne     8f
        moveq   #15,%d0
        add.l   %d0,%d1
        asr.l   #4,%d1                  | the bars
        move.l  %d1,-(%sp)
        pea     sg_fsd
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     12(%sp),%sp
        bsr     sg_cmid
        lea     SG_SMALL,%a0
        move.l  %d4,%d0
        moveq   #50,%d1
        moveq   #0,%d2
        lea     sg_b1,%a1
        bsr     sg_tx
        moveq   #15,%d0                 | the pattern to come, after it
        and.l   %d5,%d0
        addq.l  #1,%d0
        move.l  %d0,-(%sp)
        move.l  %d5,%d0
        lsr.l   #4,%d0
        moveq   #15,%d1
        and.l   %d1,%d0
        addi.l  #65,%d0
        move.l  %d0,-(%sp)
        pea     sg_fpt
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     16(%sp),%sp
        lea     SG_SMALL,%a0
        moveq   #70,%d0
        moveq   #50,%d1
        moveq   #0,%d2
        lea     sg_b1,%a1
        bsr     sg_tx
8:      moveq   #0,%d0                  | the band inverted
        moveq   #8,%d1
        moveq   #127,%d2
        moveq   #14,%d3
        bsr     sg_inv
        movem.l (%sp),%d2-%d7/%a3/%a6
        lea     32(%sp),%sp
9:      rts

sg_fgrid:
        tst.l   sg_view
        beq.s   1f
        tst.l   sg_nlay                 | Z set: the grid; clear: the timeline
        rts
1:      move.w  #0,%ccr                 | the 8-track window: Z clear
        rts

| d7 = a gap (1 ..): d3 its lower guide row, sg_fdy the dot row (a pixel over the next steps' tops):
| between the foot of the steps above (F) and the top of those below (T), d3 = (F + T + 3) / 2 -- in
| the timeline and the 8-track window T = sg_tp r + 11 and F = T - sg_tp + 2 (7 r + 10 both at 7), in
| the full 4-page grid T = sg_rs (r + 1) + 4 and F = sg_rs r + 6 (build 107). Uses d0 d1 d3.
sg_fgap:
        move.l  %d2,-(%sp)              | F (d2) and T (d1)
        bsr     sg_fgrid
        bne.s   1f
        move.l  %d7,%d0                 | the full 4-page grid: its rows (sg_frow)
        subq.l  #1,%d0
        bsr     sg_frow
        addq.l  #2,%d0
        move.l  %d0,%d2
        move.l  %d7,%d0
        bsr     sg_frow
        move.l  %d0,%d1
        bra.s   2f
1:      move.l  sg_tp,%d0               | the timeline and the 8-track window
        move.l  %d7,%d1
        muls.l  %d0,%d1
        addi.l  #11,%d1
        move.l  %d1,%d2
        sub.l   %d0,%d2
        addq.l  #2,%d2
2:      tst.l   sg_view                 | the 8-track window: as before 114 (TRKS not yet centred)
        bne.s   3f
        move.l  %d1,%d3
        add.l   %d2,%d3
        addq.l  #3,%d3
        asr.l   #1,%d3
        subq.l  #1,%d1
        move.l  %d1,sg_fd0
        move.l  %d1,sg_fd1
        move.l  %d3,sg_fl1
        subq.l  #1,%d3
        move.l  %d3,sg_fl0
        addq.l  #1,%d3
        move.l  (%sp)+,%d2
        rts
3:      bsr     sg_fgc
        move.l  sg_fl1,%d3
        move.l  (%sp)+,%d2
        rts
| A gap centred (builds 114-115, UI_RULES.md): F (d2) the last row of the steps above, T (d1) the
| first of those below, g = T - F - 1 blank rows. The 4-step dots: 1 px in an odd gap, 2 px in an even
| one; the 16-step page marker on the same centre, 2 px taller (3 / 4), filling a gap of 3 or 4, the
| dots' height in a gap of 2; the same blank above and below each. At 16 a row the 4-step lines are dots.
| Uses d0 d1.
sg_fgc:
        move.l  %d4,-(%sp)
        move.l  %d1,%d4                 | d4: T
        sub.l   %d2,%d1
        subq.l  #1,%d1                  | d1: g
        moveq   #1,%d0                  | h: 2 - (g & 1)
        and.l   %d1,%d0
        neg.l   %d0
        addq.l  #2,%d0
        move.l  %d1,-(%sp)
        bsr.s   .Lfgc_c                 | the dots
        move.l  %d0,-(%sp)
        move.l  sg_fl0,%d0
        move.l  %d0,sg_fd0
        move.l  sg_fl1,%d0
        move.l  %d0,sg_fd1
        move.l  (%sp)+,%d0
        move.l  (%sp)+,%d1
        moveq   #16,%d1                 | 16 a row: the lines are the dots
        cmp.l   sg_zn,%d1
        beq.s   9f
        move.l  %d4,%d1                 | the page marker: h + 2 where it fits
        sub.l   %d2,%d1
        subq.l  #1,%d1
        addq.l  #2,%d0                  | (filling a gap too small for a clear pixel, so it still
        cmp.l   %d1,%d0                 | stands out from the dots)
        ble.s   1f
        subq.l  #2,%d0
1:      bsr.s   .Lfgc_c
9:      move.l  (%sp)+,%d4
        rts
.Lfgc_c:                                | height d0 centred in gap d1 under F (d2): sg_fl0 .. sg_fl1
        move.l  %d0,-(%sp)
        sub.l   %d0,%d1
        asr.l   #1,%d1
        add.l   %d2,%d1
        addq.l  #1,%d1
        move.l  %d1,sg_fl0
        add.l   (%sp),%d1
        subq.l  #1,%d1
        move.l  %d1,sg_fl1
        move.l  (%sp)+,%d0
        rts

| d0 = the full 4-page grid's row d0's top (build 114): under the bar (rows 8-14) by the margin, then
| sg_rs apart. Uses d0 d1.
sg_frow:
        move.l  sg_rs,%d1
        muls.l  %d1,%d0
        move.l  %d0,-(%sp)
        move.l  sg_rs,%d1
        bsr     sg_fgm
        add.l   (%sp)+,%d0
        addi.l  #15,%d0
        rts

| d0 = the margin for a stride d1 (build 114): the blank between a centre line (1 or 2 px) and a row,
| (g - 1) / 2 with g = d1 - 3 the blank between two rows; 0 below 1. Uses d0.
sg_fgm:
        move.l  %d1,%d0
        subq.l  #4,%d0
        bpl.s   1f
        moveq   #0,%d0
1:      asr.l   #1,%d0
        rts

| d1 = the rows wanted: the full 4-page grid's rows that fit under its bar (build 114) -- with knob D's
| stride (sg_fps) fewer rows; without it the stride (14 to 4 rows, 7 to more, as the 4-page window's)
| narrowed until they all fit, kept in sg_fdst. Top row + 3 <= 64: 18 + m + (n - 1) s <= 64. Uses d0 d1.
sg_fzfit:
        lea     -12(%sp),%sp
        movem.l %d2-%d4,(%sp)
        move.l  %d1,%d3                 | d3: the rows
        move.l  sg_fps,%d2              | d2: the stride
        bne.s   2f
        moveq   #7,%d2
        moveq   #4,%d0
        cmp.l   %d0,%d3
        bgt.s   1f
        moveq   #14,%d2
1:      bsr.s   .Lfz_ok
        beq.s   3f
        moveq   #5,%d0
        cmp.l   %d0,%d2
        ble.s   2f
        subq.l  #1,%d2
        bra.s   1b
2:      bsr.s   .Lfz_ok                 | still not: fewer rows
        beq.s   3f
        moveq   #1,%d0
        cmp.l   %d0,%d3
        ble.s   3f
        subq.l  #1,%d3
        bra.s   2b
3:      move.l  %d2,sg_fdst
        move.l  %d3,%d1
        movem.l (%sp),%d2-%d4
        lea     12(%sp),%sp
        rts
.Lfz_ok:                                | Z set: d3 rows at stride d2 fit
        move.l  %d2,%d1
        bsr     sg_fgm
        move.l  %d3,%d4
        subq.l  #1,%d4
        muls.l  %d2,%d4
        add.l   %d4,%d0
        addi.l  #18,%d0
        moveq   #64,%d1
        cmp.l   %d1,%d0
        bgt.s   8f
        moveq   #0,%d0
        rts
8:      moveq   #1,%d0
        rts

| d0 = past the last gap: the full 4-page grid's rows shown (sg_zr), else the screen rows (sg_tne /
| sg_tpk: 8 at 7 px; build 107). Uses d0 d1.
sg_fgn:
        bsr     sg_fgrid
        bne.s   1f
        move.l  sg_zr,%d0
        rts
1:      move.l  sg_tne,%d0
        move.l  sg_tpk,%d1
        divu.l  %d1,%d0
        rts

| The full 8-track window's label for track d7 (build 99), a4 its row's top: its number at x 6-8 in the
| left column (build 100; "A01:1" at x 1-29 in 99, the pattern now in the title row), the foot on the
| steps'; as the 8-track window's numbers (builds 75-82) M in turn when muted, with the blink, and the
| active track's inverted. Uses d0 d1 a0 a1.
sg_flab:
        lea     -8(%sp),%sp
        movem.l %d2-%d3,(%sp)
        lea     sg_b2,%a1
        moveq   #49,%d1                 | the track's number, or M
        add.l   %d7,%d1
        move.l  sg_mm,%d0
        btst    %d7,%d0
        beq.s   1f
        moveq   #32,%d0
        and.l   sg_bk,%d0
        beq.s   1f
        moveq   #77,%d1
1:      move.b  %d1,(%a1)
        clr.b   1(%a1)
        lea     SG_SMALL,%a0
        moveq   #SG_FLD,%d0
        moveq   #64,%d1
        sub.l   %a4,%d1
        sub.l   sg_rh,%d1
        moveq   #0,%d2
        bsr     sg_tx
        tst.l   sg_tnum                 | the cursor on the number (build 144; build 146: it flashes, its
        beq.s   .Lfl_n                  | cell inverted in the cursor's blink phase, as the step cursor;
        cmp.l   sg_row,%d7              | the box of 144-145 gone)
        bne.s   .Lfl_n
        moveq   #32,%d0
        and.l   sg_bk,%d0
        beq.s   .Lfl_n
        moveq   #SG_FLD-1,%d0
        move.l  sg_rh,%d3
        add.l   %a4,%d3
        moveq   #-6,%d1
        add.l   %d3,%d1
        moveq   #SG_FLD+3,%d2
        bsr     sg_inv
.Lfl_n: moveq   #0,%d0                  | the active track's: inverted, the glyph and a pixel round it
        move.b  0x100b14cc,%d0
        cmp.l   %d7,%d0
        bne.s   9f
        moveq   #SG_FLD-1,%d0
        move.l  sg_rh,%d3
        add.l   %a4,%d3
        moveq   #-6,%d1
        add.l   %d3,%d1
        moveq   #SG_FLD+3,%d2
        bsr     sg_inv
9:      movem.l (%sp),%d2-%d3
        addq.l  #8,%sp
        rts

| Z clear when column d4 of the row (a6 its first step, d6 the track's length) may show the cursor: in the
| full view only its first column (the steps repeat across it; the 8-track window counted from its
| first step, sg_fwin; the 4-page window from step 1); elsewhere always (build 98). Uses d0 d1.
sg_fcur1:
        tst.l   sg_tnum                 | (the cursor on the track number: none on the steps, build 143)
        beq.s   .Lfc_0
        moveq   #0,%d0
        rts
.Lfc_0: tst.l   sg_full
        beq.s   9f
        tst.l   %d6
        ble.s   9f
        move.l  %a6,%d0
        add.l   %d4,%d0
        tst.l   sg_view
        bne.s   1f
        sub.l   sg_fwin,%d0
1:      cmp.l   %d6,%d0
        bge.s   8f
9:      moveq   #1,%d0
        rts
8:      moveq   #0,%d0
        rts

| Z clear when the full timeline's cursor is on a readout row (build 98). Uses d0 a0.
sg_trd:
        tst.l   sg_full
        beq.s   8f
        bsr     sg_tlon
        beq.s   8f
        move.l  sg_trow,%d0
        lsl.l   #4,%d0
        lea     sg_tl,%a0
        adda.l  %d0,%a0
        btst    #3,15(%a0)
        beq.s   8f
        moveq   #1,%d0
        rts
8:      moveq   #0,%d0
        rts

| LEVEL on a readout row (build 98; d0 the delta): field sg_tcol of its arrangement row -- 0 the row
| itself (nothing; build 100, the fields after it one on), 1 the pattern
| (+1, 0-255: A01-P16), 2 the repetitions (+2, 0-63: X1-X64), 3 the offset (+10, a word, 0-255; the
| length kept, the end at +12 moved with it), 4 the length (the end +12 less the offset, 1-1024), 5 / 6
| scenes A / B (+8 / +9: none (0xff), 1-16) -- written in the arrangement in use, marked unsaved as the
| ARR editor does (sg_patlv). Uses d0 d1 a0 a1.
sg_aedit:
        lea     -12(%sp),%sp
        movem.l %d2-%d4,(%sp)
        move.l  %d0,%d2                 | d2: the delta
        move.l  sg_trow,%d0
        lsl.l   #4,%d0
        lea     sg_tl,%a0
        move.w  12(%a0,%d0.l),%d0
        ext.l   %d0
        bsr     sg_trrow
        tst.l   %d0
        beq     9f                      | not a pattern row
        move.l  sg_tcol,%d3             | (field 0 the row: no edit, build 100)
        subq.l  #1,%d3
        bmi     9f
        tst.l   %d3
        bne.s   1f
        moveq   #0,%d0                  | the pattern
        move.b  21(%a0),%d0
        add.l   %d2,%d0
        move.l  #255,%d1
        bsr     sg_aclamp
        move.b  %d0,21(%a0)
        bra     8f
1:      subq.l  #1,%d3
        bne.s   2f
        moveq   #0,%d0                  | the repetitions
        move.b  22(%a0),%d0
        add.l   %d2,%d0
        moveq   #63,%d1
        bsr     sg_aclamp
        move.b  %d0,22(%a0)
        bra     8f
2:      subq.l  #1,%d3
        bne.s   3f
        moveq   #0,%d4                  | the offset; d4: the length
        move.w  32(%a0),%d4
        moveq   #0,%d0
        move.w  30(%a0),%d0
        sub.l   %d0,%d4
        add.l   %d2,%d0
        move.l  #255,%d1
        bsr     sg_aclamp
        move.w  %d0,30(%a0)
        add.l   %d4,%d0
        move.w  %d0,32(%a0)
        bra.s   8f
3:      subq.l  #1,%d3
        bne.s   4f
        moveq   #0,%d0                  | the length
        move.w  32(%a0),%d0
        moveq   #0,%d4
        move.w  30(%a0),%d4
        sub.l   %d4,%d0
        add.l   %d2,%d0
        subq.l  #1,%d0                  | (1-1024 as 0-1023)
        move.l  #1023,%d1
        bsr     sg_aclamp
        addq.l  #1,%d0
        add.l   %d4,%d0
        move.w  %d0,32(%a0)
        bra.s   8f
4:      lea     28(%a0),%a1             | the scenes: none = -1, 0-15
        subq.l  #1,%d3
        beq.s   5f
        lea     29(%a0),%a1
5:      moveq   #0,%d0
        move.b  (%a1),%d0
        cmpi.l  #0xff,%d0
        bne.s   6f
        moveq   #-1,%d0
6:      add.l   %d2,%d0
        addq.l  #1,%d0                  | (-1..15 as 0..16)
        moveq   #16,%d1
        bsr     sg_aclamp
        subq.l  #1,%d0
        move.b  %d0,(%a1)               | (-1 -> 0xff)
8:      movea.l 0x10000000,%a0          | unsaved
        moveq   #0,%d0
        move.w  16(%a0),%d0
        moveq   #1,%d1
        or.l    %d1,%d0
        move.w  %d0,16(%a0)
        bsr     sg_tupd
9:      movem.l (%sp),%d2-%d4
        lea     12(%sp),%sp
        rts
sg_aclamp:                              | d0 kept to 0..d1
        tst.l   %d0
        bpl.s   1f
        moveq   #0,%d0
1:      cmp.l   %d1,%d0
        ble.s   2f
        move.l  %d1,%d0
2:      rts

| ---- MIXER + MIDI (build 108): with MIXER held, MIDI opens the step editor's full view from anywhere --
|      MIDI mode on (0x40055548, the MIDI key's own switch, when it was off), the ARP page (0x4005578c with
|      the AMP/ARP page key 0x23, the last key cleared so it is not a double press), the full view --
|      and the MIXER window it opened closed (0x4007d274). Again: the MIDI side's page before it back
|      (page 0-4 -> key 0x22 0x24 0x23 0x25 0x26, the inverse of 0x400a7280), then audio mode back when
|      it was on, the full view as it was. Leaving the page another way (a page key, MIDI) ends it too,
|      nothing put back (sg_poll). The MIDI key's press, repeat and release in both keymaps are
|      SymbolRefs here; with MIXER up, or after the combo's press, the stock's (0x40055678), the combo's
|      repeat and release swallowed.
sg_kmidi:
        move.l  8(%sp),%d0
        tst.l   sg_mxk                  | the combo's own repeat / release: on the release its work, as
        beq     1f                      | the stock's MIDI key switches on its release (0x40055714; the
        tst.l   %d0                     | switch called on the press hung the unit under the port)
        bne     9f
        clr.l   sg_mxk
        tst.l   sg_mxa                  | MIDI alone in the view: AUDIO on / off
        beq.s   0f
        clr.l   sg_mxa
        moveq   #1,%d0                  | the other side: the Octatrack's mode with it, the view on its
        sub.l   sg_aud,%d0              | page 2 (sg_amode, build 149)
        bsr     sg_amode
        tst.l   sg_aud
        bne.s   .Lkm_a
        bsr     sg_mled                 | (AUDIO off: the LED back, build 116)
.Lkm_a: clr.l   sg_pv
        clr.l   sg_mode
        tst.l   sg_aud                  | (AUDIO from the panel view: TRKS -- no panel in AUDIO, build 141)
        beq.s   .Lkm_b
        tst.l   sg_full
        bne.s   .Lkm_b
        moveq   #1,%d0
        move.l  %d0,sg_full
        clr.l   sg_view
        moveq   #-1,%d0
        move.l  %d0,sg_zlst
        bsr     sg_zset
.Lkm_b: bsr     sg_alab
        bra     sg_now
0:
        lea     -40(%sp),%sp
        movem.l %d2-%d7/%a2-%a5,(%sp)
        tst.l   sg_own
        beq.s   3f
        movem.l (%sp),%d2-%d7/%a2-%a5   | in the view: the next window, TRKS -> PAGES -> PITCH (build
        lea     40(%sp),%sp             | 112; out of the view in 108-111, now a page key's)
        clr.l   sg_mode
        bra     sg_vflip
3:      bsr     sg_mxin
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        bra     sg_now
9:      rts
1:      moveq   #1,%d1
        cmp.l   %d1,%d0
        bne.s   8f
        tst.l   SG_HELD+0x30*24         | MIXER down
        bne.s   0f
        tst.l   sg_own                  | in the combo's view, MIDI alone: MIDI / AUDIO tracks (build 110)
        beq.s   8f
        move.l  %d1,sg_mxk
        move.l  %d1,sg_mxa
        rts
0:      move.l  %d1,sg_mxk
        move.l  %d1,sg_mxu              | (MIXER's release: no window, build 111)
        tst.l   0x460e7424              | a MIXER window already open: closed
        beq.s   9b
        jmp     0x4007d274
8:      jmp     0x40055678

| MIXER (code, state; both keymaps' press and release, stock 0x4007d468 / 0x4007d320; build 111): the
| press does nothing, the release does what the press did (the MIXER window opens, or closes) unless
| MIDI was pressed while it was held (MIXER + MIDI, sg_mxu). Holding MIXER no longer opens it, so the
| stock's hold-and-let-go closing (0x4007d320) is not used.
sg_kmix:
        move.l  8(%sp),%d0
        moveq   #1,%d1
        cmp.l   %d1,%d0
        bne.s   1f
        clr.l   sg_mxu                  | a press: nothing yet
        rts
1:      tst.l   %d0
        bne.s   9f                      | a repeat: nothing
        tst.l   sg_mxu                  | the release: the window, unless the combo used it
        bne.s   2f
        jmp     0x4007d468
2:      clr.l   sg_mxu
9:      rts

| The Octatrack's mode to the side the view shows (build 149): d0 = 1 AUDIO (audio mode), 0 MIDI. A
| switch is the stock's own (0x40055548, as the MIDI key's release calls it; on a press it hung the
| unit under the port, build 108), landing on the other side's page 2 (ARP / AMP: 0x460d1688 set
| first); in the view (sg_own) the stock's track follows the cursor's row (trig keys, LEDs, FUNC +
| BANK's trig edit, a held trig's locks: the audio track's in AUDIO). sg_aud is set before a switch to
| audio mode and cleared after one to MIDI mode, so sg_vis holds through the switch's redraws.
| Uses d0 d1 a0 a1.
sg_amode:
        tst.l   %d0
        beq.s   5f
        moveq   #1,%d1
        move.l  %d1,sg_aud
        tst.l   0x80000012              | MIDI mode: to audio mode
        beq.s   9f
        bra.s   6f
5:      tst.l   0x80000012              | audio mode: to MIDI mode
        bne.s   7f
6:      moveq   #2,%d1
        move.l  %d1,0x460d1688
        clr.l   -(%sp)                  | (code, 0) as the MIDI key's release passes them: it writes its
        pea     0x35.w                  | first argument's slot (0x4005566a) before its tail call
        jsr     0x40055548
        addq.l  #8,%sp
        tst.l   sg_own
        beq.s   7f
        move.l  sg_row,%d0
        bsr     sg_tsel
7:      tst.l   0x80000012
        beq.s   9f
        clr.l   sg_aud
9:      rts

| In: the view's side's mode (sg_aud: AUDIO in audio mode, build 149; MIDI mode before), page 2 (the
| ARP page, the AMP page in AUDIO), the full view (sg_own). The mode before it (sg_oam) and each
| side's page before it (sg_omp MIDI, sg_oap audio) kept for sg_mxout. Uses everything but a5 a6.
sg_mxin:
        clr.l   sg_oam
        move.l  0x460d1684,%d0
        move.l  0x460d1688,%d1
        tst.l   0x80000012
        bne.s   1f
        moveq   #1,%d2                  | audio mode
        move.l  %d2,sg_oam
        move.l  %d0,sg_oap
        move.l  %d1,sg_omp
        bra.s   2f
1:      move.l  %d0,sg_omp
        move.l  %d1,sg_oap
2:      move.l  sg_aud,%d0
        bsr     sg_amode
        moveq   #2,%d0                  | not on page 2: the ARP / AMP page by its key (the last key
        cmp.l   0x460d1684,%d0          | cleared so it is not a double press)
        beq.s   3f
        moveq   #-1,%d0
        move.l  %d0,0x400c0aac
        pea     1.w
        pea     0x23.w
        jsr     0x4005578c
        addq.l  #8,%sp
3:      move.l  sg_full,%d0
        move.l  %d0,sg_ofull
        moveq   #60,%d0
        move.l  %d0,sg_ownw
        moveq   #1,%d0
        move.l  %d0,sg_own
        move.l  %d0,sg_on               | the view's page drawn: leaving it runs sg_rest (build 141; the
        move.l  %d0,sg_pnew             | page key's draw came before sg_own, so it never did -- the view
        move.l  %d0,sg_full             | stayed on the stock's page in the tempo's corner)
        clr.l   sg_mode
        clr.l   sg_win
        clr.l   sg_idle
        moveq   #-1,%d0
        move.l  %d0,sg_zlst
        bsr     sg_zset
        tst.l   sg_nlay
        beq.s   9f
        bsr     sg_tupd
9:      rts

| Out: the full view as it was. From AUDIO (audio mode, build 149) the mode stays: the MIDI side's
| page before it back (0x460d1688), the audio side's by its key. From the MIDI views: the MIDI side's
| page by its key, the audio side's back, and audio mode back when it was on before (sg_oam), on that
| page. Uses everything but a5 a6.
sg_mxout:
        bsr     sg_aoff
        clr.l   sg_pv
        clr.l   sg_own
        clr.l   sg_mode
        clr.l   sg_win
        move.l  sg_ofull,%d0
        move.l  %d0,sg_full
        tst.l   0x80000012
        beq.s   5f
        move.l  sg_oap,%d0              | MIDI mode: the audio side's page back
        move.l  %d0,0x460d1688
        move.l  sg_omp,%d0              | the MIDI side's by its key
        bsr     sg_pgo
        tst.l   sg_oam
        beq.s   9f
        clr.l   -(%sp)                  | audio mode back (as the MIDI key's release passes them: it
        pea     0x35.w                  | writes its first argument's slot, 0x4005566a, before its
        jsr     0x40055548              | tail call)
        addq.l  #8,%sp
        bra.s   9f
5:      move.l  sg_omp,%d0              | audio mode: the MIDI side's page back
        move.l  %d0,0x460d1688
        move.l  sg_oap,%d0              | the audio side's by its key
        bsr     sg_pgo
9:      rts

| Page d0 (0-4) by its key (sg_pgk), the last key cleared so it is not a double press; page 2 (the
| view's own, ARP / AMP) not: the caller draws it (sg_nout). Uses everything but a5 a6.
sg_pgo:
        moveq   #2,%d1
        cmp.l   %d1,%d0
        beq.s   9f
        moveq   #4,%d1
        cmp.l   %d1,%d0
        bhi.s   9f
        lea     sg_pgk,%a0
        moveq   #0,%d1
        move.b  (0,%a0,%d0.l),%d1
        moveq   #-1,%d0
        move.l  %d0,0x400c0aac
        pea     1.w
        move.l  %d1,-(%sp)
        jsr     0x4005578c
        addq.l  #8,%sp
        moveq   #-1,%d0                 | and cleared after it: a page key leaving the view (sg_pkey)
        move.l  %d0,0x400c0aac          | is the stock's next, not a double press (its SETUP)
9:      rts

| ---- AN AUDIO TRACK PASTED ON A MIDI TRACK (build 113): the stock's track copy (GRID RECORDING, FUNC +
|      REC: 0x4002993c(pattern, track) copies the audio track's record to the clipboard 0x460c8122, type
|      0x460d0ffa = 4) and its MIDI track paste (FUNC + STOP: 0x4002b62c(pattern, track), which pastes
|      only a MIDI track's clipboard, type 8) -- both calls SymbolRefs here. The copy notes whether the
|      track is OCTA-303 (sg_o3s) and its Part's TUNE; the paste, with type 4, builds a MIDI track's
|      clipboard from the destination's own record, Part page-1 values (+0x8b0) and setup (+0x9a0) --
|      so those are written back unchanged -- with the audio track's steps converted, and hands it to the
|      stock's MIDI track writer (0x4002b470: bank, CS1, Part, dirty flags), as a MIDI track's paste.
|      Converted: the trig, trigless and swing masks; each step's trig word (+0x89a + 2 s -> +0x830 + 2 s:
|      micro timing, count, condition); a step's pitch -- OCTA-303: TUNE (its lock, or the Part's) - 16 as
|      the NOTE lock, an ACC lock above 0 as VEL 101-127, a trigless step after a note a note too with the
|      note before it held over it (LEN 6 a step + 3) so 303 FOLLOW slides; any other machine: a PTCH lock
|      as NOTE = the MIDI track's NOTE + PTCH - 64. Other locks are not carried (they are other knobs on
|      a MIDI track).

| ---- A MIDI TRACK PASTED ON AN AUDIO TRACK (build 116): the stock's audio track paste (FUNC + STOP in
|      GRID RECORDING, 0x4005eb50's call to 0x4002b988(pattern, track), after its undo snapshot) with a
|      MIDI track's clipboard (type 8): the audio track's record edited in place, bank and CS1 copy --
|      its trig, trigless and swing masks (MIDI +0x18 -> +0x40), each step's trig word (+0x830 + 2 s ->
|      +0x89a + 2 s), LEN and SCALE (+0x28 / +0x29 -> +0x50 / +0x51); its p-lock and slide masks and its
|      locks cleared (a MIDI track's locks are other knobs). Its machine and Part untouched. d0 = 1.
sg_apst:
        moveq   #8,%d0
        cmp.l   0x460d0ffa,%d0
        beq.s   1f
        jmp     0x4002b988
1:      lea     -16(%sp),%sp
        movem.l %d2-%d3/%a2-%a3,(%sp)
        move.l  20(%sp),%d0             | the pattern
        move.l  24(%sp),%d1             | the track
        lea     0x460c8122,%a0
        bsr     sg_m2a
        movem.l (%sp),%d2-%d3/%a2-%a3
        lea     16(%sp),%sp
        moveq   #1,%d0
        rts

| a0 = a MIDI track's record, d0 = a pattern, d1 = an audio track: that track's record from it (above),
| both copies, the dirty flags. Uses d0-d3 a0-a3.
sg_m2a:
        move.l  #0x8ed8,%d2
        muls.l  %d2,%d0
        move.l  #0x91a,%d2
        muls.l  %d2,%d1
        add.l   %d1,%d0
        movea.l 0x46c82456,%a2          | a2: the audio track's record
        adda.l  %d0,%a2
        movea.l %a2,%a3                 | a3: its CS1 copy
        suba.l  0x46c82456,%a3
        adda.l  #0x1001614e,%a3
        moveq   #0,%d2
1:      move.b  (0,%a0,%d2.l),%d0       | the masks
        move.b  %d0,(0,%a2,%d2.l)
        move.b  %d0,(0,%a3,%d2.l)
        move.b  (8,%a0,%d2.l),%d0
        move.b  %d0,(8,%a2,%d2.l)
        move.b  %d0,(8,%a3,%d2.l)
        clr.b   (16,%a2,%d2.l)
        clr.b   (16,%a3,%d2.l)
        move.b  (24,%a0,%d2.l),%d0
        move.b  %d0,(64,%a2,%d2.l)
        move.b  %d0,(64,%a3,%d2.l)
        clr.b   (72,%a2,%d2.l)
        clr.b   (72,%a3,%d2.l)
        addq.l  #1,%d2
        moveq   #8,%d0
        cmp.l   %d0,%d2
        blt.s   1b
        move.b  0x28(%a0),%d0           | LEN and SCALE
        move.b  %d0,0x50(%a2)
        move.b  %d0,0x50(%a3)
        move.b  0x29(%a0),%d0
        move.b  %d0,0x51(%a2)
        move.b  %d0,0x51(%a3)
        move.l  #0x800,%d2              | no locks
        moveq   #-1,%d0
        lea     0x59(%a2),%a1
2:      move.b  %d0,(%a1)+
        subq.l  #1,%d2
        bne.s   2b
        move.l  #0x800,%d2
        lea     0x59(%a3),%a1
3:      move.b  %d0,(%a1)+
        subq.l  #1,%d2
        bne.s   3b
        move.l  #0x7f,%d2               | the trig words
4:      move.l  %d2,%d1
        addi.l  #0x830,%d1
        move.b  (0,%a0,%d1.l),%d0
        move.l  %d2,%d1
        addi.l  #0x89a,%d1
        move.b  %d0,(0,%a2,%d1.l)
        move.b  %d0,(0,%a3,%d1.l)
        subq.l  #1,%d2
        bpl.s   4b
        bra     sg_dirty

| The stock's track copy (0x4005f46a's call, (pattern, track)): what the paste needs to know, then it.
sg_acpy:
        lea     -16(%sp),%sp
        movem.l %d0-%d1/%a0-%a1,(%sp)
        move.l  24(%sp),%d0
        moveq   #7,%d1
        and.l   %d1,%d0
        move.l  %d0,-(%sp)
        bsr     sg_o3s
        move.l  (%sp)+,%d1
        move.l  %d0,sg_cs3
        beq.s   1f
        moveq   #30,%d0
        muls.l  %d0,%d1
        moveq   #0,%d0
        move.b  (0x30,%a0,%d1.l),%d0
        move.l  %d0,sg_ctu
1:      movem.l (%sp),%d0-%d1/%a0-%a1
        lea     16(%sp),%sp
        jmp     0x4002993c

| The stock's MIDI track paste (0x4005ead2's call, (pattern, track)): an audio track's clipboard
| converted, else the stock's. d0 = 1 pasted.
sg_mpst:
        moveq   #4,%d0
        cmp.l   0x460d0ffa,%d0
        beq.s   1f
        jmp     0x4002b62c
1:      lea     -44(%sp),%sp
        movem.l %d2-%d7/%a2-%a6,(%sp)
        move.l  48(%sp),%d6             | d6: the pattern
        move.l  52(%sp),%d7             | d7: the track
        movea.l 0x46c82456,%a2          | a2: the pattern's record
        move.l  #0x8ed8,%d0
        muls.l  %d6,%d0
        adda.l  %d0,%a2
        move.l  #0x8b0,%d0              | a3: the MIDI track's record
        muls.l  %d7,%d0
        lea     (0,%a2,%d0.l),%a3
        adda.l  #0x48d0,%a3
        move.l  #0x8e57,%d0             | a4: its Part's (the pattern's, as the writer reads it)
        move.b  (0,%a2,%d0.l),%d0
        extb.l  %d0
        move.l  #0x18b2,%d1
        muls.l  %d1,%d0
        movea.l 0x46c82456,%a4
        adda.l  %d0,%a4
        lea     sg_mbuf,%a5
        pea     0x8b0.w                 | the buffer: the record, page-1 values, setup
        move.l  %a3,-(%sp)
        move.l  %a5,-(%sp)
        jsr     0x40020898
        lea     12(%sp),%sp
        move.l  %d7,%d0
        lsl.l   #5,%d0
        lea     (0,%a4,%d0.l),%a0
        adda.l  #0x8f162,%a0
        moveq   #0,%d5                  | d5: its NOTE
        move.b  (%a0),%d5
        pea     0x20.w
        move.l  %a0,-(%sp)
        pea     0x8b0(%a5)
        jsr     0x40020898
        lea     12(%sp),%sp
        moveq   #0x24,%d0
        muls.l  %d7,%d0
        lea     (0,%a4,%d0.l),%a0
        adda.l  #0x8f262,%a0
        pea     0x24.w
        move.l  %a0,-(%sp)
        pea     0x9a0(%a5)
        jsr     0x40020898
        lea     12(%sp),%sp
        lea     0x460c8122,%a0
        movea.l %a5,%a1
        bsr     sg_a2m
        move.l  52(%sp),-(%sp)          | (sg_a2m's d6 d7: the arguments again)
        move.l  52(%sp),-(%sp)
        move.l  %a5,-(%sp)
        jsr     0x4002b470
        lea     12(%sp),%sp
        movem.l (%sp),%d2-%d7/%a2-%a6
        lea     44(%sp),%sp
        moveq   #1,%d0
        rts

| a0 = an audio track's record, a1 = a MIDI track's (its fields kept), d5 = the MIDI track's NOTE:
| the steps converted (above). Uses d0-d4 d6 d7 a2.
sg_a2m:
        moveq   #0,%d0                  | the masks
1:      move.b  (0,%a0,%d0.l),%d1
        move.b  %d1,(0,%a1,%d0.l)
        move.b  (8,%a0,%d0.l),%d1
        move.b  %d1,(8,%a1,%d0.l)
        clr.b   (16,%a1,%d0.l)
        move.b  (64,%a0,%d0.l),%d1
        move.b  %d1,(24,%a1,%d0.l)
        addq.l  #1,%d0
        moveq   #8,%d1
        cmp.l   %d1,%d0
        blt.s   1b
        move.b  0x50(%a0),0x28(%a1)     | the track's LEN and SCALE (+0x50 / +0x51 -> +0x28 / +0x29;
        move.b  0x51(%a0),0x29(%a1)     | build 116)
        lea     0x30(%a1),%a2           | no locks
        move.l  #0x800,%d0
        moveq   #-1,%d1
2:      move.b  %d1,(%a2)+
        subq.l  #1,%d0
        bne.s   2b
        lea     sg_slm,%a2              | no slides marked
        moveq   #63,%d0
3:      clr.b   (0,%a2,%d0.l)
        subq.l  #1,%d0
        bpl.s   3b
        moveq   #0,%d4                  | d4: a note seen (OCTA-303's slides)
        moveq   #0,%d6                  | d6: the step
.La2_s:
        move.l  %d6,%d1                 | d2: its masks' byte, d3: 1 trig 2 trigless
        asr.l   #3,%d1
        moveq   #7,%d2
        sub.l   %d1,%d2
        moveq   #0,%d3
        btst    %d6,(8,%a1,%d2.l)
        beq.s   1f
        moveq   #2,%d3
1:      btst    %d6,(0,%a1,%d2.l)
        beq.s   2f
        moveq   #1,%d3
2:      tst.l   %d3
        beq     .La2_n
        move.l  %d6,%d0                 | its trig word
        add.l   %d0,%d0
        move.l  #0x89a,%d1
        add.l   %d0,%d1
        lea     (0,%a1,%d0.l),%a2
        adda.l  #0x830,%a2
        move.b  (0,%a0,%d1.l),%d0
        move.b  %d0,(%a2)+
        move.b  (1,%a0,%d1.l),%d0
        move.b  %d0,(%a2)
        move.l  %d6,%d7                 | d7: its locks' offset (32 s)
        lsl.l   #5,%d7
        moveq   #0,%d0
        move.b  (0x59,%a0,%d7.l),%d0    | lock 0: TUNE / PTCH
        tst.l   sg_cs3
        bne.s   .La2_3
        cmpi.l  #0xff,%d0               | another machine: PTCH as NOTE + PTCH - 64
        beq     .La2_n
        add.l   %d5,%d0
        subi.l  #64,%d0
        bra.s   .La2_w
.La2_3: cmpi.l  #0xff,%d0               | OCTA-303: TUNE - 16
        bne.s   1f
        move.l  sg_ctu,%d0
1:      subi.l  #16,%d0
        cmpi.l  #2,%d3                  | a trigless step after a note: a note, marked a slide
        bne.s   2f
        tst.l   %d4
        beq.s   2f
        bclr    %d6,(8,%a1,%d2.l)
        bset    %d6,(0,%a1,%d2.l)
        lea     sg_slm,%a2
        adda.l  %d6,%a2
        move.b  #1,(%a2)
        moveq   #1,%d3
2:      cmpi.l  #1,%d3
        bne.s   3f
        moveq   #1,%d4
3:      moveq   #0,%d1                  | ACC above 0: VEL 101-127
        move.b  (0x5e,%a0,%d7.l),%d1
        cmpi.l  #0xff,%d1
        beq.s   .La2_w
        tst.l   %d1
        beq.s   .La2_w
        moveq   #101,%d3
        cmp.l   %d3,%d1
        bge.s   4f
        move.l  %d3,%d1
4:      move.b  %d1,(0x31,%a1,%d7.l)
.La2_w: tst.l   %d0                     | the NOTE lock, 0-127, and the step's plock bit
        bpl.s   1f
        moveq   #0,%d0
1:      cmpi.l  #127,%d0
        ble.s   2f
        moveq   #127,%d0
2:      move.b  %d0,(0x30,%a1,%d7.l)
        bset    %d6,(16,%a1,%d2.l)
.La2_n:
        addq.l  #1,%d6
        moveq   #64,%d0
        cmp.l   %d0,%d6
        blt     .La2_s
        tst.l   sg_cs3                  | OCTA-303: a note slid into, the one before it held over it
        beq.s   9f
        lea     sg_slm,%a2
        moveq   #1,%d6
1:      tst.b   (0,%a2,%d6.l)
        beq.s   5f
        move.l  %d6,%d3                 | the note before it
2:      subq.l  #1,%d3
        bmi.s   5f
        move.l  %d3,%d1
        asr.l   #3,%d1
        moveq   #7,%d2
        sub.l   %d1,%d2
        btst    %d3,(0,%a1,%d2.l)
        beq.s   2b
        move.l  %d6,%d0
        sub.l   %d3,%d0
        moveq   #6,%d1
        muls.l  %d1,%d0
        addq.l  #3,%d0
        cmpi.l  #126,%d0
        ble.s   3f
        moveq   #126,%d0
3:      move.l  %d3,%d1
        lsl.l   #5,%d1
        move.b  %d0,(0x32,%a1,%d1.l)
5:      addq.l  #1,%d6
        moveq   #64,%d0
        cmp.l   %d0,%d6
        blt.s   1b
9:      rts

| ---- AUDIO (build 110): in MIXER + MIDI's view, MIDI alone switches the view between the 8 MIDI tracks
|      and the 8 audio tracks (sg_aud; the Octatrack in audio mode since build 149, sg_amode). The views read an audio track's
|      record (pattern + 0x91a t: the trig mask +0x00, trigless +0x08, locks +0x59 + 32 s, its LEN +0x50
|      in PER TRACK) and its step playing (0x800064e0 + t, running 0x80006500 + t: 0x4009b2b0 /
|      0x4009b290's first 8 entries). The titles read AUD: / APGS:, a track "T<n>"; no panel, no
|      note-length lines, no mutes shown, no pitch view, COPY / CLEAR / PASTE do nothing. YES cycles the
|      cursor's step: none -> trig -> trigless -> none; NO clears it. A new trig or a cleared step has its
|      32 lock bytes 0xff (as the stock's trig placing, 0x400603a8), the plock bit cleared; written to the
|      bank and its CS1 copy, the dirty flags, 0x4009da20(t).

| AUDIO off, the titles back. Keeps everything.
sg_aoff:
        tst.l   sg_aud
        beq.s   9f
        clr.l   sg_aud
        bsr     sg_mled
        bra     sg_alab
9:      rts
| The MIDI key's LED as the stock sets it, by the mode (0x40033f70; build 116). Keeps everything.
sg_mled:
        lea     -16(%sp),%sp
        movem.l %d0-%d1/%a0-%a1,(%sp)
        jsr     0x40033f70
        jsr     0x400486cc              | (the trig LEDs back too, build 119)
        movem.l (%sp),%d0-%d1/%a0-%a1
        lea     16(%sp),%sp
        rts

| The titles for MIDI / AUDIO (sg_ftk, sg_fpg rewritten). Keeps everything.
sg_alab:
        lea     -8(%sp),%sp
        movem.l %a0-%a1,(%sp)
        lea     sg_ftk,%a1
        lea     sg_ltm,%a0
        tst.l   sg_aud
        beq.s   1f
        lea     sg_lta,%a0
1:      move.l  (%a0)+,(%a1)+
        move.w  (%a0)+,(%a1)+
        lea     sg_fpg,%a1
        lea     sg_lpm,%a0
        tst.l   sg_aud
        beq.s   2f
        lea     sg_lpa,%a0
2:      move.l  (%a0)+,(%a1)+
        move.w  (%a0)+,(%a1)+
        move.b  (%a0)+,(%a1)+
        movem.l (%sp),%a0-%a1
        addq.l  #8,%sp
        rts

| NO in AUDIO (sg_kno's frame, a press): the cursor's step cleared.
sg_aclr:
        moveq   #1,%d0
        bra.s   sg_aset
| YES in AUDIO (sg_kyes' frame, a press): none -> trig -> trigless -> none.
sg_atog:
        moveq   #0,%d0
sg_aset:
        lea     -40(%sp),%sp
        movem.l %d2-%d7/%a2-%a5,(%sp)
        move.l  %d0,%d7                 | d7: 1 clear
        clr.l   sg_idle
        bsr     sg_cedit
        bne     9f
        bsr     sg_sel                  | a1 the record, d0 the step
        move.l  %d0,%d5
        movea.l %a1,%a3                 | a3: its CS1 copy
        suba.l  0x46c82456,%a3
        adda.l  #0x1001614e,%a3
        move.l  %d5,%d1
        asr.l   #3,%d1
        moveq   #7,%d2
        sub.l   %d1,%d2                 | d2: the masks' byte
        moveq   #0,%d6                  | d6: the new state, 0 none 1 trig 2 trigless
        tst.l   %d7
        bne.s   2f
        moveq   #0,%d6                  | trigless -> none
        btst    %d5,(8,%a1,%d2.l)
        bne.s   2f
        moveq   #1,%d6                  | none -> trig
        btst    %d5,(0,%a1,%d2.l)
        beq.s   2f
        moveq   #2,%d6                  | trig -> trigless
2:      bclr    %d5,(0,%a1,%d2.l)       | both masks off, then the one
        bclr    %d5,(0,%a3,%d2.l)
        bclr    %d5,(8,%a1,%d2.l)
        bclr    %d5,(8,%a3,%d2.l)
        cmpi.l  #1,%d6
        bne.s   3f
        bset    %d5,(0,%a1,%d2.l)
        bset    %d5,(0,%a3,%d2.l)
        bra.s   4f
3:      cmpi.l  #2,%d6
        bne.s   4f
        bset    %d5,(8,%a1,%d2.l)
        bset    %d5,(8,%a3,%d2.l)
        bra.s   6f                      | trigless: its locks kept
4:      bclr    %d5,(16,%a1,%d2.l)      | a new trig or none: no locks
        bclr    %d5,(16,%a3,%d2.l)
        move.l  %d5,%d0
        lsl.l   #5,%d0
        lea     (0x59,%a1,%d0.l),%a0
        lea     (0x59,%a3,%d0.l),%a2
        moveq   #32,%d1
        moveq   #-1,%d0
5:      move.b  %d0,(%a0)+
        move.b  %d0,(%a2)+
        subq.l  #1,%d1
        bne.s   5b
6:      bsr     sg_dirty
        move.l  sg_row,-(%sp)
        jsr     0x4009da20
        addq.l  #4,%sp
9:      movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        bra     sg_now

| ---- THE PITCH VIEW (build 109; three layouts, build 123): the full view's third window (ARP: TRKS ->
|      PAGES -> PITCH), the cursor's MIDI track as a piano roll over two octaves -- sg_pb (an A) to 23
|      semitones above it, the cursor's note sg_pb + sg_pr (sg_pr 0-23). Knob F picks the layout
|      (sg_plo): 0, the page's 16 steps across (7 px a step from x 10) and 9 of the 24 notes up the
|      screen (6 px a row, each row named at the left, a dot on each step), the window (sg_pwr, its
|      bottom row) following the cursor, a bar at the right edge showing where it sits; 1, 32 steps (the
|      page and its pair, 3 px a step from x 11) and all 24 notes (2 px a row) beside a piano keyboard,
|      the cursor's note, step and velocity at the right; 2, horizontal: 16 steps down the screen (3 px
|      a row from row 8, a dotted line every 4) over a 24-key keyboard along the foot (5 px a key from
|      x 4). Each step with a trig a block at its NOTE (its lock or the Part's), a trigless step its
|      outline, NOT2-4 smaller; a note outside the window a mark at its edge. The title: PITCH, the
|      track, the cursor's note and step, the pattern, and the four pages as boxes (the shown filled).
|      The step playing inverted, the cursor a box. LEFT / RIGHT and LEVEL a step (wrapping through the
|      64, the page following), UP / DOWN a semitone (past an end of the two octaves the range an
|      octave), FUNC + UP / DOWN the range an octave, YES the cursor's note: a step without a trig gets
|      one there (sg_trig) with that NOTE lock (sg_lock), a step with another note takes this one, a
|      step already on it is left alone (build 123; it was cleared before -- NO's CLEAR? clears, as in
|      the grid). FUNC + LEFT / RIGHT a page.

| The window on the cursor step's note (entering the view). Uses d0 d1 a0 a1 a2.
sg_pini:
        moveq   #-1,%d0                 | the trig keys from the cursor's octave again (build 129)
        move.l  %d0,sg_pkb0
        bsr     sg_sel
        moveq   #0,%d0
        bsr     sg_val
| d0 = a note: the range from the A at or below an octave under it (A0 9 .. A7 93: its octave the
| range's upper one, the one below in view too), the cursor on the note, the window round it. Uses d0 d1.
sg_pset:
        move.l  %d0,-(%sp)
        subi.l  #9,%d0                  | (n - 12 + 3) / 12 * 12 - 3: the A at or below n - 12
        bpl.s   0f
        moveq   #0,%d0
0:      moveq   #12,%d1
        divu.l  %d1,%d0
        muls.l  %d1,%d0
        subq.l  #3,%d0
        moveq   #9,%d1
        cmp.l   %d1,%d0
        bge.s   1f
        move.l  %d1,%d0
1:      moveq   #93,%d1
        cmp.l   %d1,%d0
        ble.s   2f
        move.l  %d1,%d0
2:      move.l  %d0,sg_pb
        move.l  (%sp)+,%d1
        sub.l   %d0,%d1                 | the cursor's row, 0-23
        bpl.s   3f
        moveq   #0,%d1
3:      moveq   #23,%d0
        cmp.l   %d0,%d1
        ble.s   4f
        move.l  %d0,%d1
4:      move.l  %d1,sg_pr
        subq.l  #5,%d1                  | the window: the cursor in its middle
        move.l  %d1,sg_pwr
| The window (layout 0) on the cursor: sg_pwr .. + 10 holds sg_pr, sg_pwr 0-13. Uses d0 d1.
sg_pwin:
        move.l  sg_pr,%d0
        cmp.l   sg_pwr,%d0
        bge.s   1f
        move.l  %d0,sg_pwr
1:      moveq   #10,%d1
        add.l   sg_pwr,%d1
        cmp.l   %d1,%d0
        ble.s   2f
        subi.l  #10,%d0
        move.l  %d0,sg_pwr
2:      tst.l   sg_pwr
        bpl.s   3f
        clr.l   sg_pwr
3:      moveq   #13,%d0
        cmp.l   sg_pwr,%d0
        bge.s   4f
        move.l  %d0,sg_pwr
4:      rts

| The arrows (from sg_mv: d0 the code). Uses d0 d1 a0 a1.
sg_pmv:
        moveq   #2,%d1                  | KEYS (layout 2, build 124): the steps run down the screen and
        cmp.l   sg_plo,%d1              | the notes across, so UP / DOWN a step and LEFT / RIGHT a
        bne.s   0f                      | semitone: UP -> LEFT's, DOWN -> RIGHT's, LEFT -> DOWN's,
        lea     sg_pkm,%a0              | RIGHT -> UP's
1:      move.b  (%a0)+,%d1
        beq.s   0f
        cmp.b   %d1,%d0
        beq.s   2f
        addq.l  #1,%a0
        bra.s   1b
2:      moveq   #0,%d0
        move.b  (%a0),%d0
0:      moveq   #1,%d1                  | RIGHT, UP: +1
        cmpi.l  #0x34,%d0
        beq.s   1f
        cmpi.l  #0x20,%d0
        bne.s   2f
1:      moveq   #-1,%d1                 | LEFT, DOWN: -1
2:      cmpi.l  #0x34,%d0
        beq     3f
        cmpi.l  #0x21,%d0
        beq     3f
        add.l   sg_pr,%d1               | UP / DOWN: a semitone; past an end the range a semitone, the
        tst.l   %d1                     | cursor on the edge (build 136 in every layout; KEYS 16 in 134-135,
        bpl.s   8f                      | the range an octave until then; octaves are FUNC's)
        moveq   #0,%d1
        tst.l   sg_pb
        beq.s   5f
        subq.l  #1,sg_pb
        bra.s   5f
8:      moveq   #23,%d0
        cmp.l   %d0,%d1
        ble.s   5f
        move.l  %d0,%d1
        moveq   #104,%d0
        cmp.l   sg_pb,%d0
        ble.s   5f
        addq.l  #1,sg_pb
5:      move.l  %d1,sg_pr
        bsr     sg_pwin
        bra.s   6f
3:      add.l   %d1,sg_step             | LEFT / RIGHT: a step, wrapping
        moveq   #63,%d0
        and.l   %d0,sg_step
6:      clr.l   sg_bk
        clr.l   sg_idle
        bsr     sg_pgset
        bra     sg_now

| Knob D in ROLL 32 and KEYS 16 (build 136; it reached the hidden PAGES spacing before): the range a
| semitone that way (0-104), the cursor's note kept while in it. Uses d0 d1 a0 a1.
sg_prsc:
        tst.l   %d1
        bgt.s   1f
        tst.l   sg_pb
        beq.s   9f
        subq.l  #1,sg_pb
        addq.l  #1,sg_pr
        bra.s   2f
1:      moveq   #104,%d0
        cmp.l   sg_pb,%d0
        ble.s   9f
        addq.l  #1,sg_pb
        subq.l  #1,sg_pr
2:      tst.l   sg_pr
        bpl.s   3f
        clr.l   sg_pr
3:      moveq   #23,%d0
        cmp.l   sg_pr,%d0
        bge.s   4f
        move.l  %d0,sg_pr
4:      clr.l   sg_idle
        bra     sg_now
9:      rts

| Knob D in ROLL 16 (build 129; from sg_kenc, d1 the delta): its 11 rows a semitone up or down, past the
| range's ends the range an octave (the window on the same notes), the cursor kept on the window.
| Uses d0 d1 a0 a1.
sg_pscr:
        moveq   #1,%d0
        tst.l   %d1
        bgt.s   1f
        moveq   #-1,%d0
1:      add.l   sg_pwr,%d0
        bmi.s   2f
        moveq   #13,%d1
        cmp.l   %d1,%d0
        bgt.s   3f
        move.l  %d0,sg_pwr
        bra.s   5f
2:      tst.l   sg_pb                   | under the range's foot: the range a semitone down (an octave
        beq.s   9f                      | until 135), the cursor's note kept
        subq.l  #1,sg_pb
        addq.l  #1,sg_pr
        bra.s   5f
3:      moveq   #104,%d0                | over its top: up
        cmp.l   sg_pb,%d0
        ble.s   9f
        addq.l  #1,sg_pb
        subq.l  #1,sg_pr
5:      move.l  sg_pwr,%d0              | the cursor on the window's rows
        cmp.l   sg_pr,%d0
        ble.s   6f
        move.l  %d0,sg_pr
6:      addi.l  #10,%d0
        cmp.l   sg_pr,%d0
        bge.s   7f
        move.l  %d0,sg_pr
7:      clr.l   sg_idle
        bra     sg_now
9:      rts

| d0 = +12 / -12: the range an octave, its A within A0 (9) .. A7 (93): d0 = 1 moved, 0 not. Uses d0 d1.
sg_poct:
        add.l   sg_pb,%d0
        bmi.s   9f                      | (0 .. 104: the range any note since build 134; A0 .. A7 before)
        moveq   #104,%d1
        cmp.l   %d1,%d0
        bgt.s   9f
        move.l  %d0,sg_pb
        moveq   #1,%d0
        rts
9:      moveq   #0,%d0
        rts

| FUNC + UP / DOWN (sg_kfud's frame: code, state): the range an octave on a press.
sg_pfud:
        moveq   #1,%d0
        cmp.l   8(%sp),%d0
        bne.s   9f
        moveq   #12,%d0
        moveq   #0x33,%d1
        cmp.l   4(%sp),%d1
        beq.s   1f
        moveq   #-12,%d0
1:      bra.s   sg_poc
9:      rts

| d0 = +12 / -12: the pitch view's range an octave (sg_poct), redrawn. Uses d0 d1 a0 a1.
sg_poc:
        bsr     sg_poct
        clr.l   sg_idle
        bra     sg_now

| Z clear in KEYS 16 (the pitch view, no panel). Uses d0.
sg_pkeys:
        tst.l   sg_full
        beq.s   9f
        tst.l   sg_pv
        beq.s   9f
        tst.l   sg_mode
        bne.s   8f
        moveq   #2,%d0
        cmp.l   sg_plo,%d0
        bne.s   8f
        moveq   #1,%d0
        rts
8:      moveq   #0,%d0
9:      rts

| Knob A in the pitch view (build 133; from sg_kenc, d1 the delta): the cursor a semitone that way (as
| UP / DOWN in the rolls, LEFT / RIGHT in KEYS 16: sg_pmv), with FUNC the range an octave.
| Knob A in the pitch view (sg_kenc's frame): ROLL 32 the steps, as LEVEL elsewhere (sg_lvl with
| sg_swp; build 148, Zach: LEVEL and A swapped there); else sg_pka.
sg_pkaa:
        moveq   #1,%d0
        cmp.l   sg_plo,%d0
        bne.s   sg_pka
        move.l  %d0,sg_swp
        bra     sg_lvl

| Z clear when ROLL 32's grid takes LEVEL and knob A swapped: the pitch view in layout 1, no panel, no
| window or menu (build 148). Uses d0 d1 a0.
sg_pl32:
        bsr     sg_free
        bne.s   8f
        tst.l   sg_pv
        beq.s   8f
        tst.l   sg_win
        bne.s   8f
        tst.l   sg_mode
        bne.s   8f
        moveq   #1,%d0
        cmp.l   sg_plo,%d0
        bne.s   8f
        moveq   #1,%d0
        rts
8:      moveq   #0,%d0
        rts

sg_pka:
        tst.l   SG_HELD+0x2d*24
        beq.s   1f
        moveq   #12,%d0
        tst.l   %d1
        bgt     sg_poc
        moveq   #-12,%d0
        bra     sg_poc
1:      moveq   #2,%d0
        cmp.l   sg_plo,%d0
        beq.s   2f
        moveq   #0x33,%d0               | the rolls: UP / DOWN
        tst.l   %d1
        bgt     sg_pmv
        moveq   #0x20,%d0
        bra     sg_pmv
2:      moveq   #0x21,%d0               | KEYS 16: RIGHT / LEFT (sg_pmv turns them into the semitones)
        tst.l   %d1
        bgt     sg_pmv
        moveq   #0x34,%d0
        bra     sg_pmv

| Knob F in the pitch view (from sg_kenc: d0 = +1 / -1): the layout, "ROLL 16" / "ROLL 32" / "KEYS 16"
| at the title for 1.5 s. Uses d0 d1 a0 a1.
sg_pzoom:
        add.l   sg_plo,%d0
        bmi.s   9f
        moveq   #2,%d1
        cmp.l   %d1,%d0
        bgt.s   9f
        move.l  %d0,sg_plo
        lea     sg_fro,%a0
        moveq   #16,%d1
        tst.l   %d0
        beq.s   1f
        moveq   #32,%d1
        subq.l  #1,%d0
        beq.s   1f
        lea     sg_fky,%a0
        moveq   #16,%d1
1:      move.l  %d1,%d0
        bsr     sg_cmsg
        clr.l   sg_idle
        bra     sg_now
9:      rts

| YES (sg_kyes' frame, a press): the cursor's note at its step. Uses everything but a5 a6.
sg_pyes:
        tst.l   sg_ptg                  | a trig key held: its release opens no window (build 126)
        bmi.s   0f
        moveq   #1,%d0
        move.l  %d0,sg_pty
0:      lea     -40(%sp),%sp
        movem.l %d2-%d7/%a2-%a5,(%sp)
        clr.l   sg_idle
        bsr     sg_cedit
        bne.s   9f
        move.l  sg_pb,%d4               | d4: the cursor's note
        add.l   sg_pr,%d4
        bsr     sg_sel                  | a1 record, a2 locks, a0 the Part's, d0 step
        move.l  %d0,%d5                 | d5: the step
        move.l  %d0,%d1
        asr.l   #3,%d1
        moveq   #7,%d2
        sub.l   %d1,%d2
        btst    %d0,(0,%a1,%d2.l)
        beq.s   2f                      | no trig: one, with the note
        moveq   #0,%d0
        bsr     sg_val
        cmp.l   %d4,%d0
        bne.s   3f                      | another note: this one
        bra.s   9f                      | its note: left alone (build 123)
2:      move.l  %d5,%d0
        bsr     sg_trig
        bsr     sg_sel
3:      move.l  %d4,%d0
        moveq   #0,%d1
        bsr     sg_lock
9:      movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        bra     sg_now

| d5 = a step (a3 its record, d6 the Part's NOTE): d3 = 0 nothing, 1 a trig, 2 trigless; d1 its note.
| Uses d0 d1 d3.
sg_pst:
        move.l  %d5,%d0
        asr.l   #3,%d0
        moveq   #7,%d1
        sub.l   %d0,%d1
        moveq   #0,%d3
        btst    %d5,(0,%a3,%d1.l)
        beq.s   1f
        moveq   #1,%d3
1:      btst    %d5,(8,%a3,%d1.l)
        beq.s   2f
        moveq   #2,%d3
2:      move.l  %d5,%d0
        lsl.l   #5,%d0
        moveq   #0,%d1
        move.b  (0x30,%a3,%d0.l),%d1
        cmpi.l  #0xff,%d1
        bne.s   3f
        move.l  %d6,%d1
3:      rts

| d0 = slot 3-5 (NOT2-4) of step d5 (a3 its record, a5 the Part's NOTE page, a6 its note): d1 the
| chord note, -1 when off (64). Uses d0 d1.
sg_pcn:
        move.l  %d0,-(%sp)
        move.l  %d5,%d1
        lsl.l   #5,%d1
        add.l   %d0,%d1
        moveq   #0,%d0
        move.b  (0x30,%a3,%d1.l),%d0
        cmpi.l  #0xff,%d0
        bne.s   1f
        move.l  (%sp),%d1
        move.b  (0,%a5,%d1.l),%d0
1:      addq.l  #4,%sp
        cmpi.l  #64,%d0
        beq.s   8f
        subi.l  #64,%d0
        add.l   %a6,%d0
        move.l  %d0,%d1
        rts
8:      moveq   #-1,%d1
        rts

| A filled rectangle: d0 x0, d1 top, d2 x1, d3 bottom; keeps d2 d3. (sg_r1 with SG_FILL.)
sg_pf:
        lea     SG_FILL,%a0
        bra     sg_r1

| The pitch view's screen (from sg_run, a2 the pattern). Uses d0-d7 a0 a1 a3 a4 (keeps a2 a5 a6).
sg_pdraw:
        lea     -12(%sp),%sp
        movem.l %a2/%a5-%a6,(%sp)
        moveq   #0,%d0                  | the whole screen
        moveq   #0,%d1
        move.l  #127,%d2
        moveq   #63,%d3
        bsr     sg_clr
        move.l  sg_row,%d1              | d5 the step playing (-1 stopped), from the pattern's record
        bsr     sg_trk
        move.l  %d5,sg_pply
        bsr     sg_ptitle
        bsr     sg_sel                  | a3 the record, d6 the Part's NOTE, a5 its NOTE page
        movea.l %a1,%a3
        movea.l %a0,%a5
        moveq   #0,%d6
        move.b  (%a0),%d6
        move.l  sg_plo,%d0
        beq     sg_pd0
        subq.l  #1,%d0
        beq     sg_pd1
        bra     sg_pd2
.Lpd_end:
        movem.l (%sp),%a2/%a5-%a6
        lea     12(%sp),%sp
        rts

| ---- layout 0: 16 steps, 11 notes (build 124; 9 in 123). Row r (0 at the top) holds the note sg_pwr +
|      10 - r over the range's A, rows 8 + 5 r .. + 4 (its middle + 2); step column c at x 14 + 7 c (a
|      5 x 5 square, the dot at + 2; x 10 + 7 c until 130). A keyboard at the left (build 130). A note in another octave
|      an arrow on its letter's row, pointing to its octave.
sg_pd0:
        moveq   #10,%d4                 | d4: the row, from the foot up
.Lp0r:  moveq   #10,%d7
        add.l   sg_pwr,%d7
        sub.l   %d4,%d7                 | d7: its note over the A
        move.l  %d4,%d5                 | d5: its top, 8 + 5 r
        lsl.l   #2,%d5
        add.l   %d4,%d5
        addq.l  #8,%d5
        move.l  sg_pb,%d0               | a natural: its letter at the left; a sharp: a dash (build 124)
        add.l   %d7,%d0
        move.l  %d0,%d1                 | n mod 12: C = 0
        moveq   #12,%d2
        divu.l  %d2,%d1
        muls.l  %d2,%d1
        move.l  %d0,%d2
        sub.l   %d1,%d2
        lea     sg_pkc,%a0              | a keyboard, x 4-10 (build 131; x 0-6 in 130, the names until 129):
        tst.b   (0,%a0,%d2.l)           | a sharp a black key, x 4-8, rows + 1 .. + 3, its white keys'
        bne.s   3f                      | edge through it at x 9-10; under C and F the edge; left of C
        tst.l   %d2                     | its octave, at x 0
        bne.s   1f
        move.l  %d2,-(%sp)
        lea     sg_b2,%a1
        bsr     sg_name
        moveq   #59,%d1
        sub.l   %d5,%d1
        moveq   #0,%d0
        moveq   #0,%d2
        lea     SG_SMALL,%a0
        lea     sg_b2+4,%a1
        bsr     sg_tx
        move.l  (%sp)+,%d2
        bra.s   2f
1:      moveq   #5,%d1
        cmp.l   %d1,%d2
        bne.s   5f
2:      moveq   #4,%d0
        moveq   #4,%d1
        add.l   %d5,%d1
        moveq   #10,%d2
        move.l  %d1,%d3
        bsr     sg_pf
        bra.s   5f
3:      moveq   #4,%d0
        moveq   #1,%d1
        add.l   %d5,%d1
        moveq   #8,%d2
        moveq   #3,%d3
        add.l   %d5,%d3
        bsr     sg_pf
        moveq   #9,%d0
        moveq   #2,%d1
        add.l   %d5,%d1
        moveq   #10,%d2
        move.l  %d1,%d3
        bsr     sg_pf
5:      cmp.l   sg_pr,%d7               | the cursor's row: its key inverted
        bne.s   4f
        moveq   #4,%d0
        move.l  %d5,%d1
        moveq   #10,%d2
        moveq   #4,%d3
        add.l   %d5,%d3
        bsr     sg_inv
4:      moveq   #16,%d2                 | a dot on each step, on the row's middle
2:      move.l  %d2,%d0
        moveq   #2,%d1
        add.l   %d5,%d1
        bsr     sg_xp
        addq.l  #7,%d2
        cmpi.l  #121,%d2
        ble.s   2b
        subq.l  #1,%d4
        bpl     .Lp0r
        moveq   #11,%d0                 | the keyboard's edge
        moveq   #8,%d1
        moveq   #11,%d2
        moveq   #62,%d3
        bsr     sg_pf
        bsr     sg_pcb                  | the trig keys' first note's octaves (build 136): a dotted line
        sub.l   sg_pb,%d0               | on the foot row of each one's row (its octave's edge), x 14-124
        bsr     sg_pm12
        move.l  %d0,%d4
1:      move.l  %d4,%d0
        sub.l   sg_pwr,%d0
        bmi.s   3f
        moveq   #10,%d1
        cmp.l   %d1,%d0
        bgt.s   3f
        bsr     sg_ptop
        move.l  %d1,%d5
        addq.l  #4,%d5
        moveq   #14,%d2
2:      move.l  %d2,%d0
        move.l  %d5,%d1
        bsr     sg_xp
        addq.l  #2,%d2
        cmpi.l  #124,%d2
        ble.s   2b
3:      addi.l  #12,%d4
        moveq   #23,%d0
        cmp.l   %d0,%d4
        ble.s   1b
        moveq   #0x30,%d7               | d7: the page's first step, d4 the column
        and.l   sg_step,%d7
        moveq   #0,%d4
.Lp0c:  move.l  %d7,%d5
        add.l   %d4,%d5
        bsr     sg_pst
        tst.l   %d3
        beq     .Lp0n
        movea.l %d1,%a6                 | a6: the note
        move.l  %d4,%d2                 | d2: x = 14 + 7 c (10 + 7 c until 130)
        lsl.l   #3,%d2
        sub.l   %d4,%d2
        addi.l  #14,%d2
        move.l  %d1,%d0
        sub.l   sg_pb,%d0
        sub.l   sg_pwr,%d0              | d0: rows over the window's bottom
        bmi     .Lp0o
        moveq   #10,%d1
        cmp.l   %d1,%d0
        bgt     .Lp0o
        bsr     sg_ptop                 | d1: its top
        move.l  %d3,-(%sp)
        move.l  %d1,-(%sp)
        move.l  %d2,-(%sp)
        move.l  %d2,%d0
        addq.l  #4,%d2
        move.l  %d1,%d3
        addq.l  #4,%d3
        bsr     sg_pf                   | the block, 5 x 5
        move.l  (%sp)+,%d2
        move.l  (%sp)+,%d1
        move.l  (%sp)+,%d3
        cmpi.l  #2,%d3
        bne     .Lp0ch
        move.l  %d2,-(%sp)              | trigless: its middle cleared, an outline
        move.l  %d2,%d0
        addq.l  #1,%d0
        addq.l  #3,%d2
        addq.l  #1,%d1
        move.l  %d1,%d3
        addq.l  #2,%d3
        bsr     sg_clr
        move.l  (%sp)+,%d2
        bra     .Lp0ch
.Lp0o:  move.l  %d0,%d3                 | another octave (build 124): an arrow on the row of its letter,
        moveq   #12,%d1                 | up for a note above it, down below; none of the 11 rows its
        tst.l   %d3                     | letter (a 12th): a mark at the edge
        bpl.s   1f
        neg.l   %d3
        divu.l  %d1,%d3
        addq.l  #1,%d3
        muls.l  %d1,%d3
        add.l   %d0,%d3                 | the row d3 = d0 mod 12, 0-11
        bra.s   2f
1:      divu.l  %d1,%d3
        muls.l  %d1,%d3
        neg.l   %d3
        add.l   %d0,%d3
2:      moveq   #12,%d1
        cmp.l   %d1,%d3
        bne.s   3f
        moveq   #0,%d3
3:      moveq   #10,%d1
        cmp.l   %d1,%d3
        bgt     .Lp0e
.Lp0a:  move.l  %d0,-(%sp)              | d0 > the row: above it -> up
        move.l  %d3,%d0
        bsr     sg_ptop
        move.l  (%sp)+,%d0
        lea     sg_pdn,%a4
        cmp.l   %d3,%d0
        blt.s   4f
        lea     sg_pup,%a4
4:      moveq   #0,%d3                  | its three lines, top + 1 .. top + 3, (x0, x1) over x
5:      moveq   #0,%d0
        move.b  (%a4)+,%d0
        add.l   %d2,%d0
        move.l  %d2,-(%sp)
        move.l  %d3,-(%sp)
        move.l  %d1,-(%sp)
        addq.l  #1,%d1
        add.l   %d3,%d1
        move.l  %d2,%d3
        moveq   #0,%d2
        move.b  (%a4)+,%d2
        add.l   %d3,%d2
        move.l  %d1,%d3
        bsr     sg_pf
        move.l  (%sp)+,%d1
        move.l  (%sp)+,%d3
        move.l  (%sp)+,%d2
        addq.l  #1,%d3
        moveq   #3,%d0
        cmp.l   %d0,%d3
        blt.s   5b
        bra     .Lp0ch
.Lp0e:  moveq   #10,%d3                 | the 12th letter (none of the 11 rows its letter): the arrow on
        tst.l   %d0                     | the edge row on its side, the top row up, the bottom row down
        bpl     .Lp0a                   | (build 148, Zach: a pixel under the title or at the foot until
        moveq   #0,%d3                  | 147, which read as nothing)
        bra     .Lp0a
.Lp0ch: moveq   #3,%d3                  | NOT2-4: a 3 x 3 block in the square's middle on its row
1:      move.l  %d3,%d0
        bsr     sg_pcn
        tst.l   %d1
        bmi.s   4f
        sub.l   sg_pb,%d1
        sub.l   sg_pwr,%d1
        bmi.s   4f
        moveq   #10,%d0
        cmp.l   %d0,%d1
        bgt.s   4f
        move.l  %d1,%d0
        bsr     sg_ptop
        addq.l  #1,%d1
        move.l  %d2,-(%sp)
        move.l  %d3,-(%sp)
        move.l  %d2,%d0
        addq.l  #1,%d0
        addq.l  #3,%d2
        move.l  %d1,%d3
        addq.l  #2,%d3
        bsr     sg_pf
        move.l  (%sp)+,%d3
        move.l  (%sp)+,%d2
4:      addq.l  #1,%d3
        cmpi.l  #5,%d3
        ble.s   1b
.Lp0n:  addq.l  #1,%d4
        moveq   #16,%d0
        cmp.l   %d0,%d4
        blt     .Lp0c
        moveq   #127,%d0                | where the window sits in the 24: a line at the right edge, the
        moveq   #8,%d1                  | window a 2-px bar on it (11 of 24 rows over 55 px: 25; x 124-126
        moveq   #127,%d2                | until 130)
        moveq   #62,%d3
        bsr     sg_pf
        moveq   #13,%d1
        sub.l   sg_pwr,%d1
        move.l  %d1,%d0
        lsl.l   #3,%d0
        add.l   %d1,%d0
        asr.l   #2,%d0
        addq.l  #8,%d0
        move.l  %d0,%d1
        moveq   #126,%d0
        moveq   #127,%d2
        move.l  %d1,%d3
        addi.l  #25,%d3
        bsr     sg_pf
        moveq   #0,%d0                  | the trig keys' notes marked (build 129)
        bsr     sg_pmk
        moveq   #0,%d0                  | the notes the trig keys play lit
        bsr     sg_phl
        moveq   #0x30,%d0               | the note playing: its key inverted (build 126; its name until 129)
        bsr     sg_ppn
        bmi.s   7f
        sub.l   sg_pwr,%d1
        bmi.s   7f
        moveq   #10,%d0
        cmp.l   %d0,%d1
        bgt.s   7f
        move.l  %d1,%d0
        bsr     sg_ptop
        moveq   #4,%d0
        moveq   #10,%d2
        moveq   #4,%d3
        add.l   %d1,%d3
        bsr     sg_inv
7:
        move.l  sg_pply,%d0             | the step playing: its column inverted
        bmi.s   1f
        moveq   #0x30,%d1
        and.l   %d0,%d1
        cmp.l   %d7,%d1
        bne.s   1f
        sub.l   %d7,%d0
        move.l  %d0,%d1
        lsl.l   #3,%d0
        sub.l   %d1,%d0
        addi.l  #13,%d0
        moveq   #6,%d2
        add.l   %d0,%d2
        moveq   #8,%d1
        moveq   #62,%d3
        bsr     sg_inv
1:      bsr     sg_cvis                 | the cursor (build 132; its cell inverted until 131): an outline
        tst.l   %d1                     | round the cell, inside it a 3 x 3 square on a note (trigless:
        beq     .Lpd_end                | its middle out), the dot on none
        bsr     sg_pcur
        move.l  %d0,%d6                 | d6: the note there (0 / 1 / 2)
        move.l  sg_step,%d0
        sub.l   %d7,%d0
        move.l  %d0,%d1
        lsl.l   #3,%d0
        sub.l   %d1,%d0
        addi.l  #14,%d0
        move.l  %d0,%d4                 | d4: x
        move.l  sg_pr,%d0
        sub.l   sg_pwr,%d0
        bsr     sg_ptop
        move.l  %d1,%d5                 | d5: top
        moveq   #5,%d0
        bra     .Lpcur

| d2 = a natural's note mod 12 (C = 0): its letter, 3 x 5, at x 1, rows d5 .. d5 + 4. Uses d0 d1 a0 a1.
sg_pgl:
        lea     -8(%sp),%sp
        movem.l %d2-%d3,(%sp)
        lea     sg_pgt,%a0
        add.l   %d2,%d2
        moveq   #0,%d3
        move.w  (0,%a0,%d2.l),%d3
        moveq   #17,%d0
        lsl.l   %d0,%d3                 | the glyph's first pixel at bit 31, row by row
        moveq   #0,%d2                  | d2: row << 4 | column
1:      tst.l   %d3
        beq.s   9f
        bpl.s   2f
        moveq   #3,%d0
        and.l   %d2,%d0
        addq.l  #1,%d0
        move.l  %d2,%d1
        lsr.l   #4,%d1
        add.l   %d5,%d1
        bsr     sg_xp
2:      add.l   %d3,%d3
        addq.l  #1,%d2
        moveq   #3,%d0
        and.l   %d2,%d0
        cmpi.l  #3,%d0
        bne.s   1b
        addi.l  #13,%d2
        bra.s   1b
9:      movem.l (%sp),%d2-%d3
        addq.l  #8,%sp
        rts

| The flashes' phase (build 126): sg_bk bits 4 and 5 both = P, sg_mbk = sg_bk. P flips every 2^k steps,
| k from the tempo (0x8000181c, BPM x 24): 1 under 85 BPM, 2 to 170, 3 above -- a half period of
| 0.35-0.7 s (0.5 s at 60, 120, 240). Playing, from the step count (in time with the steps); stopped,
| from DTCN0 (the 11.2896 MHz audio clock: a 16th is 4,064,256,000 / tempo24 counts). Uses d0 d1.
sg_flash:
        move.l  %d2,-(%sp)
        move.l  0x8000181c,%d2
        moveq   #1,%d0
        cmpi.l  #85*24,%d2
        blt.s   1f
        moveq   #2,%d0
        cmpi.l  #170*24,%d2
        blt.s   1f
        moveq   #3,%d0
1:      tst.l   0x800065b8
        beq.s   2f
        moveq   #0,%d1
        move.w  0x800065b4,%d1
        lsr.l   %d0,%d1
        bra.s   3f
2:      tst.l   %d2
        bgt.s   4f
        move.l  #120*24,%d2
4:      move.l  #0xf23fa000,%d1         | the counts of a 16th
        divu.l  %d2,%d1
        lsl.l   %d0,%d1                 | of the half period
        move.l  %d1,%d2
        move.l  0xfc07000c,%d1
        divu.l  %d2,%d1
3:      moveq   #48,%d0
        btst    #0,%d1
        bne.s   5f
        moveq   #0,%d0
5:      move.l  sg_bk,%d1
        andi.l  #-49,%d1
        or.l    %d0,%d1
        move.l  %d1,sg_bk
        move.l  %d1,sg_mbk
        move.l  (%sp)+,%d2
        rts

| The pitch view's trig keys (build 128; a step keyboard in 126-127), outside grid recording (0x460d1736)
| and any window: a chromatic keyboard from the C of the cursor's note's octave, trig 1 = C .. trig 12 =
| B, 13-16 = C .. D+ above. A press plays the note on the cursor's MIDI track (0x4009e9a8(track, note,
| the Part's VEL, 1), the stock CHROMATIC keys' call), its release stops it; FUNC + a trig puts the note
| on the cursor's step (sg_pyes, the cursor on that note) and plays it. The 16 keys' handlers in the
| key table (0x46c7d8de + code * 24, +0) are ours while the view is up and the stock's back when it is
| not (sg_ptsv keeps them). Their LEDs: the cursor's step's note (the first colour) and the step
| playing's (the second); in grid recording the stock's. Uses d0 d1 a0 a1.
sg_ptrg:
        tst.l   sg_full
        beq     8f
        tst.l   sg_pv
        beq     8f
        tst.l   sg_win
        bne 8f
        tst.l   0x460d1736
        bne 8f
        lea     0x46c7d8de,%a0          | ours in the table (the stock's kept)
        lea     sg_ptsv,%a1
        moveq   #0,%d0
1:      move.l  (%a0),%d1
        cmpi.l  #sg_ptkh,%d1
        beq.s   2f
        move.l  %d1,(%a1)
        move.l  #sg_ptkh,(%a0)
2:      lea     24(%a0),%a0
        addq.l  #4,%a1
        addq.l  #1,%d0
        moveq   #16,%d1
        cmp.l   %d1,%d0
        blt.s   1b
        lea     0x46c7d8de+0x38*24,%a0  | encoder A's and C's presses: ROLL 16's jumps (build 131)
        lea     sg_pjsv,%a1
        bsr     sg_pjin
        lea     0x46c7d8de+0x3a*24,%a0
        lea     sg_pjsv+4,%a1
        bsr     sg_pjin

        moveq   #1,%d0
        move.l  %d0,sg_ptin
        moveq   #0,%d0                  | a key let go (whichever handler saw it): its note off
        bsr     sg_poff
        tst.l   SG_HELD+0x2e*24         | (PATTERN or BANK held: the stock's LEDs -- its blinking
        bne.s   1f                      | pattern, ours off; build 138)
        tst.l   SG_HELD+0x2f*24
        bne.s   1f
        bra     sg_pled
1:      tst.l   0x460ba9ae
        beq.s   2f
        clr.l   0x460ba9ae
        moveq   #1,%d0
        move.l  %d0,0x460babec
2:      rts
8:      bra     sg_ptoff

| a0 a key's table entry, a1 its stock handler's keep: sg_pjmp there. Uses d1.
sg_pjin:
        move.l  (%a0),%d1
        cmpi.l  #sg_pjmp,%d1
        beq.s   1f
        move.l  %d1,(%a1)
        move.l  #sg_pjmp,(%a0)
1:      rts

| Off the pitch view, or off the page (sg_poll, build 131): every note off, the stock's key handlers
| back, and its trig LEDs (0x400486cc: ours stayed lit on the stock's pages until a key). Uses d0 d1 a0 a1.
sg_ptoff:
        moveq   #1,%d0
        bsr     sg_poff
        tst.l   sg_ptin                 | the stock's back
        beq     9f
        clr.l   sg_ptin
        lea     0x46c7d8de,%a0
        lea     sg_ptsv,%a1
        moveq   #0,%d0
1:      move.l  (%a0),%d1
        cmpi.l  #sg_ptkh,%d1
        bne.s   2f
        move.l  (%a1),(%a0)
2:      lea     24(%a0),%a0
        addq.l  #4,%a1
        addq.l  #1,%d0
        moveq   #16,%d1
        cmp.l   %d1,%d0
        blt.s   1b
        lea     0x46c7d8de+0x38*24,%a0  | encoder A's and C's presses
        move.l  (%a0),%d1
        cmpi.l  #sg_pjmp,%d1
        bne.s   3f
        move.l  sg_pjsv,(%a0)
3:      lea     0x46c7d8de+0x3a*24,%a0
        move.l  (%a0),%d1
        cmpi.l  #sg_pjmp,%d1
        bne.s   4f
        move.l  sg_pjsv+4,(%a0)
4:
5:      clr.l   0x460ba9ae              | our trig LEDs off, then the stock's own
        clr.l   0x460ba98c
        moveq   #1,%d0
        move.l  %d0,0x460babec
        jsr     0x400486cc
9:      rts

| The notes the trig keys sound: d0 = 0 those whose key is up, 1 all -- off (0x4009e9a8(track, note, 0,
| 1)). Uses d0 d1 a0 a1.
sg_poff:
        lea     -12(%sp),%sp
        movem.l %d2-%d4,(%sp)
        move.l  %d0,%d4
        moveq   #0,%d2
1:      lea     sg_pko,%a0              | (the note sent, build 130)
        moveq   #0,%d3
        move.b  (0,%a0,%d2.l),%d3
        beq.s   2f
        tst.l   %d4
        bne.s   3f
        move.l  %d2,%d0
        lsl.l   #3,%d0
        move.l  %d0,%d1
        add.l   %d0,%d0
        add.l   %d1,%d0                 | d0: 24 k
        lea     SG_HELD,%a0
        tst.l   (0,%a0,%d0.l)
        bne.s   2f
3:      lea     sg_pkn,%a0
        clr.b   (0,%a0,%d2.l)
        lea     sg_pko,%a0
        clr.b   (0,%a0,%d2.l)
        subq.l  #1,%d3
        pea     1.w
        clr.l   -(%sp)
        move.l  %d3,-(%sp)
        move.l  sg_row,-(%sp)
        jsr     0x4009e9a8
        lea     16(%sp),%sp
2:      addq.l  #1,%d2
        moveq   #16,%d0
        cmp.l   %d0,%d2
        blt.s   1b
        movem.l (%sp),%d2-%d4
        lea     12(%sp),%sp
        rts

| d0 = the C of the cursor's note's octave. Uses d0 d1.
sg_pcb:
        move.l  sg_pkb0,%d0             | the trig keys' first note (build 129: knob E moves it); unset,
        bpl.s   9f                      | the C of the cursor's octave, or an octave off it to fit
        move.l  sg_pb,%d1
        add.l   sg_pr,%d1
        moveq   #12,%d0
        divu.l  %d0,%d1
        muls.l  %d0,%d1
        move.l  %d1,%d0
        move.l  sg_pb,%d1               | all 16 on the range's 24: a C from its first note to the 9th
        addq.l  #8,%d1
1:      cmp.l   %d1,%d0
        ble.s   2f
        subi.l  #12,%d0
        bra.s   1b
2:      cmp.l   sg_pb,%d0
        bge.s   3f
        addi.l  #12,%d0
        bra.s   2b
3:      move.l  %d0,sg_pkb0
9:      rts

| Knob E in the pitch view (build 129; from sg_kenc, d1 the delta): the trig keys' 16 notes a semitone
| that way, with FUNC an octave (build 131) (first note 0-112), the range an octave after them when they leave it, "TRIGS C4" at the
| title for 1.5 s. Uses d0 d1 a0 a1.
sg_prng:
        move.l  %d1,-(%sp)
        bsr     sg_pcb
        move.l  (%sp)+,%d1
        tst.l   %d1                     | a semitone; with FUNC an octave (build 131)
        bgt.s   1f
        moveq   #-1,%d1
        tst.l   SG_HELD+0x2d*24
        beq.s   2f
        moveq   #-12,%d1
        bra.s   2f
1:      moveq   #1,%d1
        tst.l   SG_HELD+0x2d*24
        beq.s   2f
        moveq   #12,%d1
2:      add.l   %d1,%d0
        bmi     9f
        moveq   #112,%d1
        cmp.l   %d1,%d0
        bgt     9f
        move.l  %d0,sg_pkb0
        move.l  %d0,%d1                 | the range an octave only once the 16 are all in the next one
        sub.l   sg_pb,%d1               | (build 132; as soon as one left it until 131): down when the
        moveq   #-4,%d0                 | top one is under the range's 13th (first <= -4), up when the
        cmp.l   %d0,%d1                 | first is at the 13th or over (>= 12)
        bgt.s   2f
        moveq   #-12,%d0
        bsr     sg_poct
        tst.l   %d0
        beq.s   3f
        moveq   #12,%d0                 | (the cursor's note kept)
        add.l   %d0,sg_pr
        bra.s   3f
2:      moveq   #12,%d0                 | above: up
        cmp.l   %d0,%d1
        blt.s   3f
        moveq   #12,%d0
        bsr     sg_poct
        tst.l   %d0
        beq.s   3f
        moveq   #-12,%d0
        add.l   %d0,sg_pr
3:      tst.l   sg_pr                   | the cursor kept in the range
        bpl.s   4f
        clr.l   sg_pr
4:      moveq   #23,%d0
        cmp.l   sg_pr,%d0
        bge.s   5f
        move.l  %d0,sg_pr
5:      bsr     sg_pwin
        move.l  sg_pkb0,%d0             | the message: "TRIGS C4"
        lea     sg_b2,%a1
        bsr     sg_name
        pea     sg_b2+4
        pea     sg_b2
        pea     sg_ftr
        pea     sg_umsg
        jsr     SG_SPRINTF
        lea     16(%sp),%sp
        moveq   #90,%d0
        move.l  %d0,sg_umt
        clr.l   sg_idle
        bra     sg_now
9:      rts

| The notes the trig keys sound (sg_pkn), lit while held (build 129; layout d0): 0 the name inverted
| and its row a solid line, 1 the left keyboard's key inverted, 2 the foot's key lit. Uses d0-d3 a0 a1.
sg_phl:
        lea     -12(%sp),%sp
        movem.l %d4-%d6,(%sp)
        move.l  %d0,%d6
        moveq   #0,%d5
1:      lea     sg_pkn,%a0
        moveq   #0,%d0
        move.b  (0,%a0,%d5.l),%d0
        beq     6f
        subq.l  #1,%d0
        sub.l   sg_pb,%d0
        bmi     6f
        moveq   #23,%d1
        cmp.l   %d1,%d0
        bgt     6f
        tst.l   %d6
        bne.s   2f
        sub.l   sg_pwr,%d0
        bmi.s   6f
        moveq   #10,%d1
        cmp.l   %d1,%d0
        bgt.s   6f
        move.l  %d0,-(%sp)
        bsr     sg_ptop
        move.l  %d1,%d4
        move.l  (%sp)+,%d0
        add.l   sg_pwr,%d0
        cmp.l   sg_pr,%d0               | (the cursor's row's key is inverted already)
        beq.s   5f
        moveq   #4,%d0
        moveq   #10,%d2
        moveq   #4,%d3
        add.l   %d4,%d3
        move.l  %d4,%d1
        bsr     sg_inv
5:      moveq   #14,%d0
        moveq   #2,%d1
        add.l   %d4,%d1
        moveq   #124,%d2
        move.l  %d1,%d3
        bsr     sg_pf
        bra.s   6f
2:      moveq   #1,%d1
        cmp.l   %d1,%d6
        bne.s   3f
        moveq   #23,%d1
        sub.l   %d0,%d1
        add.l   %d1,%d1
        addi.l  #9,%d1
        moveq   #5,%d0
        moveq   #12,%d2
        move.l  %d1,%d3
        addq.l  #1,%d3
        bsr     sg_inv
        bra.s   6f
3:      bsr     sg_pk2
6:      addq.l  #1,%d5
        moveq   #16,%d0
        cmp.l   %d0,%d5
        blt     1b
        movem.l (%sp),%d4-%d6
        lea     12(%sp),%sp
        rts

| The trig keys' 16 notes marked beside the keyboard (layout d0: 0 the names, 1 the left keyboard, 2
| the foot's), inside the range. Uses d0-d3 a0 a1.
sg_pmk:
        lea     -12(%sp),%sp
        movem.l %d4-%d6,(%sp)
        move.l  %d0,%d6
        bsr     sg_pcb
        sub.l   sg_pb,%d0
        move.l  %d0,%d4                 | d4: its first note over the A
        moveq   #0,%d5                  | d5: k
1:      move.l  %d4,%d0
        add.l   %d5,%d0                 | d0: the note over the A
        bmi     6f
        moveq   #23,%d1
        cmp.l   %d1,%d0
        bgt     6f
        tst.l   %d6
        bne.s   2f
        sub.l   sg_pwr,%d0              | the keyboard: a line right of its edge, x 12, on the window's rows
        bmi.s   6f
        moveq   #10,%d1
        cmp.l   %d1,%d0
        bgt.s   6f
        bsr     sg_ptop
        moveq   #12,%d0
        moveq   #12,%d2
        moveq   #4,%d3
        add.l   %d1,%d3
        bsr     sg_pf
        bra.s   6f
2:      subq.l  #1,%d6
        bne.s   3f
        addq.l  #1,%d6
        moveq   #23,%d1                 | the left keyboard: x 14, beside its edge, on its two rows
        sub.l   %d0,%d1
        add.l   %d1,%d1
        addi.l  #9,%d1
        moveq   #14,%d0
        moveq   #14,%d2
        move.l  %d1,%d3
        addq.l  #1,%d3
        bsr     sg_pf
        bra.s   6f
3:      addq.l  #1,%d6                  | the foot's: row 55 over the key
        move.l  %d0,%d1
        add.l   %d1,%d1
        add.l   %d1,%d1
        add.l   %d1,%d0
        addq.l  #4,%d0
        moveq   #4,%d2
        add.l   %d0,%d2
        moveq   #55,%d1
        moveq   #55,%d3
        bsr     sg_pf
6:      addq.l  #1,%d5
        moveq   #16,%d0
        cmp.l   %d0,%d5
        blt     1b
        movem.l (%sp),%d4-%d6
        lea     12(%sp),%sp
        rts

| YES in the pitch view (build 129): on a step with a trig its step's window (as a second YES in the
| grids, SG_WST; build 130: the panel's state with it, so LEVEL and the arrows edit it, on NOTE); on an
| empty step the cursor's note there (sg_pyes). NO's "CLEAR? YES" up: the step cleared (build 130).
sg_pyw:
        bsr     sg_nask
        beq.s   0f
        clr.l   sg_nconf
        clr.l   sg_umt
        clr.l   sg_idle
        bsr     sg_ndel
        bra     sg_now
0:      lea     -12(%sp),%sp
        movem.l %d5-%d6/%a3,(%sp)
        bsr     sg_sel                  | a1 the record, a0 the Part's NOTE page
        movea.l %a1,%a3
        moveq   #0,%d6
        move.b  (%a0),%d6
        move.l  sg_step,%d5
        move.l  %d3,-(%sp)
        bsr     sg_pst
        move.l  %d3,%d0
        move.l  (%sp)+,%d3
        movem.l (%sp),%d5-%d6/%a3
        lea     12(%sp),%sp
        tst.l   %d0
        beq     sg_pyes
        move.l  0x460d5de0,%d0
        move.l  %d0,sg_ytk
        moveq   #1,%d0
        move.l  %d0,sg_mode
        moveq   #SG_PN,%d0
        move.l  %d0,sg_prm
        moveq   #SG_WST,%d0
        move.l  %d0,sg_win
        clr.l   sg_idle
        bra     sg_now

| Encoder F pressed in the pitch view (the key table's handler, code 0x3d, state; build 132): the next
| layout, ROLL 16 -> ROLL 32 -> KEYS 16 -> ROLL 16 (sg_pzoom's message).
sg_pfk:
        moveq   #1,%d0
        cmp.l   8(%sp),%d0
        bne.s   9f
        moveq   #2,%d0
        cmp.l   sg_plo,%d0
        bgt.s   1f
        moveq   #-2,%d0                 | KEYS 16 -> ROLL 16
        bra     sg_pzoom
1:      moveq   #1,%d0
        bra     sg_pzoom
9:      rts

| Encoder F pressed in the view (the key table's handler, code 0x3d, state; build 143, Zach: every
| "turn F" a "press F"): PITCH the next layout (sg_pfk); TRKS and PAGES the zoom, 16 <-> 32 a row; the
| panel view's timeline 4 -> 8 -> 16 -> 4 a row (both through sg_kenc's F, sg_fkx set); the panel view's
| 8 tracks nothing. A menu, popup, window of ours or the name's keyboard: the stock's handler.
sg_fkp:
        bsr     sg_free
        bne     8f
        tst.l   sg_win
        bne     8f
        tst.l   sg_kb
        bne     8f
        moveq   #1,%d0
        cmp.l   8(%sp),%d0
        bne     9f                      | (a press only)
        tst.l   sg_full
        beq.s   2f
        tst.l   sg_pv
        bne     sg_pfk
        moveq   #1,%d1                  | TRKS / PAGES: 16 <-> 32
        moveq   #3,%d0
        cmp.l   sg_fzr,%d0
        bne.s   5f
        moveq   #-1,%d1
        bra.s   5f
2:      tst.l   sg_view                 | the panel view: its timeline only
        beq.s   9f
        moveq   #1,%d1
        moveq   #2,%d0
        cmp.l   sg_zm,%d0
        bne.s   5f
        moveq   #-2,%d1                 | 16 -> 4
5:      moveq   #1,%d0
        move.l  %d0,sg_fkx
        move.l  %d1,-(%sp)
        pea     5.w
        bsr     sg_kenc
        addq.l  #8,%sp
        clr.l   sg_fkx
9:      rts
8:      movea.l sg_fksv,%a0
        jmp     (%a0)

| Encoder F's press ours in the key table while the view is up (sg_poll; the stock's kept in sg_fksv),
| the stock's back off it. Uses d1 a0.
sg_fkin:
        lea     0x46c7d8de+0x3d*24,%a0
        move.l  (%a0),%d1
        cmpi.l  #sg_fkp,%d1
        beq.s   9f
        move.l  %d1,sg_fksv
        move.l  #sg_fkp,(%a0)
9:      rts
sg_fkout:
        lea     0x46c7d8de+0x3d*24,%a0
        move.l  (%a0),%d1
        cmpi.l  #sg_fkp,%d1
        bne.s   9f
        move.l  sg_fksv,(%a0)
9:      rts

| Encoders A-E pressed while the view is up (key codes 0x38-0x3c): nothing. The stock's press resets
| the hidden page's parameter (the ARP page's TRAN and NLEN went back to their defaults, the port, 8 Nov
| 2026). A menu, popup, window of ours or the name's keyboard: the stock's handler, as F's (sg_fkp).
sg_ek0: suba.l  %a1,%a1
        bra.s   sg_ekp
sg_ek1: movea.w #1,%a1
        bra.s   sg_ekp
sg_ek2: movea.w #2,%a1
        bra.s   sg_ekp
sg_ek3: movea.w #3,%a1
        bra.s   sg_ekp
sg_ek4: movea.w #4,%a1
sg_ekp:
        move.l  %a1,-(%sp)
        bsr     sg_free
        movea.l (%sp)+,%a1
        bne.s   8f
        tst.l   sg_win
        bne.s   8f
        tst.l   sg_kb
        bne.s   8f
        move.l  %a1,-(%sp)              | a trig key down: the stock's (a held trig's lock, as the knobs')
        bsr     sg_tkd
        movea.l (%sp)+,%a1
        bne.s   8f
        rts
8:      move.l  %a1,%d0
        lsl.l   #2,%d0
        lea     sg_eksv,%a0
        movea.l (%a0,%d0.l),%a0
        jmp     (%a0)

| A-E's presses ours in the key table while the view is up (sg_poll; the stock's kept in sg_eksv), the
| stock's back off it. Uses d0 d1 a0 a1.
sg_ekin:
        lea     0x46c7d8de+0x38*24,%a0  | A's entry; 24 bytes an entry
        lea     sg_ekt,%a1
        moveq   #0,%d0                  | the offset in sg_eksv
1:      move.l  (%a0),%d1
        cmp.l   (%a1),%d1
        beq.s   2f                      | ours already
        move.l  %a1,-(%sp)
        lea     sg_eksv,%a1
        move.l  %d1,(%a1,%d0.l)
        movea.l (%sp)+,%a1
        move.l  (%a1),(%a0)
2:      addq.l  #4,%a1
        lea     24(%a0),%a0
        addq.l  #4,%d0
        moveq   #20,%d1
        cmp.l   %d1,%d0
        blt.s   1b
        rts
sg_ekout:
        lea     0x46c7d8de+0x38*24,%a0
        lea     sg_ekt,%a1
        moveq   #0,%d0
1:      move.l  (%a0),%d1
        cmp.l   (%a1),%d1
        bne.s   2f                      | not ours
        move.l  %a1,-(%sp)
        lea     sg_eksv,%a1
        move.l  (%a1,%d0.l),(%a0)
        movea.l (%sp)+,%a1
2:      addq.l  #4,%a1
        lea     24(%a0),%a0
        addq.l  #4,%d0
        moveq   #20,%d1
        cmp.l   %d1,%d0
        blt.s   1b
        rts

| Z set in the full 8-track window (TRKS), where the cursor can sit on the track number (build 143).
| Uses d0.
sg_tnv:
        moveq   #1,%d0
        tst.l   sg_full
        beq.s   9f
        tst.l   sg_pv
        bne.s   9f
        tst.l   sg_view
        bne.s   9f
        moveq   #0,%d0
9:      tst.l   %d0
        rts

| FUNC + REC / PLAY / STOP with the cursor on a track number (TRKS; sg_kcop, d0 the key: 0 COPY, 1
| CLEAR, 2 PASTE; build 143): the whole track. COPY its 64 steps (a PAGES clip of all four pages) and
| its LEN and SCALE; CLEAR its 64 steps; PASTE a track's clip onto it, the pages where they were and its
| LEN and SCALE (another clip: as PASTE at step 1). AUDIO: CLEAR only (sg_aclrt). Uses everything but
| a5 a6.
sg_ktrk:
        tst.l   sg_aud
        beq.s   1f
        moveq   #1,%d1
        cmp.l   %d1,%d0
        bne     9f
        bra     sg_aclrt
1:      lea     -40(%sp),%sp
        movem.l %d2-%d7/%a2-%a5,(%sp)
        clr.l   sg_idle
        clr.l   sg_step
        moveq   #-1,%d1
        move.l  %d1,sg_sela
        move.l  %d0,%d6
        moveq   #2,%d1
        cmp.l   %d1,%d6
        beq.s   4f
        moveq   #15,%d0                 | COPY / CLEAR: all four pages
        move.l  %d0,sg_wpm
        moveq   #2,%d3
        bsr     sg_cop
        tst.l   %d6
        bne.s   3f
        bsr     sg_crec                 | COPY: the track's LEN and SCALE with the clip
        moveq   #0,%d0
        move.b  0x28(%a3),%d0
        move.l  %d0,sg_ctl
        move.b  0x29(%a3),%d0
        move.l  %d0,sg_cts
        moveq   #1,%d0
        move.l  %d0,sg_ctrk
        bra.s   3f
4:      bsr     sg_cpaste
        tst.l   sg_ctrk                 | a track's clip: its LEN and SCALE too
        beq.s   3f
        bsr     sg_crec
        move.l  sg_ctl,%d0
        move.b  %d0,0x28(%a3)
        move.b  %d0,0x28(%a4)
        move.l  sg_cts,%d0
        move.b  %d0,0x29(%a3)
        move.b  %d0,0x29(%a4)
        bsr     sg_sref
3:      movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        bra     sg_now
9:      rts

| CLEAR on an audio track's number (build 143): its 64 steps -- trig, trigless and p-lock masks clear,
| every lock 0xff (as sg_aset clears a step), the bank and its CS1 copy, the dirty flags, 0x4009da20(t),
| "CLEAR 64". Uses everything but a5 a6.
sg_aclrt:
        lea     -40(%sp),%sp
        movem.l %d2-%d7/%a2-%a5,(%sp)
        clr.l   sg_idle
        bsr     sg_sel                  | a1 the audio track's record
        movea.l %a1,%a3                 | a3: its CS1 copy
        suba.l  0x46c82456,%a3
        adda.l  #0x1001614e,%a3
        moveq   #23,%d1
1:      clr.b   (0,%a1,%d1.l)
        clr.b   (0,%a3,%d1.l)
        subq.l  #1,%d1
        bpl.s   1b
        lea     0x59(%a1),%a0
        lea     0x59(%a3),%a2
        move.l  #2048,%d1
        moveq   #-1,%d0
2:      move.b  %d0,(%a0)+
        move.b  %d0,(%a2)+
        subq.l  #1,%d1
        bne.s   2b
        bsr     sg_dirty
        move.l  sg_row,-(%sp)
        jsr     0x4009da20
        addq.l  #4,%sp
        lea     sg_fcc,%a0
        moveq   #64,%d0
        bsr     sg_cmsg
        movem.l (%sp),%d2-%d7/%a2-%a5
        lea     40(%sp),%sp
        bra     sg_now

| Encoder A / C pressed in the pitch view (the key table's handler, code 0x38 / 0x3a, state; build 131):
| in ROLL 16 the cursor on the lowest / highest note on the page shown, and that note on the bottom /
| top row (the range's A at or under it, sg_pwr the rest); ROLL 32 (its 32 steps) and KEYS 16 (build
| 133): the range's lowest octave on the lowest note, its upper octave on the highest. The panel up:
| the stock's handler.
sg_pjmp:
        lea     -24(%sp),%sp
        movem.l %d2-%d6/%a3,(%sp)
        tst.l   sg_mode                 | (the panel: the stock's)
        bne     8f
        moveq   #1,%d0
        cmp.l   24+8(%sp),%d0
        bne     9f
        bsr     sg_sel
        movea.l %a1,%a3
        moveq   #0,%d6
        move.b  (%a0),%d6
        moveq   #-1,%d4                 | d4: the note found, d2 its step
        moveq   #-1,%d2
        moveq   #0x30,%d5               | the page shown: 16 steps, ROLL 32's 32 (build 133)
        moveq   #1,%d0
        cmp.l   sg_plo,%d0
        bne.s   0f
        moveq   #0x20,%d5
0:      and.l   sg_step,%d5
1:      bsr     sg_pst
        tst.l   %d3
        beq.s   3f
        tst.l   %d4
        bmi.s   2f
        moveq   #0x38,%d0
        cmp.l   24+4(%sp),%d0
        bne.s   4f
        cmp.l   %d4,%d1                 | A: a lower one
        bge.s   3f
        bra.s   2f
4:      cmp.l   %d4,%d1                 | C: a higher one
        ble.s   3f
2:      move.l  %d1,%d4
        move.l  %d5,%d2
3:      addq.l  #1,%d5
        moveq   #15,%d0
        moveq   #1,%d1
        cmp.l   sg_plo,%d1
        bne.s   0f
        moveq   #31,%d0
0:      and.l   %d5,%d0
        bne.s   1b
        tst.l   %d4
        bmi     9f
        move.l  %d2,sg_step
        tst.l   sg_plo                  | ROLL 32, KEYS 16 (build 136): the range on it exactly, A its
        beq.s   0f                      | first note, C its last
        move.l  %d4,%d0
        moveq   #0x38,%d1
        cmp.l   24+4(%sp),%d1
        beq.s   1f
        subi.l  #23,%d0
1:      tst.l   %d0
        bpl.s   2f
        moveq   #0,%d0
2:      moveq   #104,%d1
        cmp.l   %d1,%d0
        ble.s   3f
        move.l  %d1,%d0
3:      move.l  %d0,sg_pb
        bra     7f
0:      move.l  %d4,%d0                 | d0: the bottom row's note (C: 10 under it)
        moveq   #0x38,%d1
        cmp.l   24+4(%sp),%d1
        beq.s   5f
        subi.l  #10,%d0
5:      moveq   #9,%d1
        cmp.l   %d1,%d0
        bge.s   6f
        move.l  %d1,sg_pb               | under A0: the lowest range
        clr.l   sg_pwr
        bra.s   7f
6:      move.l  %d0,%d1                 | the A at or under it: d1 = (d0 - 9) mod 12
        subi.l  #9,%d1
        move.l  %d1,%d3
        moveq   #12,%d5
        divu.l  %d5,%d3
        muls.l  %d5,%d3
        sub.l   %d3,%d1
        sub.l   %d1,%d0
        moveq   #93,%d3                 | (A7 the highest range)
        cmp.l   %d3,%d0
        ble.s   1f
        add.l   %d0,%d1
        sub.l   %d3,%d1
        move.l  %d3,%d0
        moveq   #13,%d3
        cmp.l   %d3,%d1
        ble.s   1f
        move.l  %d3,%d1
1:      move.l  %d0,sg_pb
        move.l  %d1,sg_pwr
7:      move.l  %d4,%d0                 | the cursor on it
        sub.l   sg_pb,%d0
        bpl.s   1f
        moveq   #0,%d0
1:      moveq   #23,%d1
        cmp.l   %d1,%d0
        ble.s   2f
        move.l  %d1,%d0
2:      move.l  %d0,sg_pr
        tst.l   sg_plo                  | (the others: ROLL 16's window on the cursor)
        beq.s   3f
        bsr     sg_pwin
3:      clr.l   sg_bk
        bsr     sg_pgset
        clr.l   sg_idle
        bsr     sg_now
9:      movem.l (%sp),%d2-%d6/%a3
        lea     24(%sp),%sp
        rts
8:      moveq   #0x3a,%d0               | another layout: the stock's
        cmp.l   24+4(%sp),%d0
        lea     sg_pjsv,%a0
        bne.s   1f
        addq.l  #4,%a0
1:      movem.l (%sp),%d2-%d6/%a3
        lea     24(%sp),%sp
        movea.l (%a0),%a0
        jmp     (%a0)

| A trig key in the pitch view (the key table's handler: code 0-15, state 1 press / 0 release).
sg_ptkh:
        tst.l   SG_HELD+0x2e*24         | PATTERN or BANK held: the stock's (pattern and bank select;
        bne .Lptst                  | build 138)
        tst.l   SG_HELD+0x2f*24
        bne .Lptst
        lea     -16(%sp),%sp
        movem.l %d2-%d4/%a2,(%sp)
        move.l  16+4(%sp),%d2           | d2: the key
        moveq   #15,%d0
        and.l   %d0,%d2
        lea     sg_pkn,%a2
        tst.l   16+8(%sp)
        bne.s   1f
        lea     sg_pko,%a0              | a release: its note off (the note sent, build 130)
        moveq   #0,%d0
        move.b  (0,%a0,%d2.l),%d0
        bne.s   2f                      | (none of ours: the stock's -- a pattern select's key let go,
        movem.l (%sp),%d2-%d4/%a2       | build 138)
        lea     16(%sp),%sp
        bra .Lptst
2:
        clr.b   (0,%a0,%d2.l)
        clr.b   (0,%a2,%d2.l)
        subq.l  #1,%d0
        pea     1.w
        clr.l   -(%sp)
        move.l  %d0,-(%sp)
        move.l  sg_row,-(%sp)
        jsr     0x4009e9a8
        lea     16(%sp),%sp
        bra     9f
1:      moveq   #1,%d0
        cmp.l   16+8(%sp),%d0
        bne     9f                      | (a press only)
        bsr     sg_pcb
        add.l   %d2,%d0
        move.l  %d0,%d3                 | d3: the note
        cmpi.l  #127,%d3
        bgt     9f
        tst.l   SG_HELD+0x2d*24         | FUNC + the key: the note on the cursor's step
        beq.s   3f
        move.l  %d3,%d0
        sub.l   sg_pb,%d0
        bmi.s   2f
        moveq   #23,%d1
        cmp.l   %d1,%d0
        bgt.s   2f
        move.l  %d0,sg_pr               | in the range: the cursor on it
        bsr     sg_pwin
        bra.s   4f
2:      move.l  %d3,%d0                 | outside it: the range round it
        bsr     sg_pset
4:      bsr     sg_pyes
3:      moveq   #0,%d0                  | play it: the Part's VEL for the track
        move.b  0x100b14cf,%d0
        move.l  #6322,%d1
        muls.l  %d1,%d0
        add.l   0x46c82456,%d0
        move.l  sg_row,%d1
        lsl.l   #5,%d1
        add.l   %d1,%d0
        addi.l  #0x8f163,%d0
        movea.l %d0,%a0
        moveq   #0,%d4
        move.b  (%a0),%d4
        move.l  %d3,%d0                 | the note the ARP page's TRAN makes it, as the sequencer's (build 130)
        bsr     sg_ptr
        pea     1.w
        move.l  %d4,-(%sp)
        move.l  %d0,-(%sp)
        move.l  sg_row,-(%sp)
        move.l  %d0,%d4
        jsr     0x4009e9a8
        lea     16(%sp),%sp
        lea     sg_pko,%a0
        addq.l  #1,%d4
        move.b  %d4,(0,%a0,%d2.l)
        move.l  %d3,%d0
        addq.l  #1,%d0
        move.b  %d0,(0,%a2,%d2.l)
9:      movem.l (%sp),%d2-%d4/%a2
        lea     16(%sp),%sp
        rts
.Lptst: move.l  4(%sp),%d0              | the stock's handler for the key (sg_ptsv), its frame as ours
        moveq   #15,%d1
        and.l   %d1,%d0
        lsl.l   #2,%d0
        lea     sg_ptsv,%a0
        movea.l (0,%a0,%d0.l),%a0
        jmp     (%a0)

| d0 = a note: d0 = it moved by the cursor's track's TRAN (the ARP page's since build 140, the live record
| 0x46c76dc0 + 0x44 t + 12; NOTE SETUP + 3 in 130-139; 64 none, 0 as 64), 0-127, as the engine plays a step's
| (build 130). Uses d0 d1 a0.
sg_ptr:
        move.l  sg_row,%d1
        lsl.l   #2,%d1
        lea     0x46c76dc0+12,%a0
        adda.l  %d1,%a0
        lsl.l   #4,%d1
        adda.l  %d1,%a0                 | + 0x44 t
        moveq   #0,%d1
        move.b  (%a0),%d1
        bne.s   1f
        moveq   #64,%d1
1:      add.l   %d1,%d0
        subi.l  #64,%d0
        bpl.s   2f
        moveq   #0,%d0
2:      cmpi.l  #127,%d0
        ble.s   3f
        moveq   #127,%d0
3:      rts

| The pitch view's trig LEDs (from sg_ptrg): the key of the cursor's step's note (id 2 k, the first
| colour) and of the step playing's (2 k + 1), 0x460ba9ae's first four bytes (byte id >> 3, bit id & 7;
| the blink bits 0x460ba98c cleared), the panel told (0x460babec). Uses d0 d1 a0 a1.
sg_pled:
        lea     -24(%sp),%sp
        movem.l %d2-%d6/%a3,(%sp)
        bsr     sg_sel                  | a1 the record, a0 the Part's NOTE page
        movea.l %a1,%a3
        moveq   #0,%d6
        move.b  (%a0),%d6
        bsr     sg_pcb
        move.l  %d0,%d4                 | d4: the keys' first note
        moveq   #0,%d2                  | d2: the LEDs, id i at bit 8 (3 - i / 8) + i mod 8
        moveq   #0,%d5                  | the naturals lit, as the stock CHROMATIC keyboard (build 129)
7:      move.l  %d4,%d0
        add.l   %d5,%d0
        moveq   #12,%d1
        divu.l  %d1,%d0
        muls.l  %d1,%d0
        move.l  %d4,%d1
        add.l   %d5,%d1
        sub.l   %d0,%d1                 | the note mod 12
        lea     sg_pkc,%a0
        tst.b   (0,%a0,%d1.l)
        bne.s   8f
        move.l  %d5,%d1
        add.l   %d1,%d1
        bsr     sg_lbit
8:      addq.l  #1,%d5
        moveq   #16,%d0
        cmp.l   %d0,%d5
        blt.s   7b
        move.l  sg_pply,%d5             | playing (build 133: none stopped or paused): the cursor's step's
        bmi.s   2f                      | note and the note playing in the second colour
        move.l  sg_step,%d5
        moveq   #1,%d0
        bsr.s   1f
        move.l  sg_pply,%d5
        moveq   #1,%d0
        bsr.s   1f
2:      clr.l   0x460ba98c
        move.l  %d2,0x460ba9ae
        moveq   #1,%d0
        move.l  %d0,0x460babec
        movem.l (%sp),%d2-%d6/%a3
        lea     24(%sp),%sp
        rts
1:      move.l  %d0,-(%sp)              | step d5's note's key, colour d0 (0 / 1)
        bsr     sg_pst
        move.l  (%sp)+,%d0
        tst.l   %d3
        beq.s   3f
        sub.l   %d4,%d1
        bmi.s   3f
        moveq   #15,%d3
        cmp.l   %d3,%d1
        bgt.s   3f
        add.l   %d1,%d1
        add.l   %d0,%d1
        bsr     sg_lbit
3:      rts

| d1 = an LED id 0-31: its bit set in d2. Uses d1 d3.
sg_lbit:
        move.l  %d0,-(%sp)
        move.l  %d1,%d0
        moveq   #7,%d3
        and.l   %d1,%d3                 | the bit in its byte
        lsr.l   #3,%d0                  | its byte
        neg.l   %d0
        addq.l  #3,%d0
        lsl.l   #3,%d0
        add.l   %d3,%d0
        moveq   #1,%d3
        lsl.l   %d0,%d3
        or.l    %d3,%d2
        move.l  (%sp)+,%d0
        rts

| d0 = the shown steps' mask (0x30 a page, 0x20 a pair), d7 their first: d1 = the note of the step
| playing (sg_pply) over the range's A when it is shown and has one, else -1 (N set). Uses d0 d1 d3 d5.
sg_ppn:
        move.l  sg_pply,%d1
        bmi.s   9f
        and.l   %d1,%d0
        cmp.l   %d7,%d0
        bne.s   8f
        move.l  %d1,%d5
        bsr     sg_pst
        tst.l   %d3
        beq.s   8f
        sub.l   sg_pb,%d1
        bmi.s   8f
        tst.l   %d1
        rts
8:      moveq   #-1,%d1
9:      rts

| The views' settings saved with the project (build 137): PROJECT settings of STEP VIEW in BRAIN's value
| table (SAVE PROJECT writes them to brain.work, LOAD PROJECT reads them). Each tick: a table value that
| is not what we last saw (a load, a SETTINGS edit) puts the table into ours; else ours that changed go
| into the table. Keeps every register.
        .set    SG_BN, 10
sg_bsync:
        lea     -24(%sp),%sp
        movem.l %d0-%d2/%a0-%a2,(%sp)
        lea     sg_btab,%a1
        lea     sg_bshd,%a2
        moveq   #SG_BN-1,%d1
        moveq   #0,%d2
1:      movea.l (%a1)+,%a0
        move.l  (%a0),%d0
        cmp.l   (%a2)+,%d0
        beq.s   2f
        moveq   #1,%d2
2:      subq.l  #1,%d1
        bpl.s   1b
        lea     sg_btab,%a1
        lea     sg_bshd,%a2
        moveq   #SG_BN-1,%d1
        tst.l   %d2
        beq.s   5f
3:      movea.l (%a1)+,%a0              | the table's into ours
        move.l  (%a0),%d0
        move.l  %d0,(%a2)+
        movea.l (SG_BN*4-4,%a1),%a0
        move.l  %d0,(%a0)
        subq.l  #1,%d1
        bpl.s   3b
        tst.l   sg_pv                   | (the pitch view is the full view's)
        beq.s   4f
        moveq   #1,%d0
        move.l  %d0,sg_full
4:      moveq   #1,%d0
        move.l  %d0,0x46c7c72c
        bra.s   9f
5:      movea.l (%a1)+,%a0              | ours that changed into the table: a0 its slot
        move.l  %a0,-(%sp)
        movea.l (SG_BN*4-4,%a1),%a0     | (sg_bvar follows sg_btab)
        move.l  (%a0),%d0
        movea.l (%sp)+,%a0
        cmp.l   (%a2),%d0
        beq.s   6f
        move.l  %d0,(%a2)
        move.l  %d0,(%a0)
6:      addq.l  #4,%a2
        subq.l  #1,%d1
        bpl.s   5b
9:      movem.l (%sp),%d0-%d2/%a0-%a2
        lea     24(%sp),%sp
        rts

| d0 = d0 mod 12, 0-11, for any sign (build 136). Uses d0 d1.
sg_pm12:
        move.l  %d0,-(%sp)
        bpl.s   1f
        neg.l   %d0
        moveq   #12,%d1
        divu.l  %d1,%d0
        addq.l  #1,%d0
        muls.l  %d1,%d0
        add.l   (%sp)+,%d0
        moveq   #12,%d1
        cmp.l   %d1,%d0
        bne.s   2f
        moveq   #0,%d0
2:      rts
1:      moveq   #12,%d1
        divu.l  %d1,%d0
        muls.l  %d1,%d0
        neg.l   %d0
        add.l   (%sp)+,%d0
        rts

| d0 = a key of the range (0-23): d0 = its note's class over the A (sg_pkb's index), (sg_pb + d0 + 3) mod
| 12 -- the range's first note any note since build 134 (an A until 133). Uses d0 d1.
sg_pkk:
        add.l   sg_pb,%d0
        addq.l  #3,%d0
        move.l  %d0,-(%sp)
        moveq   #12,%d1
        divu.l  %d1,%d0
        muls.l  %d1,%d0
        neg.l   %d0
        add.l   (%sp)+,%d0
        rts

| d0 = a key of layout 2's keyboard (0-23): lit, the whole key (build 132; its middle / foot until 131) --
| a black key's body hollow and its foot as wide as it, a white key filled. Uses d0-d3 a0 a1.
sg_pk2:
        move.l  %d4,-(%sp)
        move.l  %d0,%d4                 | d4: x = 4 + 5 n
        add.l   %d4,%d4
        add.l   %d4,%d4
        add.l   %d0,%d4
        addq.l  #4,%d4
        bsr     sg_pkk                  | (its class from its note: the range any note, build 134)
1:      lea     sg_pkb,%a0
        tst.b   (0,%a0,%d0.l)
        beq.s   2f
        moveq   #1,%d0                  | a black key: its body hollow, its foot as wide as it
        add.l   %d4,%d0
        moveq   #58,%d1
        moveq   #3,%d2
        add.l   %d4,%d2
        moveq   #60,%d3
        bsr     sg_clr
        move.l  %d4,%d0
        moveq   #62,%d1
        moveq   #4,%d2
        add.l   %d4,%d2
        moveq   #63,%d3
        bsr     sg_pf
        bra.s   3f
2:      move.l  %d4,%d0                 | a white key: filled, its full height
        moveq   #57,%d1
        moveq   #3,%d2
        add.l   %d4,%d2
        moveq   #63,%d3
        bsr     sg_pf
3:      move.l  (%sp)+,%d4
        rts

| The pitch views' cursor (build 132): d4 x, d5 top of the cell, d0 its width (= height; KEYS 16: 4 x 2,
| d0 = -4), d6 the note there (0 none, 1 a trig, 2 trigless). The cell cleared, an outline a pixel round
| it, inside a square of the cell's size - 2 (ROLL 32: 1 x 2, KEYS 16: 2 x 2) on a note, its middle out
| when trigless (ROLL 16); on none ROLL 16's dot. Ends the draw.
.Lpcur: move.l  %d0,%d7                 | d7: the width; the height d3 - d5 + 1 below
        moveq   #-4,%d1
        cmp.l   %d1,%d0
        bne.s   1f
        moveq   #4,%d7
        moveq   #2,%d2                  | (KEYS 16: 2 rows)
        bra.s   2f
1:      moveq   #2,%d2                  | (ROLL 32: 3 x 2)
        moveq   #3,%d1
        cmp.l   %d1,%d0
        beq.s   2f
        move.l  %d0,%d2                 | (ROLL 16: 5 x 5)
2:      move.l  %d2,-(%sp)              | (sp): the height
        tst.l   %d6                     | (no note there: the cell as drawn, its dot or an other octave's
        beq.s   5f                      | arrow inside the outline; build 133)
        move.l  %d4,%d0                 | the cell cleared
        move.l  %d5,%d1
        move.l  %d4,%d2
        add.l   %d7,%d2
        subq.l  #1,%d2
        move.l  %d5,%d3
        add.l   (%sp),%d3
        subq.l  #1,%d3
        bsr     sg_clr
5:      move.l  %d4,%d0                 | the outline
        subq.l  #1,%d0
        move.l  %d5,%d1
        subq.l  #1,%d1
        move.l  %d4,%d2
        add.l   %d7,%d2
        move.l  %d5,%d3
        add.l   (%sp),%d3
        bsr     sg_obox
        tst.l   %d6
        beq.s   9f
        move.l  %d4,%d0                 | a note: the square inside, x + 1 .. x + w - 2
        addq.l  #1,%d0
        move.l  %d4,%d2
        add.l   %d7,%d2
        subq.l  #2,%d2
        move.l  %d5,%d1                 | rows: ROLL 16 + 1 .. + 3, the others the cell's
        move.l  %d5,%d3
        add.l   (%sp),%d3
        subq.l  #1,%d3
        moveq   #5,%d0
        cmp.l   %d0,%d7
        bne.s   4f
        addq.l  #1,%d1
        subq.l  #1,%d3
4:      move.l  %d4,%d0
        addq.l  #1,%d0
        bsr     sg_pf
        moveq   #2,%d0                  | trigless in ROLL 16: its middle out
        cmp.l   %d0,%d6
        bne.s   9f
        moveq   #5,%d0
        cmp.l   %d0,%d7
        bne.s   9f
        moveq   #2,%d0
        add.l   %d4,%d0
        moveq   #2,%d1
        add.l   %d5,%d1
        bsr     sg_xc
9:      addq.l  #4,%sp
        bra     .Lpd_end

| d0 = the note at the cursor (build 132): 0 none, 1 a trig, 2 trigless -- the cursor's step's note
| when it is the cursor's (sg_pb + sg_pr). a3 d6 as for sg_pst. Uses d0 d1 d3 d5.
sg_pcur:
        move.l  sg_step,%d5
        bsr     sg_pst
        moveq   #0,%d0
        tst.l   %d3
        beq.s   9f
        move.l  sg_pb,%d0
        add.l   sg_pr,%d0
        cmp.l   %d1,%d0
        bne.s   8f
        move.l  %d3,%d0
        rts
8:      moveq   #0,%d0
9:      rts

| An outline: d0 x0, d1 top, d2 x1, d3 bottom; keeps d2 d3. Uses d0 d1 a0 a1.
sg_obox:
        lea     -16(%sp),%sp
        movem.l %d0-%d3,(%sp)
        move.l  4(%sp),%d3
        bsr     sg_pf                   | the top
        move.l  (%sp),%d0
        move.l  12(%sp),%d1
        move.l  12(%sp),%d3
        bsr     sg_pf                   | the foot
        move.l  (%sp),%d0
        move.l  4(%sp),%d1
        move.l  (%sp),%d2
        bsr     sg_pf                   | the left
        move.l  8(%sp),%d0
        move.l  4(%sp),%d1
        move.l  8(%sp),%d2
        bsr     sg_pf                   | the right
        movem.l (%sp),%d0-%d3
        lea     16(%sp),%sp
        rts

| d0 = a row of layout 0's window over its bottom (0-10): d1 its top, 8 + 5 (10 - d0). Uses d1.
sg_ptop:
        moveq   #10,%d1
        sub.l   %d0,%d1
        move.l  %d1,-(%sp)
        lsl.l   #2,%d1
        add.l   (%sp)+,%d1
        addq.l  #8,%d1
        rts

| ---- layout 1: 32 steps, the 24 notes, a keyboard. Note n over the A at rows y = 9 + 2 (23 - n) and
|      y + 1; step column c (0-31, the page pair from sg_step & 0x20) at x 16 + 3 (c mod 4) + 14 (c / 4),
|      3 px (2 before the same note: build 129; x 11 + 3 c, 2 px, and a right column until 129). The
|      keyboard at x 5-13, the octave numbers at x 1, a dot per step at the foot (row 60).
sg_pd1:
        moveq   #0,%d4                  | the octave numbers at the C's (build 129), at x 1; first, so the
.Lp1o:  move.l  sg_pb,%d0               | keyboard is over anything their cells clear
        add.l   %d4,%d0
        move.l  %d0,%d1
        moveq   #12,%d2
        divu.l  %d2,%d1
        muls.l  %d2,%d1
        cmp.l   %d0,%d1
        bne.s   1f
        lea     sg_b2,%a1
        bsr     sg_name
        moveq   #23,%d1                 | its top: the key's row - 2
        sub.l   %d4,%d1
        add.l   %d1,%d1
        addq.l  #7,%d1
        moveq   #59,%d0
        sub.l   %d1,%d0
        move.l  %d0,%d1
        moveq   #1,%d0
        moveq   #0,%d2
        lea     SG_SMALL,%a0
        lea     sg_b2+4,%a1
        bsr     sg_tx
1:      addq.l  #1,%d4
        moveq   #24,%d0
        cmp.l   %d0,%d4
        blt.s   .Lp1o
        moveq   #0,%d4                  | the keyboard (x 5-13): d4 the note over the A
.Lp1k:  moveq   #23,%d5
        sub.l   %d4,%d5
        add.l   %d5,%d5
        addi.l  #9,%d5                  | d5: its top row
        move.l  %d4,%d0
        bsr     sg_pkk                  | (its class from its note: the range any note, build 134)
1:      lea     sg_pkb,%a0
        move.l  %d0,-(%sp)
        tst.b   (0,%a0,%d0.l)
        beq.s   2f
        moveq   #5,%d0                  | a black key: x 5-9
        move.l  %d5,%d1
        moveq   #9,%d2
        move.l  %d5,%d3
        addq.l  #1,%d3
        bsr     sg_pf
2:      move.l  (%sp)+,%d0
        moveq   #3,%d1                  | under C and F (over B and E): a white keys' edge
        cmp.l   %d1,%d0
        beq.s   3f
        moveq   #8,%d1
        cmp.l   %d1,%d0
        bne.s   4f
3:      moveq   #5,%d0
        move.l  %d5,%d1
        addq.l  #1,%d1
        moveq   #12,%d2
        move.l  %d1,%d3
        bsr     sg_pf
4:      addq.l  #1,%d4
        moveq   #24,%d0
        cmp.l   %d0,%d4
        blt.s   .Lp1k
        moveq   #13,%d0                 | its right edge
        moveq   #9,%d1
        moveq   #13,%d2
        moveq   #56,%d3
        bsr     sg_pf
        moveq   #28,%d2                 | a dotted line in each gap between 4 steps
1:      moveq   #9,%d3
2:      move.l  %d2,%d0
        move.l  %d3,%d1
        bsr     sg_xp
        addq.l  #4,%d3
        moveq   #56,%d0
        cmp.l   %d0,%d3
        ble.s   2b
        addi.l  #14,%d2
        cmpi.l  #112,%d2
        ble.s   1b
        bsr     sg_pcb                  | the trig keys' first note's octaves (build 136): a dotted line
        sub.l   sg_pb,%d0               | on each one's foot row: a dot under each step's middle, as the
        bsr     sg_pm12                 | foot row (build 147, Zach; every 2 px, x 16-125, until 146)
        move.l  %d0,%d4
1:      moveq   #23,%d5
        sub.l   %d4,%d5
        add.l   %d5,%d5
        addi.l  #10,%d5                 | y + 1 = 10 + 2 (23 - n)
        moveq   #0,%d2                  | d2: the step, 0-31
2:      move.l  %d2,%d0
        bsr     sg_p1x
        addq.l  #1,%d0
        move.l  %d5,%d1
        bsr     sg_xp
        addq.l  #1,%d2
        moveq   #32,%d0
        cmp.l   %d0,%d2
        blt.s   2b
        addi.l  #12,%d4
        moveq   #23,%d0
        cmp.l   %d0,%d4
        ble.s   1b
        moveq   #0x20,%d7               | d7: the pair's first step, d4 the column
        and.l   sg_step,%d7
        moveq   #0,%d4
.Lp1c:  move.l  %d7,%d5
        add.l   %d4,%d5
        bsr     sg_pst
        tst.l   %d3
        beq     .Lp1n
        movea.l %d1,%a6
        moveq   #3,%d0                  | the width: 3, 2 when the next step in the 4 has the same note
        move.l  %d0,sg_p1w              | (a gap kept: two notes never touch)
        and.l   %d4,%d0
        moveq   #3,%d2
        cmp.l   %d2,%d0
        beq.s   1f
        move.l  %d3,-(%sp)
        move.l  %d1,-(%sp)
        addq.l  #1,%d5
        bsr     sg_pst
        subq.l  #1,%d5
        move.l  (%sp)+,%d0
        tst.l   %d3
        beq.s   2f
        cmp.l   %d0,%d1
        bne.s   2f
        moveq   #2,%d1
        move.l  %d1,sg_p1w
2:      move.l  %d0,%d1
        move.l  (%sp)+,%d3
1:      move.l  %d4,%d0                 | d2: x
        bsr     sg_p1x
        move.l  %d0,%d2
        move.l  %a6,%d0
        sub.l   sg_pb,%d0
        bmi     .Lp1dn
        moveq   #23,%d1
        cmp.l   %d1,%d0
        bgt     .Lp1up
        sub.l   %d0,%d1                 | y = 9 + 2 (23 - n)
        add.l   %d1,%d1
        addi.l  #9,%d1
        move.l  %d3,-(%sp)
        move.l  %d1,-(%sp)
        move.l  %d2,-(%sp)
        move.l  %d2,%d0
        add.l   sg_p1w,%d2
        subq.l  #1,%d2
        move.l  %d1,%d3
        addq.l  #1,%d3
        bsr     sg_pf                   | w x 2
        move.l  (%sp)+,%d2
        move.l  (%sp)+,%d1
        move.l  (%sp)+,%d3
        cmpi.l  #2,%d3
        bne.s   .Lp1ch
        move.l  %d2,%d0                 | trigless: a checker
        addq.l  #1,%d0
        move.l  %d1,-(%sp)
        bsr     sg_xc
        move.l  (%sp)+,%d1
        addq.l  #1,%d1
        move.l  %d2,%d0
        move.l  %d1,-(%sp)
        bsr     sg_xc
        move.l  (%sp)+,%d1
        moveq   #3,%d0
        cmp.l   sg_p1w,%d0
        bne.s   .Lp1ch
        move.l  %d2,%d0
        addq.l  #2,%d0
        bsr     sg_xc
        bra.s   .Lp1ch
.Lp1up: moveq   #12,%d1                 | another octave (build 136; a dash at the grid's edge until 135):
        bra.s   1f                      | an arrow on its letter's row, the upper octave's for one above,
.Lp1dn: moveq   #0,%d1                  | pointing up; the lower's, down -- 3 px, over the row's 2
1:      move.l  %d1,-(%sp)
        bsr     sg_pm12                 | (d0 = the note over the range's first)
        add.l   (%sp),%d0
        moveq   #23,%d1
        sub.l   %d0,%d1
        add.l   %d1,%d1
        addi.l  #9,%d1                  | d1: the row's top
        move.l  %d2,-(%sp)              | up: its top the middle pixel, its foot all 3; down: the other way
        move.l  %d1,-(%sp)
        move.l  %d2,%d0
        addq.l  #1,%d0
        tst.l   8(%sp)
        bne.s   2f
        addq.l  #1,%d1
2:      bsr     sg_xp
        move.l  (%sp),%d1
        tst.l   8(%sp)
        beq.s   3f
        addq.l  #1,%d1
3:      move.l  4(%sp),%d0
        moveq   #2,%d2
        add.l   %d0,%d2
        move.l  %d1,%d3
        bsr     sg_pf
        addq.l  #4,%sp
        move.l  (%sp)+,%d2
        addq.l  #4,%sp
.Lp1ch: moveq   #3,%d3                  | NOT2-4: a w x 1 dash on its row
1:      move.l  %d3,%d0
        bsr     sg_pcn
        tst.l   %d1
        bmi.s   4f
        sub.l   sg_pb,%d1
        bmi.s   4f
        moveq   #23,%d0
        cmp.l   %d0,%d1
        bgt.s   4f
        sub.l   %d1,%d0
        add.l   %d0,%d0
        addi.l  #9,%d0
        move.l  %d0,%d1
        move.l  %d2,-(%sp)
        move.l  %d3,-(%sp)
        move.l  %d2,%d0
        add.l   sg_p1w,%d2
        subq.l  #1,%d2
        move.l  %d1,%d3
        bsr     sg_pf
        move.l  (%sp)+,%d3
        move.l  (%sp)+,%d2
4:      addq.l  #1,%d3
        cmpi.l  #5,%d3
        ble.s   1b
.Lp1n:  addq.l  #1,%d4
        moveq   #32,%d0
        cmp.l   %d0,%d4
        blt     .Lp1c
        moveq   #1,%d0                  | the trig keys' notes marked (build 129)
        bsr     sg_pmk
        moveq   #1,%d0                  | the notes the trig keys play lit
        bsr     sg_phl
        moveq   #0x20,%d0               | the note playing: its key inverted (build 126)
        bsr     sg_ppn
        bmi.s   7f
        moveq   #23,%d0
        cmp.l   %d0,%d1
        bgt.s   7f
        sub.l   %d1,%d0
        add.l   %d0,%d0
        addi.l  #9,%d0
        move.l  %d0,%d1
        moveq   #5,%d0
        moveq   #12,%d2
        move.l  %d1,%d3
        addq.l  #1,%d3
        bsr     sg_inv
7:      moveq   #0,%d4                  | the foot (build 129): a dot for each step, rows 59-61
1:      move.l  %d4,%d0
        bsr     sg_p1x
        addq.l  #1,%d0
        moveq   #60,%d1
        bsr     sg_xp
        addq.l  #1,%d4
        moveq   #32,%d0
        cmp.l   %d0,%d4
        blt.s   1b
        move.l  sg_pply,%d0             | the step playing: its column inverted, a hollow square at the foot
        bmi.s   1f
        moveq   #0x20,%d1
        and.l   %d0,%d1
        cmp.l   %d7,%d1
        bne.s   1f
        sub.l   %d7,%d0
        bsr     sg_p1x
        move.l  %d0,%d4
        moveq   #2,%d2
        add.l   %d0,%d2
        moveq   #9,%d1
        moveq   #56,%d3
        bsr     sg_inv
        move.l  %d4,%d0
        moveq   #2,%d2
        add.l   %d0,%d2
        moveq   #59,%d1
        moveq   #61,%d3
        bsr     sg_pf
        move.l  %d4,%d0
        addq.l  #1,%d0
        moveq   #60,%d1
        bsr     sg_xc
1:      move.l  sg_step,%d0             | the cursor's step: a filled square at the foot
        sub.l   %d7,%d0
        bsr     sg_p1x
        move.l  %d0,%d4                 | d4: its x
        moveq   #2,%d2
        add.l   %d0,%d2
        moveq   #59,%d1
        moveq   #61,%d3
        bsr     sg_pf
        bsr     sg_cvis                 | the cursor: its key inverted, its cell an outline (build 132)
        tst.l   %d1
        beq     .Lpd_end
        bsr     sg_pcur
        move.l  %d0,%d6
        moveq   #23,%d1
        sub.l   sg_pr,%d1
        add.l   %d1,%d1
        addi.l  #9,%d1
        move.l  %d1,%d5                 | d5: its top row
        moveq   #5,%d0
        moveq   #12,%d2
        move.l  %d1,%d3
        addq.l  #1,%d3
        bsr     sg_inv
        moveq   #3,%d0
        bra     .Lpcur

| d0 = a step column of layout 1 (0-31): d0 its x, 16 + 3 (c mod 4) + 14 (c / 4) (build 129: 3-px notes,
| a 2-px gap after each 4). Uses d0 d1.
sg_p1x:
        moveq   #3,%d1
        and.l   %d0,%d1
        move.l  %d1,-(%sp)
        add.l   %d1,%d1
        add.l   (%sp)+,%d1              | 3 (c mod 4)
        lsr.l   #2,%d0
        move.l  %d0,-(%sp)
        lsl.l   #4,%d0
        sub.l   (%sp),%d0
        sub.l   (%sp)+,%d0              | 14 (c / 4)
        add.l   %d1,%d0
        addi.l  #16,%d0
        rts

| One pixel cleared: d0 x, d1 row; keeps d2 d3.
sg_xc:
        move.l  %d2,-(%sp)
        move.l  %d3,-(%sp)
        move.l  %d0,%d2
        move.l  %d1,%d3
        bsr     sg_clr
        move.l  (%sp)+,%d3
        move.l  (%sp)+,%d2
        rts

| ---- layout 2: horizontal. Step row c (0-15) at rows y = 8 + 3 c and y + 1, a dotted line under every
|      4th (rows 19, 31, 43); note n over the A at x 4 + 5 n (a 4-px block); the keyboard at rows 56-63.
sg_pd2:
        moveq   #19,%d3                 | the 4-step lines
1:      moveq   #4,%d2
2:      move.l  %d2,%d0
        move.l  %d3,%d1
        bsr     sg_xp
        addq.l  #2,%d2
        cmpi.l  #123,%d2
        ble.s   2b
        addi.l  #12,%d3
        cmpi.l  #43,%d3
        ble.s   1b
        bsr     sg_pcb                  | a dot on each step row at the trig keys' first note's every
        sub.l   sg_pb,%d0               | octave on the range (build 136; that note and the next in 134-135,
        bsr     sg_pm12                 | the range's two C's until 133), in the gap left of their keys'
        move.l  %d0,%d4                 | notes (x 3 + 5 k)
        add.l   %d4,%d4
        add.l   %d4,%d4
        add.l   %d0,%d4
        addq.l  #3,%d4
        moveq   #8,%d3
3:      move.l  %d4,%d5
7:      move.l  %d5,%d0
        bsr.s   4f
        addi.l  #60,%d5
        cmpi.l  #123,%d5
        ble.s   7b
        addq.l  #3,%d3
        cmpi.l  #53,%d3
        ble.s   3b
        bra.s   5f
4:      moveq   #3,%d1                  | x d0 on the keys (3 .. 123): the dot at row d3
        cmp.l   %d1,%d0
        blt.s   6f
        moveq   #123,%d1
        cmp.l   %d1,%d0
        bgt.s   6f
        move.l  %d3,%d1
        bsr     sg_xp
6:      rts
5:
        moveq   #0,%d0                  | the keyboard: its top line
        moveq   #56,%d1
        move.l  #127,%d2
        moveq   #56,%d3
        bsr     sg_pf
        moveq   #3,%d0                  | its ends
        moveq   #57,%d1
        moveq   #3,%d2
        moveq   #63,%d3
        bsr     sg_pf
        moveq   #124,%d0
        moveq   #57,%d1
        moveq   #124,%d2
        moveq   #63,%d3
        bsr     sg_pf
        moveq   #0,%d4                  | d4: the key
.Lp2k:  move.l  %d4,%d5                 | d5: x = 4 + 5 n
        add.l   %d5,%d5
        add.l   %d5,%d5
        add.l   %d4,%d5
        addq.l  #4,%d5
        move.l  %d4,%d0
        bsr     sg_pkk                  | (its class from its note: the range any note, build 134)
1:      lea     sg_pkb,%a0
        move.l  %d0,-(%sp)
        tst.b   (0,%a0,%d0.l)
        beq.s   2f
        move.l  %d5,%d0                 | a black key: the upper 5 rows, its middle line below
        moveq   #57,%d1
        moveq   #4,%d2
        add.l   %d5,%d2
        moveq   #61,%d3
        bsr     sg_pf
        moveq   #2,%d0
        add.l   %d5,%d0
        moveq   #62,%d1
        move.l  %d0,%d2
        moveq   #63,%d3
        bsr     sg_pf
2:      move.l  (%sp)+,%d0
        moveq   #2,%d1                  | B and E: their right edge the full height
        cmp.l   %d1,%d0
        beq.s   3f
        moveq   #7,%d1
        cmp.l   %d1,%d0
        bne.s   4f
3:      moveq   #4,%d0
        add.l   %d5,%d0
        moveq   #57,%d1
        move.l  %d0,%d2
        moveq   #63,%d3
        bsr     sg_pf
4:      addq.l  #1,%d4
        moveq   #24,%d0
        cmp.l   %d0,%d4
        blt     .Lp2k
        moveq   #0x30,%d7               | d7: the page's first step, d4 the row
        and.l   sg_step,%d7
        moveq   #0,%d4
.Lp2c:  move.l  %d7,%d5
        add.l   %d4,%d5
        bsr     sg_pst
        tst.l   %d3
        beq     .Lp2n
        movea.l %d1,%a6
        move.l  %d4,%d2                 | d2: y = 8 + 3 c (kept as the row here)
        add.l   %d2,%d2
        add.l   %d4,%d2
        addq.l  #8,%d2
        move.l  %d1,%d0
        sub.l   sg_pb,%d0
        bmi     .Lp2dn
        moveq   #23,%d1
        cmp.l   %d1,%d0
        bgt     .Lp2up
        move.l  %d0,%d1                 | x = 4 + 5 n
        add.l   %d1,%d1
        add.l   %d1,%d1
        add.l   %d1,%d0
        addq.l  #4,%d0
        move.l  %d3,-(%sp)
        move.l  %d2,-(%sp)
        move.l  %d0,-(%sp)
        move.l  %d2,%d1
        moveq   #3,%d2
        add.l   %d0,%d2
        move.l  %d1,%d3
        addq.l  #1,%d3
        bsr     sg_pf                   | 4 x 2
        move.l  (%sp)+,%d0
        move.l  (%sp)+,%d2
        move.l  (%sp)+,%d3
        cmpi.l  #2,%d3
        bne .Lp2ch
        move.l  %d0,-(%sp)              | trigless: its top's middle cleared
        addq.l  #1,%d0
        move.l  %d2,%d1
        bsr     sg_xc
        move.l  (%sp)+,%d0
        addq.l  #2,%d0
        move.l  %d2,%d1
        bsr     sg_xc
        bra .Lp2ch
.Lp2up: moveq   #12,%d1                 | another octave (build 133; marks at the edges in 123-132): an
        bra.s   1f                      | arrow on its letter's key, pointing to its octave -- above on
.Lp2dn: moveq   #0,%d1                  | the upper octave's key, right, below on the lower's, left
1:      move.l  %d1,-(%sp)
        move.l  %d0,%d3                 | d3 = d0 mod 12, 0-11
        moveq   #12,%d1
        tst.l   %d3
        bpl.s   2f
        neg.l   %d3
        divu.l  %d1,%d3
        addq.l  #1,%d3
        muls.l  %d1,%d3
        add.l   %d0,%d3
        bra.s   3f
2:      divu.l  %d1,%d3
        muls.l  %d1,%d3
        neg.l   %d3
        add.l   %d0,%d3
3:      cmp.l   %d1,%d3
        bne.s   4f
        moveq   #0,%d3
4:      move.l  (%sp)+,%d1
        add.l   %d1,%d3                 | the key; x = 4 + 5 k
        move.l  %d3,%d0
        add.l   %d0,%d0
        add.l   %d0,%d0
        add.l   %d3,%d0
        addq.l  #4,%d0
        move.l  %d2,-(%sp)
        move.l  %d0,-(%sp)
        lea     sg_pal,%a1              | a chevron over 3 rows, y .. y + 2 (the gap under), 4 px: < for
        tst.l   %d1                     | the lower octave, > for the upper (build 134; up / down in 133):
        beq.s   5f                      | each row (x0, x1) over x
        lea     sg_par,%a1
5:      moveq   #0,%d3
6:      move.l  (%sp),%d0
        moveq   #0,%d1
        move.b  (%a1)+,%d1
        add.l   %d1,%d0
        move.l  (%sp),%d2
        moveq   #0,%d1
        move.b  (%a1)+,%d1
        add.l   %d1,%d2
        move.l  4(%sp),%d1
        add.l   %d3,%d1
        move.l  %d3,-(%sp)
        move.l  %a1,-(%sp)
        move.l  %d1,%d3
        bsr     sg_pf
        movea.l (%sp)+,%a1
        move.l  (%sp)+,%d3
        addq.l  #1,%d3
        moveq   #3,%d0
        cmp.l   %d0,%d3
        blt.s   6b
        addq.l  #4,%sp
        move.l  (%sp)+,%d2
.Lp2ch: moveq   #3,%d3                  | NOT2-4: 2 x 2 in the key's middle
1:      move.l  %d3,%d0
        bsr     sg_pcn
        tst.l   %d1
        bmi.s   4f
        sub.l   sg_pb,%d1
        bmi.s   4f
        moveq   #23,%d0
        cmp.l   %d0,%d1
        bgt.s   4f
        move.l  %d1,%d0
        add.l   %d0,%d0
        add.l   %d0,%d0
        add.l   %d1,%d0
        addq.l  #5,%d0
        move.l  %d2,-(%sp)
        move.l  %d3,-(%sp)
        move.l  %d2,%d1
        moveq   #1,%d2
        add.l   %d0,%d2
        move.l  %d1,%d3
        addq.l  #1,%d3
        bsr     sg_pf
        move.l  (%sp)+,%d3
        move.l  (%sp)+,%d2
4:      addq.l  #1,%d3
        cmpi.l  #5,%d3
        ble.s   1b
.Lp2n:  addq.l  #1,%d4
        moveq   #16,%d0
        cmp.l   %d0,%d4
        blt     .Lp2c
        moveq   #2,%d0                  | the trig keys' notes marked (build 129)
        bsr     sg_pmk
        moveq   #2,%d0                  | the notes the trig keys play lit
        bsr     sg_phl
        moveq   #0x30,%d0               | the note playing: its key lit (build 126)
        bsr     sg_ppn
        bmi.s   7f
        moveq   #23,%d0
        cmp.l   %d0,%d1
        bgt.s   7f
        move.l  %d1,%d0
        bsr     sg_pk2
7:      moveq   #8,%d4                  | the steps' column at the left (build 132): a 2 x 2 square each at
1:      moveq   #0,%d0                  | x 0-1 (a dot until 132), the step playing a 3 x 2 bar
        move.l  %d4,%d1
        moveq   #1,%d2
        move.l  %d4,%d3
        addq.l  #1,%d3
        bsr     sg_pf
        addq.l  #3,%d4
        moveq   #53,%d0
        cmp.l   %d0,%d4
        ble.s   1b
        move.l  sg_pply,%d0
        bmi.s   1f
        moveq   #0x30,%d1
        and.l   %d0,%d1
        cmp.l   %d7,%d1
        bne.s   1f
        sub.l   %d7,%d0
        move.l  %d0,%d1
        add.l   %d0,%d0
        add.l   %d0,%d1
        addq.l  #8,%d1
        moveq   #0,%d0
        moveq   #2,%d2
        move.l  %d1,%d3
        addq.l  #1,%d3
        bsr     sg_pf
1:
        move.l  sg_pply,%d0             | the step playing: a solid line in the gap under its row (build
        bmi.s   1f                      | 127; its row inverted in 123-126, which flipped its notes off
        moveq   #0x30,%d1               | and its blanks on as the bar passed)
        and.l   %d0,%d1
        cmp.l   %d7,%d1
        bne.s   1f
        sub.l   %d7,%d0
        move.l  %d0,%d1
        add.l   %d0,%d0
        add.l   %d0,%d1
        addi.l  #10,%d1
        moveq   #4,%d0
        moveq   #123,%d2
        move.l  %d1,%d3
        bsr     sg_pf
1:      bsr     sg_cvis                 | the cursor: its cell an outline (build 132; inverted until 131),
        tst.l   %d1                     | and its key
        beq     .Lpd_end
        bsr     sg_pcur
        move.l  %d0,%d6
        move.l  sg_pr,%d4               | d4: x = 4 + 5 n
        move.l  %d4,%d0
        add.l   %d0,%d0
        add.l   %d0,%d0
        add.l   %d0,%d4
        addq.l  #4,%d4
        move.l  sg_step,%d0
        sub.l   %d7,%d0
        move.l  %d0,%d5
        add.l   %d0,%d0
        add.l   %d0,%d5
        addq.l  #8,%d5                  | d5: y
        move.l  sg_pr,%d0               | the key: a black one's middle cleared, a white one's foot filled
        bsr     sg_pkk                  | (its class from its note: the range any note, build 134)
1:      lea     sg_pkb,%a0
        tst.b   (0,%a0,%d0.l)
        beq.s   2f
        moveq   #1,%d0
        add.l   %d4,%d0
        moveq   #58,%d1
        moveq   #3,%d2
        add.l   %d4,%d2
        moveq   #60,%d3
        bsr     sg_clr
        bra.s   3f
2:      move.l  %d4,%d0
        moveq   #62,%d1
        moveq   #3,%d2
        add.l   %d4,%d2
        moveq   #63,%d3
        bsr     sg_pf
3:      moveq   #-4,%d0
        bra     .Lpcur

| The pitch view's title row: "PITCH T1 C4 S05" at the left, the pattern ("A01") and the four pages as
| boxes at the right -- the shown filled (layout 1: the pair). Uses d0-d3 a0 a1.
sg_ptitle:
        move.l  sg_step,%d0             | the cursor's step
        addq.l  #1,%d0
        move.l  %d0,-(%sp)
        move.l  sg_pb,%d0               | the cursor's note: "C4"
        add.l   sg_pr,%d0
        lea     sg_b2,%a1
        bsr     sg_name
        pea     sg_b2+4
        pea     sg_b2
        move.l  sg_row,%d0
        addq.l  #1,%d0
        move.l  %d0,-(%sp)
        pea     sg_fpv
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     24(%sp),%sp
        tst.l   sg_umt                  | a message up: it instead
        ble.s   1f
        lea     SG_SMALL,%a0
        moveq   #1,%d0
        moveq   #58,%d1
        moveq   #1,%d2
        lea     sg_umsg,%a1
        bsr     sg_tx
        bra.s   2f
1:      lea     SG_SMALL,%a0
        moveq   #1,%d0
        moveq   #58,%d1
        moveq   #0,%d2
        lea     sg_b1,%a1
        bsr     sg_tx
2:      moveq   #0,%d0                  | the pattern, right-aligned at x 100
        move.b  0x100b14d0,%d0
        moveq   #15,%d1
        and.l   %d1,%d0
        addq.l  #1,%d0
        move.l  %d0,-(%sp)
        moveq   #0,%d0
        move.b  0x80000002,%d0
        addi.l  #65,%d0
        move.l  %d0,-(%sp)
        pea     sg_fpr
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     16(%sp),%sp
        lea     SG_SMALL,%a0
        lea     sg_b1,%a1
        bsr     sg_wid
        moveq   #100,%d3
        sub.l   %d0,%d3
        move.l  %d3,%d0
        moveq   #58,%d1
        moveq   #0,%d2
        lea     SG_SMALL,%a0
        lea     sg_b1,%a1
        bsr     sg_tx
        move.l  %d4,-(%sp)
        moveq   #0,%d4                  | the four page boxes, x 104 + 6 p, rows 1-4
3:      move.l  %d4,%d0
        add.l   %d0,%d0
        move.l  %d0,%d1
        add.l   %d0,%d0
        add.l   %d1,%d0
        addi.l  #104,%d0
        moveq   #1,%d1
        moveq   #4,%d2
        add.l   %d0,%d2
        moveq   #4,%d3
        move.l  %d0,-(%sp)
        bsr     sg_pf
        move.l  (%sp)+,%d0
        move.l  sg_step,%d1             | the page shown (layout 1: the pair) stays filled
        lsr.l   #4,%d1
        move.l  %d4,%d2
        moveq   #1,%d3
        cmp.l   sg_plo,%d3
        bne.s   4f
        lsr.l   #1,%d1
        lsr.l   #1,%d2
4:      cmp.l   %d1,%d2
        bne.s   6f
        moveq   #1,%d3                  | ROLL 32's pair: the page playing (stopped: the cursor's) blinks
        cmp.l   sg_plo,%d3              | with the flashes' phase (build 131)
        bne.s   5f
        move.l  sg_pply,%d1
        bpl.s   7f
        move.l  sg_step,%d1
7:      lsr.l   #4,%d1
        cmp.l   %d1,%d4
        bne.s   5f
        moveq   #32,%d1
        and.l   sg_mbk,%d1
        bne.s   5f
6:      addq.l  #1,%d0                  | the others hollow
        moveq   #2,%d1
        moveq   #2,%d2
        add.l   %d0,%d2
        moveq   #3,%d3
        bsr     sg_clr
5:      addq.l  #1,%d4
        moveq   #4,%d0
        cmp.l   %d0,%d4
        blt.s   3b
        move.l  (%sp)+,%d4
        moveq   #0,%d0                  | a line under it, row 6
        moveq   #6,%d1
        move.l  #127,%d2
        moveq   #6,%d3
        bra     sg_pf

| FUNC + ARP (code, state): nothing in MIXER + MIDI's view (build 141: the combo picks the views); else
| the stock's (ARP SETUP). Uses d0 d1 a0.
sg_kfarp:
        bsr     sg_keyfn
        bne.s   8f
        rts
8:      jmp     0x400322f0

| The full view's title row, rows 1-7. Uses d0 d1 a0 a1.
sg_fhdr:
        tst.l   sg_view                 | (the 8-track window's own, build 100)
        beq     sg_fhdt
        lea     -12(%sp),%sp
        movem.l %d2-%d4,(%sp)
        tst.l   sg_umt                  | a message (undo, copy, CLEAR?, ZOOM) up: it at the left
        ble.s   1f
        lea     SG_SMALL,%a0
        moveq   #2,%d0
        moveq   #57,%d1
        moveq   #1,%d2
        lea     sg_umsg,%a1
        bsr     sg_tx
        bra.s   2f
1:      bsr     sg_nget                 | else TRKS: / PAGES: and the name
        lea     sg_ftk,%a1
        tst.l   sg_view
        beq.s   3f
        lea     sg_fpg,%a1
3:      lea     SG_SMALL,%a0
        moveq   #1,%d0
        moveq   #57,%d1
        moveq   #0,%d2
        bsr     sg_tx
        move.l  %d0,%d3
        addq.l  #5,%d3
        lea     SG_SMALL,%a0
        move.l  %d3,%d0
        moveq   #57,%d1
        moveq   #0,%d2
        lea     sg_nm,%a1
        bsr     sg_tx
2:      move.l  sg_zn,-(%sp)            | at the right (build 96): the steps in view, the pattern playing,
        move.l  sg_step,%d0             | the cursor's step, the zoom -- "33-64 A01 S05 32/R" (the
        addq.l  #1,%d0                  | timeline without the steps; the step after the pattern since
        move.l  %d0,-(%sp)              | build 108)
        moveq   #0,%d0
        move.b  0x100b14d0,%d0
        moveq   #15,%d1
        and.l   %d1,%d0
        addq.l  #1,%d0
        move.l  %d0,-(%sp)
        moveq   #0,%d0
        move.b  0x80000002,%d0
        addi.l  #65,%d0
        move.l  %d0,-(%sp)
        bsr     sg_tlon
        beq.s   4f
        pea     sg_fhd2
        bra.s   5f
4:      moveq   #1,%d0                  | the 4-page window: all 64
        moveq   #64,%d1
        tst.l   sg_view
        bne.s   6f
        moveq   #63,%d0                 | the 8-track window: its window
        and.l   sg_fwin,%d0
        addq.l  #1,%d0
        move.l  %d0,%d1
        add.l   sg_zn,%d1
        subq.l  #1,%d1
6:      move.l  %d1,-(%sp)
        move.l  %d0,-(%sp)
        pea     sg_fhd1
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     32(%sp),%sp
        bra.s   7f
5:      pea     sg_b1
        jsr     SG_SPRINTF
        lea     24(%sp),%sp
7:      lea     SG_SMALL,%a0
        lea     sg_b1,%a1
        bsr     sg_wid
        move.l  #127,%d4
        sub.l   %d0,%d4                 | d4: its x
        move.l  %d4,%d0
        subq.l  #1,%d0
        moveq   #1,%d1
        moveq   #127,%d2
        moveq   #7,%d3
        bsr     sg_clr
        lea     SG_SMALL,%a0
        move.l  %d4,%d0
        moveq   #57,%d1
        moveq   #0,%d2
        lea     sg_b1,%a1
        bsr     sg_tx
        movem.l (%sp),%d2-%d4
        lea     12(%sp),%sp
        rts

| The full 8-track window's title row (build 100): at the left the arrangement row playing ("R01",
| arranging), TRKS: and the name, the pattern, and when one is to come two play triangles, that pattern
| and its countdown (the bars left, "--" stopped; both flash as the panel's line 2 does) -- "R01 TRKS: T1
| A01 3 ... >>A02", the pattern to come in the top right corner; in the right column the cursor's step
| ("S01", first row), the window in view of the pattern's ("1/2", second) and the zoom ("32/R", foot). A message (undo, CLEAR?, ZOOM) takes the left as ever. Uses d0 d1 a0 a1.
sg_fhdt:
        lea     -16(%sp),%sp
        movem.l %d2-%d5,(%sp)
        moveq   #1,%d4                  | d4: x
        tst.l   sg_umt
        ble.s   1f
        lea     SG_SMALL,%a0
        moveq   #2,%d0
        moveq   #57,%d1
        moveq   #1,%d2
        lea     sg_umsg,%a1
        bsr     sg_tx
        bra     .Lsg_fhr
1:      lea     sg_ftk,%a1              | "TRKS:" and the name (the row in the right column, build 101)
        bsr     sg_fht
        bsr     sg_nget
        lea     sg_nm,%a0               | (its trailing spaces left out)
        lea     sg_b2,%a1
        moveq   #-1,%d1
        moveq   #0,%d0
5:      move.b  (%a0,%d0.l),%d2
        beq.s   6f
        move.b  %d2,(%a1,%d0.l)
        cmpi.b  #32,%d2
        beq.s   7f
        move.l  %d0,%d1
7:      addq.l  #1,%d0
        moveq   #15,%d2
        cmp.l   %d2,%d0
        blt.s   5b
6:      clr.b   1(%a1,%d1.l)
        bsr     sg_fht
        moveq   #0,%d0                  | the pattern
        move.b  0x100b14d0,%d0
        moveq   #15,%d1
        and.l   %d1,%d0
        addq.l  #1,%d0
        move.l  %d0,-(%sp)
        moveq   #0,%d0
        move.b  0x80000002,%d0
        addi.l  #65,%d0
        move.l  %d0,-(%sp)
        pea     sg_fpt
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     16(%sp),%sp
        lea     sg_b1,%a1
        bsr     sg_fht
        bsr     sg_queue                | the one to come
        tst.l   %d0
        bmi     .Lsg_fhr
        move.l  %d0,%d5                 | d5: it, d3: the steps until it
        move.l  %d1,%d3
        moveq   #32,%d0                 | (flashing: left out in the blink's off phase)
        and.l   sg_bk,%d0
        bne     .Lsg_fhr
        moveq   #15,%d0                 | that pattern in the top right corner (build 100), two
        and.l   %d5,%d0                 | triangles before it
        addq.l  #1,%d0
        move.l  %d0,-(%sp)
        move.l  %d5,%d0
        lsr.l   #4,%d0
        moveq   #15,%d1
        and.l   %d1,%d0
        addi.l  #65,%d0
        move.l  %d0,-(%sp)
        pea     sg_fpt
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     16(%sp),%sp
        move.l  %d3,-(%sp)
        moveq   #57,%d5
        bsr     sg_fhrt
        move.l  (%sp)+,%d3
        move.l  %d4,%d0
        subi.l  #10,%d0
        bsr     sg_tri
        move.l  %d4,%d0
        subq.l  #6,%d0
        bsr     sg_tri
        tst.l   %d3                     | the bars left, rounded up, in a 4-place count before the
        bpl.s   3f                      | triangles: "4321>>A02", the count's place moving right as it
        pea     sg_f3d                  | falls, 1 against them (build 101); more than 4 at the 4's
        pea     sg_b1                   | place, "--" stopped
        jsr     SG_SPRINTF
        addq.l  #8,%sp
        moveq   #1,%d3
        bra.s   4f
3:      moveq   #15,%d0
        add.l   %d0,%d3
        asr.l   #4,%d3
        move.l  %d3,-(%sp)
        pea     sg_fsd
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     12(%sp),%sp
        moveq   #4,%d0
        cmp.l   %d0,%d3
        ble.s   4f
        move.l  %d0,%d3
4:      tst.l   %d3                     | d3: its place, 1-4: its right edge at x - 12 - 4 (place - 1)
        bgt.s   5f
        moveq   #1,%d3
5:      subq.l  #1,%d3
        lsl.l   #2,%d3
        subi.l  #11,%d4
        sub.l   %d3,%d4                 | d4: past its right edge
        lea     SG_SMALL,%a0
        lea     sg_b1,%a1
        bsr     sg_wid
        sub.l   %d0,%d4
        lea     SG_SMALL,%a0
        move.l  %d4,%d0
        moveq   #57,%d1
        moveq   #0,%d2
        lea     sg_b1,%a1
        bsr     sg_tx
.Lsg_fhr:
        bsr     sg_arr                  | the right column (build 100): the arrangement row playing, "R01",
        tst.l   %d1                     | at the first track's row (build 101; the title's left in 100),
        bmi.s   1f                      | arranging
        move.l  %d1,-(%sp)
        pea     sg_fr1
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     12(%sp),%sp
        moveq   #50,%d5
        bsr     sg_fhrt
1:      move.l  sg_step,%d0             | the cursor's step, "S01", at the second (the first in 100)
        addq.l  #1,%d0
        move.l  %d0,-(%sp)
        pea     sg_fh4
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     12(%sp),%sp
        moveq   #43,%d5
        bsr     sg_fhrt
        move.l  sg_zn,%d2               | the window in view of the pattern's, "1/2", at the second's
        moveq   #63,%d0
        and.l   sg_fwin,%d0
        divu.l  %d2,%d0                 | (the window: its first step / the steps a row)
        addq.l  #1,%d0
        movea.l %a2,%a0
        adda.l  #0x8e53,%a0
        moveq   #0,%d1
        move.b  (%a0),%d1               | the pattern's length (64 when 0)
        bne.s   5f
        moveq   #64,%d1
5:      add.l   %d2,%d1
        subq.l  #1,%d1
        divu.l  %d2,%d1
        cmp.l   %d0,%d1
        bge.s   6f
        move.l  %d0,%d1
6:      move.l  %d1,-(%sp)
        move.l  %d0,-(%sp)
        pea     sg_fh5
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     16(%sp),%sp
        moveq   #36,%d5                 | (at the third, build 101)
        bsr     sg_fhrt
        move.l  sg_zn,-(%sp)            | the zoom, in the right column's foot
        pea     sg_fzz
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     12(%sp),%sp
        moveq   #1,%d5
        bsr     sg_fhrt
        movem.l (%sp),%d2-%d5
        lea     16(%sp),%sp
        rts
sg_fht:                                 | a1 at x d4 on the title row; d4 on past it and 4 px
        lea     SG_SMALL,%a0
        move.l  %d4,%d0
        moveq   #57,%d1
        moveq   #0,%d2
        bsr     sg_tx
        add.l   %d0,%d4
        addq.l  #4,%d4
        rts
sg_fhrt:                                | sg_b1 right-aligned to x 127 at y d5 (from the bottom), its
        lea     SG_SMALL,%a0            | box cleared first
        lea     sg_b1,%a1
        bsr     sg_wid
        move.l  #127,%d4
        sub.l   %d0,%d4
        move.l  %d4,%d0
        subq.l  #1,%d0
        moveq   #57,%d1                 | (rows 63 - y - 6 .. 63 - y)
        sub.l   %d5,%d1
        move.l  %d1,%d3
        addq.l  #6,%d3
        moveq   #127,%d2
        bsr     sg_clr
        lea     SG_SMALL,%a0
        move.l  %d4,%d0
        move.l  %d5,%d1
        moveq   #0,%d2
        lea     sg_b1,%a1
        bsr     sg_tx
        rts
| A play triangle, 3 x 5 px, rows 2-6 of the title row, from x d0 (build 100). Uses d0 d1 a0 a1.
sg_tri:
        lea     -12(%sp),%sp
        movem.l %d2-%d4,(%sp)
        move.l  %d0,%d4
        moveq   #2,%d1
        move.l  %d4,%d2
        moveq   #6,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
        addq.l  #1,%d4
        move.l  %d4,%d0
        moveq   #3,%d1
        move.l  %d4,%d2
        moveq   #5,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
        addq.l  #1,%d4
        move.l  %d4,%d0
        moveq   #4,%d1
        move.l  %d4,%d2
        moveq   #4,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
        movem.l (%sp),%d2-%d4
        lea     12(%sp),%sp
        rts

| The time since play started, "mm:ss" (build 82; sg_clock), at the panel's top left (build 88; line 3
| before). Uses d0 d1 a0 a1.
sg_ckdraw:
        lea     -8(%sp),%sp
        movem.l %d2-%d3,(%sp)
        move.l  sg_cks,%d0
        moveq   #60,%d1
        move.l  %d0,%d2
        divu.l  %d1,%d2                 | minutes
        move.l  %d2,%d3
        muls.l  %d1,%d3
        sub.l   %d3,%d0                 | seconds
        move.l  %d0,-(%sp)
        move.l  %d2,-(%sp)
        pea     sg_fck
        pea     sg_b1
        jsr     SG_SPRINTF
        lea     16(%sp),%sp
        lea     SG_SMALL,%a0
        moveq   #SG_PX+1,%d0
        moveq   #57,%d1
        moveq   #0,%d2
        lea     sg_b1,%a1
        bsr     sg_tx
        movem.l (%sp),%d2-%d3
        addq.l  #8,%sp
        rts

| Infinity, 7 x 3 px (two loops sharing the middle column), from x d0, rows 17-19: panel line 2.
sg_inf:
        lea     -16(%sp),%sp
        movem.l %d2-%d4/%a2,(%sp)
        move.l  %d0,%d4
        lea     sg_infp,%a2
1:      moveq   #0,%d0
        move.b  (%a2)+,%d0
        beq.s   9f
        subq.l  #1,%d0                  | stored + 1, 0 ends the list
        add.l   %d4,%d0
        moveq   #0,%d1
        move.b  (%a2)+,%d1
        move.l  %d0,%d2
        move.l  %d1,%d3
        lea     SG_FILL,%a0
        bsr     sg_r1
        bra.s   1b
9:      movem.l (%sp),%d2-%d4/%a2
        lea     16(%sp),%sp
        rts

| sg_b1 against the divider (x 42 - its width, as LEN's fraction), bottom y d1: d0 = its x. sg_rlin2:
| inverted when d2 = 1.
sg_rline:
        move.l  %d2,-(%sp)
        moveq   #0,%d2
        bsr.s   sg_rlin2
        move.l  (%sp)+,%d2
        rts
sg_rlin2:
        lea     -8(%sp),%sp
        movem.l %d1-%d2,(%sp)
        lea     SG_SMALL,%a0
        lea     sg_b1,%a1
        bsr     sg_wid
        moveq   #57,%d1
        sub.l   %d0,%d1
        move.l  %d1,%d0
        move.l  %d0,-(%sp)
        move.l  4(%sp),%d1
        move.l  8(%sp),%d2
        lea     SG_SMALL,%a0
        lea     sg_b1,%a1
        bsr     sg_tx
        move.l  (%sp)+,%d0
        movem.l (%sp),%d1-%d2
        addq.l  #8,%sp
        rts

| A panel line of sg_b1 at x 10 in the small font, bottom y d1.
sg_line:
        lea     SG_SMALL,%a0
        moveq   #SG_PX,%d0
        moveq   #0,%d2
        lea     sg_b1,%a1
        bra     sg_tx

| d0 = the width of note token d4 (sg_nb + 8 d4: the name at +0, the octave at +4), the wider of the two.
sg_nw:
        lea     -8(%sp),%sp
        movem.l %d2/%a2,(%sp)
        lea     sg_nb,%a2
        move.l  %d4,%d0
        lsl.l   #3,%d0
        adda.l  %d0,%a2
        lea     SG_SMALL,%a0
        movea.l %a2,%a1
        bsr     sg_wid
        move.l  %d0,%d2
        lea     SG_SMALL,%a0
        lea     4(%a2),%a1
        bsr     sg_wid
        cmp.l   %d2,%d0
        bge.s   1f
        move.l  %d2,%d0
1:      movem.l (%sp),%d2/%a2
        addq.l  #8,%sp
        rts

| d0 = a LEN value 0-127: d0 = the index in sg_lv of the subdivision nearest it (the lower on a tie).
sg_lnear:
        lea     -12(%sp),%sp
        movem.l %d2-%d4,(%sp)
        moveq   #0,%d2                  | the index
        moveq   #0,%d3                  | the nearest so far
        move.l  #255,%d4                | its distance
        lea     sg_lv,%a0
1:      mvz.b   (0,%a0,%d2.l),%d1
        sub.l   %d0,%d1
        bpl.s   2f
        neg.l   %d1
2:      cmp.l   %d4,%d1
        bge.s   3f
        move.l  %d1,%d4
        move.l  %d2,%d3
3:      addq.l  #1,%d2
        moveq   #SG_LN,%d1
        cmp.l   %d1,%d2
        blt.s   1b
        move.l  %d3,%d0
        movem.l (%sp),%d2-%d4
        lea     12(%sp),%sp
        rts

| d0 = a LEN value, d1 = a delta: d0 = the subdivision |d1| steps that way, each the next value of
| sg_lv strictly past the last (build 79). Uses d0 d1 a0.
sg_lstep:
        lea     -12(%sp),%sp
        movem.l %d2-%d4,(%sp)
        move.l  %d1,%d4                 | d4: steps left (signed)
1:      tst.l   %d4
        beq.s   9f
        lea     sg_lv,%a0
        bmi.s   5f
        moveq   #0,%d2                  | up: the first entry above
2:      mvz.b   (0,%a0,%d2.l),%d1
        cmp.l   %d0,%d1
        bgt.s   3f
        addq.l  #1,%d2
        moveq   #SG_LN,%d3
        cmp.l   %d3,%d2
        blt.s   2b
        bra.s   9f                      | none above: stays
3:      move.l  %d1,%d0
        subq.l  #1,%d4
        bra.s   1b
5:      moveq   #SG_LN-1,%d2            | down: the last entry below
6:      mvz.b   (0,%a0,%d2.l),%d1
        cmp.l   %d0,%d1
        blt.s   7f
        subq.l  #1,%d2
        bpl.s   6b
        moveq   #0,%d0                  | none below: 0
        bra.s   9f
7:      move.l  %d1,%d0
        addq.l  #1,%d4
        bra.s   1b
9:      movem.l (%sp),%d2-%d4
        lea     12(%sp),%sp
        rts

| Invert d0 x0, d1 top row, d2 x1, d3 bottom row.
sg_inv:
        movea.l %d0,%a1
        pea     -1.w
        lea     SG_FILL,%a0
        bra     sg_rx

sg_fs:  .asciz  "%s"
sg_flm: .asciz  "-%s"
sg_flp: .asciz  "%s+"
sg_infp: .byte  2, 17, 3, 17, 5, 17, 6, 17, 1, 18, 4, 18, 7, 18, 2, 19, 3, 19, 5, 19, 6, 19, 0 | x + 1, row
sg_f3c: .asciz  "%02d"
sg_f3d: .asciz  "--"
sg_f4:  .asciz  "STEP %02d"
sg_pk:  .byte   0, 3, 4, 5, 1, 2        | the panel's values SG_PN.. -> slots: NOTE NOT2 NOT3 NOT4 VEL LEN
sg_ls:  .byte   0, SG_PR, SG_PM, SG_PB, SG_PV, SG_PS, SG_PN, SG_PN+4, SG_PN+5 | the panel's lines: first value
sg_ll:  .byte   SG_NN, 1, 2, 1, 1, 1, 4, 1, 1 | and how many
| LEN's values in the panel: the stock's note fractions (its labels at 0x400a7f44 for 3 6 9 .. 120: the
| value is in 1/96 notes) and INF; the LEVEL knob steps through these, a value between them shows the
| nearest's label. 126 (21/16) left out in build 55: "L126 21/16" is wider than the panel. Labels
| 6 bytes each.
        .set    SG_LN, 21
sg_lv:  .byte   3, 6, 9, 12, 15, 18, 21, 24, 27, 30, 36, 42, 48, 54, 60, 72, 84, 96, 108, 120, 127
sg_lt:  .asciz  "1/32\0"
        .asciz  "1/16\0"
        .asciz  "3/32\0"
        .asciz  "1/8\0\0"
        .asciz  "5/32\0"
        .asciz  "3/16\0"
        .asciz  "7/32\0"
        .asciz  "1/4\0\0"
        .asciz  "9/32\0"
        .asciz  "5/16\0"
        .asciz  "3/8\0\0"
        .asciz  "7/16\0"
        .asciz  "1/2\0\0"
        .asciz  "9/16\0"
        .asciz  "5/8\0\0"
        .asciz  "3/4\0\0"
        .asciz  "7/8\0\0"
        .asciz  "1/1\0\0"
        .asciz  "9/8\0\0"
        .asciz  "5/4\0\0"
        .asciz  "INF\0\0"

| Run-time state (written in place).
        .balign 4
sg_mode: .long  0                       | 1 = the panel has the keys
sg_on:  .long   0                       | 1 = the ARP page was the last page drawn
sg_hk:  .long   0                       | the arrow held (its code), 0 = none
sg_ht:  .long   0                       | ticks to its next move
sg_tk:  .long   0                       | the track keys down at the last poll, T1 = bit 0
sg_rep: .long   0                       | sg_mv: 1 = the poll's repeat, 0 = a press
sg_thk: .long   -1                      | sg_thold: the trig key held (-1 none)
sg_kb:  .long   0                       | sg_fkb: 1 = the name's keyboard is up
sg_np:  .long   0                       | the next arrangement row's pattern (0 none)
sg_npn: .long   0                       | its byte: bank << 4 | pattern
sg_nlay: .long  0                       | 1: the 4-page window's arrangement layout
sg_frw: .asciz  "ROW %02d"
sg_fsv: .asciz  "SAVE"
sg_fck: .asciz  "%02d:%02d"
sg_fcm: .asciz  "%s %d"
sg_fri: .asciz  "R%02d %c%02d X%d OF%d LN%d"
sg_fr1: .asciz  "R%02d"
sg_fr2: .asciz  "X%d"
sg_fr3: .asciz  "%02d:"                 | the offset and length, "00:16" (OF0 LN16 until build 113)
sg_fr4: .asciz  "%02d"
sg_fhd1: .asciz "%d-%d %c%02d S%02d %d/R"
sg_fhd2: .asciz "%c%02d S%02d %d/R"
sg_fhd3: .asciz "%d-%d S%02d"             | (the 8-track window's, build 100)
sg_fh4: .asciz  "S%02d"                 | (its right column, build 100)
sg_fh5: .asciz  "%d/%d"
sg_fzz: .asciz  "%d/R"                  | (build 90; a Z read as a 2)
sg_fds: .asciz  "%d %s"
sg_fdn: .asciz  "%d"
sg_fvl: .asciz  "VEL"
sg_fln: .asciz  "LEN"
        .balign 4
sg_fnl: .ascii  "NOTE\0\0\0\0"            | 8 bytes each (build 90)
        .ascii  "NOT2\0\0\0\0"
        .ascii  "NOT3\0\0\0\0"
        .ascii  "NOT4\0\0\0\0"
sg_fzm: .asciz  "ZOOM"
sg_fnq: .asciz  "CLEAR? YES"
sg_fcp: .asciz  "COPY"
sg_fcc: .asciz  "CLEAR"
sg_fcs2: .asciz "PASTE"
sg_fce: .asciz  "CLIP"
sg_fob: .asciz  "OTHER BANK"
sg_fwc: .asciz  "COPY"
sg_fwl: .asciz  "CLEAR"
sg_fwt: .asciz  "TRIG"
sg_fwr: .asciz  "ROW"
sg_fwp: .asciz  "PAGES"
sg_fw3: .asciz  "303"                   | (build 107)
sg_fw3t: .asciz "T%d %s"
sg_fw3y: .asciz "OK"
sg_fw3n: .asciz "NO"
sg_fno3: .asciz "NOT OCTA-303"
sg_fpat: .asciz "PASTE TRACK"
sg_fcp3: .asciz "303 NOTES"
sg_fsq: .asciz  "SPACE"
sg_fst: .asciz  "SCALE"
sg_fspt: .asciz "SCALE SETUP"             | (build 86; "PER TRK" in 83-85)
sg_fsnm: .asciz "NORMAL"
sg_fsal: .asciz "ALL"
sg_fsms: .asciz "M"                     | MASTER (build 85: "MST" on the title row before)
sg_fsd: .asciz  "%d"
sg_fsin: .asciz "INF"
sg_fs0: .asciz  "2X"
sg_fs1: .asciz  "3/2X"
sg_fs2: .asciz  "1X"
sg_fs3: .asciz  "3/4X"
sg_fs4: .asciz  "1/2X"
sg_fs5: .asciz  "1/4X"
sg_fs6: .asciz  "1/8X"
        .balign 4
sg_sltab: .long sg_fs0, sg_fs1, sg_fs2, sg_fs3, sg_fs4, sg_fs5, sg_fs6
sg_zm:  .long   2                       | the zoom: 4 << sg_zm steps a row (build 84)
sg_zs:  .long   0                       | the 4-page window's first row shown
sg_zlst: .long  -1                      | the cursor's step at the last follow (sg_zfol)
sg_tsc: .long   0                       | the timeline: pages on past its first (knob E)
sg_zn:  .long   16                      | sg_zset's figures
sg_zp:  .long   4
sg_zbw: .long   2
sg_zr:  .long   4
sg_zrt: .long   4
sg_tne: .long   8
sg_tm:  .long   1
sg_tpk: .long   1
sg_tcn: .long   16
sg_tseg: .long  0                       | the timeline's drawing: the segment, its first screen column,
sg_tsc0: .long  0                       | past its last, the page's column less the screen's
sg_tce: .long   0
sg_tdc: .long   0
sg_spat: .long  0                       | the scale window's pattern 0-15 (build 85)
sg_tnc: .long   0                       | the timeline's names noted (build 89)
sg_tnl: .space  64                      | 8 x {the row's top, bank << 4 | pattern}
sg_srow: .long  1                       | the scale window's row: 0 MASTER, 1-8 the tracks
sg_scol: .long  0                       | its column: 0 LEN, 1 SCALE
sg_snum: .long  0                       | 1: the row's number picked, LEFT of its LEN (build 106)
        .balign 4
sg_sela: .long  -1                      | the run marked: its anchor step, -1 none (FUNC + LEVEL)
sg_win: .long   0                       | our window: 0 none, 1 COPY, 2 CLEAR
sg_wl:  .long   2                       | its line: 0 TRIG, 1 ROW, 2 PAGES
sg_wpc: .long   0                       | the page picked on PAGES
sg_wpm: .long   15                      | the pages on, page 1 = bit 0
sg_w3t: .long   0                       | COPY's 303 line: the audio track 0-7 (build 107)
sg_own: .long   0                       | 1: MIXER + MIDI's view (build 108)
sg_pv:  .long   0                       | 1: the pitch view (build 109)
sg_aud: .long   0                       | 1: AUDIO, the audio tracks (build 110)
sg_cs3: .long   0                       | the stock's last track copy: 1 an OCTA-303 track (build 113)
sg_abk: .long   0                       | 1: FUNC + BANK opened the ARRANGER menu (build 120)
sg_scret: .long 0                       | 1: ALL TRACK SCALES opened from a stock page (build 116)
sg_ctu: .long   64                      | and its Part's TUNE
sg_mxa: .long   0                       | 1: MIDI alone pressed in the view, its release not yet
sg_ltm: .ascii  "MIDI:\0"                 | (TRKS: until build 146; Zach: the title says MIDI)
sg_lta: .ascii  "AUD:\0\0"
sg_lpm: .ascii  "PAGES:\0"
sg_lpa: .ascii  "APGS:\0\0"
        .balign 4
sg_pb:  .long   45                      | the pitch view's range: its A (A2 = 45), 24 semitones
sg_pr:  .long   3                       | the cursor's note over it, 0-23
sg_plo: .long   0                       | the layout: 0 16 steps x 9 notes, 1 32 x 24, 2 horizontal (123)
sg_pwr: .long   0                       | layout 0's window: its bottom row over the A, 0-15
sg_pply: .long  -1                      | the step playing as drawn
sg_ownw: .long  0                       | ticks left for the page to come (build 108)
sg_mxu: .long   0                       | 1: MIXER held for MIXER + MIDI: its release opens nothing (111)
sg_mxk: .long   0                       | 1: the combo's MIDI press seen, its release not yet
sg_oam: .long   0                       | 1: audio mode before it
sg_omp: .long   2                       | the MIDI side's page before it (0-4)
sg_oap: .long   0                       | the audio side's page before it (0-4, build 149)
sg_ofull: .long 0                       | the full view before it
sg_pgk: .byte   0x22, 0x24, 0x23, 0x25, 0x26 | page 0-4 -> its key (build 108)
sg_fpv: .asciz  "PITCH T%d %s%s S%02d"
sg_fpr: .asciz  "%c%02d"
sg_fro: .asciz  "ROLL"
sg_ftr: .asciz  "TRIGS %s%s"
sg_fky: .asciz  "KEYS"
sg_fnn: .asciz  "%s%s"
sg_fpst: .asciz "S%02d"
sg_fpvv: .asciz "V%d"
sg_pkb: .byte   0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 1 | from A (n mod 12): the black keys A+ C+ D+ F+ G+
sg_pkc: .byte   0, 1, 0, 1, 0, 0, 1, 0, 1, 0, 1, 0 | from C (n mod 12): the sharps C+ D+ F+ G+ A+
        .balign 2
sg_pgt: .word   0x7b2f, 0, 0x6b6e, 0, 0x79e7, 0x79e4, 0, 0x396b, 0, 0x7bed, 0, 0x6bae | C .. B, 3 x 5
sg_pup: .byte   2, 2, 1, 3, 0, 4         | layout 0's arrows: lines (x0, x1 over x), top + 1 down
sg_pdn: .byte   0, 4, 1, 3, 2, 2
sg_pkm: .byte   0x33, 0x34, 0x20, 0x21, 0x34, 0x20, 0x21, 0x33, 0 | KEYS: code -> the code it acts as
        .balign 4
sg_tp:  .long   7                       | the timeline's screen-row pitch in use (build 107: 7, or sg_ftpi)
sg_ftpi: .long  7                       | the full timeline's pitch, knob D: 7-17
sg_fps: .long   0                       | the full 4-page window's row stride, knob D: 0 its own (14)
sg_fdy: .long   0                       | sg_fgap's dot row
sg_fd0: .long   0                       | sg_fgap's dots' rows (build 114)
sg_fd1: .long   0
sg_fl0: .long   0                       | and its lines'
sg_fl1: .long   0
sg_fdst: .long  14                      | the full 4-page grid's stride under the bar, knob D unset
sg_cn:  .long   0                       | the clip's steps, 0 empty
sg_ck:  .long   0                       | its kind: 0 a run, 1 a row, 2 pages
sg_cpm: .long   0                       | pages: which
sg_ccnt: .long  0                       | the steps a copy or clear took
sg_cblk: .space 36                      | a cleared step (sg_cclr)
sg_ftk: .asciz  "MIDI:"                 | (AUD: in AUDIO, sg_alab: 6 bytes; TRKS: until build 146)
sg_fpg: .asciz  "PAGES:"                | (APGS: in AUDIO: 7 bytes)
sg_ftp: .asciz  "%d/%d"
sg_fpt: .asciz  "%c%02d"
sg_fcd: .asciz  "%d %c%02d"
sg_fcs: .asciz  "-- %c%02d"
        .balign 4
sg_prow: .long  0                       | the arrangement row playing (sg_platch)
sg_pcnt: .long  0                       | the step count at the last look
sg_pnew: .long  1                       | 1: read the row afresh
sg_lhide: .long 1                       | 1: the note-length lines hidden (sg_kyes; hidden at boot, build 73)
sg_ttop: .long  0, 0, 0                 | the timeline stopped: its first page (row, pass, page)
sg_tpl: .long   0, 0, 0                 | the page playing at the last look
sg_tplv: .long  0                       | 1: sg_tpl is
sg_tsv: .long   0                       | 1: sg_ttop is
sg_t698: .long  0                       | the arranger's row sg_ttop came from
sg_trow: .long  0                       | the cursor's row in the window, 0-7
sg_tcol: .long  0                       | and its column
sg_tsl: .long   0                       | the row being drawn (sg_tl + 16 r)
sg_tof: .long   0                       | its arrangement row's offset (build 100)
sg_fxc: .space  256                     | the readouts' fields' middle x, 8 an entry (build 100)
sg_trof: .long  0                       | sg_trrow's offset (build 100)
sg_tmod: .long  0                       | sg_tnote / sg_tlen: steps mod this (0: as they are)
sg_cpat: .long  0                       | the cursor's pattern, 0 = the current one
sg_tfree: .long 0                       | 1: a trig key's step has the cursor (not sg_tsync)
sg_tlast: .long 0                       | 1: the timeline was drawn last
sg_ptk: .long   -1000000                | sg_pkey: the ticks at the last press
sg_lps: .long   -1                      | sg_stopk: the cursor track's step playing at the last tick
sg_lcnt: .long  0                       | and the step count
sg_wasp: .long  0                       | 1: playing at the last tick
sg_stk: .long   0                       | STOP down at the last tick
sg_ckl: .long   0                       | sg_clock: DTCN3 at the last tick
sg_ckf: .long   0                       | its counts into the current second
sg_cks: .long   0                       | the seconds since play started
sg_ckp: .long   0                       | 1: playing at the last tick
sg_dots: .long  0                       | the two dots' pixels as the page drew them (sg_dsave)
sg_tl:  .space  512                     | the timeline's pages (sg_tfill): 8, zoomed 2-32 (build 84)
        .balign 4
sg_ukey: .long  -1                      | undo: the pattern the history is for (-1: start again)
sg_us1: .long   0                       | its sums at the last look
sg_us2: .long   0
sg_uq:  .long   0                       | 0: no edit open, else ticks since it changed
sg_udv: .long   0                       | ticks to the next sum
sg_uold: .long  0                       | the oldest state's slot in the ring
sg_ucnt: .long  0                       | states held, 1..SG_UN
sg_upos: .long  0                       | the current state, 0 = the oldest
sg_umt: .long   0                       | ticks the message stays up
sg_umsg: .space 16
sg_fun: .asciz  "UNDO %d/%d"
sg_fre: .asciz  "REDO %d/%d"
sg_fnu: .asciz  "NO UNDO"
sg_fnr: .asciz  "NO REDO"
        .balign 4
sg_kbf: .long   0                       | FUNC down at the last poll
sg_ksel: .long  0                       | the keyboard's character - 32
sg_ksel0: .long 0                       | and the one it opened on
sg_th:  .long   0                       | and its ticks (-1: the panel opened for this hold)
sg_mm:  .long   0                       | the MIDI tracks muted as the engine plays them, bit t (sg_run)
sg_fl3: .asciz  "L %d"
        .balign 4
sg_bk:  .long   0                       | poll ticks on the page: the cursor's blink (bit 4)
sg_mbk: .long   0                       | the mutes' flash: bit 5 (build 125)
sg_ptg: .long   -1                      | the pitch view's trig key held, -1 none (build 126)
sg_pty: .long   0                       | 1: YES came while it was held
sg_ptin: .long   0                      | 1: the trig keys' handlers ours (build 128)
sg_ptsv: .space  64                     | the stock's 16 handlers
sg_pkn: .space   16                     | each key's note sounding + 1, 0 none
sg_pal: .byte   2, 3, 0, 1, 2, 3           | KEYS 16's other-octave chevrons (build 134): < and >, rows (x0, x1)
sg_par: .byte   0, 1, 2, 3, 0, 1
        .even
sg_btab: .long  brain_v_octabam_step_view_1, brain_v_octabam_step_view_2, brain_v_octabam_step_view_3
        .long   brain_v_octabam_step_view_4, brain_v_octabam_step_view_5, brain_v_octabam_step_view_6
        .long   brain_v_octabam_step_view_7, brain_v_octabam_step_view_8, brain_v_octabam_step_view_9
        .long   brain_v_octabam_step_view_10
sg_bvar: .long  sg_full, sg_view, sg_pv, sg_plo, sg_pb, sg_pr, sg_pwr, sg_pkb0, sg_fzr, sg_zm
sg_bshd: .long  0x80000000, 0x80000000, 0x80000000, 0x80000000, 0x80000000 | (none seen: the first tick
        .long   0x80000000, 0x80000000, 0x80000000, 0x80000000, 0x80000000 | takes the table)
sg_pjsv: .long  0, 0, 0                  | encoder A's, C's (build 131) and F's (132) stock press handlers
sg_pko: .space   16                     | each key's note sent (TRAN in) + 1, 0 none (build 130)
sg_pkb0: .long  -1                      | the trig keys' first note, -1 unset (build 129)
sg_p1w: .long   3                       | layout 1: the note being drawn's width (build 129)
sg_idle: .long  0                       | poll ticks since the last touch (arrows, YES, NO, LEVEL, trig, track, PAGE)
sg_kp:  .long   0                       | the trig keys' page (0x460d1e04) as last read
sg_pw:  .long   0                       | the page the window and the keys last agreed on
sg_view: .long  0                       | 0 = the 8 MIDI tracks at one page, 1 = the cursor's track at its 4 pages
sg_vpg: .long   0                       | the page in view (sg_run), 0-3
sg_rh:  .long   4                       | a row: its height
sg_rs:  .long   8                       | and its stride
sg_row: .long   0                       | the cursor's MIDI track
sg_step: .long  0                       | the cursor's step, 0-63
sg_prm: .long   SG_PN                   | the panel's value (sg_pmove)
sg_sig: .long   -1
sg_psum: .long  -1
sg_b1:  .space  24
sg_b2:  .space  16
sg_nb:  .space  32                     | the four notes: name at +0, octave at +4, 8 bytes each
sg_b3:  .space  16
sg_lbl: .space  4                       | "L" (build 90)
sg_pvb: .space  8                       | the panel's VEL value, formatted (build 90; the step's window)
sg_plf: .space  12                      | its LEN fraction ("-5/8") and value
sg_plv: .long   0
sg_ytk: .long   -1000000                | the ticks at the YES that opened the panel (build 90)
sg_nrow: .long  -1                      | the next arrangement row (sg_nxt; -1 none)
sg_tqx: .long   -1                      | the timeline's name carrying the countdown (sg_tl2set)
sg_tqs: .long   -1                      | the steps to come (sg_queue's d1)
sg_full: .long  0                       | 1: the full view (build 92; sg_kfarp)
sg_fzr: .long   3                       | its zoom: 4 << this a row (3 or 4)
sg_fwv: .long   0                       | 1: sg_fsc / sg_fws hold (build 98)
sg_fsc: .long   0                       | the count play stopped at
sg_fws: .long   0                       | the cursor's step then
sg_tstop: .long 0                       | 1: just stopped (sg_tupd)
sg_tsfix: .long 0                       | 1: the cursor to the stopped page after the fill
sg_tps: .long   0, 0, 0                 | the page playing as play stopped (sg_stopk, build 100)
sg_tpsv: .long  0                       | 1: sg_tps valid
sg_tbeg: .long  0                       | 1: STOP again, the timeline to its start (build 100)
sg_fband: .long 0                       | the full timeline's readout rows, bit r (build 97)
sg_fwin: .long  0                       | the 8-track window's first step (build 96)
sg_fpc: .long   -1                      | the full view's play column, the row's track (build 94)
sg_tpo: .long   0                       | the page playing's place in the timeline's first screen row (93)
sg_half: .long  0                       | 1: drawing a track's second line (build 93)
sg_gx:  .long   SG_GX                   | the grid's first column (sg_zset)
sg_tnum: .long 0                        | 1: the cursor on the track number in TRKS (build 143)
sg_ctrk: .long 0                        | 1: the clip is a whole track's (sg_ktrk), its LEN and SCALE:
sg_ctl:  .long 0
sg_cts:  .long 0
sg_fkx:  .long 0                        | 1: sg_kenc called by encoder F's press (sg_fkp)
sg_fksv: .long 0                        | encoder F's stock press handler
sg_eksv: .long 0, 0, 0, 0, 0            | encoders A-E's stock press handlers (sg_ekin)
sg_ekt:  .long sg_ek0, sg_ek1, sg_ek2, sg_ek3, sg_ek4
sg_swp:  .long 0                        | 1: sg_lvl reached from knob A in ROLL 32 (build 148)
sg_vwch: .long 0                        | sg_vwin changed the panel view's window: draw (build 141)
sg_nconf: .long 0                       | NO asked to clear (build 91; sg_nask)
sg_ncs: .long   0                       | the step it asked for
sg_ncp: .long   0                       | and its pattern (sg_cpat)
sg_tl2: .long   0                       | line 2 in the timeline: 0 as ever, 1 the count from x 12, 2 empty
sg_nm:  .space  16                     | the name as shown

| ==== names.work: the step editor's track names, a STORE client (build 140) ===============================
| sg_names (bank * 384 + Part * 96 + track * 12) beside the bank files: a 16-byte header ('SGNM', version 1,
| 6144, the CRC-32 of the names), then the names. Written at the bank writer and before the project store
| when a name changed; names.strd is its copy at the project store, copied back at a project reload. No
| file: no names (T<n>). A file that is not version 1 or fails its CRC is left alone and never written over
| this session (no prompt: STEP VIEW has no STORE client id). Part Clear empties that Part's names. As SCALES'
| scales.work (modules/scales, sc_st_*). Handlers may clobber every register.
        .equ    SGN_B, 16*4*8*12
        .equ    SGN_MAGIC, 0x53474e4d   | 'SGNM'
        .globl  sgn_st_loadall_pre, sgn_st_loadmask_pre, sgn_st_newproj, sgn_st_bankw_post
        .globl  sgn_st_pstore_pre, sgn_st_pstore_post, sgn_st_preload_post, sgn_st_partclear

| sgn_clear: d1 = a bank mask -> those banks' names empty. Clobbers d0-d2, a0.
sgn_clear:
        moveq   #0,%d2
1:      btst    %d2,%d1
        beq.s   3f
        move.l  #384,%d0
        muls.l  %d2,%d0
        lea     sg_names,%a0
        adda.l  %d0,%a0
        moveq   #96,%d0
2:      clr.l   (%a0)+
        subq.l  #1,%d0
        bne.s   2b
3:      addq.l  #1,%d2
        moveq   #16,%d0
        cmp.l   %d0,%d2
        bne.s   1b
        rts

| sgn_copy: a0 = the source format, a1 = the destination's -> d0 < 0 when the copy failed.
sgn_copy:
        move.l  %a1,-(%sp)
        lea     sgn_psrc,%a1
        moveq   #0,%d0
        jsr     store_path
        movea.l (%sp)+,%a0
        lea     sgn_path,%a1
        moveq   #0,%d0
        jsr     store_path
        clr.l   -(%sp)
        pea     sgn_psrc
        pea     sgn_path
        jsr     0x40016388              | the stock file copy (dst, src, 0)
        lea     12(%sp),%sp
        rts

| sgn_write -> d0 = 0 when names.work holds sg_names.
sgn_write:
        move.l  %d2,-(%sp)
        lea     sg_names,%a0
        move.l  #SGN_B,%d0
        moveq   #0,%d1
        jsr     store_crc32
        move.l  %d0,sgn_hdr+12
        move.l  #SGN_MAGIC,%d0
        move.l  %d0,sgn_hdr
        moveq   #1,%d0
        move.l  %d0,sgn_hdr+4
        move.l  #SGN_B,%d0
        move.l  %d0,sgn_hdr+8
        lea     sgn_fwork,%a0
        lea     sgn_path,%a1
        moveq   #0,%d0
        jsr     store_path
        lea     sgn_path,%a0
        lea     sgn_mw,%a1
        lea     sgn_ctx,%a2
        jsr     store_fopen
        tst.l   %d0
        bmi.s   8f
        lea     sgn_hdr,%a0
        moveq   #16,%d0
        jsr     store_fwrite
        move.l  %d0,%d2
        lea     sg_names,%a0
        move.l  #SGN_B,%d0
        jsr     store_fwrite
        subq.l  #1,%d0
        bne.s   7f
        subq.l  #1,%d2
        bne.s   7f
        jsr     store_fclose
        moveq   #0,%d0
        bra.s   9f
7:      jsr     store_fclose
8:      moveq   #-1,%d0
9:      move.l  (%sp)+,%d2
        rts

sgn_wdue:
        tst.l   sgn_dirty
        beq.s   1f
        tst.l   sgn_nowr
        bne.s   1f
        bsr     sgn_write
        tst.l   %d0
        bne.s   1f
        clr.l   sgn_dirty
1:      rts

| sgn_read: d1 = a bank mask -> d0 = 0 the masked banks read, 1 no file, 2 not names.work version 1 or a bad
| CRC (sg_names untouched then).
sgn_read:
        lea     -8(%sp),%sp
        movem.l %d2-%d3,(%sp)
        move.l  %d1,%d3
        lea     sgn_fwork,%a0
        lea     sgn_path,%a1
        moveq   #0,%d0
        jsr     store_path
        lea     sgn_path,%a0
        lea     sgn_mr,%a1
        lea     sgn_ctx,%a2
        jsr     store_fopen
        tst.l   %d0
        bpl.s   1f
        moveq   #1,%d0
        bra     9f
1:      lea     sgn_hdr,%a0
        moveq   #16,%d0
        jsr     store_fread
        subq.l  #1,%d0
        bne     7f
        lea     sgn_hdr,%a0
        move.l  (%a0),%d0
        cmpi.l  #SGN_MAGIC,%d0
        bne     7f
        moveq   #1,%d0
        cmp.l   4(%a0),%d0
        bne     7f
        move.l  8(%a0),%d0
        cmpi.l  #SGN_B,%d0
        bne     7f
        lea     sgn_stage,%a0
        move.l  #SGN_B,%d0
        jsr     store_fread
        subq.l  #1,%d0
        bne     7f
        jsr     store_fclose
        lea     sgn_stage,%a0
        move.l  #SGN_B,%d0
        moveq   #0,%d1
        jsr     store_crc32
        cmp.l   sgn_hdr+12,%d0
        bne.s   6f
        moveq   #0,%d2                  | the bank
2:      btst    %d2,%d3
        beq.s   4f
        move.l  #384,%d0
        muls.l  %d2,%d0
        lea     sgn_stage,%a0
        adda.l  %d0,%a0
        lea     sg_names,%a1
        adda.l  %d0,%a1
        moveq   #96,%d1
3:      move.l  (%a0)+,(%a1)+
        subq.l  #1,%d1
        bne.s   3b
4:      addq.l  #1,%d2
        moveq   #16,%d0
        cmp.l   %d0,%d2
        bne.s   2b
        moveq   #0,%d0
        bra.s   9f
7:      jsr     store_fclose
6:      moveq   #2,%d0
9:      movem.l (%sp),%d2-%d3
        addq.l  #8,%sp
        rts

| sgn_load: d1 = a bank mask: those banks from names.work; empty when it has none, empty and never
| overwritten when it is unreadable.
sgn_load:
        move.l  %d1,%d4
        bsr     sgn_read
        tst.l   %d0
        beq.s   9f
        move.l  %d0,%d5
        move.l  %d4,%d1
        bsr     sgn_clear
        moveq   #2,%d0
        cmp.l   %d0,%d5
        bne.s   9f
        moveq   #1,%d0
        move.l  %d0,sgn_nowr
9:      rts

sgn_st_loadall_pre:
        clr.l   sgn_nowr
        clr.l   sgn_dirty
        move.l  #0xffff,%d1
        bra     sgn_load

sgn_st_loadmask_pre:                    | d1 = the mask
        bra     sgn_load

sgn_st_newproj:
        move.l  #0xffff,%d1
        bsr     sgn_clear
        clr.l   sgn_nowr
        clr.l   sgn_dirty
        rts

sgn_st_bankw_post:
sgn_st_pstore_pre:
        bra     sgn_wdue

sgn_st_pstore_post:
        tst.l   sgn_nowr
        bne.s   9f
        lea     sgn_fwork,%a0
        lea     sgn_fstrd,%a1
        bra     sgn_copy
9:      rts

| A project reload: names.strd back to names.work and read; a project stored without one has no names.
sgn_st_preload_post:
        lea     sgn_fstrd,%a0
        lea     sgn_fwork,%a1
        bsr     sgn_copy
        clr.l   sgn_nowr
        clr.l   sgn_dirty
        tst.l   %d0
        bmi.s   1f
        move.l  #0xffff,%d1
        bra     sgn_load
1:      move.l  #0xffff,%d1
        bsr     sgn_clear
        moveq   #1,%d0
        move.l  %d0,sgn_dirty
        rts

sgn_st_partclear:                       | d0 = the Part: its eight names empty
        andi.l  #3,%d0
        moveq   #0,%d1
        move.b  0x80000002,%d1
        andi.l  #15,%d1
        lsl.l   #2,%d1
        add.l   %d1,%d0
        moveq   #96,%d1
        muls.l  %d1,%d0
        lea     sg_names,%a0
        adda.l  %d0,%a0
        moveq   #24,%d0
1:      clr.l   (%a0)+
        subq.l  #1,%d0
        bne.s   1b
        moveq   #1,%d0
        move.l  %d0,sgn_dirty
        rts

sgn_dirty: .long 0                      | names.work is due
sgn_nowr: .long 0                       | names.work was unreadable: never overwritten
sgn_fwork: .asciz "%s/names.work"
sgn_fstrd: .asciz "%s/names.strd"
sgn_mr: .asciz  "r"
sgn_mw: .asciz  "w"
        .balign 2

        .section .bss
        .balign 4
sg_uh:  .space  SG_UN*SG_PSZ            | the undo states, 365,680 B
sg_clip: .space 64*36                   | the clip: 64 steps of SG_CSZ (build 82)
sg_mbuf: .space 0x9c4                   | a MIDI track's clipboard, an audio track converted (build 113)
sg_slm: .space  64                      | its steps slid into
        .balign 4
sg_names: .space SGN_B                  | the track names (build 140, names.work)
sgn_stage: .space SGN_B                 | names.work read here before it is applied
sgn_hdr: .space 16
sgn_ctx: .space 4120                    | STORE_CTX
sgn_path: .space 260
sgn_psrc: .space 260
