; zero page
;
; Layout map ($02-$FF game state; migration: hot pack was $62-$87, now $D6-$FB):
;
;   $02-$61   game scalars (px/py, pointers, guardian scratch hx..guard_axis $20-$28, etc.)
;   $62-$66   spawn_px/py, initial_room_load, room_has_rope, menx (unused)
;   $67       edge_cmp — CheckRoomEdge scratch (do not use tmp+1; $03 is arr)
;   $46/$47   left_right_ctr / up_down_ctr (guardian anim; moved off $9D/$9F)
;   $68-$87   rope_old_screen_pos (32 B ZP address table; sits below KERNAL $90-$93)
;   $88-$8F   rope draw scalars/pointers
;   $90-$93   KERNAL disk-I/O reserve — DO NOT place game ZP here (see below)
;   $94-$9F   rope draw temps + rope state scalars
;   $A0-$A5   player_overlap (6 B)
;   $A6-$D5   player_touch (48 B) — DrawPlayer clears $A0-$D5 each frame
;   $D6-$DB   (gap)
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
;   $033C-$35B     ROPE_SEGMENT_Y (32 B; cassette buffer, rope rooms only)
;   $35C-$391     rope_xadd (54 B; copied from PRG at WarmStart)
;   $392-$3FB     relocated code block B (see relocated_code.asm)
;   $B7   FNLEN    filename length (SETNAM)
;   $BB-$BC FNADR  filename pointer low/high (SETNAM)
;   $B8   LFN      logical file number (SETLFS)
;   $B9           secondary address (SETLFS)
;   $BA   LDEV     device number (SETLFS)
;   $C1-$C2 STAL  I/O start address low/high (LOAD) — not $AE/$AF
;   $C3-$C4       KERNAL setup pointer (LOAD)
; Reserve for KERNAL during disk I/O: $90-$93, $AE-$AF, $B7-$C4.
; CRITICAL: never place game ZP that is written during play in $90-$93.
; $90 (ST) is read by LOAD; a stray value there (bit6/bit7 set) makes LOAD
; think the transfer hit EOF/error and abort early, so the room never loads —
; the screen keeps the stale chars from before the load, and PaintColors then
; reads those as colour-table indices -> garbage / multicolour corruption.
; rope_old_screen_pos used to span $76-$95 and clobbered $90-$93; it now lives
; at $68-$87 (16 slots, ends $87, 4 slots clear of $90).
; CRITICAL (TRUE DRIVE EMULATION): under TDE the KERNAL LOAD performs a real IEC
; serial transfer that uses extra zero page beyond $90-$93:
;   $94 C3PO  — flag: serial output char buffered (tested by TALK/LISTEN; bit 7
;               set => a stray byte is sent first, desyncing the bus -> ST=$80)
;   $95 BSOUR — the buffered serial byte
;   $A3-$A5   — serial bit/EOI counters (KERNAL re-inits these per byte)
; rope_udg_mem lives at $94/$95, so each rope frame leaves a charset pointer
; there. LoadRoom now zeroes $94/$95 immediately before SETNAM so the rope can
; never poison the IEC transfer. Anything written during play that lands in
; $94/$95 (or that must survive a load) is therefore still unsafe long-term;
; prefer keeping serial-critical bytes ($90-$95, $A3-$A5) clear or clearing
; them in LoadRoom as done here.
; IEC LOAD also calls STOP scan each byte → writes $F5/$F6 (keyboard ptr).
; $AC-$AD tape/scroll pointers — no persistent game state there.
;
; Volatile across LoadRoom (loadram_test: SETNAM/SETLFS/LOAD/CLOSE).
; Assume overwritten; do not persist game state here between room loads:
;
;   $A0-$A5   jiffy/serial
;   $C5-$F4   KERNAL screen editor (keys, cursor, line/colour ptrs, line links).
;             Includes $C5/$CB (STOP scan), $C7-$D8, $F3/$F4; subset touched
;             each load; treat whole block as volatile. $D6 = KERNAL cursor row.
;   $0277-$29E  page-0 editor tail ($287 colour-under-cursor, $288 HIBASE, …)
;
; Candidate per-room gameplay scratch — rope erase, character
; clear temp buffer, etc. Do not persist state there across LoadRoom.
;
; Relocated resident code (WarmStart; survives KERNAL disk LOAD):
;   $0200-$258  reloc block A (FormatRoomName, DrawHud, ShouldMove*, SaveSpawn)
;   $0334-$33B  reloc block C (GetCollision)
;   $0392-$3FB  reloc block B (ConvertXYToScreenAddr, GetSpriteFrameAddr, CalcGuardian*)
;   $1000-$100C  reloc block D (ResetMap; overwrites BASIC stub after WarmStart entry)
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
; Rope: $68-$87 old_screen_pos (ZP ptr table); $88-$8F draw temps; $94-$9F state

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
ht              = $25
hfmax           = $26
hc              = $27
guard_axis      = $28

lastxmove       = $29
was_on_ground   = $2a
inairtime       = $2b
men             = $2c
stream_ptr      = $52
stream_ptr_hi   = $53

arr3            = $31

totalinairtime  = $51

rasterline      = $36

draw_player_offsets = $37
draw_player_chrs    = $3d

jumpIsPressed   = $0f          ; was $3C — freed $37-$42 for draw tables
leftIsPressed   = $12
rightIsPressed  = $2d

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
willy_hidden    = $66          ; 1 = ending sequence; skip player erase/input/draw
edge_cmp        = $67          ; CheckRoomEdge compare mode (must not use tmp+1 — that is arr)

ramp_tmp        = $54
ramp_y          = $55
is_in_ramp_bounds = $56
is_on_ramp      = $57

ts              = $50

guardian_index  = $61

; Rope block $68-$9F. The 32-byte (ptr,x) clear table goes FIRST (lowest) so it
; ends at $87 — four slots clear of the KERNAL disk-I/O reserve at $90-$93.
; NOTHING rope (or any other game ZP written during play) may land in $90-$93;
; see the KERNAL clobber map above for why ($90 = ST aborts LOAD).
rope_old_screen_pos = $68     ; 32 byte address table (16 slots) for (ptr,x) clears -> $68-$87
rope_udg            = $88
rope_frame          = $89
rope_swing_side     = $8a
rope_swing_dir      = $8b
rope_scr            = $8c     ; current rope screen addr (lo/hi) during rope_draw
rope_bit            = $8e
rope_y              = $8f
; --- $90-$93 KERNAL disk-I/O reserve: leave empty ---
rope_udg_mem        = $94
rope_index          = $96
rope_udg_advance    = $97
rope_willy_is_holding = $98
rope_willy_seg      = $99
rope_segment_cur_x  = $9a
rope_segment_cur_y  = $9b
rope_seg_skip_above = $9c
rope_loop_count     = $9d
rope_grab_cooldown  = $9e

cell_off_2x3        = $dc
lr_edge_px          = $e2
lr_touch_a          = $e4
lr_touch_b          = $e6
lr_touch_c          = $e8
draw_vguard_chrs    = $ea

left_right_ctr  = $46          ; moved off $9D so rope_old_screen_pos clears $90-$93
up_down_ctr     = $47

player_overlap  = $a0
player_touch    = $a6

vguard_frame    = $fc
hguard_frame    = $fd

; Page $0100 copied tables (WarmStart; stack must stay above $01B4)
edge_tbl        = $140
x24rowtab       = $158
jumptab         = $17c
