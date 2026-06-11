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

TILE_CHR_BASE = 16
ITEM_CHR = 15
GUARDIAN_CHR = 22
PLAY_CHR = 58

udg_base = $1c00
guardian_udgs = udg_base + GUARDIAN_CHR*8
player_udg = udg_base + PLAY_CHR*8

; Screen shifted down 4 tile rows ($9001); sync below playfield by same amount
SCREEN_DOWN_RASTER  = 16
RASTERLINE_PAL      = $66 + SCREEN_DOWN_RASTER
RASTERLINE_NTSC     = $54 + SCREEN_DOWN_RASTER

GUARDIAN_HORIZONTAL = 0
GUARDIAN_VERTICAL = 1

; player frames are indices 8-15 in the 512-byte guardian_sprites_base block
PLAYER_SPRITE_FRAME = 8

RAMP_NONE = 0
RAMP_UP_RIGHT = 1
RAMP_UP_LEFT = 2

; px is quarter-char units; 24-col playfield (cols 0-23)
EDGE_EAST_PX = 92              ; column 23 - east exit when px >= 92
EDGE_EAST_ENTRY_PX = 4         ; west spawn when entering from the east
EDGE_WEST_ENTRY_PX = 88        ; east spawn when entering from the west (col 22, below east trigger)
