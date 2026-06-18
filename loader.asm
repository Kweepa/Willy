;
; LoadRoom - KERNAL LOAD R00 PRG to image_base ($1A45), then:
;   paint color RAM from tile_color_src lookup (tile types 0-5)
;   paint map_base ($9400): store tile type 0-5 (low nybble of screen chr 16-21);
;     map_base is VIC colour RAM — only low nybble valid; read with AND #$0f
;   draw item chr 15 separately (DrawItem) — not in tilemap
;
; PRG image layout (1467 bytes at $1A45):
;   +$000 conveyor animate 19 @ $1A45 (baked per room; jsr AnimateConveyors)
;   +$013 guardian sprites 288 @ $1A58 (9 frames x 32)
;   +$133 player_bmp 256 @ $1B78 (chr 7 UDG @$1C38 = bmp+$c0, HUD head icon)
;   +$233 tile UDG 56 @ $1C78 (chr 15-21)
;   +$24B runtime pad 336 ($1CB0-$1DFF)
;   +$39B screen 408 @ $1E00 (24x17)
;   +$533 tail 104 @ $1F98 (meta, colors, guardian SoA)
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

DrawHud
    lda items_collected
    ldy #$b0
-
    cmp #10
    bcc +
    sbc #10
    iny
    bne -
+
    sty hud_items_scr
    clc
    adc #$b0
    sta hud_items_scr+1

    lda men
    clc
    adc #$b0
    sta hud_men_count_scr
    rts

LoadRoom
    ; clear colors
    lda #0
    ldx #192
-
    sta $95ff,x
    sta $96bf,x
    dex
    bne -

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
    ldx map
    lda pickup_got,x
    bne draw_item_done
    jsr item_draw
draw_item_done
    rts

;
; Layout: guardians, border, spawn x2, belt, ramp, rx1, rx2, ry, E, A, conn x4, item draw;
;         meta_off_rope, tilecolors, guardian SoA
ParseRoomMeta
    lda meta_content_src + meta_off_border
    sta $900f
    lda meta_content_src + meta_off_rope
    sta room_has_rope
    beq parse_clear_rope_hold
    lda #0
    sta rope_frame
    sta rope_swing_side
    sta rope_willy_is_holding
    sta rope_grab_cooldown
    sta rope_udg
    sta rope_loop_count
    lda #1
    sta rope_swing_dir
    ldx #31
-
    lda #0
    sta rope_old_screen_pos,x
    sta ROPE_SEGMENT_Y,x
    dex
    bpl -
    jmp parse_room_spawn
parse_clear_rope_hold
    lda #0
    sta rope_willy_is_holding
parse_room_spawn
    lda use_room_spawn
    beq skip_room_spawn
    lda meta_content_src + meta_off_spawn_px
    sta px
    lda meta_content_src + meta_off_spawn_py
    sta py
skip_room_spawn
    lda #27
    sta inairtime
    lda #1
    sta on_ground
    sta was_on_ground
    lda py
    sta last_py
    rts

GetCollision
    lda (map_ptr),y
    and #$0f
    rts
