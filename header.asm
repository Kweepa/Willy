; unexpanded JSW layout

image_base = $1c00
meta_base = $1fb0
tile_color_off = $1fd0
screen_base = $1e00
map_base = $9400
color_base = $9600
room_image_size = $206
meta_slot_size = $20
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
