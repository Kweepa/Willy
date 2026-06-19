; Rope player input, grab, release (room_has_rope from ParseRoomMeta)

rope_release
    lda #0
    sta rope_willy_is_holding
    lda #ROPE_GRAB_COOLDOWN_MAX
    sta rope_grab_cooldown
    rts

RopePlayerInput
    lda room_has_rope
    beq +
    lda rope_willy_is_holding
    bne rope_input_holding
+
    rts

rope_input_holding
    lda jumpIsPressed
    beq rope_input_climb
    jsr rope_release
    lda #0
    sta inairtime
    lda rope_swing_side
    beq rope_jump_left
    lda #1
    sta xadd
    sta lastxmove
    rts
rope_jump_left
    lda #-1
    sta xadd
    sta lastxmove
    rts

rope_input_climb
    lda rope_swing_side
    beq rope_climb_left_swing
rope_climb_right_swing
    lda leftIsPressed
    beq rope_climb_down_seg
    lda rightIsPressed
    beq rope_climb_up_seg
    rts
rope_climb_left_swing
    lda rightIsPressed
    beq rope_climb_down_seg
    lda leftIsPressed
    beq rope_climb_up_seg
    rts

rope_climb_down_seg
    lda rope_willy_seg
    cmp #ROPE_SEG_MAX
    bcs rope_step_off_tip
    inc rope_willy_seg
    rts

rope_step_off_tip
    jsr rope_release
    lda #0
    sta on_ground
    inc py
    rts

rope_climb_up_seg
    lda rope_willy_seg
    beq +
    dec rope_willy_seg
+
    rts

RopeTryGrab
    lda rope_grab_cooldown
    bne +
    lda py
    ldx #ROPE_SEG_MAX
-
    cmp ROPE_SEGMENT_Y,x
    beq rope_grab_seg
    dex
    bpl -
+
    rts
rope_grab_seg
    stx rope_willy_seg
    lda #1
    sta rope_willy_is_holding
    sta on_ground
    lda #27
    sta inairtime
    rts

CollideOnRope
    jsr rope_draw
    jsr DrawPlayer
    rts
