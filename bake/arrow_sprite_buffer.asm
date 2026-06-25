; Per-room arrow init + update_a — 32-byte slot @ guardian_sprites_base + 256 ($1B48).
; CLI: -DCOOKED_X=... -DCOOKED_Y=... -DARROW_UPDATE_B=$1da8 -DSLOT_BYTES=32

!source "equates.asm"

ConvertXYToScreenAddr = $0392

*= $0000
arrow_init_bake
	lda #COOKED_X  ; <- compile time constant (got from room text file @arrow x=)
	sta arrow_x_zp
	rts

arrow_update_a_bake
	ldx left_right_ctr      ; every 4th frame (same cadence as conveyors / h-guardians)
	beq +
	rts
+
	; setup (x is 0 thanks to above check)
	ldy #COOKED_Y  ; ConvertXY Y for tile row (@arrow y >> 3), baked in mkroom
	jsr ConvertXYToScreenAddr
	jmp ARROW_UPDATE_B

!if * < SLOT_BYTES {
	!fill SLOT_BYTES - *, $ea
}
!if * > SLOT_BYTES {
	!error "arrow_sprite_buffer size ", *, " exceeds SLOT_BYTES ", SLOT_BYTES
}
