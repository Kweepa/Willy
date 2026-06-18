; unexpanded JSW layout

image_base = $1a58
guardian_sprites_base = $1a58    ; 9 guardian frames x 32 bytes ($1A58-$1B77)
player_bmp = $1b78               ; player frames at indices 9-16 (288 bytes into sprite block)
; Rope runtime in cassette buffer ($033C-$03FB); not persisted across LOAD
ROPE_SEGMENT_Y = $33c            ; 32 B segment Y table ($33C-$35B)
ROPE_XADD = $35c                 ; 54 B horiz shift table ($35C-$391); copied at WarmStart
rope_xadd = ROPE_XADD
meta_content_src = $1f98
; Meta payload at meta_content_src (see build_meta in mkroom.py)
meta_off_guardians = 0
meta_off_border = 1
meta_off_spawn_px = 2
meta_off_spawn_py = 3
meta_off_belt = 4
meta_ramp = $1f9d
meta_ramp_rx1 = $1f9e
meta_ramp_rx2 = $1f9f
meta_ramp_ry = $1fa0
meta_ramp_E = $1fa1
meta_ramp_A = $1fa2
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
tail_base = $1f98
tail_size = $68                  ; 104 bytes ($1F98–$1FFF)
guardian_stride = 6
g_off_x = 0
g_off_y = 6
g_off_min = 12
g_off_max = 18
g_off_vel = 24
g_off_fmin = 30
g_off_fmax = 36
g_off_color = 42
g_off_axis = 48
guardian_g_x = guardian_data_base + g_off_x
guardian_g_y = guardian_data_base + g_off_y
guardian_g_min = guardian_data_base + g_off_min
guardian_g_max = guardian_data_base + g_off_max
guardian_g_vel = guardian_data_base + g_off_vel
guardian_g_fmin = guardian_data_base + g_off_fmin
guardian_g_fmax = guardian_data_base + g_off_fmax
guardian_g_color = guardian_data_base + g_off_color
guardian_g_axis = guardian_data_base + g_off_axis
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
room_image_size = $5a8           ; 1448 bytes ($1A58–$1FFF)
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
