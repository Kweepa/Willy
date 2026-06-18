;
; WaitForRasterLine
;

WaitForRaster
    ; wait for raster below sync band (inlined WaitForRasterLineLessThan)
-
    lda $9004
    and #$fe
    cmp #RASTERLINE_PAL
    bcs -

WaitForRasterLine
    lda $9004
    and #$fe
    cmp #RASTERLINE_PAL
    bne WaitForRasterLine
    rts

UpdateMoveCounters
    lda rope_grab_cooldown
    beq +
    dec rope_grab_cooldown
+
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
