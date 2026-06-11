; Jet Set Willy - unexpanded VIC-20
; PRG from $1000; room image loads to $1A60 (overwrites $1A60+ at runtime)

!source "zp.asm"
!source "defines.asm"

!source "header.asm"
!source "gameloop.asm"
!source "map.asm"
!source "loader.asm"
!source "willy.asm"
!source "util.asm"
!source "input.asm"
!source "guardians.asm"

prg_end = *

!source "warm.asm"

prg_overlap = prg_end - $1a60

!if prg_end > $1a60 {
!warn "PRG extends ", prg_overlap, " bytes past $1A60 room load base - trim resident code/data"
}
