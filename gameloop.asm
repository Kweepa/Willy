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
    jsr CheckRoomEdge
    jsr AnimateBelts
    jsr WaitForRaster
    +BorderDebugColor 8
    lda dead
    beq +
	jsr DeathFlash
    dec men
    beq ++
    jmp start_map
+
    jmp main_loop

++
	jmp start_game
