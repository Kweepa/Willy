!zone guardians_implementation

CopyDownGuardianData
    jsr CalcGuardianRecPtr
    ldy #g_off_axis
-
    lda (arr),y
    sta hx,y
    dey
    bpl -
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
    lda hy
    and #7
    beq +
    inx
    inx
+
    ; erase_block
-
    ldy cell_off_2x3,x
    lda #TILE_CHR_BASE
    sta (scr_ptr),y
    lda #WHITE
    sta (col_ptr),y
    dex
    bpl -

    inc guardian_index
    lda guardian_index
    cmp meta_content_src + meta_off_guardians
    bne erase_guardian_loop
erase_guardians_done
    rts

GetHorizontalGuardianFrame
    lda hx
    and #$03
    ldx g_fctl ; check bidirectional
    beq +
    ldx hd ; if going left, want to use the first four frames
    bmi ++
    eor #4 ; otherwise use the next four
+
    bpl ++

GetVerticalGuardianBmpAddr
    lda g_frame
++
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
    lda hd     ; flip direction
    eor #$ff
    clc
    adc #1
    sta hd
+++
    inc g_frame
    lda g_frame
    and g_fctl
    sta g_frame
    rts

DrawGuardian
    lda guard_axis
    cmp #GUARDIAN_VERTICAL
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
--
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
    lda guard_axis
    cmp #GUARDIAN_VERTICAL
    bcs +
    jsr ShouldMoveHorizontalGuardianThisFrame
    bne draw_guardian
    jmp move_guardian
+
    jsr ShouldMoveVerticalGuardianThisFrame
    bne draw_guardian
move_guardian
    jsr MoveGuardian
    lda guard_axis
    cmp #GUARDIAN_VERTICAL
    bcs +
    jsr GetHorizontalGuardianFrame
    jmp got_sprite_frame
+
    jsr GetVerticalGuardianBmpAddr
got_sprite_frame
    jsr CalcGuardianUDGAddr
    jsr CopyGuardianFrame
draw_guardian
    jsr DrawGuardian
    jmp EndGuardianLoop

EndGuardianLoop

    ; CopyUpGuardianData
    jsr CalcGuardianRecPtr
    ldy #g_off_frame
-
    lda hx,y
    sta (arr),y
    dey
    bpl -

    +BorderDebugGuardianIndex
    inc guardian_index
    lda guardian_index
    cmp meta_content_src + meta_off_guardians
    bne --
move_guardians_done
    rts
