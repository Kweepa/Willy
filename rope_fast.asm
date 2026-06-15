; zero page assignments - need the rest of the zp to fit around this
rope_udg = $6a ; (0..23-ish)
rope_frame = $6b ; (0..53)
rope_swing_side = $6c ; (0 or 1)
rope_swing_dir = $6d ; (-1 or 1)
rope_screen_pos = $6e ; and $6f
rope_bit = $70 ; only one bit set - the pixel that draws
rope_y = $71 ; (0..7, index in current UDG)
rope_udg_mem = $72 ; and $73, current UDG mem address
rope_index = $74 ; used during the drawing loop, rope_frame + i
rope_udg_advance = $75 ; used during drawing loop to specify whether to advance the UDG (screen x or y changed)
rope_old_screen_pos = $76 ; 48 byte address table
rope_segment_y = $a6 ; 32 byte y value for segment
rope_willy_is_holding = $c6 ; whether willy is grabbing the rope
rope_willy_seg = $c7 ; which segment willy is holding
rope_segment_cur_x = $c8 ; segment willy's holding x value
rope_segment_cur_y = $c9 ; segment willy's holding y value
rope_seg_skip_above = $ca; precomputed: stop tracking cur x/y when rope_loop_count >= this
rope_loop_count = $cb

ROPE_FIRST_UDG = 32
ROPE_FIRST_UDG_ADDRESS = $1c00 + 32*8

; willy grabs the rope the same way he collides with other items, by checking the UDG while drawing
; so in this case, we'd detect a collision, then use the rope_segment_y table to match willy's y with a segment
; then if holding the rope, move willy to the coordinates of that segment

rope_xadd
	; These values determine how much to rotate the rope drawing byte (which in turn determines the x-coordinate at which each segment of rope is drawn)
    ; note, this is backwards so we can loop backwards over it
    !byte 1,2,3,2,2,2,3,1
    !byte 2,2,2,2,0,1,2,0
    !byte 1,2,1,1,1,2,1,2
    !byte 1,2,1,2,1,2,1,2
    !byte 1,2,1,2,1,2,1,2
    !byte 1,2,1,2,1,0,1,1
    !byte 1,1,1,0,1,1
;    !byte 0,0,0,0,0,0,0,0 ; these 0s are implied in the code
;    !byte 0,0,0,0,0,0,0,0
;    !byte 0,0,0,0,0,0,0,0
;    !byte 0,0,0,0,0,0,0,0
rope_xadd_end

; ===========================================================================

rope_clear_pre_player_draw

; clear the rope UDGs from the screen memory
; no need to clear color as we're using white for both the rope and the player
    lda rope_udg
    asl
    tax
-
    lda #15 ; empty tile
    sta (rope_old_screen_pos,x) ; valid 6502, intended for tables of addresses in ZP
    dex
    dex
    bne -
    rts

; ===========================================================================

rope_draw

; first clear the old rope

    ldx #127 ; tweak this based on max num udgs that can be used
-
    sta ROPE_FIRST_UDG_ADDRESS,x
    dex
    bpl -

; then advance the rope frame
; we need the index to go from 0 to 53, then back to 0 for a right swing
; then from 0 to 53, and back to 0 for a left swing (with rope_xadd interpreted as negative)
; rope_swing_dir determines this

    lda rope_frame
    clc
    adc rope_swing_dir
    sta rope_frame
    cmp #0
    beq +
    cmp #53
    beq ++
    bne +++
+
    lda rope_swing_side
    eor #1
    sta rope_swing_side
++
    lda rope_swing_dir
    eor #$ff
    clc
    adc #1
    sta rope_swing_dir
+++

; now step through the rope segments and draw them

; rope_udg starts at 0
; screen_pos starts at $1e00+12
; rope_bit starts at $80

    ; since we're starting with the first UDG,
    ; fill in the first entry in the old_screen_pos table immediately to $1e12 (y=0,x=12)
    lda #12
    sta rope_screen_pos
    sta rope_old_screen_pos
    lda #$1e
    sta rope_screen_pos+1
    sta rope_old_screen_pos+1
    ; write the first actual rope UDG to the screen
    ldy #0
    lda #ROPE_FIRST_UDG
    sta (rope_screen_pos),y
    lda #$80
    sta rope_bit
    lda #0
    sta rope_y
    sta rope_udg
    sta rope_loop_count
    ; write address $1d00
    sta rope_udg_mem
    lda #$1d
    sta rope_udg_mem+1

    ; anchor: col 12 = 96 VIC px; row 0 = py 8 (ROPE_ANCHOR_PY — top of willy 16px hitbox)
    lda #96
    sta rope_segment_cur_x
    lda #8
    sta rope_segment_cur_y

    ; calculate loop count to stop storing segment x,y
    lda #32
    sta rope_seg_skip_above
    lda rope_willy_is_holding
    beq +
    lda rope_willy_seg
    clc
    adc #1
    sta rope_seg_skip_above
+

    ; loop rope_frame..rope_frame+31 backwards; rope_loop_count = segment 0..31 (0=anchor, 31=tip)
    lda rope_frame
    clc
    adc #31
    sta rope_index
--
    lda #0
    sta rope_udg_advance

    ; shift rope_bit by xadd in an x loop
    ldx rope_index
    cpx #(rope_xadd_end - rope_xadd) ; 0 implied after the end of the table
    bpl +++
    lda rope_xadd,x
    beq +++
    tax
    ldy rope_swing_side
    beq ++
-
    lda rope_loop_count
    cmp rope_seg_skip_above
    bcs +
    dec rope_segment_cur_x
+
    asl rope_bit
    bcc +
    rol rope_bit
    lda #1
    sta rope_udg_advance
    dec rope_screen_pos
    jmp +++
++
    lda rope_loop_count
    cmp rope_seg_skip_above
    bcs +
    inc rope_segment_cur_x
    lsr rope_bit
    bcc +
    ror rope_bit
    lda #1
    sta rope_udg_advance
    inc rope_screen_pos
+++
    dex
    bpl -

+++
    ; now shift down Y (same value added to rope_y and rope_segment_cur_y when tracking)
    lda #2
    ldx rope_index
    cpx #16
    bpl +
    lda #3
+
    tax                    ; step preserved in x

    lda rope_loop_count
    cmp rope_seg_skip_above
    bcs +
    txa
    clc
    adc rope_segment_cur_y
    sta rope_segment_cur_y
+
    txa
    clc
    adc rope_y
    sta rope_y
    cmp #8
    bmi ++
    eor #8 ; set to 0 (rope_y wrapped -> next char row)
    sta rope_y
    lda rope_screen_pos
    clc
    adc #24
    sta rope_screen_pos
    lda #0
    adc rope_screen_pos+1
    sta rope_screen_pos+1
    ldx #1
    stx rope_udg_advance
++

    lda rope_udg_advance
    beq +
    inc rope_udg
    lda rope_udg
    clc
    adc #ROPE_FIRST_UDG
    ldy #0
    sta (rope_screen_pos),y
    lda rope_udg
    asl
    tax
    lda rope_screen_pos
    sta rope_old_screen_pos,x
    lda rope_screen_pos+1
    sta rope_old_screen_pos+1,x
    lda rope_udg_mem
    clc
    adc #8
    sta rope_udg_mem
+
    lda rope_bit
    ldy rope_y
    sta (rope_udg_mem),y

    lda rope_loop_count
    cmp rope_seg_skip_above
    bcs +
    tax
    lda rope_segment_cur_y
    sta rope_segment_y,x
+

    inc rope_loop_count
    dec rope_index
    lda rope_index
    cmp #rope_frame
    bpl --

    ; snap willy to attach point; px = cur_x/2 (VIC px -> quarter-chars)
    lda rope_willy_is_holding
    beq +++
    lda #1
    sta on_ground
    lda rope_segment_cur_x
    lsr
    sta px
    lda meta_content_src + meta_off_conn ; conn[0]: $ff = no east exit / ceiling rope
    cmp #$ff
    bne +
    lda #0
    sta py
    rts
+
    lda rope_segment_cur_y
    sta py
+++
    rts