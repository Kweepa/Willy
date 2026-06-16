; Boot source tables — copied once at WarmStart to ZP ($D6+) and page $100 ($140+).
; Not read at runtime; game code uses equates in zp.asm.

boot_zp_pack
    !byte $f7, $04, $01, $ef, $02, $ff             ; belt_opp_key_boot / willy.asm do_belt
    !byte 24, 25, 48, 49, 72, 73                    ; cell_off_2x3_boot / util.asm, guardians.asm
    !byte EDGE_WEST_PX, EDGE_EAST_PX                ; lr_edge_px_boot / willy.asm CollideLeftRight
    !byte 23, 25, 47, 49, 71, 73                    ; lr_touch_a_boot / willy.asm CollideLeftRight
    !byte 0, 3, 1, 4, 2, 5                            ; draw_vguard_chrs_boot / guardians.asm
boot_draw_player_offsets
    !byte 24, 48, 72, 25, 49, 73                    ; willy.asm DrawPlayer
boot_draw_player_chrs
    !byte PLAY_CHR, PLAY_CHR+1, PLAY_CHR+2, PLAY_CHR+3, PLAY_CHR+4, PLAY_CHR+5
boot_zp_pack_end = *

boot_zp_room_size = boot_draw_player_offsets - boot_zp_pack

boot_page_pack
    ; edge_tbl_boot / map.asm
    !byte 0, 1, EDGE_EAST_PX, 1, EDGE_EAST_ENTRY_PX, $ff  ; east
    !byte 0, 0, EDGE_WEST_PX + 1, 3, EDGE_WEST_ENTRY_PX, $ff ; west
    !byte 1, 0, 3, 0, $ff, 103                            ; up
    !byte 1, 1, 107, 2, $ff, 4                            ; down
    ; x24rowtab_boot
    !word screen_base - 24
    !word screen_base + 0
    !word screen_base + 24
    !word screen_base + 48
    !word screen_base + 72
    !word screen_base + 96
    !word screen_base + 120
    !word screen_base + 144
    !word screen_base + 168
    !word screen_base + 192
    !word screen_base + 216
    !word screen_base + 240
    !word screen_base + 264
    !word screen_base + 288
    !word screen_base + 312
    !word screen_base + 336
    !word screen_base + 360
    !word screen_base + 384
    ; jumptab_boot / willy.asm Collide
    !byte -2, -1, -2, -1, -2, -1, -1, -1, -2, -1, -1, 0, -1, -1, -1, 0, -1, 0, -1, 0, 0, -1, 0, 0, 0, 0, 0
    !byte 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 2, 1, 1, 1, 2, 1, 2, 1, 2
boot_page_pack_end = *

boot_zp_size = boot_zp_pack_end - boot_zp_pack
!if boot_zp_size <> 38 {
!error "boot_zp_size must be 38"
}
!if boot_zp_room_size <> 26 {
!error "boot_zp_room_size must be 26"
}

boot_page_size = boot_page_pack_end - boot_page_pack
!if boot_page_size <> 114 {
!error "boot_page_size must be 114"
}
