BLACK = 0
WHITE = 1
RED = 2
CYAN = 3
PURPLE = 4
GREEN = 5
BLUE = 6
YELLOW = 7

TILE_EMPTY = 0
TILE_PLATFORM = 1
TILE_SOLID = 2
TILE_HAZARD = 3
TILE_RAMP = 4
TILE_CONVEYOR = 5
TILE_ITEM = 6                   ; map-only marker for pickup cell (not in author tilemap)

TILE_CHR_BASE = 16
ITEM_CHR = 15
MEN_CHR = 13                    ; HUD men icon @ $1C68 (hud_udg_base)
HUD_ITEM_CHR = 14               ; HUD items icon @ $1C70
GUARDIAN_CHR = 22
PLAY_CHR = 58

udg_base = $1c00
guardian_udgs = udg_base + GUARDIAN_CHR*8
player_udg = udg_base + PLAY_CHR*8

; Sync at row 15/16 boundary (below playfield, above HUD). Screen shifted down ($9001 = $32).
RASTERLINE_PAL      = $6E
RASTERLINE_NTSC     = $62

GUARDIAN_HORIZONTAL = 0
GUARDIAN_VERTICAL = 1

; player frames are indices 9-16 in the guardian_sprites_base + player_bmp block
PLAYER_SPRITE_FRAME = 9

RAMP_NONE = 0
RAMP_UP_RIGHT = 1
RAMP_UP_LEFT = $FF

; Endgame: collect ITEMS_REQUIRED pickups, enter master bedroom (Maria vanishes),
; walk to ENDING_TRIGGER_PX, then teleport to bathroom for the toilet ending.
ITEMS_REQUIRED = 2
ROOM_MASTER_BED = 35
ROOM_BATHROOM = 33
ROOM_START = 1
ROOM_TITLE = 62
ENDING_TRIGGER_PX = 20

; px is quarter-char units; 24-col playfield (cols 0-23)
; Room transitions use hysteresis: exit threshold vs entry px differ by 1.
EDGE_WEST_PX = 0               ; west exit when px <= 0
EDGE_EAST_PX = 91              ; east exit when px >= 91
EDGE_EAST_ENTRY_PX = 1         ; entering from the east (spawn west side)
EDGE_WEST_ENTRY_PX = 90        ; entering from the west (spawn east side)

; 1 = emit border colour writes for raster timing bars; 0 = no code/size cost
BORDER_DEBUG = 0

; Rope constants (addresses in header.asm)
ROPE_ANCHOR_COL = 12
ROPE_ANCHOR_PY = 8
ROPE_FIRST_UDG = GUARDIAN_CHR + 12
ROPE_UDG_BYTES = 128
ROPE_XADD_BYTES = 54
ROPE_GRAB_COOLDOWN_MAX = 60
ROPE_SEG_MAX = 31
