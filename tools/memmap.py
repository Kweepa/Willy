#!/usr/bin/env python3
"""Print JSW PRG code memory map from jsw.lbl."""

import re
import sys
from pathlib import Path

MODULES = [
    ("header/boot", ["cold_start", "warm_start", "basic_end"]),
    ("gameloop", ["start_game", "start_map", "main_loop"]),
    ("map", ["ResetGame", "DrawMap", "CheckRoomEdge"]),
    ("loader", ["LoadRoom", "room_name", "ParseRoomMeta"]),
    ("willy", ["Collide", "ErasePlayer", "DrawPlayer"]),
    ("util", ["ClearScreen", "UpdateMoveCounters"]),
    ("input", ["GetPlayerInput", "ScanKeyRow"]),
    ("spritedata", ["player_bmp", "guardian_bmps"]),
    ("guardians", ["MulGuardianIndexBy8", "MoveGuardians", "EraseGuardians"]),
    ("warm boot", ["WarmStart", "init24_val"]),
]

RAM = [
    ("guardian_sprites_base", 0x1B00, 256, "from room PRG"),
    ("udg_base / tile UDGs", 0x1C00, 56, "from room PRG"),
    ("guardian_data_base", 0x1C6F, 48, "live guardian state"),
    ("guardian_udgs chr 22+", 0x1CB0, 288, "runtime UDG workspace"),
    ("player_udg chr 58+", 0x1DD0, 64, "runtime"),
    ("screen_base", 0x1E00, 408, "tilemap + title from room PRG"),
    ("meta slot (in room image)", 0x1FB0, 48, "ParseRoomMeta reads meta_content_src @ $1FB2"),
]


def main():
    lbl = Path(sys.argv[1] if len(sys.argv) > 1 else "jsw.lbl")
    labels = {}
    for line in lbl.read_text().splitlines():
        m = re.match(r"al C:([0-9a-f]+) \.(.+)", line, re.I)
        if m:
            labels[m.group(2)] = int(m.group(1), 16)

    bounds = []
    for name, syms in MODULES:
        for sym in syms:
            if sym in labels:
                bounds.append((labels[sym], name, sym))
                break

    bounds.sort()
    prg_end = labels.get("prg_end", max(labels.values()))
    load_base = 0x1000
    room_base = 0x1B00

    total = prg_end - load_base
    overlap = prg_end - room_base

    print(f"PRG load: ${load_base:04X}-${prg_end - 1:04X}  ({total} bytes)")
    if overlap > 0:
        print(f"  *** {overlap} bytes (${room_base:04X}+) overlap room load area ***")
    print(f"Room LOAD overwrites: ${room_base:04X}-${room_base + 0x4E0 - 1:04X}  (1248 bytes)")
    print()
    print(f"{'Segment':32} {'Start':>6} {'End':>6} {'Size':>6}  Notes")
    print("-" * 72)

    for i, (start, name, sym) in enumerate(bounds):
        end = bounds[i + 1][0] - 1 if i + 1 < len(bounds) else prg_end - 1
        size = end - start + 1
        notes = f"; {sym}"
        if start >= room_base:
            notes += "  [entirely in room zone]"
        elif end >= room_base:
            notes += f"  [{end - room_base + 1} B past ${room_base:04X}]"
        print(f"{name:32} ${start:04X} ${end:04X} {size:5}  {notes}")

    print()
    print("Guardians detail (labels):")
    for sym in sorted(labels, key=lambda s: labels[s]):
        if sym[0].isupper() and labels[sym] >= bounds[-2][0]:
            print(f"  ${labels[sym]:04X}  {sym}")

    print()
    print("Runtime RAM (absolute, during play):")
    for name, addr, size, note in RAM:
        print(f"  ${addr:04X}  {name:28} {size:4} B  ({note})")


if __name__ == "__main__":
    main()
