;
; ScanKeyRow
;
; call with the row in .X
; and the column mask in .Y
; the row is 1,2,4,8... ^ FF
; returns keys pressed in .X
; Z set = no key in mask, Z clear = key pressed
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
    rts

GetPlayerInput
    lda #0
    sta jumpIsPressed
    lda rope_willy_is_holding
    beq +
    ;jmp RopePlayerInput
+
    lda on_ground
    beq player_input_done
    lda belt_active
    bne player_input_try_jump
    ldx #$ef
    ldy #$02
    jsr ScanKeyRow
    beq player_input_right
    lda #-1
    sta lastxmove
    sta xadd
player_input_right
    ldx #$f7
    ldy #$04
    jsr ScanKeyRow
    beq player_input_try_jump
    lda #1
    sta lastxmove
    sta xadd
player_input_try_jump
    ldx #$ef
    ldy #$01
    jsr ScanKeyRow
    beq player_input_done
    lda #1
    sta jumpIsPressed
player_input_done
    rts
