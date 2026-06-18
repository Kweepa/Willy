; Per-room item draw stub — 16 bytes in meta tail @ meta_off_item_draw.
; CLI: -DSCR_ADDR=... -DCOL_ADDR=... -DMAP_ADDR=... -DITEM_COLOR=... -DSLOT_BYTES=16

!source "equates.asm"

*= $0000
item_draw
    lda #ITEM_CHR
    sta SCR_ADDR
    lda #ITEM_COLOR
    sta COL_ADDR
    lda #TILE_ITEM
    sta MAP_ADDR
    rts

!if * <> SLOT_BYTES {
    !error "item_draw size ", *, " != SLOT_BYTES ", SLOT_BYTES
}
