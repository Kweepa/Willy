; ===========================================================================
; call this once per frame, irrespective of movement

calculate_ramp_y
    lda #0
    sta is_in_ramp_bounds
    lda px
    tax
    sec
    sbc meta_ramp_rx1
    tay
    bpl +
    jmp ramp_dbg_done ; outside ramp lower bound
+
    ; check upper bound (rx1 <= px < rx2; rx2 baked as max px + 1)

    txa
    cmp meta_ramp_rx2
    bcc +
    jmp ramp_dbg_done ; outside ramp upper bound
+
    ; ramp_y = ry + ((2 * dx EOR E) + A)  — E/A baked per ramp type

    tya
    asl
    eor meta_ramp_E
    clc
    adc meta_ramp_A
    clc
    adc meta_ramp_ry
    sta ramp_y

    lda #1
    sta is_in_ramp_bounds
    jmp ramp_dbg_done

ramp_dbg_done
    lda was_on_ground
    clc
    adc #$b0
    sta hud_dbg_scr+0
    lda is_on_ramp
    clc
    adc #$b0
    sta hud_dbg_scr+1
    lda is_in_ramp_bounds
    clc
    adc #$b0
    sta hud_dbg_scr+2
    lda was_on_ground
    bne falling_0
    lda inairtime
    cmp #27
    bcc falling_0
    lda #1
    bne falling_store
falling_0
    lda #0
falling_store
    clc
    adc #$b0
    sta hud_dbg_scr+3
    lda ramp_y
    ldy #$b0
-
    cmp #100
    bcc +
    sbc #100
    iny
    bne -
+
    sty hud_dbg_scr+5
    ldy #$b0
-
    cmp #10
    bcc ++
    sbc #10
    iny
    bne -
++
    sty hud_dbg_scr+6
    clc
    adc #$b0
    sta hud_dbg_scr+7
    rts

; ===========================================================================
; Call when moving horizontally on the ground or on a ramp — snaps py to
; ramp_y when within +/-2. Caller (CollideLeftRight) must gate on
; (was_on_ground OR is_on_ramp) and xadd != 0.

do_walking_ramp_check
    lda #0
    sta is_on_ramp
    lda is_in_ramp_bounds
    bne +
    rts
+
    lda py
    sec
    sbc ramp_y
    bcc wr_below
    cmp #3
    bcs wr_out
    jmp wr_snap

wr_below:
    lda ramp_y
    sec
    sbc py
    cmp #3
    bcs wr_out

wr_snap:
    lda ramp_y
    sta py
    lda #1
    sta is_on_ramp
    rts

wr_out:
    rts

; ===========================================================================
; Call when falling straight down onto a ramp (not on ground, not already
; on ramp, no horizontal movement). Caller (collide_down) must gate on
; !on_ground, !is_on_ramp, and xadd == 0.

do_falling_ramp_check
    lda #0
    sta is_on_ramp
    lda is_in_ramp_bounds
    bne +
    rts
+
    lda last_py
    cmp ramp_y
    bcc +
    rts ; was not above the ramp surface last frame
+
    lda newy
    cmp ramp_y
    bcc +
    rts ; has not reached the ramp surface yet
+
    lda ramp_y
    sta py
    lda #1
    sta is_on_ramp
    rts
