; Build sources: bake/arrow_sprite_buffer.asm (init + update_a @ guardian_sprites_base+256),
; bake/arrow_udg_buffer.asm (update_b @ arrow_udg_addr+8).
;
; so in a room if there are these lines:
; @arrow y=<tile_y> x=<tile_x> v=[-1 or 1] sound=<value>
; @arrowudg N,N,N,N,N,N,N,N
; then place arrow_init + arrow_update_a where the last guardian sprite data usually is (guardian_sprites_base + 256)
; and place the arrow udg data (8 bytes) and arrow_update_b in the last guardian udg location ($1c00 + 52*8)
; and set a byte in the metadata to indicate that there's an arrow in the room
;
; in game, just these
;
;   in LoadRoom
;		; 8 bytes
;		lda meta_content_has_arrow
;		beq +
;		jsr arrow_init
;	+
;
;	in gameloop, just after $900c <- 0
;		; 8 bytes
;		lda meta_content_has_arrow
;		beq +
;		jsr arrow_update
;	+
;
; so the run-time cost is 16 bytes
;

; =====================================

arrow_init
	lda #cooked_x_value  ; <- compile time constant (got from room text file @arrow x=)
	sta arrow_x_zp
	rts
	
; =====================================

arrow_update_a

	ldx left_right_ctr      ; every 4th frame (same cadence as conveyors / h-guardians)
	beq +
	rts
+
	; setup (x is 0 thanks to above check)
	ldy #COOKED_Y_VALUE ; in pixels, straight from the room text file
	jsr ConvertXYToScreenAddr
	jmp arrow_update_b

; =====================================

arrow_update_b

	ldy arrow_x_zp
	cpy #24
	bcs +

	; replace the tile
	lda (map_ptr),y
	and #$0f   ; mask out the random high nibble
	ora #$10   ; bump up into the tile udg range
	sta (scr_ptr),y
+
	; increment and play sound
	iny ; or dey, depending on direction (compile time instruction @arrow v= -1 or 1)
	sty arrow_x_zp
	cpy #cooked_launch_sound_x  ; <- compile time constant (@arrowsoundx)
	bne +
	lda #66
	sta $900c
+
	cpy #24
	bcs +

	; draw
	lda #ARROW_TILE    ; see above, ARROW_TILE is 52
	sta (scr_ptr),y
+
	rts
