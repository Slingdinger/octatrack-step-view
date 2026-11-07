| STEP VIEW -- since OctaZach 140 only the step editor's clean-up of Parts saved before 140 (manifest.py says what).
|
| Builds up to 139 kept TRAN in NOTE SETUP's unused byte +3 (slot p9) and the step editor's track name in
| the ARP page's and ARP SETUP's bytes (setup + 13..19, page-1 + 13..17). With the stock ARP page back those
| bytes are the arpeggiator's again: a name character in LEG or MODE would switch legato or the arp on, so
| sv_mig, inside the Part validator, gives such a track the ARP page's and ARP SETUP's defaults back, and
| moves a TRAN found in NOTE SETUP +3 to the ARP page's TRAN (page-1 + 12), before the validator checks them.
        .text
        .global sv_mig
| ---- Detour 0x400029b4 (jsr, 8 bytes: `movel %a1@(130),%d1` ; `mvzb %a0@(1250),%d0`), the Part validator's
|      NOTE SETUP slot check, run for each MIDI track (d5) and NOTE SETUP slot (d4 = 4 slot); the Part is the
|      validator's argument, 100(sp) in its frame, 104(sp) here (measured under the port, 7 Nov 2026: d5 0..7,
|      d4 0..0x14, 0x40170f60). Its MIDI page-1 record is Part + 0x3e2 + 32 t, its setup record + 0x4e2 + 36 t
|      (NOTE SETUP + 0..5, ARP SETUP + 12..17). The ARP page's check comes after this one (0x400029e0).
sv_mig:
        tst.l   %d4
        bne     9f                      | once a track: slot 0
        lea     -20(%sp),%sp
        movem.l %d0-%d1/%a0-%a2,(%sp)
        movea.l 20+4+100(%sp),%a2       | the Part
        moveq   #36,%d0
        muls.l  %d5,%d0
        adda.l  %d0,%a2
        adda.l  #0x4e2,%a2              | a2: the setup record
        move.l  %d5,%d0
        lsl.l   #5,%d0
        movea.l 20+4+100(%sp),%a1
        adda.l  %d0,%a1
        adda.l  #0x3e2,%a1              | a1: the page-1 record
        moveq   #0,%d0
        move.b  3(%a2),%d0              | a TRAN in NOTE SETUP (builds up to 139): to the ARP page
        beq.s   1f
        move.b  %d0,12(%a1)
        clr.b   3(%a2)
1:      moveq   #0,%d0
        move.b  13(%a2),%d0             | a name character (32-95) where stock keeps 0 (ARP SETUP slot 7,
        moveq   #32,%d1                 | one value) or 0/1 (LEG): a named track
        cmp.l   %d1,%d0
        bge.s   2f
        move.b  13(%a1),%d0
        cmp.l   %d1,%d0
        blt.s   8f
2:      lea     0x400d3f98+0x96,%a0     | the ARP descriptor's defaults, params 1..5 and 6..11
        move.b  1(%a0),13(%a1)          | LEG
        move.b  2(%a0),14(%a1)          | MODE
        move.b  3(%a0),15(%a1)          | SPD
        move.b  4(%a0),16(%a1)          | RNGE
        move.b  5(%a0),17(%a1)          | NLEN
        move.b  7(%a0),13(%a2)          | ARP SETUP 7..11 (setup + 13..17)
        move.b  8(%a0),14(%a2)
        move.b  9(%a0),15(%a2)
        move.b  10(%a0),16(%a2)
        move.b  11(%a0),17(%a2)
        clr.b   18(%a2)                 | CTRL1 SETUP's unused + 18..19 (name characters 6-7)
        clr.b   19(%a2)
8:      movem.l (%sp),%d0-%d1/%a0-%a2
        lea     20(%sp),%sp
9:      move.l  130(%a1),%d1            | displaced
        mvz.b   1250(%a0),%d0           | displaced
        rts
