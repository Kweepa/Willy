; One-shot boot at end of PRG (overwritten by room UDG load at $1C00+).
; sei -> VIA #2 IER/T2CL -> stack -> IOINIT -> VIC init24_val -> cli
;
; Target registers (pause in monitor after WarmStart):
;   $9000 = $0A   horizontal centre
;   $9001 = $22   vertical centre
;   $9002 = $98   24 columns + bit7 (screen at $1E00, color at $9600)
;   $9003 = $24   18 rows (doubled count in bits 1-6)
;   $9004 = $00   default (light pen Y)
;   $9005 = $FF   screen block $1C00+$200, charset block $1C00
WarmStart
    sei

    lda #$7f
    sta $911d                   ; VIA #2 IER - disable all enables
    sta $911e                   ; T2CL - preset timer 2 low

    cld
    ldx #$ff
    txs

    jsr $fdf9                   ; IOINIT

    ldx #5
-
    lda init24_val,x
    sta $9000,x
    dex
    bpl -

    cli
    rts

init24_val
    !byte $0a, $22, $98, $24, $00, $ff
