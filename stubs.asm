;
; Stubs and small resident data — PRG must end below $1C00 (UDG/screen above)
;

InitMusic
PlayInGameMusic
PlayTitleMusic
	rts

TitleScreen
	lda #8
	sta $900f
	jsr ClearScreen
	rts

BootSquash
	rts

CopyAndFlipGuardian
CopyDownVerticalGuardianBmp
EraseGuardians
MoveGuardians
	rts

PrintSpecFontString
ConvertCharToFontChar
GetCharDefAddr
GetCharWidth
GetStringWidth
PutFontUDGsOnScreen
	rts

prg_end

!if * > $1c00 {
!error "PRG exceeds $1C00 — would corrupt UDG at $1C00 and screen at $1E00"
}
