!zone endgame_implementation

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
