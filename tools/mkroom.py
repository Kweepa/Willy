#!/usr/bin/env python3
"""Convert .room text files to PRG room binaries for JSW VIC-20."""

import argparse
import re
import struct
from pathlib import Path

WIDTH, HEIGHT = 24, 16
TILE_BYTES = WIDTH * HEIGHT
UDG_BYTES = 48
META_SLOT_BYTES = 32
TILE_COLOR_BYTES = 6
UDG_OFF = 0
META_OFF = 48
TILE_COLOR_OFF = 80
PADDING_BYTES = 426
TILE_OFF = 512
IMAGE_LOAD = 0x1C00
ROOM_IMAGE_SIZE = 920
DEFAULT_TILE_COLORS = [0, 1, 3, 2, 5, 4]


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


def parse_byte_list(text: str) -> list[int]:
    """Comma-separated byte list (Skoolkit style): 0, 0, 255, 24."""
    return [parse_byte(part) for part in text.split(",") if part.strip()]


def parse_room(text: str) -> dict:
    lines = text.splitlines()
    room = {
        "id": 0,
        "title": "",
        "conn": [0xFF, 0xFF, 0xFF, 0xFF],
        "spawn": (0, 0),
        "bg": 0,
        "belt": 0,
        "ramp": (0, 0, 0),
        "hguard": 0,
        "vguard": 0,
        "tilemap": [],
        "tilecolors": list(DEFAULT_TILE_COLORS),
        "items": [],
        "guardians": [],
        "tileudg": [bytes(8) for _ in range(6)],
        "guardianbmp": b"",
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
                if idx < 6 and len(bs) == 8:
                    if invert:
                        bs = [b ^ 0xFF for b in bs]
                    room["tileudg"][idx] = bytes(bs)
        elif block == "guardianbmp":
            bs = []
            for line in block_lines:
                bs.extend(parse_byte_list(line))
            room["guardianbmp"] = bytes(bs)
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
            if tag in ("tilemap", "tileudg", "guardianbmp", "guardians", "items"):
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
            elif tag == "bg":
                room["bg"] = int(parts[1])
            elif tag == "belt":
                room["belt"] = int(parts[1])
            elif tag == "ramp":
                room["ramp"] = (int(parts[1]), int(parts[2]), int(parts[3]))
            elif tag == "hguard":
                room["hguard"] = int(parts[1])
            elif tag == "vguard":
                room["vguard"] = int(parts[1])
            elif tag == "tilecolors":
                vals = [int(x) for x in parts[1:7]]
                if len(vals) != 6:
                    raise ValueError("@tilecolors needs 6 values (tile types 0-5)")
                if any(v > 7 for v in vals):
                    raise ValueError("tile color out of range 0-7")
                room["tilecolors"] = vals
            continue
        if block == "guardians":
            if line:
                room["guardians"].append([int(x) for x in line.split()])
        elif block == "items":
            cols = [int(x) for x in line.split()]
            for i in range(0, len(cols) - 1, 2):
                room["items"].append((cols[i], cols[i + 1]))
        elif block in ("tilemap", "tileudg", "guardianbmp"):
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
    meta = bytearray()
    g = room["guardians"]
    meta.append(len(g))
    for rec in g:
        if len(rec) != 7:
            raise ValueError("guardian record needs 7 fields")
        meta.extend(rec)
    meta.append(room["bg"] & 0xFF)
    meta.append(room["spawn"][0] & 0xFF)
    meta.append(room["spawn"][1] & 0xFF)
    meta.append(belt_byte(room["belt"]))
    meta.extend(room["ramp"])
    meta.append(room["hguard"] & 0xFF)
    meta.append(room["vguard"] & 0xFF)
    meta.extend(room["conn"])
    meta.extend(room["title"].encode("ascii") + b"\x00")
    meta.append(len(room["items"]))
    for col, row in room["items"]:
        meta.append(col & 0xFF)
        meta.append(row & 0xFF)
    if room["guardianbmp"]:
        meta.extend(room["guardianbmp"])
    return bytes(meta)


def build_udg(room: dict) -> bytes:
    out = bytearray()
    for i in range(6):
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
    """RAM image loaded at $1C00 (920 bytes).

    $1C00 UDG (48) | $1C30 meta slot (32) | $1C50 tile_colors (6) | padding (426) | $1E00 tiles (384) | $1F80 room_name (24)
    """
    tiles = grid_bytes(room["tilemap"], "tilemap")
    # Append room name (24 bytes) mapped to ROM characters
    padded_title = room["title"].upper().center(24)
    title_bytes = bytes(ascii_to_rom_screen(c) for c in padded_title)
    tiles += title_bytes

    meta = build_meta(room)
    if len(meta) > META_SLOT_BYTES - 2:
        raise ValueError(f"meta too large ({len(meta)} bytes, max {META_SLOT_BYTES - 2})")
    meta_slot = struct.pack("<H", len(meta)) + meta
    meta_slot = meta_slot.ljust(META_SLOT_BYTES, b"\x00")
    udg = build_udg(room)
    tile_colors = build_tile_colors(room)
    padding = b"\x00" * PADDING_BYTES
    blob = udg + meta_slot + tile_colors + padding + tiles
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
    ap.add_argument("output", nargs="?", help="output file stem e.g. rooms/out/ROOM01")
    ap.add_argument("--all", action="store_true", help="convert all *.room in input dir")
    args = ap.parse_args()
    if args.all:
        indir = Path(args.input or "rooms")
        outdir = Path(args.output or "rooms/out")
        for src in sorted(indir.glob("*.room")):
            n = parse_room(src.read_text(encoding="utf-8"))["id"]
            convert_file(src, outdir / f"ROOM{n:02d}")
        return
    if not args.input or not args.output:
        ap.error("need input and output, or --all")
    convert_file(Path(args.input), Path(args.output))


if __name__ == "__main__":
    main()
