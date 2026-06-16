; zero page
;
; KERNAL clobber map (routines this project calls):
;
; LoadRoom: SETNAM ($FFBD), SETLFS ($FFBA), LOAD ($FFD5)
;   $90   ST       serial status (LOAD)
;   $93           load/verify flag (LOAD)
;   $AE   STAL     load address ptr low (LOAD, overwritten)
;   $AF   SAHA     load address ptr high (LOAD, overwritten)
;   $B7   FNMLEN   filename length (SETNAM)
;   $BB           filename pointer low (SETNAM)
;   $BC           filename pointer high (SETNAM)
;   $B8   LFN      logical file number (SETLFS)
;   $BA   LDEV     device number (SETLFS)
;   $B9           secondary address (SETLFS)
;   $C3-$C4       KERNAL setup pointer (LOAD)
; Reserve for KERNAL during disk I/O: $90-$93, $AE-$AF, $B7-$C4.
; $AC-$AD tape/scroll pointers — no persistent game state there.
;
; WarmStart only: IOINIT ($FDF9) reinitialises much of low ZP ($22+, $30+, $90+).
;
; Copied const tables (WarmStart; see runtime_const.asm boot pack):
;   $62-$87  hot tables (38 B)
; Do not place new game symbols in $62-$87 or the KERNAL reserve bands above.

tmp             = $02
arr             = $03
scr_ptr         = $05
col_ptr         = $07
num             = $09
run             = $0a
col             = $0c
mov             = $0d

xadd            = $0e
px              = $10
py              = $11
arr2            = $13
map_ptr         = $15
dead            = $17
on_ground       = $18
items_collected = $19
udg_ptr         = $1a
play_udg        = $1c
newy            = $1f

hx              = $20
hy              = $21
hl              = $22
hr              = $23
hd              = $24
hc              = $25
ht              = $26

lastxmove       = $27
was_on_ground   = $28
inairtime       = $29
men             = $2a
menx            = $84          ; was $2b (TXTTAB) - unused, kept off BASIC ZP
stream_ptr      = $52
stream_ptr_hi   = $53

arr3            = $31

totalinairtime  = $51

rasterline      = $36
jumpIsPressed   = $3c

guard_udg_off   = $48
guard_udg_index = $49

hguard_count    = $4a
vguard_count    = $4b

last_py         = $4e
belt_active     = $4f
tmp_xadd        = $30

align_tmp       = $58
entry_px        = $59
entry_py        = $5a
map             = $5b
use_room_spawn  = $5f          ; 1 = ParseRoomMeta sets px/py from @spawn

spawn_px        = $89          ; respawn position (game start or last room entry)
spawn_py        = $8a
initial_room_load = $8b        ; 1 = first DrawMap after ResetGame (use @spawn)

ramp_tmp        = $54
ramp_y          = $55
is_in_ramp_bounds = $56
is_on_ramp      = $57

ts              = $50

guardian_index  = $61

belt_opp_key        = $62
cell_off_2x3        = $68
lr_edge_px          = $6e
lr_touch_a          = $70
lr_touch_b          = $72
lr_touch_c          = $74
draw_vguard_chrs    = $76
draw_player_offsets = $7c
draw_player_chrs    = $82

left_right_ctr  = $9d
up_down_ctr     = $9f

player_overlap  = $a0
player_touch    = $a6

vguard_frame    = $f7
hguard_frame    = $f8

; Page $0100 copied tables (WarmStart; stack must stay above $01B4)
edge_tbl        = $140
x24rowtab       = $158
jumptab         = $17c
