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

    lda meta_content_src + meta_off_belt
    bpl belt_pos_idx
    ldx #3
    bne belt_check_key
belt_pos_idx
    ldx #0
belt_check_key
    stx tmp
    ldy belt_opp_key+1,x
    lda belt_opp_key,x
    tax
    jsr ScanKeyRow
    beq do_belt_release
    ldx tmp
    lda belt_opp_key+2,x
    sta xadd
    bne do_block_below

do_belt_release
    lda #1
    sta belt_active

do_belt_conveyor
    lda meta_content_src + meta_off_belt
    sta xadd
    sta lastxmove
    bne do_block_below

do_belt_zero
    lda #0
    sta xadd
    beq do_block_below

do_block_below
    lda #1
    rts
++
    lda #0
    rts

CollideLeftRight
    lda left_right_ctr
    bne clr_done
    lda xadd
    beq clr_done
    bmi lr_dir_left
    ldx #1
    bne lr_dir_ok
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
    bne lr_stepped
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
clr_done
    rts

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
    beq move_up_down
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
