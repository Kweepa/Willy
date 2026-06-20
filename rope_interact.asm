; Rope player input, grab/attach, release. Callers gate on room_has_rope.

rope_jump_xadd  !byte $ff, $01                      ; swing_side 0=left->-1, 1=right->+1
rope_near_key   !byte leftIsPressed, rightIsPressed ; descend key, indexed by swing_side
rope_far_key    !byte rightIsPressed, leftIsPressed ; climb key,   indexed by swing_side

rope_release
    lda #0
    sta rope_willy_is_holding
    lda #ROPE_GRAB_COOLDOWN_MAX
    sta rope_grab_cooldown
    rts

; tick frame counter (0..5) then clear rope only on draw (even) frames
rope_pre_draw
    ldx rope_anim_ctr
    inx
    cpx #6
    bcc +
    ldx #0
+
    stx rope_anim_ctr
    txa
    lsr
    bcs +                           ; odd -> skip clear (keep rope on screen)
    jmp rope_clear_pre_player_draw  ; tail call
+
    rts

; draw rope only on even frames (every other frame)
rope_draw_maybe
    lda rope_anim_ctr
    lsr
    bcs +
    jmp rope_draw                   ; tail call (also snaps willy via ROPE_SNIP_SNAP)
+
    rts

; called from Collide only while holding the rope
RopePlayerInput
    lda jumpIsPressed
    bne rope_jump
    lda rope_anim_ctr               ; climb/descend every third frame (ctr 0 or 3)
    beq +
    cmp #3
    bne rope_input_done
+
    ldy rope_swing_side             ; data-driven near/far key select
    ldx rope_near_key,y
    lda $00,x                       ; zp,x reads leftIsPressed/rightIsPressed flag
    bne rope_descend
    ldx rope_far_key,y
    lda $00,x
    beq rope_input_done
rope_climb
    lda rope_willy_seg
    beq rope_input_done
    dec rope_willy_seg
rope_input_done
    rts

rope_descend
    inc rope_willy_seg
    lda rope_willy_seg
    cmp #32                         ; reached segment 32 -> fall straight off
    bcc rope_input_done
    lda #0
    sta xadd
    jsr rope_release
    lda #27
    sta inairtime
    rts

rope_jump
    jsr rope_release
    lda #0
    sta inairtime
    ldx rope_swing_side
    lda rope_jump_xadd,x
    sta xadd
    sta lastxmove
    rts

; rope_attach: tail-called from HandleOverlapChar on rope-UDG overlap.
; Must preserve X (coll_check loop depends on it); does not touch Y.
; Grabs the segment whose Y is closest to py+8 (willy's vertical center).
; rope_index / rope_udg_advance are dead here (rope_draw already finished),
; so they are reused as best-diff / best-index scratch.
rope_attach
    lda rope_willy_is_holding
    bne rope_attach_done            ; already carried
    lda rope_grab_cooldown
    bne rope_attach_done            ; cooling down
    txa
    pha                             ; save coll_check X
    lda py
    clc
    adc #8
    sta tmp                         ; target = py + 8
    lda #$ff
    sta rope_index                  ; best diff seen so far (max)
    ldx #ROPE_SEG_MAX
-
    lda ROPE_SEGMENT_Y,x
    sec
    sbc tmp                         ; A = seg_y - target
    bpl +
    eor #$ff
    clc
    adc #1                          ; A = abs(seg_y - target)
+
    cmp rope_index
    bcs ++                          ; not closer than best
    sta rope_index                  ; new best diff
    stx rope_udg_advance            ; new best index
++
    dex
    bpl -
    ldx rope_udg_advance
    stx rope_willy_seg              ; closest segment
    pla
    tax                             ; restore coll_check X
    lda #1
    sta rope_willy_is_holding
    sta on_ground
    lda #27
    sta inairtime
rope_attach_done                    ; early-outs branch here, grab path falls through
    rts
