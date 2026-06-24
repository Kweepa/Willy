;
; LoadRoom - KERNAL LOAD R00 PRG to image_base ($1A02), then:
;   paint color RAM from tile_color_src lookup (tile types 0-5)
;   paint map_base ($9400): store tile type 0-5 (low nybble of screen chr 16-21);
;     map_base is VIC colour RAM — only low nybble valid; read with AND #$0f
;   draw item chr 15 separately (DrawItem) — not in tilemap
;
; PRG image layout (1534 bytes at $1A02, ends $1FFF):
;   +$000 FlickerItem 16 @ $1A02
;   +$010 AnimateConveyors 19 @ $1A12
;   +$023 DoBelt 29 @ $1A25
;   +$040 tile colours 6 @ $1A42
;   +$046 guardian sprites 288 @ $1A48
;   +$166 player_bmp 256 @ $1B68       (title room: logo UDGs span from $1C00)
;   +$266 HUD UDG 16 @ $1C68 (chr 13-14)
;   +$276 tile UDG 56 @ $1C78 (chr 15-21)
;   +$280 runtime pad 336 ($1CB0-$1DFF)
;   +$3F0 screen 408 @ $1E00 (24x17)
;   +$588 tail 104 @ $1F98 (meta, guardian AoS)
;

room_lfn = 15

room_name
    !text "R00"

LoadRoom
    lda #0
    jsr SetColors

    jsr FormatRoomName

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

    lda meta_content_border
    sta $900f

     ; shut off sound effects
    ldx #0
    stx $900c

    ; minimal rope/conveyor/ramp clear
    stx belt_active
    stx is_on_ramp
    stx rope_willy_is_holding
    stx rope_udg
    stx rope_frame
    stx rope_grab_cooldown ; allow immediate grab on entering a rope room
    stx rope_swing_side ; this needs to be 0 or 1
    inx
    stx rope_swing_dir ; this needs to be -1 or 1

    stx on_ground
    stx was_on_ground

    ; spawn at position set in the room meta data?
    ; otherwise px and py are already set up (from room transition)
    lda use_room_spawn
    beq +
    lda meta_content_spawn_px
    sta px
    lda meta_content_spawn_py
    sta py
+
    ; must be after px is set
    jsr calculate_ramp_y

    lda #27
    sta inairtime
    lda py
    sta last_py

    ; special map cases
    lda map
    cmp #ROOM_TITLE
    bne +
    rts
+
    ; check for endgame - turn off Maria if conditions are met
    cmp #ROOM_MASTER_BED
    bne +
    lda items_collected
    cmp #ITEMS_REQUIRED
    bcc +
    lda #0
    sta meta_content_guardians
+

    ; paint screen colours
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

    ; draw item
    ldx map
    lda pickup_got,x
    bne +
    jsr item_draw
+
    rts
