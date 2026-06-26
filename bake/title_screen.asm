; Title screen loop + scrolling HUD message — baked into r62 @ guardian_sprites_base.
; CLI: -DORG=$1A48 -DSCANKEYROW=… -DWAITFORRASTERLINE=… -DSETCOLORS=… -DHUD_SCR=… -DHUD_COL=…
;      -DMSG_LEN=… -DHOLD_FRAMES=150 -DSCROLL_FRAMES=6 -DSLOT_BYTES=544
; Must assemble at ORG (load address); internal labels are absolute, not PC-relative.
; Scratch (title_scroll_off … title_scroll_ctr) lives in this slot, not game ZP.

!source "equates.asm"

*= ORG

TitleScreen
    lda #RED
    jsr SETCOLORS
    lda #0
    sta title_scroll_off
    sta title_phase
    lda #HOLD_FRAMES
    sta title_hold_ctr
    lda #SCROLL_FRAMES
    sta title_scroll_ctr

.title_loop
    jsr .draw_hud
    ldx #$ef                    ; space bar row
    jsr SCANKEYROW
    bne .title_exit             ; Z clear = key pressed
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
