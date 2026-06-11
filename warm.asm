; One-shot boot at end of PRG (below $1A60; not overwritten by room load).
; sei -> VIA #2 IER/T2CL -> stack -> IOINIT -> VIC init24_val -> jmp start_game
; Must not RTS here: txs clears the SYS return address on the stack.
;
; Target registers (pause in monitor after WarmStart):
;   $9000 = $0A   horizontal centre
;   $9001 = $32   vertical centre (+16 from $22 — 4 tile rows down)
;   $9002 = $98   24 columns + bit7 (screen at $1E00, color at $9600)
;   $9003 = $22   17 rows (doubled count in bits 1-6)
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
    jmp start_game

init24_val
    !byte $0a, $32, $98, $22, $00, $ff
