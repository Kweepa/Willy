#!/usr/bin/env python3
"""Convert .room text files to PRG room binaries for JSW VIC-20."""

import argparse
import re
import struct
from pathlib import Path

WIDTH, HEIGHT = 24, 16
TILE_BYTES = WIDTH * HEIGHT
UDG_BYTES = 56
META_SLOT_BYTES = 48
TILE_COLOR_BYTES = 6
GUARDIAN_SPRITES_BYTES = 256
GUARDIAN_DATA_BYTES = 48          # 6 guardians × 8 bytes
MAX_GUARDIANS = 6
META_RESERVE_BYTES = 48           # pad $1C38-$1C67 (keeps tile_colors at $1C68)
TILE_COLOR_OFF = 256 + UDG_BYTES + META_RESERVE_BYTES   # 360 → $1C68
GUARDIAN_DATA_OFF = TILE_COLOR_OFF + TILE_COLOR_BYTES   # 366 → $1C6E
PADDING_BYTES = 402
PADDING_REST = PADDING_BYTES - GUARDIAN_DATA_BYTES
TILE_OFF = 768                    # $1E00 screen / tilemap
META_GAP_BYTES = 24
META_OFF = 1200                   # $1FB0
IMAGE_LOAD = 0x1B00
ROOM_IMAGE_SIZE = META_OFF + META_SLOT_BYTES  # 1248 bytes
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


def parse_guardian_line(line: str) -> list[int]:
    """Parse guardian DSL line into 8-byte record (cur_frame = frame_min)."""
    line = line.split(";", 1)[0].strip()
    m = GUARDIAN_DSL_H.match(line)
    if m:
        hy, x_tile, xmin, xmax, vel, fmin, fmax, colour = m.groups()
        gx = int(x_tile) * 4
        gmin = int(xmin) * 4
        gmax = int(xmax) * 4
        gy = int(hy)
    else:
        m = GUARDIAN_DSL_V.match(line)
        if not m:
            raise ValueError(f"bad @guardians line: {line!r}")
        x_tile, gy, ymin, ymax, vel, fmin, fmax, colour = m.groups()
        gx = int(x_tile) * 4
        gy = int(gy)
        gmin = int(ymin)
        gmax = int(ymax)

    fmin_i = int(fmin)
    fmax_i = int(fmax)
    if not 0 <= fmin_i <= 7 or not 0 <= fmax_i <= 7 or fmin_i > fmax_i:
        raise ValueError(f"frame range out of range 0-7: {fmin}..{fmax}")

    return [
        gx & 0xFF,
        gy & 0xFF,
        gmin & 0xFF,
        gmax & 0xFF,
        parse_velocity(vel),
        ((fmin_i & 0x0F) << 4) | (fmax_i & 0x0F),
        parse_vic_color(colour),
        fmin_i,
    ]


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
        "items": [],
        "guardians": [],
        "tileudg": [bytes(8) for _ in range(6)] + [DEFAULT_ITEM_UDG],
        "guardiansprites": b"",
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
        block = None
        block_lines.clear()

    for raw in lines:
        line = raw.split("#", 1)[0].strip()
        if not line:
            continue
        if line.startswith("@"):
            flush_block()
            parts = line.split()
            tag = parts[0][1:].lower()
            if tag in ("tilemap", "tileudg", "guardiansprites", "guardians", "items"):
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
                if len(parts[1:]) != 6:
                    raise ValueError("@tilecolors needs 6 values (tile types 0-5)")
                room["tilecolors"] = [parse_vic_color(x) for x in parts[1:7]]
            continue
        if block == "guardians":
            if line:
                room["guardians"].append(parse_guardian_line(line))
        elif block == "items":
            cols = [int(x) for x in line.split()]
            for i in range(0, len(cols) - 1, 2):
                room["items"].append((cols[i], cols[i + 1]))
        elif block in ("tilemap", "tileudg", "guardiansprites"):
            block_lines.append(line)
    flush_block()
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
            if v > 5:
                raise ValueError(f"tile out of range 0-5: {v}")
            out.append(v)
    return bytes(out)


def belt_byte(speed: int) -> int:
    return speed & 0xFF


def build_meta(room: dict) -> bytes:
    g = room["guardians"]
    if len(g) > MAX_GUARDIANS:
        raise ValueError(f"too many guardians ({len(g)}, max {MAX_GUARDIANS})")
    meta = bytearray()
    meta.append(len(g))
    meta.append(room["border"] & 0xFF)
    meta.append(room["spawn"][0] & 0xFF)
    meta.append(room["spawn"][1] & 0xFF)
    meta.append(belt_byte(room["belt"]))
    meta.append(room["ramp"] & 0xFF)
    meta.extend(room["conn"])
    meta.append(len(room["items"]))
    for col, row in room["items"]:
        meta.append(col & 0xFF)
        meta.append(row & 0xFF)
    return bytes(meta)


def build_guardian_data(room: dict) -> bytes:
    out = bytearray(GUARDIAN_DATA_BYTES)
    for i, rec in enumerate(room["guardians"]):
        if len(rec) != 8:
            raise ValueError("guardian record needs 8 fields")
        off = i * 8
        out[off : off + 8] = bytes(rec)
    return bytes(out)


def build_udg(room: dict) -> bytes:
    out = bytearray()
    for i in range(7):
        out.extend(room["tileudg"][i])
    return bytes(out)


def build_tile_colors(room: dict) -> bytes:
    return bytes(room["tilecolors"])


def ascii_to_rom_screen(ch: str) -> int:
    """Map ASCII to screen codes 128-255 (ROM charset with bit 7 set)."""
    code = ord(ch)
    if 65 <= code <= 90:  # A-Z -> screen codes 1-26
        return code + 64
    return code + 128  # space, digits, punctuation


def build_room_image(room: dict) -> bytes:
    """RAM image loaded at $1B00 (1248 bytes).

    $1B00 sprites (256) | $1C00 UDG (56) | reserved (48) | $1C68 colors (6)
    $1C6E guardian data (48) | pad (354) | $1E00 tiles (384+24) | meta ($1FB0)
    """
    tiles = grid_bytes(room["tilemap"], "tilemap")
    padded_title = room["title"].upper().center(24)
    title_bytes = bytes(ascii_to_rom_screen(c) for c in padded_title)
    tiles += title_bytes

    meta = build_meta(room)
    if len(meta) > META_SLOT_BYTES - 2:
        raise ValueError(f"meta too large ({len(meta)} bytes, max {META_SLOT_BYTES - 2})")
    meta_slot = struct.pack("<H", len(meta)) + meta
    meta_slot = meta_slot.ljust(META_SLOT_BYTES, b"\x00")

    sprites = room["guardiansprites"] or bytes(GUARDIAN_SPRITES_BYTES)
    udg = build_udg(room)
    tile_colors = build_tile_colors(room)
    guardian_data = build_guardian_data(room)
    padding_rest = b"\x00" * PADDING_REST
    reserved = b"\x00" * META_RESERVE_BYTES
    meta_gap = b"\x00" * META_GAP_BYTES

    blob = (
        sprites
        + udg
        + reserved
        + tile_colors
        + guardian_data
        + padding_rest
        + tiles
        + meta_gap
        + meta_slot
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
