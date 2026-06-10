; unexpanded JSW layout

image_base = $1c00
meta_slot_off = $3b0             ; $1FB0 — above HUD row 17 (mkroom META_OFF 944)
meta_slot_src = image_base + meta_slot_off
meta_content_src = meta_slot_src + 2
meta_base = $1fb0                ; copy destination for fast-loader path
tile_color_off = image_base + $68 ; $1C68 (mkroom TILE_COLOR_OFF 88)
tile_color_src = tile_color_off
screen_base = $1e00
map_base = $9400
color_base = $9600
room_image_size = $3e0           ; 992 bytes
meta_slot_size = $30             ; 48 bytes: u16 len + meta + pad (mkroom META_SLOT_BYTES)
tile_color_bytes = 6

hguard_bmp = $1900
vguard_bmp = $1980

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

    sei

    lda #$7f
    sta $911d
    sta $911e

    cld
    ldx #$ff
    txs

    jsr $fdf9                   ; RAMTAS — RAM test / BASIC pointers
    jsr $e518                   ; BASIC init (screen defaults)

	jsr InitScreen24            ; 24-col before game/title

    cli
