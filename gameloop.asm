start_game
	jsr ResetGame

start_map
	jsr ResetMap
    jsr DrawMap
main_loop
    jsr ErasePlayer
    jsr EraseGuardians
    jsr UpdateMoveCounters
    lda meta_content_room_has_rope
    beq +
    jsr rope_pre_draw
+
    jsr MoveGuardians
    jsr GetPlayerInput
    lda #0
    sta $900c
    jsr Collide
    jsr DrawHud
    jsr CheckEndingTeleport
    jsr AnimateConveyors        ; baked per room at image_base
    jsr WaitForRaster
    +BorderDebugColor 8

    lda dead
    beq main_loop

    ; death flash
    ldy #24
    lda #(WHITE + 8)
    ldx #0
-
    eor #(WHITE ^ RED)
    sta $900f
    txa
    eor #240
    tax
    stx $900c
    jsr WaitForRaster
    dey
    bne -
 
    dec men
    bne start_map
    beq start_game
