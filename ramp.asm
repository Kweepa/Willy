; ===========================================================================
; call this once per frame, irrespective of movement

calculate_ramp_y
    lda #0
    sta is_in_ramp_bounds
    lda px
    clc
    adc xadd
    tax
    sec
    sbc meta_ramp_rx1
    tay
    bpl +
    rts ; outside ramp lower bound
+
    ; check upper bound (rx1 <= pc < rx2; rx2 baked as max pc + 1)

    txa
    cmp meta_ramp_rx2
    bcc +
    rts ; outside ramp upper bound
+
    ; ramp_y = ry + ((2 * dx EOR E) + A)  — E/A baked per ramp type

    tya
    sec
    sbc xadd
    asl
    eor meta_ramp_E
    clc
    adc meta_ramp_A
    adc meta_ramp_ry
    sta ramp_y

    lda #1
    sta is_in_ramp_bounds
    rts

; ===========================================================================
; Call when about to move horizontally on the ground or on a ramp — adjusts py
; by +/-2 to follow the slope. Caller (CollideLeftRight) must gate on
; (was_on_ground OR is_on_ramp) and xadd != 0.

do_walking_ramp_check
    lda #0
    sta is_on_ramp
    lda is_in_ramp_bounds
    bne +
    rts
+
    lda ramp_y
    cmp py
    beq +
    rts ; not on the level with the ramp
    lda #1
    sta is_on_ramp
+
    ; depending on ramp direction + player movement direction, increment or decrement py by 2
    lda xadd
    eor meta_ramp
    beq +
    inc py
    inc py
    rts
+
    dec py
    dec py
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
