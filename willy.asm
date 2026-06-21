!zone willy_implementation

try_touch
    jsr GetCollision
    cmp #TILE_SOLID
    beq do_block
    clc
    rts
do_block
    sec
    rts

try_touch_below
    jsr GetCollision
    cmp #TILE_EMPTY
    beq no_hit
    cmp #TILE_ITEM
    beq no_hit
    cmp #TILE_CONVEYOR
    bne check_floor
    jmp DoBelt                 ; tail call — must exit with C=1
check_floor
    cmp #TILE_PLATFORM
    beq hit
    cmp #TILE_SOLID
    beq hit
no_hit
    clc
    rts
hit
    sec
    rts

CollideLeftRight
    lda left_right_ctr
    bne lr_out

    ; x=0 moving left, x=1 moving right (from sign of xadd: $FF / $01)
    ldx xadd
    beq lr_out
    inx
    txa
    lsr
    tax

    ; Side probes: lr_touch is 2 cols (move left / move right) x 3 rows
    ; (a/b/c).  x picks the col; rows are map offsets at $E2-$E7.
    ; Left: probe only at px&3==0 (char boundary).  Right: only at
    ; px&3==3 (last px before next boundary) — right col uses far offsets
    ; 26/50/74 so we look past the sprite, not inside it.  px&3==1,2: no
    ; probe either direction (sub-pixel steps between check points).
    ; Gate: (left & px&3==0) or (right & px&3==3); cmp #1 / rol maps dir 0->0, 1->3.
    cmp #1
    rol
    sta tmp
    lda px
    and #$03
    cmp tmp
    bne lr_move

lr_do_touch
    ldy lr_touch_a,x
    jsr try_touch
    bcs lr_out
    ldy lr_touch_b,x
    jsr try_touch
    bcs lr_out
    ldy lr_touch_c,x
    ; lower side probe when py&7!=0 (misaligned feet).  On ramps feet are
    ; always misaligned; UP_LEFT baked ry+2 lowers py so c hits W under \
    ; tiles and blocks climbing — skip c while already on the ramp.
    lda is_on_ramp
    bne lr_move
    lda py
    and #$07
    beq lr_move
    jsr try_touch
    bcs lr_out
lr_move
    ; px += xadd (xadd is +1 / -1 as $01 / $FF)
    lda px
    clc
    adc xadd
    sta px
    tax
    ldy py
    jsr ConvertXYToScreenAddr
    jsr calculate_ramp_y
    ; xadd is guaranteed nonzero here (early return above), so just gate the
    ; walking-ramp snap on was_on_ground OR is_on_ramp.
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
lr_out
    rts

Collide
    lda willy_hidden
    beq collide_active
    rts
collide_active
    lda room_has_rope
    beq collide_body
    lda rope_willy_is_holding
    beq collide_body
    jsr RopePlayerInput          ; climb / descend / jump / fall-off
    lda rope_willy_is_holding
    beq collide_body             ; released this frame -> normal physics applies jump/fall
    jsr rope_draw_maybe          ; gated draw; snaps willy to the held segment
    jmp DrawPlayerEntry          ; skip gravity while carried
collide_body
    lda py
    sta last_py
    lda xadd
    sta tmp_xadd
    lda on_ground
    bne +
    sta belt_active
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
    lda py
    cmp #8
    bcs jump_above_check
    lda meta_content_src + meta_off_conn   ; north @conn; allow exit without tile probe
    cmp #$ff
    bne move_up_down
    lda #27
    sta inairtime
    lda #0
    sta newy
    beq move_up_down
jump_above_check
    ldy #0
    jsr try_touch
    bcc +
    jmp hit_above
+
    ldy #1
    jsr try_touch
    bcc +
    jmp hit_above
+
    bcc move_up_down
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
    bne check_jump
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
    bcs hit_below
    iny
    jsr try_touch_below
    bcs hit_below
    bcc move_up_down
look_below_2
    lda was_on_ground
    beq +
    lda #0
    sta xadd
+
    ldy #72
    jsr try_touch_below
    bcs check_jump
    iny
    jsr try_touch_below
    bcc move_up_down
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
    beq collide_end
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
    lda room_has_rope
    beq collide_draw_player
    jsr rope_draw_maybe          ; animate rope + attach detection via DrawPlayer/coll_check
collide_draw_player
    jmp DrawPlayerEntry        ; tail call — was jsr/rts
hit_above
    lda #27
    sta inairtime
    lda py
    and #$f8
    sta newy
    jmp move_up_down
hit_below
    ; fatal fall if inairtime >= 70 (inlined CheckDeathFall)
    lda inairtime
    cmp #70
    bcc +
    lda #1
    sta dead
+
    lda #1
    sta on_ground
    lda #27
    sta inairtime

    lda newy
    and #$f8
    sta newy
    jmp move_up_down

ErasePlayer
    lda willy_hidden
    bne erase_player_done
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
	bne ++
+
	ora #$10
	sta (scr_ptr),y
++
	dex
	bpl -
erase_player_done
    rts

DrawPlayerEntry
    lda dead
    bne +
    jsr CheckRoomEdge
    lda edge_skip_draw
    beq DrawPlayerBody
+
    lda #0
    sta edge_skip_draw
    rts

DrawPlayerBody
    lda willy_hidden
    beq +
    rts
+
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
    ; screen chr -> UDG ptr (inlined setudgadd)
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
    ; copy 8 bytes into player UDG slot (inlined copy_udg)
    ldy #7
--
    lda (udg_ptr),y
    sta (play_udg),y
    dey
    bpl --

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
	ora player_touch,x
	sta tmp
	dex
	txa
	and #7
    cmp #7
	bne -
	lda tmp
	beq +
	lda player_overlap,y
	jsr HandleOverlapChar
+
	dey
	bpl --
    +BorderDebugColor (WHITE + 8)
draw_player_done
    rts

check_for_pickup

; HandleOverlapChar - A = screen chr under a Willy cell (player_overlap).
; Items: pickup. Hazards/guardians: kill. Solids: pass through.
; coll_check only calls us when player_touch is non-zero.
; this function should preserve x and y
HandleOverlapChar
    cmp #ITEM_CHR
    bne ++

    ; pickup item at overlap cell (inlined PickupItemAtOverlap)
    txa
    pha
    ldx map
    lda pickup_got,x
    bne +
    inc pickup_got,x
    inc items_collected
    jsr item_erase
+
    pla
    tax
    rts

++
    cmp #TILE_HAZARD + TILE_CHR_BASE
    beq kill_player
    cmp #TILE_SOLID + TILE_CHR_BASE
    beq dont_kill_player
    cmp #GUARDIAN_CHR
    bcs +
    rts

+

    ; hit a guardian (22-33) or rope UDG (34+). Guardians kill directly;
    ; rope UDGs attach only when room_has_rope (no pha — kill_player must
    ; not return with an extra byte on the stack).
    cmp #ROPE_FIRST_UDG
    bcc kill_player
    lda room_has_rope
    beq kill_player
    jmp rope_attach ; tail call

kill_player
    lda #1
    sta dead
dont_kill_player
    rts
