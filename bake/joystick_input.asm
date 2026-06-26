; Stick-only GetPlayerInput for RJY.prg — must fit PATCH_BYTES (63 B resident slot).

!source "equates.asm"

*= $0000

GetPlayerInput

    ; 6 bytes
    lda willy_hidden
    bne .stick_done
    sta jumpIsPressed ; A = willy_hidden = 0

    ; 6 bytes
    sta $9113    ; A is still 0
    sta $9122    ; set data direction to read (input mode)

    ; 9 bytes
    lda $9120            ; bit 7 of $9120 == 0 means right
    eor #$ff
    and #$80
    sta rightIsPressed

    ; 10 bytes
    lda $9111
    eor #$ff
    tay
    and #$10            ; bit 4 of $9111 == 0 means left
    sta leftIsPressed

    ; 4 bytes
    ldx on_ground
    beq .stick_done

    ; 4 bytes
    ldx belt_active
    bne .stick_try_jump
    ; at this point x = 0

    ; 9 bytes
.stick_try_left
    lda leftIsPressed
    beq .stick_try_right
    dex ; was 0, now $ff
    stx lastxmove
    stx xadd

    ; 9 bytes
.stick_try_right
    lda rightIsPressed
    beq .stick_try_jump
    inx ; was 0, now 1
    stx lastxmove
    stx xadd

    ; 5 bytes
.stick_try_jump
    tya             ; bit 5 of $9111 == 0 means fire
    and #$20
    sta jumpIsPressed

    ; 1 byte
.stick_done
    rts


!if PATCH_BYTES > 0 {
!if * > PATCH_BYTES {
    !error "joystick GetPlayerInput size ", *, " exceeds ", PATCH_BYTES
}
}
