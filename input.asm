;
; ScanKeyRow
;
; call with the row in .X ($fe,$fd,$fb,$f7,$ef,$df,$bf,$7f)
; Z set = key pressed, Z clear = no key pressed
;
; left to right is LSB-MSB
; fe -> 1,3,5,7,9,-,DEL,
; fd ->  ,W,R,Y,I,P,],RET
; fb ->  ,A,D,G,J,L,',
; f7 -> LSH,X,V,N,<,/,
; ef -> SPC,Z,C,B,M,>,RSH,
; df -> CTL,S,F,H,K,;,
; bf -> Q,E,T,U,O,[,
; 7f -> 2,4,6,8,0,=,
;

!zone input_implementation

ScanKeyRow
    ldy #$ff    ; restore DDR for VIA2
    sty $9122
    iny ; set to 0
    sty $9123   ; set data direction for $9121
    stx $9120   ; request row
    lda $9121   ; read
    eor #$ff    ; $ff is no keys pressed
    rts

GetPlayerInput
    lda willy_hidden
    bne .player_input_done
    lda #0
    sta jumpIsPressed
    sta leftIsPressed
    sta rightIsPressed

    lda on_ground
    beq .player_input_done
    lda belt_active
    bne .player_input_try_jump
.player_input_left
    ldx #$bf ; Q/E/T etc
    jsr ScanKeyRow
    beq .player_input_right
    lda #-1
    sta lastxmove
    sta xadd
    sta leftIsPressed
.player_input_right
    ldx #$fd ; W/R/Y etc
    jsr ScanKeyRow
    beq .player_input_try_jump
    lda #1
    sta lastxmove
    sta xadd
    sta rightIsPressed
.player_input_try_jump
    ldx #$ef
    jsr ScanKeyRow
    sta jumpIsPressed ; just needs to be non-zero
.player_input_done
    rts
