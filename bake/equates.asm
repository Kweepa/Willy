; Shared equates for per-room bake templates (assembled at org $0000).

!source "../defines.asm"

left_right_ctr  = $46          ; keep in sync with zp.asm (moved off $9D)
belt_active     = $4f
xadd            = $0e
lastxmove       = $4c

conveyor_udg_lo = $1ca8
conveyor_udg_hi = $1caa

; Conveyor oppose rows — must match GetPlayerInput left/right (QW/OP)
belt_opp_right_row   = $fd
belt_opp_right_xadd  = $01

belt_opp_left_row   = $bf
belt_opp_left_xadd  = $ff

belt_push_left  = $ff
belt_push_right = $01
