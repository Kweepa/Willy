ResetGame
    lda #2
    sta map
    lda #3
    sta men
    lda #0
    sta game_time
    sta game_time_hi
    sta items_left
	rts

ResetMap
    lda #0
    sta dead
    sta left_right_ctr
	sta up_down_ctr
	sta belt_active
	rts

DrawMap
	jsr InitMusic
	jsr InitScreen24
	lda #8
	sta $900f
	ldx #20
-
    jsr WaitForRaster
    dex
    bne -
    jsr InitScreen24
    jsr ClearScreen
    lda #0
    sta dead
    lda #51
    sta inairtime
    sta last_py
    jsr LoadRoom
    rts

AnimateBelts
    ; could replace these first two lines with nop or rts which would save 3 bytes
    ; if we already had to populate left_right_ctr from room metadata
    ; alternatively we could stream in the code per room, which would reduce this to 15 bytes
    ; or less if we can combine several functions
    lda left_right_ctr
    bne no_belt_animate
    lda belt_spd
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

TryPickupItem
    lda item_count
    beq exit_pickup
    
    ; Calculate base_col and base_row of Willy
    lda px
    lsr
    lsr
    sta tmp                     ; tmp = base_col = px >> 2
    
    lda py
    sec
    sbc #8
    lsr
    lsr
    and #$fe
    sta tmp+1                   ; tmp+1 = base_row
    
    ; Loop through all items in items_buf
    lda item_count
    asl
    sta tmp+2                   ; tmp+2 = item_count * 2
    
item_loop
    ldy tmp+2
    lda items_buf-2,y           ; col
    cmp #255                    ; already collected?
    beq next_item
    
    ; Check column: is base_col <= item_col <= base_col + 1?
    sec
    sbc tmp                     ; item_col - base_col
    cmp #2                      ; must be 0 or 1
    bcs next_item               ; if >= 2 or negative (bcs works for unsigned < 2), no match
    
    ; Check row: is base_row + 1 <= item_row <= base_row + 3?
    lda items_buf-1,y           ; row
    sec
    sbc tmp+1                   ; item_row - base_row
    cmp #1                      ; must be >= 1
    bcc next_item
    cmp #4                      ; must be < 4 (so 1, 2, or 3)
    bcs next_item
    
    ; COLLISION! We picked up the item!
    ; 1. Convert item row/col to screen addresses and erase before overwriting buffer
    ldy tmp+2
    lda items_buf-2,y           ; col
    tax
    lda items_buf-1,y           ; row
    tay
    jsr ConvertCellToScreenAddr
    
    ldy #0
    lda #TILE_EMPTY             ; Empty tile (0)
    sta (scr_ptr),y             ; Erase from screen
    sta (map_ptr),y             ; Erase from collision map
    lda #BLACK
    sta (col_ptr),y             ; Set background to black
    
    ; 2. Erase item from items_buf
    ldy tmp+2
    lda #255
    sta items_buf-2,y
    sta items_buf-1,y
    
    ; 3. Play beep sound on $900C
    lda #180                    ; beep frequency
    sta $900c
    
    ; 4. Decrement items_left
    dec items_left

next_item
    lda tmp+2
    sec
    sbc #2
    sta tmp+2
    beq exit_pickup
    jmp item_loop

exit_pickup
    rts

GetConnByte
    lda (conn_ptr),y
    rts

; flags: bits 0-1 conn index, bit 2=py (0=px), bit 3=ge (0=eq)
edge_tbl
    !byte $09, EDGE_EAST_PX, EDGE_EAST_ENTRY_PX, $ff
    !byte $03, 0, EDGE_EAST_PX, $ff
    !byte $04, 8, $ff, 112
    !byte $0c, 112, $ff, 16

CheckRoomEdge
    ldx #0
-
    lda edge_tbl,x
    sta tmp+1
    lda edge_tbl+1,x
    sta tmp
    lda tmp+1
    and #$04
    beq +
    lda py
    jmp ++
+
    lda px
++
    pha
    lda tmp+1
    and #$08
    beq +
    pla
    cmp tmp
    bcs edge_hit
    jmp edge_next
+
    pla
    cmp tmp
    bne edge_next
edge_hit
    lda tmp+1
    and #$03
    tay
    jsr GetConnByte
    cmp #$ff
    beq edge_next
    sta map
    lda edge_tbl+2,x
    sta entry_px
    lda edge_tbl+3,x
    sta entry_py
    jmp do_room_change
edge_next
    txa
    clc
    adc #4
    tax
    cpx #16
    bcc -
    jmp edge_done
do_room_change
    jsr LoadRoom
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
    lda #51
    sta inairtime
edge_done
    lda py
    sta last_py
    rts
