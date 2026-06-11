MulGuardianIndexBy8
    lda guardian_index
    asl
    asl
    asl
    rts

CopyDownGuardianData
    jsr MulGuardianIndexBy8
    tay
    lda guardian_data_base,y
    sta hx
    lda guardian_data_base+1,y
    sta hy
    lda guardian_data_base+2,y
    sta hl
    lda guardian_data_base+3,y
    sta hr
    lda guardian_data_base+4,y
    sta hd
    lda guardian_data_base+5,y
    sta ht
    lda guardian_data_base+6,y
    sta hc
    lda guardian_data_base+7,y
    sta hguard_frame
    rts

CopyUpGuardianData
    jsr MulGuardianIndexBy8
    tay
    lda hx
    sta guardian_data_base,y
    lda hy
    sta guardian_data_base+1,y
    lda hl
    sta guardian_data_base+2,y
    lda hr
    sta guardian_data_base+3,y
    lda hd
    sta guardian_data_base+4,y
    lda ht
    sta guardian_data_base+5,y
    lda hc
    sta guardian_data_base+6,y
    lda hguard_frame
    sta guardian_data_base+7,y
    rts

IsVerticalGuardian
    lda ht
    and #$f0
    cmp #$40
    rts

EraseBlock
    ldy guardian_erase_off,x
    lda #0
    sta (scr_ptr),y
    lda #1
    sta (col_ptr),y
    dex
    bpl EraseBlock
    rts

guardian_erase_off
    !byte 24,25,48,49,72,73

EraseGuardians
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
    rts

; A = frame index 0-7 -> arr = guardian_sprites_base + frame*32
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
    and #$f0
    lsr
    lsr
    lsr
    lsr
    sta tmp_xadd
    lda ht
    and #$0f
    sec
    sbc tmp_xadd
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
    lda ht
    and #$0f
    cmp hguard_frame
    bcs +
    lda ht
    and #$f0
    lsr
    lsr
    lsr
    lsr
    sta hguard_frame
+
    rts

MoveHorizontalGuardian
    lda hx
    clc
    adc hd
    sta hx
    lda hd
    bmi +
    lda hx
    cmp hr
    bne +++
    beq ++
+
    lda hx
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

MoveVerticalGuardian
    lda hy
    clc
    adc hd
    sta hy
    lda hd
    bmi +
    lda hy
    cmp hr
    bne +++
    beq ++
+
    lda hy
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

draw_guardian_offsets
    !byte 24,25,48,49,72,73
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
    ldy draw_guardian_offsets,x
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
    ldy draw_guardian_offsets,x
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
    bne EndMoveHorizontalGuardian
    jsr MoveHorizontalGuardian
    jsr GetHorizontalGuardianFrame
    jsr CalcGuardianUDGAddr
    jsr CopyHorizontalGuardianFrame
EndMoveHorizontalGuardian
    jsr DrawHorizontalGuardian
    jmp EndGuardianLoop

MoveNormalVerticalGuardian
    jsr ShouldMoveVerticalGuardianThisFrame
    bne +
    jsr MoveVerticalGuardian
    jsr AdvanceVerticalFrame
    jsr GetVerticalGuardianBmpAddr
    jsr CalcGuardianUDGAddr
    jsr CopyVerticalGuardianFrame
+
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
