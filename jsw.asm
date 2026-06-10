; Jet Set Willy — unexpanded VIC-20
; PRG layout: code from $1000, then resident sprite data, all below $1C00 (UDG/room image)

!source "zp.asm"
!source "defines.asm"

!source "header.asm"
!source "gameloop.asm"
!source "map.asm"
!source "loader.asm"
!source "willy.asm"
!source "util.asm"
!source "input.asm"
!source "playerdata.asm"
!source "stubs.asm"
!source "spritedata.asm"

!if * > $1c00 {
!error "PRG exceeds $1C00 — would corrupt UDG at $1C00 and screen at $1E00"
}
