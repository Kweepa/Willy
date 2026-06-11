; Jet Set Willy - unexpanded VIC-20
; PRG from $1000; room image loads to $1B00 (overwrites $1B00+ at runtime)

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
!source "spritedata.asm"
!source "guardians.asm"
!source "warm.asm"

prg_end = *

!if * > $1b00 {
!warn "PRG extends past $1B00 room load base - trim resident code/data"
}
