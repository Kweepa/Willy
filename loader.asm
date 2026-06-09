;
; LoadRoom — KERNAL LOAD roomnn PRG to image_base ($1C00), then:
;   copy tiles from tile_src ($1C56) -> screen_base ($1E00)
;   paint color RAM from tile_color_off ($1C50) lookup (types 0-5)
;   copy screen -> map_base ($9400)
;
; PRG image layout (518 bytes at $1C00):
;   +$00  UDG 48
;   +$30  meta slot 32 (u16 len LE + meta + pad)
;   +$50  tile_colors 6 (colour for tile types 0-5)
;   +$56  tiles 432
;
; Debug borders on failure: RED = LOAD/OPEN failed, GREEN = verify failed.
; After a successful load, check VIC: $9002=$98, $9005=$FF (see InitScreen24).
;

room_lfn = 1

room_name
    !text "ROOM00"

LoadRoom
    jsr BuildRoomFilename       ; map -> "ROOM01" .. "ROOM63"
    jsr LoadRoomPrg
    bcc +
    jmp LoadRoomErrorOpen
+
    ; KERNAL LOAD resets VIC to 22-col / ROM charset — restore before using RAM
    jsr InitScreen24
    jsr VerifyRoomUdg           ; $1C00 must be 0 (empty-tile UDG byte)
    bcc +
    jmp LoadRoomErrorScreen
+
    jsr RelocateMetadata        ; Copy $1C30..$1C55 to $1FB0..$1FD5
    jsr PaintColors             ; color = tile_color_off[tile] (384 bytes)
    jsr RelocateCollision       ; $1E00 -> $9400 (384 bytes)
    jsr ParseRoomMeta           ; spawn, conns, border ($900F), items, etc.
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
    jsr $ff86                   ; CLALL — close all open files
    lda #6                      ; SETNAM: filename length
    ldx #<room_name
    ldy #>room_name
    jsr $ffbd                   ; SETNAM — A=len, XY=filename
    lda #room_lfn               ; SETLFS: logical file 1
    ldx #8                      ; SETLFS: device 8 (disk)
    ldy #1                      ; SETLFS: secondary address 1 (LOAD)
    jsr $ffba                   ; SETLFS
    lda #0                      ; LOAD: A=0 load (not verify)
    ldx #<image_base            ; optional load addr if file is not PRG
    ldy #>image_base
    jsr $ffd5                   ; LOAD — carry set on error
    bcs load_fail
    clc
    rts
load_fail
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
    lda tile_color_off,x        ; lookup table at tile_color_off
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

LoadRoomErrorOpen
    jsr InitScreen24
    lda #RED | 8
    sta $900f                   ; border/background
-
    jmp -

LoadRoomErrorScreen
    jsr InitScreen24
    lda #GREEN | 8
    sta $900f
-
    jmp -

; Meta starts at meta_base+$2 (skip u16 length at $1C30)
ParseRoomMeta
    lda #<meta_base+$2
    sta arr
    lda #>meta_base+$2
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
    sta $900f                   ; @bg border colour
    iny
    lda (arr),y
    sta px
    iny
    lda (arr),y
    sta py
    iny
    lda (arr),y
    sta belt_spd
    iny
    lda (arr),y
    sta ramp_type
    iny
    lda (arr),y
    sta ramp_row
    iny
    lda (arr),y
    sta ramp_col
    iny
    lda (arr),y
    sta hguard_count
    iny
    lda (arr),y
    sta vguard_count
    iny
    lda (arr),y
    sta conn_n
    iny
    lda (arr),y
    sta conn_e
    iny
    lda (arr),y
    sta conn_s
    iny
    lda (arr),y
    sta conn_w
    iny
-
    lda (arr),y                 ; skip ASCIZ @title
    iny
    tax                         ; test if A is 0
    bne -
    lda (arr),y
    sta item_count
    iny
    lda item_count
    sta items_left
    sta items_total

    ; Copy items list to items_buf ($D6)
    lda item_count
    beq skip_item_copy
    asl                         ; item_count * 2
    tax
-
    lda (arr),y
    sta items_buf-1,x
    iny
    dex
    bne -
skip_item_copy
    rts

RelocateMetadata
    ldx #37
-   lda $1c30,x
    sta $1fb0,x
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
    asl                         ; Row * 2 (index into x24tab)
    tay
    lda x24tab,y
    sta scr_ptr
    txa
    clc
    adc scr_ptr
    sta scr_ptr
    sta map_ptr
    sta col_ptr
    
    lda x24tab+1,y
    adc #>screen_base
    sta scr_ptr+1
    adc #((>map_base) - (>screen_base))
    sta map_ptr+1
    adc #((>color_base) - (>map_base))
    sta col_ptr+1
    rts

GetCollision
    lda (map_ptr),y
    and #$0f
    rts

DrawLives
    rts
