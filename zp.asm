; zero page
tmp             = $02
arr             = $03
scr_ptr         = $05
col_ptr         = $07
num             = $09
run             = $0a
typ             = $0b
col             = $0c
mov             = $0d

xadd            = $0e
yadd            = $0f
px              = $10
py              = $11
arr2            = $13
map_ptr         = $15
dead            = $17
on_ground       = $18
items_left      = $19
udg_ptr         = $1a
play_udg        = $1c
newy            = $1f

hx              = $20
hy              = $21
hl              = $22
hr              = $23
hd              = $24
hc				= $25
ht				= $26

lastxmove       = $27
was_on_ground   = $28
inairtime       = $29
men             = $2a
menx            = $84          ; was $2b (TXTTAB) - unused, kept off BASIC ZP
items_total     = $85          ; was $2d (VARTAB) - must not clobber KERNAL LOAD
stream_ptr      = $52
stream_ptr_hi   = $53

arr3			= $31

totalinairtime  = $51

rasterline      = $36
jumpIsPressed   = $3c
music_index     = $3d
music_delay     = $3e
music_note		= $3f
music_mod       = $42
music_bit       = $45

hguardian_index = $46
vguardian_index = $47
guard_udg_off   = $48
guard_udg_index = $49

hguard_count    = $4a
vguard_count    = $4b

game_time       = $4c
game_time_hi    = $4d
last_py         = $4e
belt_active     = $4f
tmp_xadd        = $30

align_tmp       = $58
entry_px        = $59
entry_py        = $5a
map             = $5b
use_room_spawn  = $5f          ; 1 = ParseRoomMeta sets px/py from @spawn
initial_room_load = $86        ; 1 = first DrawMap after ResetGame (use @spawn)
spawn_px        = $87          ; respawn position (game start or last room entry)
spawn_py        = $88

ramp_tmp        = $54
ramp_tmp1       = $55
ramp_tmp2       = $56
ramp_tmp3       = $57

ts              = $50

guardian_index  = $61
item_count      = $94

items_buf       = $d6

left_right_ctr  = $9d
up_down_ctr     = $9f

player_overlap  = $a0
player_touch    = $a6

frame_ctr		= $e6

stringwidth     = $e8
stringindex     = $e9
stringstart     = $ea
stringxdiv		= $eb
stringxmod		= $ec
stringcur		= $ed
stringleft		= $ee
stringright		= $ef
stringrow		= $f0

vguard_frame    = $f7
hguard_frame	= $f8
