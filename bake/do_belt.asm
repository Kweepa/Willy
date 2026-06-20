; Per-room conveyor collision — fixed prefix slot after AnimateConveyors.
; CLI: -DBELT=... -DSCANKEYROW=$.... -DSLOT_BYTES=33

!source "equates.asm"

*= $0000
DoBelt
!if BELT = $ff {
    ; @belt -1 pushes left: oppose key is right (belt_opp_right / index 0)
    lda belt_active
    bne +
    ldx #belt_opp_right_row
    jsr SCANKEYROW
    beq ++
    lda #belt_opp_right_xadd
    sta xadd
    lda #1
    rts
++
    lda #1
    sta belt_active
+
    lda #belt_push_left
    sta xadd
    sta lastxmove
    lda #1
    rts
}
!if BELT = 1 {
    ; @belt 1 pushes right: oppose key is left (belt_opp_left / index 3)
    lda belt_active
    bne +
    ldx #belt_opp_left_row
    jsr SCANKEYROW
    beq ++
    lda #belt_opp_left_xadd
    sta xadd
    lda #1
    rts
++
    lda #1
    sta belt_active
+
    lda #belt_push_right
    sta xadd
    sta lastxmove
    lda #1
    rts
}
!if BELT = 0 {
    lda #0
    sta xadd
    lda #1
    rts
}

!if * < SLOT_BYTES {
    !fill SLOT_BYTES - *, $ea
}
!if * > SLOT_BYTES {
    !error "DoBelt size ", *, " exceeds SLOT_BYTES ", SLOT_BYTES
}
