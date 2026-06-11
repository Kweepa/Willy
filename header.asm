; unexpanded JSW layout

image_base = $1b00
guardian_sprites_base = $1b00    ; 256 bytes: up to 8 guardian frames x 32 bytes
meta_slot_src = $1fb0
meta_content_src = meta_slot_src + 2
; Meta payload layout at meta_content_src (see build_meta in mkroom.py)
meta_off_guardians = 0
meta_off_border = 1
meta_off_spawn_px = 2
meta_off_spawn_py = 3
meta_off_belt = 4
meta_off_ramp = 5
meta_off_conn = 6
tile_color_off = $1c68
tile_color_src = tile_color_off
screen_base = $1e00
map_base = $9400
color_base = $9600
room_image_size = $4e0           ; 1248 bytes
meta_slot_size = $30             ; 48 bytes: u16 len + meta + pad
tile_color_bytes = 7
guardian_data_base = $1c6f       ; after 7 tile colour bytes at $1C68
guardian_record_bytes = 8
max_guardians = 6

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
    jsr WarmStart
