start_game
	jsr ResetGame

start_map
	jsr ResetMap
    jsr DrawMap
main_loop
    jsr ErasePlayer
    jsr EraseGuardians
    jsr UpdateMoveCounters
    lda room_has_rope
    beq +
    jsr rope_pre_draw
+
    jsr MoveGuardians
    jsr GetPlayerInput
    jsr Collide
    jsr DrawHud
    jsr CheckEndingTeleport
    jsr AnimateConveyors        ; baked per room at image_base
    jsr WaitForRaster
    +BorderDebugColor 8
    lda dead
    beq main_loop
	lda #(RED + 8)
	sta $900f
    dec men
    beq ++
    bne start_map

++
	jmp start_game
