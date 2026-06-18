; One-shot boot at end of PRG (below image_base; not overwritten by room load).
; sei -> VIA #2 IER/T2CL -> stack -> IOINIT -> VIC init -> copy tables -> jmp start_game
; Must not RTS here: txs clears the SYS return address on the stack.

WarmStart
    sei

    lda #$7f
    sta $911d                   ; VIA #2 IER - disable all enables
    sta $911e                   ; T2CL - preset timer 2 low

    cld                         ; clear bcd mode
    ldx #$ff                    ; reset stack
    txs

    jsr $fdf9                   ; IOINIT

    ldx #5                      ; initialize vic registers
-
    lda init24_val,x
    sta $9000,x
    dex
    bpl -

    ldx #boot_zp_room_size - 1  ; cell_off..draw_vguard at $DC
-
    lda boot_zp_pack,x
    sta cell_off_2x3,x
    dex
    bpl -

    jsr RelocateDrawPlayerTables
    jsr RelocateRopeXadd

    ldx #boot_page_size - 1     ; edge_tbl, x24rowtab, jumptab at $140+
-
    lda boot_page_pack,x
    sta edge_tbl,x
    dex
    bpl -

    jmp start_game

; Copy draw_player tables to $37/$3D (off KERNAL keyboard ptr $F5/$F6 during LOAD).
RelocateDrawPlayerTables
    ldx #5
-
    lda boot_draw_player_offsets,x
    sta draw_player_offsets,x
    lda boot_draw_player_chrs,x
    sta draw_player_chrs,x
    dex
    bpl -
    rts

; Copy rope_xadd to cassette buffer $35C (clobbered by KERNAL LOAD).
RelocateRopeXadd
    ldx #boot_rope_xadd_size - 1
-
    lda boot_rope_xadd_pack,x
    sta ROPE_XADD,x
    dex
    bpl -
    rts

init24_val
    !byte $0a, $32, $98, $22, $00, $ff
