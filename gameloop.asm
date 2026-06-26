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
    jsr PlayInGameMusic
    lda meta_content_has_arrow
    beq +
    jsr arrow_update
+
    jsr Collide
    jsr DrawHud
    jsr CheckEndingTeleport
    jsr FlickerItem             ; baked per room at image_base
    jsr AnimateConveyors
    jsr WaitForRaster
    +BorderDebugColor 8

    lda dead
    beq main_loop

    ; prevent infinite death loop
    lda safe_transition_count
    beq +
    sta fall_death_respawn
+

    ; death flash
    ldy #24
    lda #(WHITE + 8)
    ldx #0
-
    eor #(WHITE ^ RED)
    sta $900f
    pha
    txa
    eor #240
    tax
    stx $900c
    jsr WaitForRaster ; clobbers A
    pla
    dey
    bne -
 
    dec men
    bne start_map
    beq start_game
