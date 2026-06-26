PlayInGameMusic
	; always update the note
	lda music_index
	and #$3f
	sta music_index
	tax
	lda INGAME_TUNE_SEQ,x
	and #$0f
	tay
	lda ingame_tune_pitch,y
	sta $900b

	; advance the counters
	inc music_delay
	lda music_delay
	and #7
	sta music_delay
	bne +
	inc music_index
+
	rts
play_ingame_music_end = *
play_ingame_music_size = play_ingame_music_end - PlayInGameMusic

!if play_ingame_music_size > 40 {
!error "PlayInGameMusic exceeds 40 bytes"
}
