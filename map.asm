ResetGame
    lda #1
    sta map
    lda #3
    sta men
    lda #0
    sta items_left
    lda #1
    sta initial_room_load       ; first room load uses @spawn from meta
	rts

SaveSpawn
    lda px
    sta spawn_px
    lda py
    sta spawn_py
    rts

ResetMap
    lda #0
    sta dead
    sta left_right_ctr
	sta up_down_ctr
	sta belt_active
	rts

DrawMap
	lda #8
	sta $900f
	ldx #20
-
    jsr WaitForRaster
    dex
    bne -
    lda #0
    sta dead
    lda #51
    sta inairtime
    sta last_py
    lda initial_room_load
    bne drawmap_first_room
    lda spawn_px
    sta px
    lda spawn_py
    sta py
    lda #0
    sta use_room_spawn
    jsr LoadRoom
    rts
drawmap_first_room
    lda #1
    sta use_room_spawn          ; new game - @spawn from room meta
    jsr LoadRoom
    jsr SaveSpawn
    lda #0
    sta use_room_spawn
    lda #0
    sta initial_room_load
    rts

AnimateBelts
    ; could replace these first two lines with nop or rts which would save 3 bytes
    ; if we already had to populate left_right_ctr from room metadata
    ; alternatively we could stream in the code per room, which would reduce this to 15 bytes
    ; or less if we can combine several functions
    lda left_right_ctr
    bne no_belt_animate
    lda meta_content_src + meta_off_belt
    bpl belt_animate_right
    lda udg_base + TILE_CONVEYOR*8
    asl
    rol udg_base + TILE_CONVEYOR*8
    lda udg_base + TILE_CONVEYOR*8 + 2
    lsr
    ror udg_base + TILE_CONVEYOR*8 + 2
    rts
belt_animate_right
    lda udg_base + TILE_CONVEYOR*8
    lsr
    ror udg_base + TILE_CONVEYOR*8
    lda udg_base + TILE_CONVEYOR*8 + 2
    asl
    rol udg_base + TILE_CONVEYOR*8 + 2
no_belt_animate
    rts

GetConnByte
    lda meta_content_src + meta_off_conn,y
    rts

; row: coord(0=px,1=py), cmp(0=le,1=ge), limit+1 for le / limit for ge, conn, entry_px, entry_py
edge_tbl
    !byte 0, 1, EDGE_EAST_PX, 1, EDGE_EAST_ENTRY_PX, $ff
    !byte 0, 0, 1, 3, EDGE_WEST_ENTRY_PX, $ff
    !byte 1, 0, 9, 0, $ff, 112
    !byte 1, 1, 112, 2, $ff, 16
EDGE_ROW_SIZE = 6

CheckRoomEdge
    ldx #0
-
    lda edge_tbl+1,x
    sta tmp+1
    lda edge_tbl,x
    bne +
    lda px
    jmp ++
+
    lda py
++
    cmp edge_tbl+2,x
    ldy tmp+1
    beq +
    bcc edge_next
    jmp edge_hit
+
    bcs edge_next
edge_hit
    ldy edge_tbl+3,x
    jsr GetConnByte
    cmp #$ff
    beq edge_next
    sta map
    lda edge_tbl+4,x
    sta entry_px
    lda edge_tbl+5,x
    sta entry_py
    jmp do_room_change
edge_next
    txa
    clc
    adc #EDGE_ROW_SIZE
    tax
    cpx #EDGE_ROW_SIZE*4
    bcc -
    jmp edge_done
do_room_change
    lda entry_px
    cmp #$ff
    beq +
    sta px
+
    lda entry_py
    cmp #$ff
    beq +
    sta py
+
    lda #0
    sta use_room_spawn          ; edge transition - px/py already set, not @spawn
    jsr LoadRoom
    jsr SaveSpawn
    lda #51
    sta inairtime
edge_done
    lda py
    sta last_py
    rts
