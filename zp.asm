; zero page
;
; Layout map ($02-$FF game state; migration: hot pack was $62-$87, now $D6-$FB):
;
;   $02-$61   game scalars (px/py, pointers, guardian hx..ht block at $20-$26, etc.)
;   $62-$66   spawn_px/py, initial_room_load, room_has_rope, menx (unused)
;   $67       edge_cmp — CheckRoomEdge scratch (do not use tmp+1; $03 is arr)
;   $6A-$75   rope draw temps
;   $76-$95   rope_old_screen_pos (32 B ZP address table)
;   $96-$9C   rope state scalars
;   $9D/$9F   left_right_ctr / up_down_ctr (guardian anim)
;   $A0-$A5   player_overlap (6 B) — overlaps KERNAL jiffy $A0-$A2 (see below)
;   $A6-$D5   player_touch (48 B) — DrawPlayer clears $A0-$D5 each frame; index touch at +0 only (never touch-1)
;   $D6-$DB   belt_opp_key (boot)
;   $DC-$E1   cell_off_2x3 (boot)
;   $E2-$E3   lr_edge_px (boot)
;   $E4-$E9   lr_touch_a/b/c (boot)
;   $EA-$EF   draw_vguard_chrs (boot)
;   $37-$3C   draw_player_offsets (boot) — off $F5 KERNAL keyboard ptr during LOAD
;   $3D-$42   draw_player_chrs (boot) — off $F6 KERNAL keyboard ptr during LOAD
;   $FC-$FD   vguard_frame / hguard_frame (dynamic)
;
; KERNAL clobber map — VIC-20 KERNAL (this build; not C64-only AAY labels):
;
; LoadRoom: SETNAM ($FFBD), SETLFS ($FFBA), LOAD ($FFD5)
; SETNAM stores filename length and pointer only — it does not copy the string
; and does not append ,P (device/SA come from SETLFS; ,P is a DOS directory type).
; room_name lives in PRG; pointer in $BB/$BC during LOAD.
;
;   $90   ST       serial status (LOAD / IEC)
;   $93           load/verify flag (LOAD)
;   $AE-$AF       load end pointer (tape buffer end; used during LOAD)
;   $B7   FNLEN    filename length (SETNAM)
;   $BB-$BC FNADR  filename pointer low/high (SETNAM)
;   $B8   LFN      logical file number (SETLFS)
;   $B9           secondary address (SETLFS)
;   $BA   LDEV     device number (SETLFS)
;   $C1-$C2 STAL  I/O start address low/high (LOAD) — not $AE/$AF
;   $C3-$C4       KERNAL setup pointer (LOAD)
; Reserve for KERNAL during disk I/O: $90-$93, $AE-$AF, $B7-$C4.
; IEC LOAD also calls STOP scan each byte → writes $F5/$F6 (keyboard ptr); not $D6-$F4.
; $AC-$AD tape/scroll pointers — no persistent game state there.
;
; $A0-$A2 jiffy clock (KERNAL IRQ) — first 3 bytes of player_overlap; game
; reuses them anyway (no BASIC; acceptable if overlap refreshed each DrawPlayer).
;
; WarmStart only: IOINIT ($FDF9) reinitialises much of low ZP ($22+, $30+, $90+).
;
; Page $0100 copied tables (WarmStart; stack must stay above $01B4):
;   $100-$13D  pickup_got
;   $140-$157  edge_tbl (24 B)
;   $158-$177  x24rowtab (32 B)
;   $17C-$1B5  jumptab (58 B)
;
; Copied const tables (WarmStart; see runtime_const.asm boot pack):
;   $D6-$EF  belt..draw_vguard (26 B); $37-$42 draw_player tables (12 B)
;   must avoid $A0-$D5 (DrawPlayer overlap clear)
; Rope: $6A-$75 draw temps; $76-$95 old_screen_pos (ZP ptr table); $96-$9C state

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
stream_ptr      = $52
stream_ptr_hi   = $53

arr3            = $31

totalinairtime  = $51

rasterline      = $36

draw_player_offsets = $37
draw_player_chrs    = $3d

jumpIsPressed   = $0f          ; was $3C — freed $37-$42 for draw tables

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

spawn_px        = $62          ; respawn position (before rope block; not in old_screen table)
spawn_py        = $63
initial_room_load = $64        ; 1 = first DrawMap after ResetGame (use @spawn)
room_has_rope   = $65
menx            = $66          ; unused; kept off rope_old_screen_pos ($76+)
edge_cmp        = $67          ; CheckRoomEdge compare mode (must not use tmp+1 — that is arr)

ramp_tmp        = $54
ramp_y          = $55
is_in_ramp_bounds = $56
is_on_ramp      = $57

ts              = $50

guardian_index  = $61

rope_udg            = $6a
rope_frame          = $6b
rope_swing_side     = $6c
rope_swing_dir      = $6d
rope_scr            = $6e     ; current rope screen addr (lo/hi) during rope_draw
rope_bit            = $70
rope_y              = $71
rope_udg_mem        = $72
rope_index          = $74
rope_udg_advance    = $75
rope_old_screen_pos = $76     ; 32 byte address table (16 slots) for (ptr,x) clears
rope_willy_is_holding = $96
rope_willy_seg      = $97
rope_segment_cur_x  = $98
rope_segment_cur_y  = $99
rope_seg_skip_above = $9a
rope_loop_count     = $9b
rope_grab_cooldown  = $9c

belt_opp_key        = $d6
cell_off_2x3        = $dc
lr_edge_px          = $e2
lr_touch_a          = $e4
lr_touch_b          = $e6
lr_touch_c          = $e8
draw_vguard_chrs    = $ea

left_right_ctr  = $9d
up_down_ctr     = $9f

player_overlap  = $a0
player_touch    = $a6

vguard_frame    = $fc
hguard_frame    = $fd

; Page $0100 copied tables (WarmStart; stack must stay above $01B4)
edge_tbl        = $140
x24rowtab       = $158
jumptab         = $17c
