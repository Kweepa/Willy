ShouldMoveHorizontalGuardianThisFrame
    lda hguard_count
    and #3
    cmp left_right_ctr
    rts

ShouldMoveVerticalGuardianThisFrame
    lda vguard_count
    cmp up_down_ctr
    beq +
    sec
    sbc #3
    cmp up_down_ctr
+
    rts

guard_cell_off
    !byte 24,25,48,49,72,73

CopyDownGuardianData
    ldx guardian_index
    lda guardian_g_x,x
    sta hx
    lda guardian_g_y,x
    sta hy
    lda guardian_g_min,x
    sta hl
    lda guardian_g_max,x
    sta hr
    lda guardian_g_vel,x
    sta hd
    lda guardian_g_color,x
    sta hc
    lda guardian_g_fmin,x
    sta ht
    lda guardian_g_frame,x
    sta hguard_frame
    rts

CopyUpGuardianData
    ldx guardian_index
    lda hx
    sta guardian_g_x,x
    lda hy
    sta guardian_g_y,x
    lda hl
    sta guardian_g_min,x
    lda hr
    sta guardian_g_max,x
    lda hd
    sta guardian_g_vel,x
    lda hguard_frame
    sta guardian_g_frame,x
    rts

IsVerticalGuardian
    ldx guardian_index
    lda guardian_g_axis,x
    cmp #GUARDIAN_VERTICAL
    rts

EraseBlock
    ldy guard_cell_off,x
    lda #TILE_CHR_BASE
    sta (scr_ptr),y
    lda #WHITE
    sta (col_ptr),y
    dex
    bpl EraseBlock
    rts

EraseGuardians
    lda meta_content_src + meta_off_guardians
    beq erase_guardians_done
    lda #0
    sta guardian_index
erase_guardian_loop
    jsr CopyDownGuardianData
    ldx hx
    ldy hy
    jsr ConvertXYToScreenAddr
    ldx #3
    jsr IsVerticalGuardian
    bcc +
    lda hy
    and #7
    beq +
    inx
    inx
+
    jsr EraseBlock

    inc guardian_index
    lda guardian_index
    cmp meta_content_src + meta_off_guardians
    bne erase_guardian_loop
erase_guardians_done
    rts

GetGuardianSpriteAddr
    sta tmp
    lda tmp
    asl
    asl
    asl
    asl
    asl
    clc
    adc #<guardian_sprites_base
    sta arr
    lda #>guardian_sprites_base
    adc #0
    sta arr+1
    rts

GetHorizontalGuardianFrame
    lda hx
    and #$03
    sta tmp
    lda ht
    sta tmp_xadd
    ldx guardian_index
    lda guardian_g_fmax,x
    sec
    sbc ht
    cmp #4
    bcs bidirectional_frames
    lda tmp
    clc
    adc tmp_xadd
    jmp GetGuardianSpriteAddr

bidirectional_frames
    lda hd
    bmi leftward_frames
    lda tmp
    clc
    adc #4
    jmp GetGuardianSpriteAddr

leftward_frames
    lda tmp
    clc
    adc tmp_xadd
    jmp GetGuardianSpriteAddr

GetVerticalGuardianBmpAddr
    lda hguard_frame
    jmp GetGuardianSpriteAddr

AdvanceVerticalFrame
    inc hguard_frame
    ldx guardian_index
    lda hguard_frame
    cmp guardian_g_fmax,x
    bcc +
    lda guardian_g_fmin,x
    sta hguard_frame
+
    rts

MoveGuardian
    ldx guardian_index
    lda guardian_g_axis,x
    tax
    lda hx,x
    clc
    adc hd
    sta hx,x
    lda hd
    bmi +
    lda hx,x
    cmp hr
    bne +++
    beq ++
+
    lda hx,x
    cmp hl
    bne +++
++
    lda hd
    eor #$ff
    clc
    adc #1
    sta hd
+++
    rts

draw_vguard_chrs
    !byte 0,3,1,4,2,5
draw_hguard_chrs
    !byte 0,2,1,3

DrawHorizontalGuardian
    inc hguard_count
    ldx hx
    ldy hy
    jsr ConvertXYToScreenAddr

    ldx #3
-
    ldy guard_cell_off,x
    lda hc
    sta (col_ptr),y
    lda draw_hguard_chrs,x
    clc
    adc guard_udg_index
    sta (scr_ptr),y
    dex
    bpl -
    rts

DrawVerticalGuardian
    inc vguard_count
    ldx hx
    ldy hy
    jsr ConvertXYToScreenAddr

    ldx #3
    lda hy
    and #7
    beq +
    inx
    inx
+
-
    ldy guard_cell_off,x
    lda hc
    sta (col_ptr),y
    lda draw_vguard_chrs,x
    clc
    adc guard_udg_index
    sta (scr_ptr),y
    dex
    bpl -
    rts

CalcGuardianUDGIndex
    lda guardian_index
    asl
    clc
    adc guardian_index
    asl
    sta guard_udg_off
    clc
    adc #GUARDIAN_CHR
    sta guard_udg_index
    rts

CalcGuardianUDGAddr
    lda guard_udg_off
    asl
    asl
    asl
    clc
    adc #<guardian_udgs
    sta arr2
    lda #>guardian_udgs
    adc #0
    sta arr2+1
    rts

CopyHorizontalGuardianFrame
    ldy #31
-
    lda (arr),y
    sta (arr2),y
    dey
    bpl -
    rts

CopyVerticalGuardianFrame
    lda arr2
    clc
    adc #24
    sta arr3
    lda arr2+1
    adc #0
    sta arr3+1
    lda arr
    sta mod_src_col1+1
    clc
    adc #16
    sta mod_src_col2+1
    lda arr+1
    sta mod_src_col1+2
    sta mod_src_col2+2

    ldy #0

    lda hy
    and #7
    beq +
    tax

    lda #0
-
    sta (arr2),y
    sta (arr3),y
    iny
    dex
    bne -
+
    ldx #16
-
mod_src_col1
    lda guardian_sprites_base
    inc mod_src_col1+1
    sta (arr2),y
mod_src_col2
    lda guardian_sprites_base
    inc mod_src_col2+1
    sta (arr3),y
    iny
    dex
    bne -

    lda hy
    and #7
    eor #7
    tax

    lda #0
-
    sta (arr2),y
    sta (arr3),y
    iny
    dex
    bpl -

    rts

MoveGuardians
    lda meta_content_src + meta_off_guardians
    beq move_guardians_done
    lda #0
    sta guardian_index
    sta hguard_count
    sta vguard_count
-
    jsr CalcGuardianUDGIndex
    jsr CopyDownGuardianData
    jsr IsVerticalGuardian
    bcs MoveNormalVerticalGuardian
    jmp MoveBidirectionalHorizontalGuardian

MoveBidirectionalHorizontalGuardian
    jsr ShouldMoveHorizontalGuardianThisFrame
    bne draw_h_guardian
    jsr MoveGuardian
    jsr GetHorizontalGuardianFrame
    jsr CalcGuardianUDGAddr
    jsr CopyHorizontalGuardianFrame
draw_h_guardian
    jsr DrawHorizontalGuardian
    jmp EndGuardianLoop

MoveNormalVerticalGuardian
    jsr ShouldMoveVerticalGuardianThisFrame
    bne draw_v_guardian
    jsr MoveGuardian
    jsr AdvanceVerticalFrame
    jsr GetVerticalGuardianBmpAddr
    jsr CalcGuardianUDGAddr
    jsr CopyVerticalGuardianFrame
draw_v_guardian
    jsr DrawVerticalGuardian
    jmp EndGuardianLoop

EndGuardianLoop
    jsr CopyUpGuardianData
    inc guardian_index
    lda guardian_index
    cmp meta_content_src + meta_off_guardians
    bne -
move_guardians_done
    rts
