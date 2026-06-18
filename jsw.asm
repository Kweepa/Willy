; Jet Set Willy - unexpanded VIC-20
; PRG from $1000; room image loads to image_base ($1A24)

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
!source "relocated_code.asm"

prg_overlap = prg_end - image_base

!if prg_overlap > 0 {
!warn "PRG extends ", prg_overlap, " bytes past image_base room load base - trim resident code/data"
} else {
!warn "PRG has ", -prg_overlap, " bytes free before image_base room load base"
}
