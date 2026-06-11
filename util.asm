;
; WaitForRasterLine
;

WaitForRasterLine
    lda $9004
    and #$fe
    cmp #RASTERLINE_PAL
    bne WaitForRasterLine
    rts

WaitForRasterLineLessThan
    lda $9004
    and #$fe
    cmp #RASTERLINE_PAL
    bcs WaitForRasterLineLessThan
    rts

WaitForRaster
	jsr WaitForRasterLineLessThan
	jmp WaitForRasterLine

; Row-base screen addresses (column 0).
; Pixel py: index (py >> 2) & $FE from start (word 0 = one row above screen).
; Cell row: index row << 1 from x24rowtab+2 (row 0 = $1E00).
x24rowtab
    !word screen_base - 24
    !word screen_base + 0
    !word screen_base + 24
    !word screen_base + 48
    !word screen_base + 72
    !word screen_base + 96
    !word screen_base + 120
    !word screen_base + 144
    !word screen_base + 168
    !word screen_base + 192
    !word screen_base + 216
    !word screen_base + 240
    !word screen_base + 264
    !word screen_base + 288
    !word screen_base + 312
    !word screen_base + 336
    !word screen_base + 360
    !word screen_base + 384
    !word screen_base + 408
    !word screen_base + 432

ConvertXYToScreenAddr
    tya
    lsr
    lsr
    and #$fe
    tay
    lda x24rowtab,y
    sta scr_ptr
    lda x24rowtab + 1,y
    sta scr_ptr + 1
    txa
    lsr
    lsr
    clc
    adc scr_ptr
    sta scr_ptr
    bcc +
    inc scr_ptr + 1
+
    ; screen/map/color bases differ by $xx00 only - low byte unchanged
    lda scr_ptr
    sta map_ptr
    sta col_ptr
    lda scr_ptr + 1
    clc
    adc #>(map_base - screen_base)
    sta map_ptr + 1
    clc
    adc #>(color_base - map_base)
    sta col_ptr + 1
    rts

UpdateMoveCounters
    dec left_right_ctr
    bpl +
    lda #3
    sta left_right_ctr
	inc hguard_frame
+
	dec up_down_ctr
	bpl +
	lda #2
	sta up_down_ctr
	inc vguard_frame
+
    rts

AddExtraMan
	inc men
	rts

EndGame
	rts
