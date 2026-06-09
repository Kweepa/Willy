; standing pose — 6 chars (PLAY_CHR .. PLAY_CHR+5)
InitPlayerUDGs
    ldx #47
-
    lda player_bmp,x
    sta udg_base + PLAY_CHR*8,x
    dex
    bpl -
    ldx #7
-
    lda #255
    sta udg_base + TILE_SOLID*8,x
    dex
    bpl -
    rts

