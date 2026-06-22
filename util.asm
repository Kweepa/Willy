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
+
	dec up_down_ctr
	bpl +
	lda #2
	sta up_down_ctr
+
    rts

    ; set colors to A
SetColors
    ldx #192
-
    sta $95ff,x
    sta $96bf,x
    dex
    bne -
    rts

try_fall_death
    lda inairtime
    cmp #70
    bcc +
    lda #1
    sta fall_death_respawn
    sta dead
    lda safe_map
    sta map
+
    rts