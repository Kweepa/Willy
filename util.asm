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

; 24×18 screen at $1E00, color RAM at $9600, tile UDGs at $1C00.
; KERNAL LOAD resets $9002/$9005 to 22-col / ROM charset — call after every LOAD.
;
; Target registers (pause in monitor after InitScreen24):
;   $9000 = $02   horizontal position
;   $9001 = $2C   vertical position
;   $9002 = $98   24 columns + bit7 (screen at $1E00, color at $9600)
;   $9003 = $24   18 rows (doubled count in bits 1-6)
;   $9005 = $FF   screen block $1C00+$200, charset block $1C00
;   $0288 = $1E   KERNAL screen page for $1E00
InitScreen24
    lda #$0a
    sta $9000                   ; horizontal centre
    lda #$98
    sta $9002                   ; 24 cols + half-page offset
    lda #$24
    sta $9003                   ; 18 rows
    lda #$22
    sta $9001                   ; vertical centre (moved up 10 units/20 scanlines)
    lda #$ff
    sta $9005                   ; screen $1E00, chars $1C00
    lda #$1e
    sta $0288                   ; KERNAL screen page (not VIC)
    rts

ClearScreen
    ldx #0
-
    lda #0
    sta screen_base,x
    sta screen_base + $100,x
    sta map_base,x
    sta map_base + $100,x
    lda #1
    sta color_base,x
    sta color_base + $100,x
    inx
    bne -
    rts

x24pytab
    !word -24
x24tab
    !word 0,24,48,72,96,120,144,168,192,216,240,264,288,312,336,360,384,408,432

ConvertXYToScreenAddr
    tya
    lsr
    lsr
    and #$fe
    tay
    lda x24pytab,y
    sta tmp
    txa
    lsr
    lsr
    clc
    adc tmp
    sta scr_ptr
    sta map_ptr
    sta col_ptr
    lda x24pytab + 1,y
    adc #>screen_base
    sta scr_ptr + 1
    adc #((>map_base) - (>screen_base))
    sta map_ptr + 1
    adc #((>color_base) - (>map_base))
    sta col_ptr + 1
    rts

PrintString
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
	inc frame_ctr
	inc game_time
	bne +
	inc game_time_hi
+
    rts

DisplayStatusLine
    rts

AddExtraMan
	inc men
	rts

EndGame
	rts

FinalBarrierUpperSettings
	rts

FinalBarrierLowerSettings
	rts
