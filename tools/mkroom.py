#!/usr/bin/env python3
"""Convert .room text files to PRG room binaries for JSW VIC-20."""

import argparse
import re
import struct
from pathlib import Path

WIDTH, HEIGHT = 24, 17
TILE_BYTES = WIDTH * HEIGHT
UDG_BYTES = 56
TILE_COLOR_BYTES = 6
ITEM_DRAW_BYTES = 11
OP_LDA_IMM = 0xA9
OP_STA_ABS = 0x8D
OP_RTS = 0x60
GUARDIAN_SPRITES_BYTES = 256
PLAYER_BMP_BYTES = 256
GUARDIAN_DATA_BYTES = 60          # SoA: 10 fields x 6 guardians
MAX_GUARDIANS = 6
RUNTIME_UDG_PAD = 336             # $1CB0-$1DFF
TAIL_BYTES = 104
META_SIZE = 14 + ITEM_DRAW_BYTES
IMAGE_LOAD = 0x1A78
SCREEN_BASE = 0x1E00
COLOR_BASE = 0x9600
MAX_ITEMS = 1
ROOM_IMAGE_SIZE = 0x588           # 1416 bytes ($1A78-$1FFF)
TILE_CHR_BASE = 16
TILE_CONVEYOR = 5
ITEM_CHR = 15
HUD_TITLE_COLS = 15
DEFAULT_TILE_COLORS = [0, 1, 3, 2, 5, 4]
DEFAULT_ITEM_UDG = bytes([48, 72, 136, 144, 104, 4, 10, 4])
DEFAULT_PLAYER_BMP = bytes([
    0x06, 0x3E, 0x7C, 0x34, 0x3E, 0x3C, 0x18, 0x3C,
    0x7E, 0x7E, 0xF7, 0xFB, 0x3C, 0x76, 0x6E, 0x77,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x01, 0x0F, 0x1F, 0x0D, 0x0F, 0x0F, 0x06, 0x0F,
    0x1F, 0x1B, 0x1B, 0x1D, 0x0F, 0x06, 0x06, 0x07,
    0x80, 0x80, 0x00, 0x00, 0x80, 0x00, 0x00, 0x00,
    0x80, 0x80, 0x80, 0x80, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x03, 0x07, 0x03, 0x03, 0x03, 0x01, 0x03,
    0x07, 0x07, 0x0F, 0x0F, 0x03, 0x07, 0x06, 0x07,
    0x60, 0xE0, 0xC0, 0x40, 0xE0, 0xC0, 0x80, 0xC0,
    0xE0, 0xE0, 0x70, 0xB0, 0xC0, 0x60, 0xE0, 0x70,
    0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x01, 0x03, 0x07, 0x06, 0x00, 0x01, 0x03, 0x03,
    0x18, 0xF8, 0xF0, 0xD0, 0xF8, 0xF0, 0x60, 0xF0,
    0xF8, 0xFC, 0xFE, 0xF6, 0xF8, 0xDA, 0x0E, 0x8C,
    0x60, 0x7C, 0x3E, 0x2C, 0x7C, 0x3C, 0x18, 0x3C,
    0x7E, 0x7E, 0xEF, 0xDF, 0x3C, 0x6E, 0x76, 0xEE,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x18, 0x1F, 0x0F, 0x0B, 0x1F, 0x0F, 0x06, 0x0F,
    0x1F, 0x3F, 0x7F, 0x6F, 0x1F, 0x5B, 0x70, 0x21,
    0x00, 0x00, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x80, 0xC0, 0xE0, 0x60, 0x00, 0x80, 0xC0, 0xC0,
    0x06, 0x07, 0x03, 0x02, 0x07, 0x03, 0x01, 0x03,
    0x07, 0x07, 0x0E, 0x0D, 0x03, 0x06, 0x07, 0x0E,
    0x00, 0xC0, 0xE0, 0xC0, 0xC0, 0xC0, 0x80, 0xC0,
    0xE0, 0xE0, 0xF0, 0xF0, 0xC0, 0xE0, 0x60, 0xE0,
    0x01, 0x01, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00,
    0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00,
    0x80, 0xF0, 0xF8, 0xB0, 0xF0, 0xF0, 0x60, 0xF0,
    0xF8, 0xD8, 0xD8, 0xB8, 0xF0, 0x60, 0x60, 0xE0,
])

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
    r"f\s*=\s*(\d+)\.\.(\d+)\s+"
    r"(\w+)",
    re.I,
)
GUARDIAN_DSL_V = re.compile(
    r"x\s*=\s*(\d+)\s+"
    r"y\s*=\s*(\d+)\((\d+)\.\.(\d+)\)\s+"
    r"v\s*=\s*([+-]?\d+)\s+"
    r"f\s*=\s*(\d+)\.\.(\d+)\s+"
    r"(\w+)",
    re.I,
)

G_OFF_X = 0
G_OFF_Y = 6
G_OFF_MIN = 12
G_OFF_MAX = 18
G_OFF_VEL = 24
G_OFF_FMIN = 30
G_OFF_FMAX = 36
G_OFF_COLOR = 42
G_OFF_FRAME = 48
G_OFF_AXIS = 54


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


def parse_guardian_line(line: str) -> dict:
    """Parse guardian DSL line into SoA field dict."""
    m = GUARDIAN_DSL_H.match(line)
    if m:
        hy, x_tile, xmin, xmax, vel, fmin, fmax, colour = m.groups()
        gx = int(x_tile) * 4
        gmin = int(xmin) * 4
        gmax = int(xmax) * 4
        gy = int(hy)
        axis = 0
    else:
        m = GUARDIAN_DSL_V.match(line)
        if not m:
            raise ValueError(f"bad @guardians line: {line!r}")
        x_tile, gy, ymin, ymax, vel, fmin, fmax, colour = m.groups()
        gx = int(x_tile) * 4
        gy = int(gy)
        gmin = int(ymin)
        gmax = int(ymax)
        axis = 1

    fmin_i = int(fmin)
    fmax_i = int(fmax)
    if not 0 <= fmin_i <= 7 or not 0 <= fmax_i <= 7 or fmin_i > fmax_i:
        raise ValueError(f"frame range out of range 0-7: {fmin}..{fmax}")

    return {
        "x": gx & 0xFF,
        "y": gy & 0xFF,
        "min": gmin & 0xFF,
        "max": gmax & 0xFF,
        "vel": parse_velocity(vel),
        "fmin": fmin_i,
        "fmax": fmax_i,
        "color": parse_vic_color(colour),
        "frame": fmin_i,
        "axis": axis,
    }


def parse_room(text: str) -> dict:
    lines = text.splitlines()
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
    }
    block = None
    block_lines = []

    def flush_block():
        nonlocal block, block_lines
        if block == "tilemap":
            room["tilemap"] = block_lines.copy()
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

    for raw in lines:
        line = raw.split("#", 1)[0].strip()
        if not line or line.startswith(";"):
            continue
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
                "items",
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
            elif tag == "ramp":
                room["ramp"] = int(parts[1])
            elif tag == "tilecolors":
                if len(parts[1:]) != TILE_COLOR_BYTES:
                    raise ValueError(
                        f"@tilecolors needs {TILE_COLOR_BYTES} values (tile types 0-5)"
                    )
                room["tilecolors"] = [parse_vic_color(x) for x in parts[1:7]]
            elif tag == "itemcolor":
                room["itemcolor"] = parse_vic_color(parts[1])
            continue
        if block == "guardians":
            if line:
                room["guardians"].append(parse_guardian_line(line))
        elif block == "items":
            cols = [int(x) for x in line.split()]
            for i in range(0, len(cols) - 1, 2):
                room["items"].append((cols[i], cols[i + 1]))
            if len(room["items"]) > MAX_ITEMS:
                raise ValueError(f"too many items ({len(room['items'])}, max {MAX_ITEMS})")
        elif block in ("tilemap", "tileudg", "guardiansprites", "playerbmp"):
            block_lines.append(line)
    flush_block()
    if len(room["items"]) != MAX_ITEMS:
        raise ValueError(f"room must have exactly {MAX_ITEMS} item (col row pair in @items)")
    return room


def grid_bytes(rows: list, name: str) -> bytes:
    if len(rows) != HEIGHT:
        raise ValueError(f"{name}: expected {HEIGHT} rows, got {len(rows)}")
    out = bytearray()
    for r, row in enumerate(rows):
        row = row.strip()
        if len(row) != WIDTH:
            raise ValueError(f"{name} row {r}: expected {WIDTH} cols, got {len(row)} ({row!r})")
        for ch in row:
            v = int(ch)
            if v > TILE_CONVEYOR:
                raise ValueError(f"tile out of range 0-{TILE_CONVEYOR}: {v}")
            if r < HEIGHT - 1:
                out.append(v + TILE_CHR_BASE)
            else:
                out.append(TILE_CHR_BASE)
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
    base = (HEIGHT - 1) * WIDTH
    for i, ch in enumerate(title):
        tiles[base + i] = ascii_to_rom_screen(ch)


def belt_byte(speed: int) -> int:
    return speed & 0xFF


TILE_RAMP = 4


def derive_ramp_bounds(tilemap: list, ramp_type: int) -> tuple[int, int, int, int]:
    """Return (col_start, col_end, row_start, row_step) for room meta."""
    cells: list[tuple[int, int]] = []
    for row, line in enumerate(tilemap):
        if row >= HEIGHT - 1:
            continue
        for col, ch in enumerate(line.strip()):
            if int(ch) == TILE_RAMP:
                cells.append((col, row))

    if ramp_type == 0:
        if cells:
            raise ValueError(f"@ramp 0 but tilemap has {len(cells)} ramp tile(s)")
        return (0, 0, 0, 0)

    if not cells:
        raise ValueError(f"@ramp {ramp_type} but no ramp tiles (4) in tilemap")

    col_start = min(col for col, _ in cells)
    col_end = max(col for col, _ in cells)

    by_col: dict[int, list[int]] = {}
    for col, row in cells:
        by_col.setdefault(col, []).append(row)

    for col in range(col_start, col_end + 1):
        if col not in by_col or len(by_col[col]) != 1:
            raise ValueError(f"ramp gap or multiple tiles in column {col}")

    row_start = by_col[col_start][0]
    if col_end == col_start:
        row_step = 0
    else:
        row_step = by_col[col_start + 1][0] - row_start
        if row_step not in (-1, 0, 1):
            raise ValueError(f"invalid ramp row step {row_step}")
        for col in range(col_start, col_end + 1):
            expected = row_start + (col - col_start) * row_step
            if by_col[col][0] != expected:
                raise ValueError(
                    f"ramp row mismatch at col {col}: expected {expected}, got {by_col[col][0]}"
                )

    return (col_start, col_end, row_start, row_step & 0xFF)


def build_meta(room: dict) -> bytes:
    g = room["guardians"]
    if len(g) > MAX_GUARDIANS:
        raise ValueError(f"too many guardians ({len(g)}, max {MAX_GUARDIANS})")
    meta = bytearray()
    meta.append(len(g))
    meta.append(room["border"] | 8)   # full $900F: white bg (bit 3) + border 0-7
    meta.append(room["spawn"][0] & 0xFF)
    meta.append(room["spawn"][1] & 0xFF)
    meta.append(belt_byte(room["belt"]))
    meta.append(room["ramp"] & 0xFF)
    col_start, col_end, row_start, row_step = derive_ramp_bounds(
        room["tilemap"], room["ramp"]
    )
    meta.append(col_start & 0xFF)
    meta.append(col_end & 0xFF)
    meta.append(row_start & 0xFF)
    meta.append(row_step & 0xFF)
    meta.extend(room["conn"])
    meta.extend(build_item_draw(room))
    if len(meta) != META_SIZE:
        raise ValueError(f"meta size {len(meta)} != {META_SIZE}")
    return bytes(meta)


def build_item_draw(room: dict) -> bytes:
    """11 bytes: lda #ITEM_CHR / sta screen / lda #color / sta color_ram / rts."""
    col, row = room["items"][0]
    if not 0 <= col < WIDTH or not 0 <= row < HEIGHT - 1:
        raise ValueError(f"item cell out of range: col={col} row={row}")
    cell_off = row * WIDTH + col
    scr_addr = SCREEN_BASE + cell_off
    col_addr = COLOR_BASE + cell_off
    color = room["itemcolor"] & 0xFF
    code = bytearray()
    code.append(OP_LDA_IMM)
    code.append(ITEM_CHR)
    code.append(OP_STA_ABS)
    code.extend(struct.pack("<H", scr_addr))
    code.append(OP_LDA_IMM)
    code.append(color)
    code.append(OP_STA_ABS)
    code.extend(struct.pack("<H", col_addr))
    code.append(OP_RTS)
    if len(code) != ITEM_DRAW_BYTES:
        raise ValueError(f"item draw code size {len(code)} != {ITEM_DRAW_BYTES}")
    return bytes(code)


def build_guardian_data(room: dict) -> bytes:
    out = bytearray(GUARDIAN_DATA_BYTES)
    for i, g in enumerate(room["guardians"]):
        out[G_OFF_X + i] = g["x"]
        out[G_OFF_Y + i] = g["y"]
        out[G_OFF_MIN + i] = g["min"]
        out[G_OFF_MAX + i] = g["max"]
        out[G_OFF_VEL + i] = g["vel"]
        out[G_OFF_FMIN + i] = g["fmin"]
        out[G_OFF_FMAX + i] = g["fmax"]
        out[G_OFF_COLOR + i] = g["color"]
        out[G_OFF_FRAME + i] = g["frame"]
        out[G_OFF_AXIS + i] = g["axis"]
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
        raise ValueError(f"tilecolors length {len(colors)} != {TILE_COLOR_BYTES}")
    return bytes(colors)


def build_tail(room: dict) -> bytes:
    tail = bytearray(TAIL_BYTES)
    meta = build_meta(room)
    colors = build_tile_colors(room)
    gdata = build_guardian_data(room)
    tail[0:META_SIZE] = meta
    off = META_SIZE
    tail[off : off + TILE_COLOR_BYTES] = colors
    off += TILE_COLOR_BYTES
    tail[off : off + GUARDIAN_DATA_BYTES] = gdata
    return bytes(tail)


def build_room_image(room: dict) -> bytes:
    """RAM image loaded at $1A78 (1416 bytes)."""
    tiles = bytearray(grid_bytes(room["tilemap"], "tilemap"))
    stamp_hud_title(tiles, room)

    sprites = room["guardiansprites"] or bytes(GUARDIAN_SPRITES_BYTES)
    player = room["playerbmp"] or DEFAULT_PLAYER_BMP
    udg = build_udg(room)
    tail = build_tail(room)

    blob = (
        sprites
        + player
        + udg
        + bytes(RUNTIME_UDG_PAD)
        + tiles
        + tail
    )
    if len(blob) != ROOM_IMAGE_SIZE:
        raise ValueError(f"room image size {len(blob)} != {ROOM_IMAGE_SIZE}")
    return blob


def build_room_prg(room: dict) -> bytes:
    return struct.pack("<H", IMAGE_LOAD) + build_room_image(room)


def convert_file(src: Path, outstem: Path) -> None:
    room = parse_room(src.read_text(encoding="utf-8"))
    data = build_room_prg(room)
    outstem.parent.mkdir(parents=True, exist_ok=True)
    outstem.write_bytes(data)
    print(
        f"{src.name} -> {outstem.name} ({len(data)} bytes PRG @ ${IMAGE_LOAD:04X}, room {room['id']})"
    )


def main():
    ap = argparse.ArgumentParser(description="Convert JSW .room files to PRG binaries")
    ap.add_argument("input", nargs="?", help=".room file or directory with --all")
    ap.add_argument("output", nargs="?", help="output file stem e.g. rooms/out/R1")
    ap.add_argument("--all", action="store_true", help="convert all *.room in input dir")
    args = ap.parse_args()
    if args.all:
        indir = Path(args.input or "rooms")
        outdir = Path(args.output or "rooms/out")
        for src in sorted(indir.glob("*.room")):
            n = parse_room(src.read_text(encoding="utf-8"))["id"]
            convert_file(src, outdir / f"R{n}")
        return
    if not args.input or not args.output:
        ap.error("need input and output, or --all")
    convert_file(Path(args.input), Path(args.output))


if __name__ == "__main__":
    main()
