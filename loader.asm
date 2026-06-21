;
; LoadRoom - KERNAL LOAD R00 PRG to image_base ($1A10), then:
;   paint color RAM from tile_color_src lookup (tile types 0-5)
;   paint map_base ($9400): store tile type 0-5 (low nybble of screen chr 16-21);
;     map_base is VIC colour RAM — only low nybble valid; read with AND #$0f
;   draw item chr 15 separately (DrawItem) — not in tilemap
;
; PRG image layout (1520 bytes at $1A10, ends $1FFF):
;   +$000 AnimateConveyors 19 @ $1A10
;   +$013 DoBelt 31 @ $1A23
;   +$032 tile colours 6 @ $1A42
;   +$038 guardian sprites 288 @ $1A48
;   +$158 player_bmp 256 @ $1B68       (title room: logo UDGs span from $1C00)
;   +$258 HUD UDG 16 @ $1C68 (chr 13-14)
;   +$268 tile UDG 56 @ $1C78 (chr 15-21)
;   +$280 runtime pad 336 ($1CB0-$1DFF)
;   +$3F0 screen 408 @ $1E00 (24x17)
;   +$588 tail 104 @ $1F98 (meta, guardian AoS)
;

room_lfn = 15

room_name
    !text "R00"

LoadRoom
    ; Clear KERNAL serial scratch before the IEC LOAD (matters under True Drive
    ; Emulation). rope_udg_mem ($94/$95) overlaps C3PO/BSOUR: each rope frame
    ; leaves a charset pointer in $94, and on the swing phases where the rope is
    ; long enough that pointer has bit 7 set. C3PO ($94) is the KERNAL "serial
    ; output char buffered" flag tested by TALK; with bit 7 set the LOAD sends a
    ; stray byte, desyncs the IEC bus, the drive times out (ST=$80) and the room
    ; never loads — leaving stale rope chars that PaintColors paints as
    ; multicolour corruption. Only bites when a death/room-change lands on a
    ; bit-7 swing phase, hence the "specific spot" symptom. Under fs-trap
    ; (virtual device) the serial code never runs, so this only shows with TDE.
    ; $90 ST error bits also abort LOAD early if left dirty. Harmless to clear:
    ; $90-$93 unused by game; rope state at $94-$9F re-inited by ParseRoomMeta.
    lda #0
    sta $90
    sta $94
    sta $95
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

    jsr ParseRoomMeta

    lda map
    cmp #ROOM_TITLE
    bne +
    rts
+

.paint_colours
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

.draw_item
    ldx map
    lda pickup_got,x
    bne +
    jsr item_draw
+

    jmp DrawPlayerBody


;
; Layout: guardians, border, spawn x2, belt, ramp, rx1, rx2, ry, E, A, conn x4, item draw;
;         meta_off_rope, guardian AoS
ParseRoomMeta
    lda meta_content_src + meta_off_border
    sta $900f
    lda meta_content_src + meta_off_rope
    sta room_has_rope

    ; minimal rope/conveyor clear
    ldx #0
    stx belt_active
    stx rope_willy_is_holding
    stx rope_udg
    stx rope_frame
    stx rope_grab_cooldown ; allow immediate grab on entering a rope room
    stx rope_swing_side ; this needs to be 0 or 1
    inx
    stx rope_swing_dir ; this needs to be -1 or 1

    ; spawn at position set in the room meta data?
    ; otherwise px and py are already set up (from room transition)
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
    jsr ApplyEndgameRoomLoad
    rts
