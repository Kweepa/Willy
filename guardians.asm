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

CalcGuardianRecPtr
    lda guardian_index
    asl
    asl
    asl
    adc guardian_index
    adc #<guardian_data_base
    sta arr
    lda #>guardian_data_base
    sta arr+1
    rts

CopyDownGuardianData
    jsr CalcGuardianRecPtr
    ldy #8
-
    lda (arr),y
    sta hx,y
    dey
    bpl -
    rts

CopyUpGuardianData
    jsr CalcGuardianRecPtr
    ldy #4
-
    lda hx,y
    sta (arr),y
    dey
    bpl -
    rts

IsVerticalGuardian
    lda guard_axis
    cmp #GUARDIAN_VERTICAL
    rts

EraseBlock
    ldy cell_off_2x3,x
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
    jsr IsVerticalGuardian
    ldx #3
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

GetHorizontalGuardianFrame
    lda hx
    and #$03
    sta tmp
    lda hfmax
    sec
    sbc ht
    cmp #4
    bcc +
    lda hd
    bmi +
    lda tmp
    clc
    adc #4
    jmp GetSpriteFrameAddr   ; tail call — rts resumes at caller after jsr GetHorizontalGuardianFrame
+
    lda tmp
    clc
    adc ht
    jmp GetSpriteFrameAddr   ; tail call — rts resumes at caller after jsr GetHorizontalGuardianFrame

GetVerticalGuardianBmpAddr
    lda hguard_frame
    and hfmax
    clc
    adc ht
    jmp GetSpriteFrameAddr   ; tail call — rts resumes at caller after jsr GetVerticalGuardianBmpAddr

MoveGuardian
    lda guard_axis
    tax
    lda hx,x
    clc
    adc hd
    sta hx,x
    tay
    lda hd
    bmi +
    tya
    cmp hr
    bne +++
    beq ++
+
    tya
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

DrawGuardian
    jsr IsVerticalGuardian
    php
    bcc +
    inc vguard_count
    bne ++
+
    inc hguard_count
++
    ldx hx
    ldy hy
    jsr ConvertXYToScreenAddr

    plp
    ldx #3
    bcc draw_guard_loop
    lda hy
    and #7
    beq draw_guard_loop
    inx
    inx
draw_guard_loop
-
    ldy cell_off_2x3,x
    lda hc
    sta (col_ptr),y
    lda draw_vguard_chrs,x
    clc
    adc guard_udg_index
    sta (scr_ptr),y
    dex
    bpl -
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

CopyGuardianFrame
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
    adc #0
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
    bne +
    inc mod_src_col1+2
+
    sta (arr2),y
mod_src_col2
    lda guardian_sprites_base
    inc mod_src_col2+1
    bne +
    inc mod_src_col2+2
+
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
    ; UDG slot from guardian_index (inlined CalcGuardianUDGIndex)
    lda guardian_index
    asl
    clc
    adc guardian_index
    asl
    sta guard_udg_off
    clc
    adc #GUARDIAN_CHR
    sta guard_udg_index
    jsr CopyDownGuardianData
    jsr IsVerticalGuardian
    bcs MoveNormalVerticalGuardian

MoveBidirectionalHorizontalGuardian
    jsr ShouldMoveHorizontalGuardianThisFrame
    bne draw_guardian
    jsr MoveGuardian
    jsr GetHorizontalGuardianFrame
    jsr CalcGuardianUDGAddr
    jsr CopyGuardianFrame
draw_guardian
    jsr DrawGuardian
    jmp EndGuardianLoop

MoveNormalVerticalGuardian
    jsr ShouldMoveVerticalGuardianThisFrame
    bne +
    jsr MoveGuardian
+
    jsr GetVerticalGuardianBmpAddr
    jsr CalcGuardianUDGAddr
    jsr CopyGuardianFrame
    jsr DrawGuardian

EndGuardianLoop
    jsr CopyUpGuardianData
    +BorderDebugGuardianIndex
    inc guardian_index
    lda guardian_index
    cmp meta_content_src + meta_off_guardians
    bne -
move_guardians_done
    rts
