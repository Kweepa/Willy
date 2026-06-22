ResetGame

SHOW_TITLE = 1

!if SHOW_TITLE {

    lda #ROOM_TITLE
    sta map
    jsr LoadRoom

    lda #RED
    jsr SetColors

title_wait
    ldx #$ef                    ; space bar row
    jsr ScanKeyRow
    beq title_wait

title_release_wait
    jsr ScanKeyRow
    bne title_release_wait
}

    lda #ROOM_START
    sta map
    lda #8
    sta men
    lda #0
    sta items_collected
    sta willy_hidden
    sta xadd
    sta edge_skip_draw
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
    jmp LoadRoom               ; tail call — LoadRoom draws via DrawPlayerBody
drawmap_first_room
    lda #1
    sta use_room_spawn          ; new game - @spawn from room meta
    jsr LoadRoom
    jsr SaveSpawn
    lda #0
    sta use_room_spawn
    sta initial_room_load
	rts

; row: coord(0=px,1=py), cmp(0=le,1=ge), limit+1 for le / limit for ge, conn, entry_px, entry_py
EDGE_ROW_SIZE = 6

CheckRoomEdge
    ldx #0
-
    lda edge_tbl,x
    bne +
    lda px
    jmp ++
+
    lda py
++
    cmp edge_tbl+2,x
    lda edge_tbl+1,x
    beq +
    bcc edge_next
    bne edge_hit
+
    bcs edge_next
edge_hit
    ldy edge_tbl+3,x
    cpy #3                      ; west conn — exit only at px <= EDGE_WEST_PX
    bne +
    lda px
    cmp #EDGE_WEST_PX + 1
    bcs edge_next
+
    lda meta_content_conn,y   ; conn byte (inlined GetConnByte)
    bmi edge_no_conn
    sta map
    lda edge_tbl+4,x
    sta entry_px
    lda edge_tbl+5,x
    sta entry_py
    jmp do_room_change
edge_no_conn
    bne edge_next               ; Y = conn index; 0 = north (py>=$80), skip south
    beq edge_done
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
    bmi +
    sta px
+
    lda entry_py
    bmi +
    sta py
+
    lda #0
    sta use_room_spawn          ; edge transition - px/py already set, not @spawn
    jsr LoadRoom
    jsr SaveSpawn
    lda #1
    sta edge_skip_draw          ; LoadRoom drew via DrawPlayerBody
edge_done
    lda py
    sta last_py
    rts
