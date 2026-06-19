#!/usr/bin/env python3
"""Convert roomNN.txt source files to PRG room binaries for JSW VIC-20."""

import argparse
import re
import struct
import subprocess
import sys
from pathlib import Path

WIDTH = 24


def normalize_tilemap_row(row: str) -> str:
    """Trim overlong rows; pad short rows with spaces to exactly WIDTH."""
    return row[:WIDTH].ljust(WIDTH)


SCREEN_ROWS = 17              # gameplay 0-15 + HUD row 16
TILEMAP_ROWS = 16             # @tilemap lines (gameplay only)
TILE_BYTES = WIDTH * SCREEN_ROWS
UDG_BYTES = 56
TILE_COLOR_BYTES = 6
ITEM_DRAW_BYTES = 16
BAKE_DIR = Path(__file__).resolve().parent.parent / "bake"
ACME = Path(r"\app\acme\acme.exe")
JSW_LBL = Path(__file__).resolve().parent.parent / "jsw.lbl"
GUARDIAN_SPRITES_BYTES = 288  # 9 frames x 32 bytes
META_OFF_ROPE = 31
TAIL_OFF_TILECOLORS = 32
TAIL_OFF_GUARDIAN_DATA = 38
PLAYER_BMP_BYTES = 256
NIGHTMARE_ROOM_ID = 29
DEFAULT_PLAYER_BMP_PATH = (
    Path(__file__).resolve().parent.parent / "willy.txt"
)
NIGHTMARE_PLAYER_BMP_PATH = (
    Path(__file__).resolve().parent.parent / "nightmareroomwilly.txt"
)
GUARDIAN_DATA_BYTES = 54          # AoS: 9 bytes x 6 guardians
GUARDIAN_RECORD_BYTES = 9
MAX_GUARDIANS = 6
TAIL_BYTES = 104
META_SIZE = 15 + ITEM_DRAW_BYTES
IMAGE_LOAD = 0x1A24
CONVEYOR_PREFIX_BYTES = 19
DO_BELT_SLOT_BYTES = 33
GUARDIAN_PREFIX_BYTES = CONVEYOR_PREFIX_BYTES + DO_BELT_SLOT_BYTES
SCREEN_BASE = 0x1E00
MAP_BASE = 0x9400
COLOR_BASE = 0x9600
MAX_ITEMS = 1
ROOM_IMAGE_SIZE = 0x5DC           # 1500 bytes ($1A24-$1FFF)
# Pad pins screen at $1E00: IMAGE_LOAD + prefix + sprites + player + udg + pad == SCREEN_BASE
RUNTIME_UDG_PAD = 0x150           # 336 bytes ($1CB0-$1DFF)
TILE_CHR_BASE = 16
TILE_EMPTY = 0
TILE_PLATFORM = 1
TILE_SOLID = 2
TILE_HAZARD = 3
TILE_RAMP = 4
TILE_CONVEYOR = 5
TILE_ITEM = 6
RAMP_NONE = 0
RAMP_UP_RIGHT = 1
RAMP_UP_LEFT = 0xFF
RAMP_BOUNDS_NONE = 99
TILE_CHAR_MAP = {
    " ": TILE_EMPTY,
    ".": TILE_EMPTY,
    "F": TILE_PLATFORM,
    "W": TILE_SOLID,
    "*": TILE_HAZARD,
    "/": TILE_RAMP,
    "\\": TILE_RAMP,
    "<": TILE_CONVEYOR,
    ">": TILE_CONVEYOR,
}
ITEM_CHR = 15
MEN_CHR = 3
HUD_TITLE_COLS = 18
DEFAULT_TILE_COLORS = [0, 1, 3, 2, 5, 4]
DEFAULT_ITEM_UDG = bytes([48, 72, 136, 144, 104, 4, 10, 4])

VIC_COLOR = {
    "BLK": 0,
    "WHT": 1,
    "RED": 2,
    "CYN": 3,
    "PUR": 4,
    "GRN": 5,
    "BLU": 6,
    "YEL": 7,
}

GUARDIAN_DSL_H = re.compile(
    r"y\s*=\s*(\d+)\s+"
    r"x\s*=\s*(\d+)\((\d+)\.\.(\d+)\)\s+"
    r"v\s*=\s*([+-]?\d+)\s+"
    r"f\s*=\s*(\d+)(?:\.\.(\d+))?\s+"
    r"(\w+)",
    re.I,
)
GUARDIAN_DSL_V = re.compile(
    r"x\s*=\s*(\d+)\s+"
    r"y\s*=\s*(\d+)\((\d+)\.\.(\d+)\)\s+"
    r"v\s*=\s*([+-]?\d+)\s+"
    r"f\s*=\s*(\d+)(?:\.\.(\d+))?\s+"
    r"(\w+)",
    re.I,
)

G_OFF_X = 0
G_OFF_Y = 1
G_OFF_MIN = 2
G_OFF_MAX = 3
G_OFF_VEL = 4
G_OFF_FMIN = 5
G_OFF_FMAX = 6
G_OFF_COLOR = 7
G_OFF_AXIS = 8


def parse_byte(s: str) -> int:
    """Parse a byte value; decimal by default (Skoolkit style), optional $FF hex."""
    s = s.strip().upper()
    if s.startswith("$"):
        v = int(s[1:], 16)
    elif s.startswith("0X"):
        v = int(s[2:], 16)
    else:
        v = int(s)
    if not 0 <= v <= 255:
        raise ValueError(f"byte out of range 0-255: {v}")
    return v


def parse_vic_color(token: str) -> int:
    """Parse a VIC colour token: name (BLK, WHT, …) or digit 0-7."""
    s = token.strip().upper()
    if s in VIC_COLOR:
        return VIC_COLOR[s]
    if len(s) == 1 and s.isdigit():
        v = int(s)
        if v > 7:
            raise ValueError(f"tile color out of range 0-7: {v}")
        return v
    names = ", ".join(VIC_COLOR)
    raise ValueError(f"unknown colour {token!r} (use {names})")


def parse_byte_list(text: str) -> list[int]:
    """Comma-separated byte list (Skoolkit style): 0, 0, 255, 24."""
    return [parse_byte(part) for part in text.split(",") if part.strip()]


def parse_velocity(text: str) -> int:
    v = int(text.strip())
    return v & 0xFF


def fmt_loc(source: Path | str | None = None, line_no: int | None = None) -> str:
    if not source:
        return ""
    loc = str(source)
    if line_no is not None:
        loc += f":{line_no}"
    return loc + ": "


def room_error(room: dict | None, msg: str) -> ValueError:
    if room:
        src = room.get("_source")
        rid = room.get("id", "?")
        if src:
            return ValueError(f"{src} (room {rid}): {msg}")
        if rid != "?":
            return ValueError(f"room {rid}: {msg}")
    return ValueError(msg)


def parse_guardian_line(
    line: str, *, source: Path | str | None = None, line_no: int | None = None
) -> dict:
    """Parse guardian DSL line into SoA field dict."""
    loc = fmt_loc(source, line_no)
    m = GUARDIAN_DSL_H.match(line)
    if m:
        hy, x_tile, xmin, xmax, vel, fmin, fmax, colour = m.groups()
        gx = int(x_tile) * 4
        gmin = int(xmin) * 4
        gmax = int(xmax) * 4 - 1
        gy = int(hy)
        axis = 0
    else:
        m = GUARDIAN_DSL_V.match(line)
        if not m:
            raise ValueError(f"{loc}bad @guardians line: {line!r}")
        x_tile, gy, ymin, ymax, vel, fmin, fmax, colour = m.groups()
        gx = int(x_tile) * 4
        gy = int(gy)
        gmin = int(ymin)
        gmax = int(ymax)
        axis = 1

    fmin_i = int(fmin)
    fmax_i = int(fmax) if fmax is not None else fmin_i
    if not 0 <= fmin_i <= 8 or not 0 <= fmax_i <= 8 or fmin_i > fmax_i:
        raise ValueError(f"{loc}frame range out of range 0-8: {fmin}..{fmax}")

    if axis == 1:
        frame_count = fmax_i - fmin_i + 1
        if frame_count not in (1, 2, 4):
            raise ValueError(
                f"{loc}vertical guardian frame count must be 1, 2, or 4: {fmin}..{fmax}"
            )
        fmax_store = frame_count - 1  # mask: 0, 1, or 3
    else:
        fmax_store = fmax_i

    return {
        "x": gx & 0xFF,
        "y": gy & 0xFF,
        "min": gmin & 0xFF,
        "max": gmax & 0xFF,
        "vel": parse_velocity(vel),
        "fmin": fmin_i,
        "fmax": fmax_store,
        "color": parse_vic_color(colour),
        "axis": axis,
    }


def parse_tile_char(ch: str, room: dict | None = None) -> int:
    """Map ASCII tilemap character to tile type 0-5. '+' bakes as empty."""
    if ch == "+":
        return TILE_EMPTY
    try:
        return TILE_CHAR_MAP[ch]
    except KeyError:
        raise room_error(room, f"unknown tilemap character {ch!r}")


def extract_item_from_tilemap(
    tilemap: list, room: dict | None = None
) -> tuple[int, int]:
    """Return (col, row) of the single '+' pickup marker."""
    found: list[tuple[int, int]] = []
    for row, line in enumerate(tilemap):
        if row >= TILEMAP_ROWS:
            continue
        for col, ch in enumerate(line):
            if ch == "+":
                found.append((col, row))
    if len(found) != MAX_ITEMS:
        raise room_error(
            room,
            f"tilemap must have exactly {MAX_ITEMS} '+' pickup marker(s), found {len(found)}",
        )
    return found[0]


def infer_ramp_from_tilemap(
    tilemap: list, room: dict | None = None
) -> int:
    """Derive ramp type from '/' (up-right) or '\\' (up-left) tiles."""
    has_up_right = False
    has_up_left = False
    for row, line in enumerate(tilemap):
        if row >= TILEMAP_ROWS:
            continue
        for ch in line:
            if ch == "/":
                has_up_right = True
            elif ch == "\\":
                has_up_left = True
    if has_up_right and has_up_left:
        raise room_error(room, "tilemap has mixed ramp directions ('/' and '\\')")
    if has_up_right:
        return RAMP_UP_RIGHT
    if has_up_left:
        return RAMP_UP_LEFT
    return RAMP_NONE


def validate_tilemap_belt(
    tilemap: list, belt: int, room: dict | None = None
) -> None:
    """Check conveyor chars match @belt direction."""
    for row, line in enumerate(tilemap):
        if row >= TILEMAP_ROWS:
            continue
        for col, ch in enumerate(line):
            if ch == "<" and belt == 1:
                raise room_error(
                    room,
                    f"conveyor '<' at col {col} row {row} but @belt 1 (expect '>')",
                )
            elif ch == ">" and belt == -1:
                raise room_error(
                    room,
                    f"conveyor '>' at col {col} row {row} but @belt -1 (expect '<')",
                )


def parse_room(text: str, source: Path | str | None = None) -> dict:
    lines = text.splitlines()
    loc = lambda line_no=None: fmt_loc(source, line_no)
    room = {
        "id": 0,
        "title": "",
        "conn": [0xFF, 0xFF, 0xFF, 0xFF],
        "spawn": (0, 0),
        "border": 0,
        "belt": 0,
        "ramp": 0,
        "tilemap": [],
        "tilecolors": list(DEFAULT_TILE_COLORS),
        "itemcolor": 7,
        "items": [],
        "guardians": [],
        "tileudg": [bytes(8) for _ in range(6)] + [DEFAULT_ITEM_UDG],
        "guardiansprites": b"",
        "playerbmp": b"",
        "rope": False,
    }
    block = None
    block_lines = []

    def flush_block():
        nonlocal block, block_lines
        if block == "tilemap":
            room["tilemap"] = [normalize_tilemap_row(line) for line in block_lines]
        elif block == "tileudg":
            for line in block_lines:
                m = re.match(r"(\d+)\s*:\s*(.+)", line.strip(), re.I)
                if not m:
                    continue
                idx = int(m.group(1))
                content = m.group(2).strip()
                invert = False
                if ";" in content:
                    left, right = content.split(";", 1)
                    if "INVERT" in right.upper():
                        invert = True
                    content = left.strip()
                bs = parse_byte_list(content)
                if idx < 7 and len(bs) == 8:
                    if invert:
                        bs = [b ^ 0xFF for b in bs]
                    room["tileudg"][idx] = bytes(bs)
        elif block == "guardiansprites":
            bs = []
            for line in block_lines:
                if line.strip().startswith(";"):
                    continue
                bs.extend(parse_byte_list(line))
            room["guardiansprites"] = bytes(bs[:GUARDIAN_SPRITES_BYTES]).ljust(
                GUARDIAN_SPRITES_BYTES, b"\x00"
            )
        elif block == "playerbmp":
            bs = []
            for line in block_lines:
                if line.strip().startswith(";"):
                    continue
                bs.extend(parse_byte_list(line))
            room["playerbmp"] = bytes(bs[:PLAYER_BMP_BYTES]).ljust(
                PLAYER_BMP_BYTES, b"\x00"
            )
        block = None
        block_lines.clear()

    for line_no, raw in enumerate(lines, start=1):
        raw_content = raw.split("#", 1)[0].rstrip("\r\n")
        line = raw_content.strip()
        if line.startswith("@"):
            flush_block()
            parts = line.split()
            tag = parts[0][1:].lower()
            if tag in (
                "tilemap",
                "tileudg",
                "guardiansprites",
                "playerbmp",
                "guardians",
            ):
                block = tag
                continue
            if tag == "room":
                room["id"] = int(parts[1])
            elif tag == "title":
                room["title"] = line.split(None, 1)[1]
            elif tag == "conn":
                room["conn"] = [parse_byte(x) for x in parts[1:5]]
            elif tag == "spawn":
                room["spawn"] = (int(parts[1]), int(parts[2]))
            elif tag == "border":
                room["border"] = parse_vic_color(parts[1])
            elif tag == "belt":
                room["belt"] = int(parts[1])
            elif tag == "rope":
                room["rope"] = True
            elif tag == "tilecolors":
                if len(parts[1:]) != TILE_COLOR_BYTES:
                    raise ValueError(
                        f"{loc(line_no)}@tilecolors needs {TILE_COLOR_BYTES} values (tile types 0-5)"
                    )
                room["tilecolors"] = [parse_vic_color(x) for x in parts[1:7]]
            elif tag == "itemcolor":
                room["itemcolor"] = parse_vic_color(parts[1])
            continue
        if block == "tilemap":
            if raw_content.lstrip().startswith(";"):
                continue
            if not raw_content and not line:
                continue
            block_lines.append(raw_content)
            continue
        if not line or line.startswith(";"):
            continue
        if block == "guardians":
            if line:
                room["guardians"].append(
                    parse_guardian_line(line, source=source, line_no=line_no)
                )
        elif block in ("tileudg", "guardiansprites", "playerbmp"):
            block_lines.append(line)
    flush_block()
    room["items"] = [extract_item_from_tilemap(room["tilemap"], room)]
    room["ramp"] = infer_ramp_from_tilemap(room["tilemap"], room)
    validate_tilemap_belt(room["tilemap"], room["belt"], room)
    if source:
        room["_source"] = str(source)
    return room


def grid_bytes(rows: list, name: str, room: dict | None = None) -> bytes:
    if len(rows) != TILEMAP_ROWS:
        raise room_error(
            room, f"{name}: expected {TILEMAP_ROWS} rows, got {len(rows)}"
        )
    out = bytearray()
    for r, row in enumerate(rows):
        row = normalize_tilemap_row(row)
        for ch in row:
            v = parse_tile_char(ch, room)
            out.append(v + TILE_CHR_BASE)
    out.extend([TILE_CHR_BASE] * WIDTH)  # HUD row 16 — title stamped later
    return bytes(out)


def ascii_to_rom_screen(ch: str) -> int:
    """Map ASCII to screen codes 128-255 (ROM charset with bit 7 set)."""
    code = ord(ch)
    if 65 <= code <= 90:
        return code + 64
    if 48 <= code <= 57:
        return code + 128
    return code + 128


def stamp_hud_title(tiles: bytearray, room: dict) -> None:
    title = room["title"].upper().ljust(HUD_TITLE_COLS)[:HUD_TITLE_COLS]
    base = (SCREEN_ROWS - 1) * WIDTH
    for i, ch in enumerate(title):
        tiles[base + i] = ascii_to_rom_screen(ch)


def stamp_hud_men(tiles: bytearray) -> None:
    """HUD row 16 col 18 — Willy head (chr 7 = player_bmp+$c0); count at col 19 runtime."""
    base = (SCREEN_ROWS - 1) * WIDTH + 18
    tiles[base] = MEN_CHR


def stamp_hud_item(tiles: bytearray) -> None:
    """HUD row 16 col 21 — item icon (chr 15); count drawn at cols 22-23 at runtime."""
    base = (SCREEN_ROWS - 1) * WIDTH + 21
    tiles[base] = ITEM_CHR


def belt_byte(speed: int) -> int:
    return speed & 0xFF


def load_scan_key_row() -> int:
    """Resident ScanKeyRow address from jsw.lbl (assemble jsw.prg first)."""
    if not JSW_LBL.is_file():
        raise ValueError(f"missing {JSW_LBL}; assemble jsw.prg before mkroom")
    for line in JSW_LBL.read_text(encoding="utf-8").splitlines():
        m = re.match(r"al C:([0-9a-f]+) \.ScanKeyRow", line, re.I)
        if m:
            return int(m.group(1), 16)
    raise ValueError(f"ScanKeyRow not found in {JSW_LBL}")


def assemble_room_code(
    asm_name: str,
    defines: dict[str, int],
    slot_bytes: int | None = None,
) -> bytes:
    """Assemble a bake/*.asm template to raw bytes via ACME (-f plain)."""
    if not ACME.is_file():
        raise ValueError(f"ACME not found at {ACME}")
    asm_path = BAKE_DIR / asm_name
    if not asm_path.is_file():
        raise ValueError(f"missing bake source {asm_path}")
    tmp_dir = BAKE_DIR / ".tmp"
    tmp_dir.mkdir(exist_ok=True)
    out_path = tmp_dir / f"{asm_path.stem}.bin"
    args = [str(ACME), "-f", "plain", "-o", str(out_path)]
    if slot_bytes is not None:
        defines = {**defines, "SLOT_BYTES": slot_bytes}
    for key, value in defines.items():
        args.append(f"-D{key}=${value:x}")
    args.append(str(asm_path))
    result = subprocess.run(
        args,
        cwd=BAKE_DIR,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        msg = result.stderr.strip() or result.stdout.strip() or "ACME failed"
        raise ValueError(f"{asm_name}: {msg}")
    data = out_path.read_bytes()
    if slot_bytes is not None and len(data) != slot_bytes:
        raise ValueError(
            f"{asm_name}: size {len(data)} != slot {slot_bytes}"
        )
    return data


def build_conveyor_animate(room: dict) -> bytes:
    """19 bytes at image_base — ACME bake/animate_conveyors.asm."""
    return assemble_room_code(
        "animate_conveyors.asm",
        {"BELT": belt_byte(room["belt"])},
        CONVEYOR_PREFIX_BYTES,
    )


def build_do_belt(room: dict, scan_key_row: int) -> bytes:
    """DoBelt prefix slot — ACME bake/do_belt.asm."""
    return assemble_room_code(
        "do_belt.asm",
        {"BELT": belt_byte(room["belt"]), "SCANKEYROW": scan_key_row},
        DO_BELT_SLOT_BYTES,
    )


def build_prefix(room: dict, scan_key_row: int) -> bytes:
    return build_conveyor_animate(room) + build_do_belt(room, scan_key_row)


def build_item_draw(room: dict) -> bytes:
    """16 bytes in meta tail — ACME bake/item_draw.asm."""
    col, row = room["items"][0]
    if not 0 <= col < WIDTH or not 0 <= row < TILEMAP_ROWS:
        raise room_error(room, f"item cell out of range: col={col} row={row}")
    cell_off = row * WIDTH + col
    scr_addr = SCREEN_BASE + cell_off
    map_addr = scr_addr + (MAP_BASE - SCREEN_BASE)
    col_addr = COLOR_BASE + cell_off
    return assemble_room_code(
        "item_draw.asm",
        {
            "SCR_ADDR": scr_addr,
            "COL_ADDR": col_addr,
            "MAP_ADDR": map_addr,
            "ITEM_COLOR": room["itemcolor"] & 0xFF,
            "ITEM_CHR": ITEM_CHR,
            "TILE_ITEM": TILE_ITEM,
        },
        ITEM_DRAW_BYTES,
    )


# Feet py = surface - RAMP_FEET_OFFSET - toe[ramp_type]
RAMP_FEET_OFFSET = 16
RAMP_RY_TOE: dict[int, int] = {
    RAMP_UP_RIGHT: 0,
    RAMP_UP_LEFT: 6,
}


def ramp_surface_abs(
    px: int,
    col_start: int,
    col_end: int,
    row_start: int,
    row_step: int,
    ramp_type: int,
) -> int:
    """Absolute Y of ramp walking surface at px."""
    mid_col = (px + 3) >> 2
    feet_row = row_start + (mid_col - col_start) * row_step
    x_offset = ((px + 3) & 3) * 2
    if ramp_type == RAMP_UP_RIGHT:
        y_surface = 6 - x_offset
    else:
        y_surface = x_offset
    return feet_row * 8 + y_surface


def ramp_baked_ry(
    rx1: int,
    col_start: int,
    col_end: int,
    row_start: int,
    row_step: int,
    ramp_type: int,
) -> int:
    """Baked meta ry: feet py at ramp entry px rx1."""
    toe = RAMP_RY_TOE.get(ramp_type, 0)
    return (
        ramp_surface_abs(rx1, col_start, col_end, row_start, row_step, ramp_type)
        - RAMP_FEET_OFFSET
        - toe
    )


def derive_ramp_bounds(
    tilemap: list, ramp_type: int, room: dict | None = None
) -> tuple[int, int, int, int]:
    """Return (col_start, col_end, row_start, row_step) for room meta."""
    cells: list[tuple[int, int]] = []
    for row, line in enumerate(tilemap):
        if row >= TILEMAP_ROWS:
            continue
        for col, ch in enumerate(line):
            if ch in ("/", "\\"):
                cells.append((col, row))

    if ramp_type == RAMP_NONE:
        return (0, 0, 0, 0)

    if not cells:
        raise room_error(room, "ramp type set but no ramp tiles (/ or \\) in tilemap")

    col_start = min(col for col, _ in cells)
    col_end = max(col for col, _ in cells)

    by_col: dict[int, list[int]] = {}
    for col, row in cells:
        by_col.setdefault(col, []).append(row)

    for col in range(col_start, col_end + 1):
        if col not in by_col or len(by_col[col]) != 1:
            raise room_error(room, f"ramp gap or multiple tiles in column {col}")

    row_start = by_col[col_start][0]
    if col_end == col_start:
        row_step = 0
    else:
        row_step = by_col[col_start + 1][0] - row_start
        if row_step not in (-1, 0, 1):
            raise room_error(room, f"invalid ramp row step {row_step}")
        for col in range(col_start, col_end + 1):
            expected = row_start + (col - col_start) * row_step
            if by_col[col][0] != expected:
                raise room_error(
                    room,
                    f"ramp row mismatch at col {col}: expected {expected}, got {by_col[col][0]}",
                )

    return (col_start, col_end, row_start, row_step & 0xFF)


def derive_ramp_params(
    tilemap: list, ramp_type: int, room: dict | None = None
) -> tuple[int, int, int, int, int]:
    """Return baked (rx1, rx2, ry, E, A) px bounds and slope sign."""
    if ramp_type == RAMP_NONE:
        return (RAMP_BOUNDS_NONE, RAMP_BOUNDS_NONE, 0, 0, 0)

    col_start, col_end, row_start, row_step_b = derive_ramp_bounds(
        tilemap, ramp_type, room
    )
    row_step = row_step_b if row_step_b < 128 else row_step_b - 256

    if ramp_type == RAMP_UP_RIGHT:
        rx1 = col_start * 4 - 4
        rx2 = col_end * 4 + 1   # exclusive upper bound
        e, a = 0xFF, 1
    else:
        rx1 = col_start * 4
        rx2 = col_end * 4 + 5   # exclusive upper bound
        e, a = 0, 0
    ry = ramp_baked_ry(
        rx1, col_start, col_end, row_start, row_step, ramp_type
    )
    return (rx1, rx2, ry, e, a)


def build_meta(room: dict) -> bytes:
    g = room["guardians"]
    if len(g) > MAX_GUARDIANS:
        raise room_error(room, f"too many guardians ({len(g)}, max {MAX_GUARDIANS})")
    meta = bytearray()
    meta.append(len(g))
    meta.append(room["border"] | 8)   # full $900F: white bg (bit 3) + border 0-7
    meta.append(room["spawn"][0] & 0xFF)
    meta.append(room["spawn"][1] & 0xFF)
    meta.append(belt_byte(room["belt"]))
    meta.append(room["ramp"] & 0xFF)
    rx1, rx2, ry, e, a = derive_ramp_params(room["tilemap"], room["ramp"], room)
    meta.append(rx1 & 0xFF)
    meta.append(rx2 & 0xFF)
    meta.append(ry & 0xFF)
    meta.append(e & 0xFF)
    meta.append(a & 0xFF)
    meta.extend(room["conn"])
    meta.extend(build_item_draw(room))
    if len(meta) != META_SIZE:
        raise room_error(room, f"meta size {len(meta)} != {META_SIZE}")
    return bytes(meta)


def build_guardian_data(room: dict) -> bytes:
    out = bytearray(GUARDIAN_DATA_BYTES)
    for i, g in enumerate(room["guardians"]):
        base = i * GUARDIAN_RECORD_BYTES
        out[base + G_OFF_X] = g["x"]
        out[base + G_OFF_Y] = g["y"]
        out[base + G_OFF_MIN] = g["min"]
        out[base + G_OFF_MAX] = g["max"]
        out[base + G_OFF_VEL] = g["vel"]
        out[base + G_OFF_FMIN] = g["fmin"]
        out[base + G_OFF_FMAX] = g["fmax"]
        out[base + G_OFF_COLOR] = g["color"]
        out[base + G_OFF_AXIS] = g["axis"]
    return bytes(out)


def build_udg(room: dict) -> bytes:
    out = bytearray()
    out.extend(room["tileudg"][6])   # item → chr 15
    for i in range(6):
        out.extend(room["tileudg"][i])  # tiles 0–5 → chr 16–21
    return bytes(out)


def build_tile_colors(room: dict) -> bytes:
    colors = room["tilecolors"]
    if len(colors) != TILE_COLOR_BYTES:
        raise room_error(
            room, f"tilecolors length {len(colors)} != {TILE_COLOR_BYTES}"
        )
    return bytes(colors)


def deinterleave_guardian_frame(frame: bytes) -> bytes:
    """Skool L,R pairs -> column-major 16+16 (matches CopyDownGuardianBmp)."""
    out = bytearray(32)
    for row in range(16):
        out[row] = frame[row * 2]
        out[row + 16] = frame[row * 2 + 1]
    return bytes(out)


def deinterleave_guardian_sprites(
    data: bytes, nbytes: int = GUARDIAN_SPRITES_BYTES
) -> bytes:
    data = data[:nbytes].ljust(nbytes, b"\x00")
    return b"".join(
        deinterleave_guardian_frame(data[i : i + 32])
        for i in range(0, nbytes, 32)
    )


def build_tail(room: dict) -> bytes:
    tail = bytearray(TAIL_BYTES)
    meta = build_meta(room)
    colors = build_tile_colors(room)
    gdata = build_guardian_data(room)
    tail[0:META_SIZE] = meta
    tail[META_OFF_ROPE] = 1 if room.get("rope") else 0
    off = TAIL_OFF_TILECOLORS
    tail[off : off + TILE_COLOR_BYTES] = colors
    off += TILE_COLOR_BYTES
    tail[off : off + GUARDIAN_DATA_BYTES] = gdata
    return bytes(tail)


def load_player_bmp_file(path: Path) -> bytes:
    """256-byte Willy sprite from Skool interleaved text file."""
    if not path.is_file():
        raise ValueError(f"missing {path}")
    bs: list[int] = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip().startswith(";") or not line.strip():
            continue
        bs.extend(parse_byte_list(line))
    if len(bs) != PLAYER_BMP_BYTES:
        raise ValueError(
            f"{path}: expected {PLAYER_BMP_BYTES} bytes, got {len(bs)}"
        )
    return deinterleave_guardian_sprites(bytes(bs), PLAYER_BMP_BYTES)


def load_default_player_bmp() -> bytes:
    return load_player_bmp_file(DEFAULT_PLAYER_BMP_PATH)


def load_nightmare_player_bmp() -> bytes:
    """256-byte Willy sprite for the Nightmare Room (room 29)."""
    return load_player_bmp_file(NIGHTMARE_PLAYER_BMP_PATH)


def player_bmp_for_room(room: dict) -> bytes:
    if room["id"] == NIGHTMARE_ROOM_ID:
        return load_nightmare_player_bmp()
    return room["playerbmp"] or load_default_player_bmp()


def build_room_image(room: dict, scan_key_row: int) -> bytes:
    """RAM image loaded at $1A24 (1500 bytes)."""
    tiles = bytearray(grid_bytes(room["tilemap"], "tilemap", room))
    stamp_hud_title(tiles, room)
    stamp_hud_men(tiles)
    stamp_hud_item(tiles)

    raw = room["guardiansprites"] or bytes(GUARDIAN_SPRITES_BYTES)
    sprites = bytes(deinterleave_guardian_sprites(raw))
    player = player_bmp_for_room(room)
    udg = build_udg(room)
    tail = build_tail(room)
    prefix = build_prefix(room, scan_key_row)

    blob = (
        prefix
        + sprites
        + player
        + udg
        + bytes(RUNTIME_UDG_PAD)
        + tiles
        + tail
    )
    if len(blob) != ROOM_IMAGE_SIZE:
        raise room_error(room, f"room image size {len(blob)} != {ROOM_IMAGE_SIZE}")
    return blob


def build_room_prg(room: dict, scan_key_row: int) -> bytes:
    return struct.pack("<H", IMAGE_LOAD) + build_room_image(room, scan_key_row)


def room_dos_name(room_id: int) -> str:
    """KERNAL LOAD filename: R + zero-padded decimal, e.g. room 33 -> r33."""
    return f"r{room_id:02d}"


def convert_file(src: Path, outstem: Path, room: dict | None = None) -> None:
    if room is None:
        room = parse_room(src.read_text(encoding="utf-8"), source=src)
    scan_key_row = load_scan_key_row()
    data = build_room_prg(room, scan_key_row)
    outstem.parent.mkdir(parents=True, exist_ok=True)
    outstem.write_bytes(data)
    print(
        f"{src.name} -> {outstem.name} ({room_dos_name(room['id'])}, {len(data)} bytes PRG @ ${IMAGE_LOAD:04X}, room {room['id']})"
    )


def main():
    ap = argparse.ArgumentParser(description="Convert JSW roomNN.txt files to PRG binaries")
    ap.add_argument("input", nargs="?", help="roomNN.txt file or directory with --all")
    ap.add_argument("output", nargs="?", help="output file stem e.g. rooms/out/33")
    ap.add_argument("--all", action="store_true", help="convert all room*.txt in input dir")
    args = ap.parse_args()
    if args.all:
        indir = Path(args.input or "rooms")
        outdir = Path(args.output or "rooms/out")
        errors: list[tuple[Path, str]] = []
        for src in sorted(indir.glob("room*.txt")):
            try:
                text = src.read_text(encoding="utf-8")
                room = parse_room(text, source=src)
                convert_file(src, outdir / str(room["id"]), room=room)
            except (ValueError, OSError) as e:
                errors.append((src, str(e)))
                print(f"error: {src.name}: {e}", file=sys.stderr)
        if errors:
            print(f"\n{len(errors)} room(s) failed", file=sys.stderr)
            sys.exit(1)
        return
    if not args.input or not args.output:
        ap.error("need input and output, or --all")
    convert_file(Path(args.input), Path(args.output))


if __name__ == "__main__":
    try:
        main()
    except ValueError as e:
        print(f"error: {e}", file=sys.stderr)
        sys.exit(1)
