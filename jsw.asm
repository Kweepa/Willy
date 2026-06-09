; Jet Set Willy — unexpanded VIC-20
; PRG layout: code only at $1000–$17FF (~2K max; UDG/screen above)

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

*=$1a00
!source "spritedata.asm"
