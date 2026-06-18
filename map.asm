ResetGame
    lda #33
    sta map
    lda #8
    sta men
    lda #0
    sta items_collected
    ldx #pickup_got_last - pickup_got
-
    sta pickup_got,x
    dex
    bpl -
    lda #1
    sta initial_room_load       ; first room load uses @spawn from meta
	rts

DrawMap
    lda #0
    sta dead
    lda initial_room_load
    bne drawmap_first_room
    lda spawn_px
    sta px
    lda spawn_py
    sta py
    lda #0
    sta use_room_spawn
    jmp LoadRoom               ; tail call — was jsr/rts
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

; row: coord(0=px,1=py), cmp(0=le,1=ge), limit+1 for le / limit for ge, conn, entry_px, entry_py
EDGE_ROW_SIZE = 6

CheckRoomEdge
    ldx #0
-
    lda edge_tbl+1,x
    sta edge_cmp
    lda edge_tbl,x
    bne +
    lda px
    jmp ++
+
    lda py
++
    cmp edge_tbl+2,x
    ldy edge_cmp
    beq +
    bcc edge_next
    bne edge_hit
+
    bcs edge_next
edge_hit
    ldy edge_tbl+3,x
    lda meta_content_src + meta_off_conn,y   ; conn byte (inlined GetConnByte)
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
