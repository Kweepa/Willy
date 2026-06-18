start_game
	jsr ResetGame

start_map
	jsr ResetMap
    jsr DrawMap
main_loop
    jsr ErasePlayer
    lda room_has_rope
    beq +
    jsr rope_clear_pre_player_draw
+
    jsr EraseGuardians
    jsr UpdateMoveCounters
    jsr MoveGuardians
    jsr GetPlayerInput
    jsr Collide
    jsr DrawHud
    jsr CheckRoomEdge
    jsr AnimateConveyors        ; baked per room at $1A45
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
