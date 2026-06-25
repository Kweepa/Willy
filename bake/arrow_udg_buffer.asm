; Per-room arrow_update_b — @ arrow_udg_addr + 8 ($1DA8 in loaded image).
; CLI: -DCOOKED_SOUND_X=... -DARROW_V=1|$ff -DARROW_TILE=52 -DSLOT_BYTES=40

!source "equates.asm"

*= $0000
arrow_update_b_bake
	ldy arrow_x_zp
	cpy #24
	bcs +

	; replace the tile
	lda (map_ptr),y
	and #$0f   ; mask out the random high nibble
	ora #$10   ; bump up to match the tile udgs
	sta (scr_ptr),y
+
	; increment and play sound
!if ARROW_V = 1 {
	iny ; or dey, depending on direction (compile time instruction @arrow v= -1 or 1)
}
!if ARROW_V <> 1 {
	dey ; or dey, depending on direction (compile time instruction @arrow v= -1 or 1)
}
	sty arrow_x_zp
	cpy #COOKED_SOUND_X  ; <- compile time constant (@arrowsoundx)
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

!if * < SLOT_BYTES {
	!fill SLOT_BYTES - *, $ea
}
!if * > SLOT_BYTES {
	!error "arrow_udg_buffer size ", *, " exceeds SLOT_BYTES ", SLOT_BYTES
}
