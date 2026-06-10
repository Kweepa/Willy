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

ITEM_CHR = 6

RASTERLINE_PAL      = $66
RASTERLINE_NTSC     = $54

udg_base = $1c00
guardian_udgs = udg_base + GUARDIAN_CHR*8
player_udg = udg_base + 58*8
propfont_udg = udg_base + 68*8

PLAY_CHR = 58
HEAD_CHR = 64
GUARDIAN_CHR = 22

GUARDIAN_HORIZONTAL = 0
GUARDIAN_VERTICAL = 17

RAMP_NONE = 0
RAMP_UP_RIGHT = 1
RAMP_UP_LEFT = 2

; px is quarter-char units; 24-col playfield (cols 0-23)
EDGE_EAST_PX = 92              ; column 23 — east exit when px >= 92
EDGE_EAST_ENTRY_PX = 4         ; west spawn when entering from the east
EDGE_WEST_ENTRY_PX = 88        ; east spawn when entering from the west (col 22, below east trigger)
