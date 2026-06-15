start_game
	jsr ResetGame

start_map
	jsr ResetMap
    jsr DrawMap
main_loop
    jsr ErasePlayer
    jsr EraseGuardians
    jsr UpdateMoveCounters
    jsr MoveGuardians
    jsr GetPlayerInput
    jsr Collide
    jsr DrawHud
    jsr CheckRoomEdge
    jsr AnimateBelts
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
