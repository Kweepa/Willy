    ; call this once per frame, irrespective of movement
calculate_ramp_y
    lda px
    clc
    adc xadd
    tax
    sec
    sbc #meta_content_src + meta_off_ramp_rx1
    bpl +
    rts ; outside ramp lower bound
+
    clc
    adc #meta_content_src + meta_off_ramp_ry
    sta ramp_y

    ; check upper bound

    txa
    sec
    sbc #meta_content_src + meta_off_ramp_rx2
    bne +
    rts ; outside ramp upper bound
+
    lda #1
    sta is_in_ramp_bounds
    rts

    ; call this when about to move when on the ground or on a ramp (on_ground or is_on_ramp)
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
    eor #meta_content_src + meta_off_ramp
    beq +
    dec py
    dec py
    rts
+
    inc py
    inc py
    rts

    ; call this when falling straight down (xadd is 0 and yadd is positive, not on ground or on ramp)
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
    lda ramp_y
    cmp newy
    bcs +
    rts
+
    sta py
    lda #1
    sta is_on_ramp
    rts
