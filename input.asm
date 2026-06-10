;
; ScanKeyRow
;
; call with the row in .X
; and the column mask in .Y
; the row is 1,2,4,8... ^ FF
; returns whether pressed in .A
; returns keys pressed in .X
;
; left to right is LSB-MSB
; fe -> 1,3,5,7,9,-,DEL,
; fd ->  ,W,R,Y,I,P,],RET
; fb ->  ,A,D,G,J,L,',
; f7 -> LSH,X,V,N,<,/,
; ef ->  ,Z,C,B,M,>,RSH,
; df -> CTL,S,F,H,K,;,
; bf -> Q,E,T,U,O,[,
; 7f -> 2,4,6,8,0,=,
;

ScanKeyRow
    lda #$ff    ; restore DDR for VIA2
    sta $9122
    lda #$00
    sta $9123   ; set data direction for $9121
    stx $9120   ; request row
    sty ts
    lda $9121   ; read
    eor #$ff    ; $ff is no keys pressed
    and ts
    tax
    beq scan_key_row_skip
    lda #$01    ; key pressed
    rts
scan_key_row_skip
    lda #$00    ; no key pressed
    rts

GetPlayerInput
    lda #0
    sta jumpIsPressed
    lda on_ground
    beq player_input_done
    lda belt_active
    bne player_input_try_jump
        ; left (Z)
    ldx #$ef
    ldy #$02
    jsr ScanKeyRow
    cmp #0
    beq player_input_skip
    lda #-1
    sta lastxmove
    clc
    adc xadd
    cmp #-2
    bne player_input_skip2
    lda #-1
player_input_skip2
    sta xadd
player_input_skip
        ; right (X)
    ldx #$f7
    ldy #$04
    jsr ScanKeyRow
    cmp #0
    beq player_input_try_jump
    sta lastxmove
    clc
    adc xadd
    cmp #2
    bne player_input_skip3
    lda #1
player_input_skip3
    sta xadd
player_input_try_jump
    lda on_ground
    beq player_input_done
        ; jump (Space)
    ldx #$ef
    ldy #$01
    jsr ScanKeyRow
    sta jumpIsPressed
player_input_done
    rts

GetJumpIsPressed
    ldx #$ef
    ldy #$01
    jmp ScanKeyRow
