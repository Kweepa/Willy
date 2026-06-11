;
; LoadRoom - KERNAL LOAD roomnn PRG to image_base ($1B00), then:
;   paint color RAM from tile_color_off lookup (types 0-6)
;   copy screen -> map_base ($9400)
;
; PRG image layout (1248 bytes at $1B00):
;   +$000 guardian sprites 256
;   +$100 UDG 56 (tile types 0-5 + item at 6) @ $1C00
;   +$138 reserved 48
;   +$168 tile_colors 7 @ $1C68
;   +$16F guardian data 48 @ $1C6F (live state, mutated at runtime)
;   +$19F padding 353
;   +$300 tiles 384 + room_name 24 @ $1E00 (item chr 6 stamped from @items)
;   +$498 UI pad 24 ($1F98)
;   +$4B0 meta slot 48 @ $1FB0
;

room_lfn = 15                 ; not 1 - BASIC reserves low LFNs after SYS

room_name
    !text "R0"                  ; byte 1 = map | '0'

LoadRoom
    lda map
    ora #'0'
    sta room_name+1
    sei
    jsr $ff86                   ; CLALL - close all open files
    jsr $ffcc                   ; CLRCHN - clear IEC channel
    lda #2                      ; SETNAM: "RX" length
    ldx #<room_name
    ldy #>room_name
    jsr $ffbd                   ; SETNAM - A=len, XY=filename
    lda #room_lfn
    ldx #8
    ldy #1                      ; SA 1 for LOAD ",8,1"
    jsr $ffba                   ; SETLFS
    lda #0                      ; LOAD: A=0 load (not verify); SA=1 uses PRG header addr
    jsr $ffd5                   ; LOAD - carry set on error
    cli
    jsr ParseRoomMeta           ; border, spawn; belt/ramp/conn read in place
    jsr PaintColors             ; color RAM from tiles + screen -> map_base
    ; DrawPlayer copy_udg initialises player_udg at $1DD0 from screen tiles
    jsr DrawPlayer
    rts

; 256 iterations x 2 ($00 and $80 offsets): paint color RAM and screen -> map_base
PaintColors
    ldy #0
-
    lda screen_base,y
    tax
    sta map_base,y
    lda tile_color_src,x
    sta color_base,y
    lda screen_base+$80,y
    tax
    sta map_base+$80,y
    lda tile_color_src,x
    sta color_base,y
    iny
    bne -

    ldy #24
    lda #7
-
    sta color_base + 383,y
    dey
    bne -
    rts

;
; ParseRoomMeta - read room meta in place at meta_content_src ($1FB2).
; Item is tile chr 6 in room tilemap; items_left tracks collected state.
; Layout: guardians, border, spawn x2, belt, ramp, conn x4
ParseRoomMeta
    lda meta_content_src + meta_off_border
    ora #8                      ; Ensure Normal Mode (bit 3 set to 1)
    sta $900f                   ; @border colour
    lda use_room_spawn
    beq skip_room_spawn
    lda meta_content_src + meta_off_spawn_px
    sta px
    lda meta_content_src + meta_off_spawn_py
    sta py
skip_room_spawn
    lda #1
    sta items_left
    lda #0
    sta inairtime
    lda #1
    sta on_ground
    sta was_on_ground
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
    ; Input: X = column, Y = row
    ; Output: scr_ptr, map_ptr, col_ptr
    tya
    asl                         ; row << 1 -> index into x24rowtab+2
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
