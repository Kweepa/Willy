start_game
	jsr InitMusic
    jsr TitleScreen
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
    jsr PrintDebug
    jsr TryPickupItem
    jsr CheckRoomEdge
    jsr AnimateBelts
	jsr PlayInGameMusic
    jsr DisplayStatusLine
    jsr WaitForRasterLineLessThan
    jsr WaitForRasterLine
    lda dead
    beq +
	jsr InitMusic
	jsr DeathFlash
    dec men
    beq ++
    jmp start_map
+
    jmp main_loop

++
	jsr BootSquash
	jmp start_game
