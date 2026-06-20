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
    rts
+
    txa
    cmp meta_ramp_rx2
    bcc +
    rts
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
    cmp meta_ramp_ymin
    bcs +
    lda meta_ramp_ymin
    sta ramp_y
+
    lda #1
    sta is_in_ramp_bounds
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
    bcc wr_snap
    bcs wr_out

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
    rts
+
    lda newy
    cmp ramp_y
    bcs +
    rts
+
    lda ramp_y
    sta py
    lda #1
    sta is_on_ramp
    rts
