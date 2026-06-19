; unexpanded JSW layout

image_base = $1a14                    ; -16 vs $1A24: HUD UDG chr 13-14; pad pins screen -> $1E00
conveyor_prefix_bytes = 19
do_belt_prefix_bytes = 33
AnimateConveyors = image_base
DoBelt = image_base + conveyor_prefix_bytes
guardian_sprites_base = image_base + conveyor_prefix_bytes + do_belt_prefix_bytes
guardian_prefix_bytes = guardian_sprites_base - image_base
player_bmp = guardian_sprites_base + 288
hud_udg_base = player_bmp + 256         ; chr 13-14 @ $1C68-$1C77
runtime_udg_pad = $150                  ; 336 B ($1CB0-$1DFF); pins screen_base after load

; Relocated resident code (copied from boot zone at WarmStart)
RELOC_A_BASE = $0200
RELOC_A_LIMIT = $0259
RELOC_B_BASE = $0392
RELOC_B_LIMIT = $03fc
RELOC_C_BASE = $0334
RELOC_C_LIMIT = $033c
RELOC_D_BASE = $1000
RELOC_D_LIMIT = $100d

; Rope runtime in cassette buffer ($033C-$03FB); survives KERNAL disk LOAD
ROPE_SEGMENT_Y = $33c            ; 32 B segment Y table ($33C-$35B)
ROPE_XADD = $35c                 ; 54 B horiz shift table ($35C-$391); copied at WarmStart
rope_xadd = ROPE_XADD
room_image_size = $5ec           ; 1516 bytes ($1A14-$1FFF); +16 HUD UDG chr 13-14
tail_size = $68                  ; 104 bytes at end of room image
meta_content_src = image_base + room_image_size - tail_size

; Meta payload at meta_content_src (see build_meta in mkroom.py)
meta_off_guardians = 0
meta_off_border = 1
meta_off_spawn_px = 2
meta_off_spawn_py = 3
meta_off_belt = 4
meta_ramp = meta_content_src + 5
meta_ramp_rx1 = meta_content_src + 6
meta_ramp_rx2 = meta_content_src + 7
meta_ramp_ry = meta_content_src + 8
meta_ramp_E = meta_content_src + 9
meta_ramp_A = meta_content_src + 10
meta_off_conn = 11
meta_off_item_draw = 15         ; 16-byte 6502: lda #chr sta scr lda #col sta col lda #TILE_ITEM sta map rts
meta_off_item_draw_size = 16
meta_size = 31
meta_off_rope = 31
meta_off_tilecolors = 32
meta_off_guardian_data = 38
item_draw = meta_content_src + meta_off_item_draw
tile_color_src = meta_content_src + meta_off_tilecolors
guardian_data_base = meta_content_src + meta_off_guardian_data
tail_base = meta_content_src
guardian_record_bytes = 9
g_off_x = 0
g_off_y = 1
g_off_min = 2
g_off_max = 3
g_off_vel = 4
g_off_fmin = 5
g_off_fmax = 6
g_off_color = 7
g_off_axis = 8
screen_base = $1e00
ROPE_ANCHOR_SCR = screen_base + ROPE_ANCHOR_COL
ROPE_FIRST_UDG_ADDRESS = udg_base + ROPE_FIRST_UDG * 8
tile_bytes = 408                 ; 24 x 17
hud_row_off = 384                ; row 16 * 24
hud_men_scr = screen_base + hud_row_off + 18
hud_men_col = color_base + hud_row_off + 18
hud_men_count_scr = screen_base + hud_row_off + 19
hud_item_scr = screen_base + hud_row_off + 21
hud_item_col = color_base + hud_row_off + 21
hud_items_scr = screen_base + hud_row_off + 22
hud_items_col = color_base + hud_row_off + 22
map_base = $9400
color_base = $9600
tile_color_bytes = 6
guardian_data_bytes = 54
max_guardians = 6

pickup_got = $100
pickup_got_last = pickup_got + $3d

basic_start = $1000

; basic header
*=basic_start-1
	!word basic_start+1
    !word basic_end
	!word 10
	!byte $9e
	!text "4109"
	!byte 0
basic_end
	!word 0

cold_start
warm_start
    jmp WarmStart
