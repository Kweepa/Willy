try_touch
    jsr GetCollision
    sta typ
    cmp #TILE_SOLID
    beq do_block
    lda #0
    rts
do_block
    lda #1
    rts

try_touch_below
    jsr GetCollision
    sta typ
    cmp #TILE_EMPTY
    beq ++
    cmp #TILE_CONVEYOR
    beq do_belt
    cmp #TILE_RAMP
    beq do_block_below
    cmp #TILE_PLATFORM
    beq do_block_below
    cmp #TILE_SOLID
    beq do_block_below
    lda #0
    rts
do_belt
    lda belt_spd
    beq do_belt_zero

    lda belt_active
    bne do_belt_conveyor

    ; Check opposite key based on belt_spd
    lda belt_spd
    bpl check_left_pressed

    ; belt_spd is negative (pushes left), so check if RIGHT is pressed
    jsr ScanJoystick
    ldx #$f7
    ldy #$04
    jsr ScanKeyRow
    ora stickright
    beq do_belt_release
    lda #1
    sta xadd
    jmp do_block_below

check_left_pressed
    ; belt_spd is positive (pushes right), so check if LEFT is pressed
    jsr ScanJoystick
    ldx #$ef
    ldy #$02
    jsr ScanKeyRow
    ora stickleft
    beq do_belt_release
    lda #-1
    sta xadd
    jmp do_block_below

do_belt_release
    lda #1
    sta belt_active

do_belt_conveyor
    lda belt_spd
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

try_ramp
    lda was_on_ground
    beq try_ramp_done
    lda ramp_type
    beq try_ramp_done
    
    ; Check if either foot (72 or 73) is on a ramp
    ldy #72
    jsr GetCollision
    cmp #TILE_RAMP
    beq check_direction
    ldy #73
    jsr GetCollision
    cmp #TILE_RAMP
    bne try_ramp_done

check_direction
    ; Determine if we go up or down based on ramp_type and xadd
    lda ramp_type
    cmp #RAMP_UP_RIGHT
    bne check_up_left

    ; UP_RIGHT ramp
    lda xadd
    beq try_ramp_done
    bpl ramp_go_up      ; If moving right, go UP
    bmi ramp_go_down    ; If moving left, go DOWN

check_up_left
    ; UP_LEFT ramp
    lda xadd
    beq try_ramp_done
    bmi ramp_go_up      ; If moving left, go UP
    bpl ramp_go_down    ; If moving right, go DOWN

ramp_go_up
    lda py
    sec
    sbc #2              ; Move up by 2 pixels
    sta py
    ldx px
    ldy py
    jsr ConvertXYToScreenAddr
    rts

ramp_go_down
    lda py
    clc
    adc #2              ; Move down by 2 pixels
    sta py
    ldx px
    ldy py
    jsr ConvertXYToScreenAddr
try_ramp_done
    rts

CollideLeftRight
    lda left_right_ctr
    bne end_collide_left_right
    lda xadd
    bpl collide_right
    lda px
    beq end_collide_left_right
    lda px
    and #$03
    bne move_left
    ldy #23
    jsr try_touch
    bne end_collide_left_right
    ldy #47
    jsr try_touch
    bne end_collide_left_right
    lda py
    and #$07
    beq move_left
    ldy #71
    jsr try_touch
    bne end_collide_left_right
move_left
    dec px
    ldx px
    ldy py
    jsr ConvertXYToScreenAddr
    jsr try_ramp
    jmp end_collide_left_right

collide_right
    lda xadd
    beq end_collide_left_right
    lda px
    cmp #88
    beq end_collide_left_right
    lda px
    and #$03
    bne move_right
    ldy #25
    jsr try_touch
    bne end_collide_left_right
    ldy #49
    jsr try_touch
    bne end_collide_left_right
    lda py
    and #$07
    beq move_right
    ldy #73
    jsr try_touch
    bne end_collide_left_right
move_right
    inc px
    ldx px
    ldy py
    jsr ConvertXYToScreenAddr
    jsr try_ramp
end_collide_left_right
    rts

Collide
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
    lda py
    and #$f8
    sta tmp
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
    cmp tmp
    beq move_up_down
    ldy #0
    jsr try_touch
    bne hit_above
    lda px
    and #$03
    beq move_up_down
    ldy #1
    jsr try_touch
    bne hit_above
    beq move_up_down
collide_down
    lda py
    and #$07
    beq look_below_2
    lda newy
    and #$f8
    cmp tmp
    beq move_up_down
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
    lda #0
    sta yadd
    lda jumpIsPressed
    beq collide_end
    lda #0
    sta inairtime
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
    lda #0
    sta yadd
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
	ldy erase_scr_off,x
	lda (map_ptr),y
	and #$0f                    ; mask off random upper nybble from color RAM $9400
	sta (scr_ptr),y
	dex
	bpl -
    rts

erase_scr_off
	!byte 24,25,48,49,72,73
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
    lda py
    and #$07
    sta tmp
    tax

    lda px
    and #$03
    asl
    asl
    asl
    asl
    asl                         ; Shift 5 times (multiplying by 32)
    clc
    adc #<player_bmp
    sta arr
	lda #>player_bmp
	adc #0
	sta arr+1
    lda lastxmove
    and #$80
    adc arr
    sta arr
    lda arr+1
    adc #0
    sta arr+1
    lda arr
    clc
    adc #16
    sta arr2
    lda arr+1
    adc #0
    sta arr2+1
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
	jsr try_killed
+
	dey
	bpl --
    rts

try_killed
	cmp #TILE_HAZARD
	beq kill_player
	cmp #TILE_SOLID
	beq dont_kill_player
	cmp #GUARDIAN_CHR
	bcs kill_player
	rts
kill_player
    ; lda #1      ; Stubbed out hazard/guardian death collision
    ; sta dead
dont_kill_player
    rts

DeathFlash
	lda #8
	sta $900f
	rts

ColFlash
	ldx #0
-
	sta color_base,x
	sta color_base+$76,x
	inx
	bne -
	rts
