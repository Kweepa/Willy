; Title screen loop + scrolling HUD message — baked into r62 @ image_base.
; CLI: -DORG=$1A02 -DSCANKEYROW=… -DWAITFORRASTER=… -DSETCOLORS=… -DHUD_SCR=… -DHUD_COL=…
;      -DMSG_LEN=… -DHOLD_FRAMES=150 -DSCROLL_FRAMES=6 -DSLOT_BYTES=510
; Must assemble at ORG (load address); internal labels are absolute, not PC-relative.
; Scratch (title_scroll_off … title_mlh) lives in this slot, not game ZP.

!source "equates.asm"

music_bar = $43
music_delay = $44

*= ORG

TitleScreen
    lda #RED
    jsr SETCOLORS
    lda #0
    sta title_scroll_off
    sta title_phase
    sta music_bar
    sta music_delay
    sta title_music_step
    lda #HOLD_FRAMES
    sta title_hold_ctr
    lda #SCROLL_FRAMES
    sta title_scroll_ctr

.title_loop
    jsr .draw_hud
    ldx #$ef                    ; space bar row
    jsr SCANKEYROW
    bne .title_exit             ; Z clear = key pressed
    jsr .play_music
    inc music_delay
    lda music_delay
    and #$0f
    sta music_delay
    bne +
    inc title_music_step
    lda title_music_step
    cmp #3
    bcc +
    lda #0
    sta title_music_step
    inc music_bar
    lda music_bar
    cmp #33
    bcc +
    lda #0
    sta music_bar
+
    jsr WAITFORRASTER
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
    lda #0
    sta $900a
    sta $900b
    ldx #$ef
    jsr SCANKEYROW
    bne .title_exit             ; wait for release (Z clear while held)
    rts

.play_music
    ldy music_bar
    lda title_bar_seq,y
    sta title_mpack
    lda title_mpack
    and #7
    tay
    lda title_music_step
    clc
    adc title_lh_ofs,y
    tay
    lda title_lh_triplets,y
    sta $900a
    lda title_mpack
    lsr
    lsr
    lsr
    tay
    lda title_music_step
    clc
    adc title_rh_ofs,y
    tay
    lda title_rh_triplets,y
    sta $900b
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

; Moonlight dual: LH->$900a RH->$900b, 7+11 unique triplets, 33-bar seq.
title_bar_seq
    !byte (0<<3)+0      ; B01 m1
    !byte (0<<3)+0      ; B02 m1
    !byte (0<<3)+0      ; B03 m1
    !byte (0<<3)+0      ; B04 m1
    !byte (0<<3)+1      ; B05 m2
    !byte (0<<3)+1      ; B06 m2
    !byte (0<<3)+1      ; B07 m2
    !byte (0<<3)+1      ; B08 m2
    !byte (1<<3)+2      ; B09 m3
    !byte (1<<3)+2      ; B10 m3
    !byte (2<<3)+3      ; B11 m3
    !byte (2<<3)+3      ; B12 m3
    !byte (3<<3)+4      ; B13 m4
    !byte (0<<3)+4      ; B14 m4
    !byte (4<<3)+4      ; B15 m4
    !byte (5<<3)+4      ; B16 m4
    !byte (6<<3)+0      ; B17 m5
    !byte (0<<3)+0      ; B18 m5
    !byte (0<<3)+0      ; B19 m5
    !byte (0<<3)+4      ; B20 m5
    !byte (7<<3)+5      ; B21 m6
    !byte (7<<3)+4      ; B22 m6
    !byte (7<<3)+5      ; B23 m6
    !byte (7<<3)+4      ; B24 m6
    !byte (0<<3)+0      ; B25 m7
    !byte (0<<3)+0      ; B26 m7
    !byte (8<<3)+3      ; B27 m7
    !byte (8<<3)+3      ; B28 m7
    !byte (9<<3)+6      ; B29 m8
    !byte (9<<3)+6      ; B30 m8
    !byte (10<<3)+6     ; B31 m8
    !byte (10<<3)+6     ; B32 m8
    !byte (9<<3)+6      ; B33 m9

title_lh_triplets
    !byte 199,227,227       ; LH0 C#4,C#5,C#5
    !byte 223,239,239       ; LH1 B4,B5,B5
    !byte 219,237,237       ; LH2 A4,A5,A5
    !byte 212,233,233       ; LH3 F#4,F#5,F#5
    !byte 217,236,236       ; LH4 G#4,G#5,G#5
    !byte 195,225,225       ; LH5 C4,C5,C5  (B# bass, m6)
    !byte 207,231,231       ; LH6 E4,E5,E5

title_rh_triplets
    !byte 217,227,231      ; RH0 G#4,C#5,E5
    !byte 219,227,231      ; RH1 A4,C#5,E5
    !byte 219,228,233      ; RH2 A4,D5,F#5
    !byte 217,195,212      ; RH3 G#4,C4,F#4  (B#)
    !byte 217,227,229      ; RH4 G#4,C#5,D#5
    !byte 217,225,229      ; RH5 G#4,C5,D#5   (m4 beat 4)
    !byte 207,217,227      ; RH6 E4,G#4,C#5  (m5 C#m 1st inv)
    !byte 217,229,233      ; RH7 G#4,D#5,F#5
    !byte 219,227,233      ; RH8 A4,C#5,F#5
    !byte 217,223,231      ; RH9 G#4,B4,E5
    !byte 212,223,229      ; RH10 F#4,B4,D#5  (Bmaj; B31-32)

title_scroll_off    !byte 0
title_phase         !byte 0
title_hold_ctr      !byte 0
title_scroll_ctr    !byte 0
title_music_step    !byte 0
title_mpack         !byte 0

title_lh_ofs
    !byte 0,3,6,9,12,15,18
title_rh_ofs
    !byte 0,3,6,9,12,15,18,21,24,27,30

!if * > ORG + SLOT_BYTES {
    !error "TitleScreen size ", *, " exceeds ", ORG + SLOT_BYTES
}
!if * < ORG + SLOT_BYTES {
    !fill ORG + SLOT_BYTES - *, $ea
}
