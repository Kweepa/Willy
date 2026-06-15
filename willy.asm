try_touch
    jsr GetCollision
    cmp #TILE_SOLID
    beq do_block
    lda #0
    rts
do_block
    lda #1
    rts

try_touch_below
    jsr GetCollision
    cmp #TILE_EMPTY
    beq ++
    cmp #TILE_ITEM
    beq ++
    cmp #TILE_CONVEYOR
    beq do_belt
    cmp #TILE_PLATFORM
    beq do_block_below
    cmp #TILE_SOLID
    beq do_block_below
    lda #0
    rts
do_belt
    lda meta_content_src + meta_off_belt
    beq do_belt_zero

    lda belt_active
    bne do_belt_conveyor

    ; Check opposite key based on belt_spd
    lda meta_content_src + meta_off_belt
    bpl check_left_pressed

    ; belt_spd is negative (pushes left), so check if RIGHT is pressed
    ldx #$f7
    ldy #$04
    jsr ScanKeyRow
    beq do_belt_release
    lda #1
    sta xadd
    jmp do_block_below

check_left_pressed
    ; belt_spd is positive (pushes right), so check if LEFT is pressed
    ldx #$ef
    ldy #$02
    jsr ScanKeyRow
    beq do_belt_release
    lda #-1
    sta xadd
    jmp do_block_below

do_belt_release
    lda #1
    sta belt_active

do_belt_conveyor
    lda meta_content_src + meta_off_belt
    sta xadd
    sta lastxmove
    jmp do_block_below

do_belt_zero
    lda #0
    sta xadd
    jmp do_block_below

do_block_below
    lda #1
    rts
++
    lda #0
    rts

lr_edge_px
    !byte EDGE_WEST_PX, EDGE_EAST_PX
lr_touch_a
    !byte 23, 25
lr_touch_b
    !byte 47, 49
lr_touch_c
    !byte 71, 73

CollideLeftRight
    jmp clr_start
clr_done
    rts
clr_start
    lda left_right_ctr
    bne clr_done
    lda xadd
    beq clr_done
    bmi lr_dir_left
    ldx #1
    jmp lr_dir_ok
lr_dir_left
    ldx #0
lr_dir_ok
    stx tmp
    lda px
    cmp lr_edge_px,x
    beq clr_done
    lda px
    and #$03
    bne lr_move
    ldy lr_touch_a,x
    jsr try_touch
    bne clr_done
    ldy lr_touch_b,x
    jsr try_touch
    bne clr_done
    lda py
    and #$07
    beq lr_move
    ldy lr_touch_c,x
    jsr try_touch
    bne clr_done
lr_move
    ldx tmp
    beq lr_dec_px
    inc px
    jmp lr_stepped
lr_dec_px
    dec px
lr_stepped
    ldx px
    ldy py
    jsr ConvertXYToScreenAddr
    jsr calculate_ramp_y
    lda xadd
    beq +
    lda was_on_ground
    bne ++
    lda is_on_ramp
    beq +
++
    jsr do_walking_ramp_check
+
    lda is_on_ramp
    beq +
    ldx px
    ldy py
    jsr ConvertXYToScreenAddr
    lda #1
    sta on_ground
    lda #27
    sta inairtime
+
    jmp clr_done

Collide
    lda py
    sta last_py
    lda xadd
    sta tmp_xadd
    lda on_ground
    bne +
    sta belt_active
+
	lda #0
	sta $900c
	lda on_ground
	bne +
	lda inairtime
	lsr
	tax
	lda jumpnotes,x
	sta $900c
+
    lda on_ground
    sta was_on_ground
    inc inairtime
    lda inairtime
    cmp #27
    bcs +
    lda #0
    sta was_on_ground
+
    lda inairtime
    cmp #52
    bne +
    lda #0
    sta xadd
+
    lda #0
    sta on_ground
    sta mov
    ldx px
    ldy py
    jsr ConvertXYToScreenAddr
    jsr CollideLeftRight
    jsr calculate_ramp_y
    lda py
    and #$f8
    sta align_tmp
	lda inairtime
	cmp #51
	bcc +
	lda #51
+
    tax
    lda jumptab,x
    clc
    adc py
    sta newy
    lda inairtime
    cmp #27
    bcs collide_down
    lda newy
    and #$f8
    cmp align_tmp
    bne +
    jmp move_up_down
+
    ldy #0
    jsr try_touch
    beq +
    jmp hit_above
+
    lda px
    and #$03
    bne +
    jmp move_up_down
+
    ldy #1
    jsr try_touch
    beq +
    jmp hit_above
+
    bne +
    jmp move_up_down
+
collide_down
    lda on_ground
    bne +
    lda is_on_ramp
    bne +
    lda xadd
    bne +
    jsr do_falling_ramp_check
+
    lda is_on_ramp
    beq +
    jmp check_jump
+
    lda py
    and #$07
    beq look_below_2
    lda newy
    and #$f8
    cmp align_tmp
    bne +
    jmp move_up_down
+
    ldy #96
    jsr try_touch_below
    bne hit_below
    lda px
    and #$03
    beq move_up_down
    iny
    jsr try_touch_below
    bne hit_below
    beq move_up_down
look_below_2
    lda was_on_ground
    beq +
    lda #0
    sta xadd
+
    ldy #72
    jsr try_touch_below
	bne check_jump
    lda px
    and #$03
    beq move_up_down
    iny
    jsr try_touch_below
    beq move_up_down
check_jump
    lda #1
    sta on_ground
    lda #27
    sta inairtime
    lda jumpIsPressed
    beq collide_end
    lda #0
    sta inairtime
    sta is_on_ramp
    jmp collide_end
move_up_down
    lda #1
    sta mov
collide_done
collide_end
    lda mov
    beq collide_dont_move_y
    lda newy
    sta py
collide_dont_move_y
    lda on_ground
    beq +
    lda belt_active
    bne +                       ; If conveyor is actively pushing us, do NOT clear xadd!
    lda #0
    sta xadd
+
    jsr DrawPlayer
    rts
hit_above
    lda #27
    sta inairtime
    lda py
    and #$f8
    sta newy
    jmp move_up_down
hit_below
	jsr CheckDeathFall
    lda #1
    sta on_ground
    lda #27
    sta inairtime

    lda newy
    and #$f8
    sta newy
    jmp move_up_down

CheckDeathFall
	lda inairtime
	cmp #70
	bcc +
	lda #1
	sta dead
+
	rts

jumptab
!byte -2, -1, -2, -1, -2, -1, -1, -1, -2, -1, -1, 0, -1, -1, -1, 0, -1, 0, -1, 0, 0, -1, 0, 0, 0, 0, 0
!byte 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, 2, 1, 1, 1, 2, 1, 2, 1, 2

jumpnotes
!byte 150,155,160,165,170,175,180,185,190
!byte 195,200,205,210,215,210,205,200,195
!byte 190,185,180,175,170,165,160,155,150

ErasePlayer
    ldx px
    ldy py
    jsr ConvertXYToScreenAddr
	ldx #5
-
	ldy cell_off_2x3,x
	lda (map_ptr),y
	and #$0f
	cmp #TILE_ITEM
	bne +
	lda #ITEM_CHR
	sta (scr_ptr),y
	jmp ++
+
	ora #$10
	sta (scr_ptr),y
++
	dex
	bpl -
    rts

draw_player_offsets
	!byte 24,48,72,25,49,73
draw_player_chrs
	!byte PLAY_CHR, PLAY_CHR+1, PLAY_CHR+2, PLAY_CHR+3, PLAY_CHR+4, PLAY_CHR+5

setudgadd
	; takes Y
	; modifies and requires X
	lda #0
	sta tmp
    lda (scr_ptr),y
	sta player_overlap,x
	inx
    asl
    asl
	rol tmp
    asl
	rol tmp
    sta udg_ptr
    lda #>udg_base
	adc tmp
    sta udg_ptr+1
    rts

copy_udg
    ldy #7
-
    lda (udg_ptr),y
    sta (play_udg),y
    dey
    bpl -
    rts

DrawPlayer
	; clear overlaps/touches
	ldx #(48+6-1)
	lda #0
-
	sta player_overlap,x
	dex
	bpl -

    ; first read screen bitmaps to player bitmaps
    ldx px
    ldy py
    jsr ConvertXYToScreenAddr
    lda #<player_udg
    sta play_udg
    lda #>player_udg
    sta play_udg+1

	ldx #0
-
    ldy draw_player_offsets,x
    jsr setudgadd
    jsr copy_udg

    lda play_udg
    clc
    adc #8
    sta play_udg

	cpx #6
	bne -

    ; now or player bitmaps to player udg 3x2
    lda px
    and #$03
    sta tmp
    lda lastxmove
    bpl +
    lda tmp
    clc
    adc #4
    sta tmp
+
    lda tmp
    clc
    adc #PLAYER_SPRITE_FRAME
    jsr GetSpriteFrameAddr
    lda arr
    clc
    adc #16
    sta arr2
    lda arr+1
    adc #0
    sta arr2+1

    lda py
    and #$07
    tax

    ldy #0
draw_center_loop
    lda (arr),y
	and player_udg,x
	sta player_touch,x
    lda (arr),y
    ora player_udg,x
    sta player_udg,x

    lda (arr2),y
	and player_udg+24,x
	sta player_touch+24,x
    lda (arr2),y
    ora player_udg+24,x
    sta player_udg+24,x
    inx
    iny
    cpy #16
    bne draw_center_loop

    ldx px
    ldy py
    jsr ConvertXYToScreenAddr

	ldx #5
-
	lda draw_player_chrs,x
	ldy draw_player_offsets,x
	sta (scr_ptr),y
	dex
	bpl -

coll_check
	; now check for collisions
	ldy #5
	ldx #(6*8-1)
--
	lda #0
	sta tmp
-
	lda tmp
	ora player_touch-1,x
	sta tmp
	dex
	txa
	and #7
	bne -
	lda tmp
	beq +
	lda player_overlap,y
	jsr HandleOverlapChar
+
	dey
	bpl --
    +BorderDebugColor (WHITE + 8)
    rts

; HandleOverlapChar - A = screen chr under a Willy cell (player_overlap).
; Items: pickup. Hazards/guardians: kill. Solids: pass through.
; coll_check only calls us when player_touch is non-zero.
HandleOverlapChar
    cmp #ITEM_CHR
    bne +
    jsr PickupItemAtOverlap
    jmp dont_kill_player
+
    cmp #TILE_HAZARD + TILE_CHR_BASE
    beq kill_player
    cmp #TILE_SOLID + TILE_CHR_BASE
    beq dont_kill_player
    cmp #GUARDIAN_CHR
    bcs kill_player
    rts

PickupItemAtOverlap
    ldx map
    lda pickup_got,x
    bne pickup_done
    inc pickup_got,x
    inc items_collected
    tya
    pha
    lda draw_player_offsets,y
    tay
    lda #TILE_CHR_BASE
    sta (scr_ptr),y
    lda #TILE_EMPTY
    sta (map_ptr),y
    tax
    lda tile_color_src,x
    sta (col_ptr),y
    lda #180
    sta $900c
    pla
    tay
pickup_done
    rts

kill_player
    lda #1
    sta dead
dont_kill_player
    rts
