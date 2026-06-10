; standing pose — 6 chars (PLAY_CHR .. PLAY_CHR+5)
; Room PRG supplies tile UDGs 0-6 at udg_base; do not overwrite them here.
InitPlayerUDGs
    ldx #47
-
    lda player_bmp,x
    sta udg_base + PLAY_CHR*8,x
    dex
    bpl -
    rts

