;
; LoadRoom - KERNAL LOAD R00 PRG to image_base ($1A78), then:
;   paint color RAM from tile_color_src lookup (tile types 0-5)
;   paint map_base ($9400): store tile type 0-5 (low nybble of screen chr 16-21);
;     map_base is VIC colour RAM — only low nybble valid; read with AND #$0f
;   draw item chr 15 separately (DrawItem) — not in tilemap
;
; PRG image layout (1416 bytes at $1A78):
;   +$000 guardian sprites 256 @ $1A78
;   +$100 player_bmp 256 @ $1B78
;   +$200 tile UDG 56 @ $1C78 (chr 15-21)
;   +$238 runtime pad 336 ($1CB0-$1DFF)
;   +$388 screen 408 @ $1E00 (24x17)
;   +$520 tail 104 @ $1F98 (meta, colors, guardian SoA)
;

room_lfn = 15

room_name
    !text "R00"

FormatRoomName
    lda map
    ldy #'0'
-
    cmp #10
    bcc +
    sbc #10
    iny
    bne -
+
    adc #'0'
    sta room_name+2
    sty room_name+1
    rts

LoadRoom
    jsr FormatRoomName
    sei
    lda #3
    ldx #<room_name
    ldy #>room_name
    jsr $ffbd                    ; SETNAM — filename length in A, ptr in XY
    lda #room_lfn
    ldx #8                       ; device 8 (disk)
    ldy #1                       ; secondary address 1
    jsr $ffba                    ; SETLFS — logical file number in A, device in X, SA in Y
    lda #0                       ; LOAD to RAM (not VERIFY)
    jsr $ffd5                    ; LOAD — uses SETNAM/SETLFS; loads file to RAM
    sei                          ; KERNAL LOAD leaves IRQs enabled
    jsr ParseRoomMeta
    jsr PaintColors
    jsr DrawItem
    ; jsr DrawHud
    jsr DrawPlayer
    rts

PaintColors
    ldy #0
-
    lda screen_base,y
    sta map_base,y
    and #$0f
    tax
    lda tile_color_src,x
    sta color_base,y
    lda screen_base+$80,y
    sta map_base+$80,y
    and #$0f
    tax
    lda tile_color_src,x
    sta color_base+$80,y
    iny
    bne -

    ldy #24
    lda #7
-
    sta color_base + 383,y
    dey
    bne -
    rts

DrawItem
    lda items_left
    beq draw_item_done
    jsr item_draw
draw_item_done
    rts

;
; ParseRoomMeta - read room meta at meta_content_src ($1F98).
; Layout: guardians, border, spawn x2, belt, ramp, rx1, rx2, ry, E, A, conn x4, item draw code
ParseRoomMeta
    lda meta_content_src + meta_off_border
    sta $900f
    lda use_room_spawn
    beq skip_room_spawn
    lda meta_content_src + meta_off_spawn_px
    sta px
    lda meta_content_src + meta_off_spawn_py
    sta py
skip_room_spawn
    lda #1
    sta items_left
    lda #27
    sta inairtime
    lda #1
    sta on_ground
    sta was_on_ground
    lda py
    sta last_py
    rts

SetupMapColFromScr
    lda scr_ptr
    sta map_ptr
    sta col_ptr
    lda scr_ptr + 1
    clc
    adc #>(map_base - screen_base)
    sta map_ptr + 1
    clc
    adc #>(color_base - map_base)
    sta col_ptr + 1
    rts

ConvertCellToScreenAddr
    tya
    asl
    tay
    lda x24rowtab + 2,y
    sta scr_ptr
    lda x24rowtab + 3,y
    sta scr_ptr + 1
    txa
    clc
    adc scr_ptr
    sta scr_ptr
    bcc +
    inc scr_ptr + 1
+
    jmp SetupMapColFromScr

GetCollision
    lda (map_ptr),y
    and #$0f
    rts
