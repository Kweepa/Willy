;
; LoadRoom — KERNAL LOAD roomnn PRG to image_base ($1C00), then:
;   paint color RAM from tile_color_off lookup (types 0-5)
;   copy screen -> map_base ($9400)
;
; PRG image layout (992 bytes at $1C00):
;   +$00  UDG 56 (tile types 0-5 + item at 6)
;   +$38  reserved 48
;   +$68  tile_colors 6 (colour for tile types 0-5)
;   +$6E  padding 402
;   +$200 tiles 384 + room_name 24
;   +$398 UI pad 24 ($1F98)
;   +$3B0 meta slot 48 (u16 len LE + meta + pad) @ $1FB0
;

room_lfn = 15                 ; not 1 — BASIC reserves low LFNs after SYS

room_name
    !text "ROOM00"

LoadRoom
    jsr BuildRoomFilename       ; map -> "ROOM01" .. "ROOM63"
    jsr LoadRoomPrg
    bcc +
    jmp LoadRoomError
+
    ; KERNAL LOAD resets VIC to 22-col / ROM charset — restore before using RAM
    jsr InitScreen24
    jsr VerifyRoomUdg           ; $1C00 must be 0 (empty-tile UDG byte)
    bcc +
    jmp LoadRoomError
+
    jsr ParseRoomMeta           ; spawn, ramp, items from meta in loaded image ($1C3A)
    jsr RelocateMetadata        ; Optional copy to $1FB0 for fast-loader path
    jsr PaintColors             ; color = tile_color_src[tile] (384 bytes)
    jsr RelocateCollision       ; $1E00 -> $9400 (384 bytes)
    jsr DrawItems               ; draw collectibles on screen
    jsr InitPlayerUDGs          ; player sprites into $1C00+$1D00 area
    jsr DrawPlayer
    jsr InitScreen24            ; belt-and-braces after all setup
    rts

BuildRoomFilename
    lda #'0'
    sta room_name+4             ; tens digit fixed '0' for rooms 1-9
    lda map
    ora #'0'                    ; ones digit: 1 -> '1', etc.
    sta room_name+5
    rts

; LOAD "ROOMnn",8,1 — PRG 2-byte header sets load address to $1C00
LoadRoomPrg
    sei
    jsr $ff86                   ; CLALL — close all open files
    jsr $ffcc                   ; CLRCHN — clear IEC channel
    lda #6                      ; SETNAM: filename length
    ldx #<room_name
    ldy #>room_name
    jsr $ffbd                   ; SETNAM — A=len, XY=filename
    lda #room_lfn
    ldx #8
    ldy #1                      ; SA 1 for LOAD ",8,1"
    jsr $ffba                   ; SETLFS
    lda #0                      ; LOAD: A=0 load (not verify)
    ldx #<image_base            ; optional load addr if file is not PRG
    ldy #>image_base
    jsr $ffd5                   ; LOAD — carry set on error
    cli
    bcs load_fail
    clc
    rts
load_fail
    cli
    sec
    rts

; First byte of tile-0 UDG at $1C00 should be 0 after a valid room PRG
VerifyRoomUdg
    lda udg_base
    beq +
    sec
    rts
+
    clc
    rts

; Dummy VerifyScreenTiles for backward compatibility or future use
VerifyScreenTiles
    clc
    rts

; For each screen cell: color RAM byte = tile_color_off[tile type 0-5]
PaintColors
    ldy #0
-
    lda screen_base,y
    tax
    lda tile_color_src,x
    sta color_base,y
    iny
    bne -
    ldy #0
--
    lda screen_base+$100,y
    tax
    lda tile_color_off,x
    sta color_base+$100,y
    iny
    cpy #$80                  ; 256 + 128 = 384 bytes (16 rows)
    bne --

    ldy #24
    lda #7
-
    sta color_base + 383,y
    dey
    bne -
    rts

RelocateCollision
    ldy #0
-
    lda screen_base,y
    sta map_base,y
    iny
    bne -
    ldy #0
--
    lda screen_base+$100,y
    sta map_base+$100,y
    iny
    cpy #$80                  ; 256 + 128 = 384 bytes (16 rows)
    bne --
    rts

LoadRoomError
-
    jmp -

; Meta content in loaded room image (skip u16 length at meta_slot_src)
ParseRoomMeta
    lda #<meta_content_src
    sta arr
    lda #>meta_content_src
    sta arr+1
    ldy #0
    lda (arr),y                 ; guardian count
    beq meta_bg_zero
    tax
    iny                         ; Y points to first guardian record (index 1)
skip_guardians
    tya
    clc
    adc #7                      ; skip 7-byte guardian record
    tay
    dex
    bne skip_guardians
    jmp meta_bg

meta_bg_zero
    ldy #1
meta_bg
    lda (arr),y
    ora #8                      ; Ensure Normal Mode (bit 3 set to 1)
    sta $900f                   ; @border colour
    iny
    lda use_room_spawn
    beq skip_room_spawn
    lda (arr),y
    sta px
    iny
    lda (arr),y
    sta py
    iny
    jmp spawn_meta_done
skip_room_spawn
    iny
    iny
spawn_meta_done
    lda (arr),y
    sta belt_spd
    iny
    lda (arr),y
    sta ramp_type
    iny
    lda (arr),y
    sta hguard_count
    iny
    lda (arr),y
    sta vguard_count
    iny
    tya
    clc
    adc arr
    sta conn_ptr
    lda arr+1
    adc #0
    sta conn_ptr+1
    tya
    clc
    adc #4
    tay
    lda (arr),y
    sta item_count
    iny
    lda item_count
    sta items_left
    sta items_total

    ; Copy items list to items_buf ($D6): col, row pairs per item
    lda item_count
    beq skip_item_copy
    sta num
    ldx #0
-
    lda (arr),y
    sta items_buf,x
    iny
    lda (arr),y
    sta items_buf+1,x
    iny
    inx
    inx
    dec num
    bne -
skip_item_copy
    lda #0
    sta inairtime
    lda #1
    sta on_ground
    sta was_on_ground
    rts

RelocateMetadata
    ldx #meta_slot_size - 1
-
    lda meta_slot_src,x
    sta meta_base,x
    dex
    bpl -
    ldx #tile_color_bytes - 1
-
    lda tile_color_src,x
    sta meta_base + meta_slot_size,x
    dex
    bpl -
    rts

DrawItems
    lda item_count
    beq no_items
    asl
    sta tmp                     ; tmp = count * 2
-
    ldy tmp
    lda items_buf-2,y           ; item column
    tax
    lda items_buf-1,y           ; item row
    tay
    jsr ConvertCellToScreenAddr ; Convert (col X, row Y) to addresses
    
    ldy #0
    lda #ITEM_CHR               ; character 67
    sta (scr_ptr),y             ; draw on screen
    sta (map_ptr),y             ; add to collision map
    lda #YELLOW
    sta (col_ptr),y             ; set yellow color
    
    lda tmp
    sec
    sbc #2
    sta tmp
    bne -
no_items
    rts

ConvertCellToScreenAddr
    ; Input: X = column, Y = row
    ; Output: scr_ptr, map_ptr, col_ptr
    tya
    asl                         ; row << 1 → index into x24rowtab+2
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

GetCollision
    lda (map_ptr),y
    and #$0f
    rts

DrawLives
    rts
