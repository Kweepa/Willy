!zone endgame_implementation

; Called from ParseRoomMeta after room meta is loaded.
; Turns off Maria when enough items are collected.
ApplyEndgameRoomLoad
    lda items_collected
    cmp #ITEMS_REQUIRED
    bcc apply_endgame_done
    lda map
    cmp #ROOM_MASTER_BED
    bne apply_endgame_done
    lda #0
    sta meta_content_src + meta_off_guardians
apply_endgame_done
    rts

; Called from main loop after Collide (edge check runs in DrawPlayerEntry).
CheckEndingTeleport
    lda map
    cmp #ROOM_MASTER_BED
    bne check_ending_done
    lda px
    cmp #ENDING_TRIGGER_PX
    bne check_ending_done

    ; Start ending Sequence
    ; Hide willy, teleport to bathroom, replace toilet
    lda #1
    sta willy_hidden
    sta use_room_spawn
    lda #ROOM_BATHROOM
    sta map
    jsr LoadRoom
    lda #6
    sta guardian_data_base + guardian_record_bytes + g_off_fmin
check_ending_done
    rts
