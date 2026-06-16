; Jet Set Willy - unexpanded VIC-20
; PRG from $1000; room image loads to $1A58 (overwrites $1A58+ at runtime)

!source "zp.asm"
!source "defines.asm"
!source "debug.asm"

!source "header.asm"
!source "gameloop.asm"
!source "map.asm"
!source "loader.asm"
!source "ramp.asm"
!source "willy.asm"
!source "util.asm"
!source "input.asm"
!source "guardians.asm"

!set ROPE_TEST = 0
!source "rope_fast.asm"
;!source "rope.asm"

prg_end = *

!source "warm.asm"
!source "runtime_const.asm"

prg_overlap = prg_end - $1a58

!if prg_overlap > 0 {
!warn "PRG extends ", prg_overlap, " bytes past $1A58 room load base - trim resident code/data"
} else {
!warn "PRG has ", -prg_overlap, " bytes free before $1A58 room load base"
}
