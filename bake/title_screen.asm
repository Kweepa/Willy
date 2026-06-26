; Title screen loop + scrolling HUD message — baked into r62 @ image_base.
; CLI: -DORG=$1A02 -DSCANKEYROW=… -DWAITFORRASTERLINE=… -DSETCOLORS=… -DHUD_SCR=… -DHUD_COL=…
;      -DMSG_LEN=… -DHOLD_FRAMES=150 -DSCROLL_FRAMES=6 -DSLOT_BYTES=510
; Must assemble at ORG (load address); internal labels are absolute, not PC-relative.
; Scratch (title_scroll_off … title_scroll_ctr) lives in this slot, not game ZP.

!source "equates.asm"

music_index = $43
music_delay = $44

*= ORG

TitleScreen
    lda #RED
    jsr SETCOLORS
    lda #0
    sta title_scroll_off
    sta title_phase
    sta music_index
    sta music_delay
    lda #HOLD_FRAMES
    sta title_hold_ctr
    lda #SCROLL_FRAMES
    sta title_scroll_ctr

.title_loop
    jsr .draw_hud
    ldx #$ef                    ; space bar row
    jsr SCANKEYROW
    bne .title_exit             ; Z clear = key pressed
    lda music_index
    tax
    lda title_tune_notes,x
    sta $900b
    sta $900a
    inc music_delay
    lda music_delay
    and #$0f
    sta music_delay
    bne +
    inc music_index
    lda music_index
    cmp #99
    bcc +
    lda #0
    sta music_index
+
    jsr WAITFORRASTERLINE
    lda title_phase
    bne .title_scroll_tick
    dec title_hold_ctr
    bne .title_loop
    lda #1
    sta title_phase
    bne .title_loop

.title_scroll_tick
    dec title_scroll_ctr
    bne .title_loop
    lda #SCROLL_FRAMES
    sta title_scroll_ctr
    inc title_scroll_off
    lda title_scroll_off
    cmp #MSG_LEN
    bne .title_loop
    lda #0
    sta title_scroll_off
    sta title_phase
    lda #HOLD_FRAMES
    sta title_hold_ctr
    jmp .title_loop

.title_exit
    ldx #$ef
    jsr SCANKEYROW
    bne .title_exit             ; wait for release (Z clear while held)
    rts

.draw_hud
    ldx #0
    ldy title_scroll_off
-
    lda scroll_msg,y
    sta HUD_SCR,x
    lda #YELLOW
    sta HUD_COL,x
    iny
    cpy #MSG_LEN
    bcc +
    ldy #0
+
    inx
    cpx #24
    bne -
    rts

scroll_msg
!source ".tmp/title_msg.inc"

; Moonlight Sonata — JSW $85FB bass-line arrangement, 33 triplets (decimal).
; Pitch classes from original Spectrum title tune; no full-score melody intrusions.
; VIC poke is monotonic: lower value = lower pitch; semitone/octave up = larger value.
title_tune_notes
    !byte 217,227,231      ; T01 m1   G#4,C#5,E5
    !byte 217,227,231      ; T02 m1   G#4,C#5,E5
    !byte 217,227,231      ; T03 m1   G#4,C#5,E5
    !byte 217,227,231      ; T04 m1   G#4,C#5,E5
    !byte 217,227,231      ; T05 m2   G#4,C#5,E5
    !byte 217,227,231      ; T06 m2   G#4,C#5,E5
    !byte 217,227,231      ; T07 m2   G#4,C#5,E5
    !byte 217,227,231      ; T08 m2   G#4,C#5,E5
    !byte 219,227,231      ; T09 m3   A4,C#5,E5
    !byte 219,227,231      ; T10 m3   A4,C#5,E5
    !byte 219,228,233      ; T11 m3   A4,D5,F#5
    !byte 219,228,233      ; T12 m3   A4,D5,F#5
    !byte 217,225,233      ; T13 m4   G#4,C5,F#5
    !byte 217,227,231      ; T14 m4   G#4,C#5,E5
    !byte 217,227,229      ; T15 m4   G#4,C#5,D#5
    !byte 212,225,229      ; T16 m4   F#4,C5,D#5
    !byte 207,217,227      ; T17 m5   E4,G#4,C#5
    !byte 217,227,231      ; T18 m5   G#4,C#5,E5
    !byte 217,227,231      ; T19 m5   G#4,C#5,E5
    !byte 179,199,217      ; T20 m5   G#3,C#4,G#4
    !byte 179,203,212      ; T21 m6   G#3,D#4,F#4
    !byte 217,229,233      ; T22 m6   G#4,D#5,F#5
    !byte 217,229,233      ; T23 m6   G#4,D#5,F#5
    !byte 179,203,217      ; T24 m6   G#3,D#4,G#4
    !byte 179,199,207      ; T25 m7   G#3,C#4,E4
    !byte 217,227,231      ; T26 m7   G#4,C#5,E5
    !byte 183,199,212      ; T27 m7   A3,C#4,F#4
    !byte 219,227,233      ; T28 m7   A4,C#5,F#5
    !byte 179,195,207      ; T29 m8   G#3,C4,E4
    !byte 217,225,231      ; T30 m8   G#4,C5,E5
    !byte 167,195,203      ; T31 m8   F#3,C4,D#4
    !byte 135,195,203      ; T32 m8   C3,C4,D#4
    !byte 143,199,227      ; T33 m9   C#3,C#4,C#5
    !byte 255                ; END

title_scroll_off    !byte 0
title_phase         !byte 0
title_hold_ctr      !byte 0
title_scroll_ctr    !byte 0

!if * > ORG + SLOT_BYTES {
    !error "TitleScreen size ", *, " exceeds ", ORG + SLOT_BYTES
}
!if * < ORG + SLOT_BYTES {
    !fill ORG + SLOT_BYTES - *, $ea
}
