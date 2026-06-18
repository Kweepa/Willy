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
    ("ramp", ["calculate_ramp_y", "do_walking_ramp_check", "do_falling_ramp_check"]),
    ("willy", ["try_touch", "Collide", "DrawPlayer"]),
    ("util", ["ConvertXYToScreenAddr", "UpdateMoveCounters"]),
    ("input", ["GetPlayerInput", "ScanKeyRow"]),
    ("guardians", ["CopyDownGuardianData", "MoveGuardians", "EraseGuardians"]),
    ("warm boot", ["WarmStart", "init24_val"]),
]

RAM = [
    ("ROPE_SEGMENT_Y", 0x33C, 32, "rope segment Y (cassette buffer)"),
    ("rope_xadd", 0x35C, 54, "copied at WarmStart (cassette buffer)"),
    ("AnimateConveyors", 0x1A24, 19, "baked per room; jsr AnimateConveyors"),
    ("DoBelt", 0x1A37, 33, "baked per room; jsr DoBelt"),
    ("guardian_sprites_base", 0x1A58, 288, "from room PRG (9 frames)"),
    ("player_bmp", 0x1B78, 256, "from room PRG"),
    ("tile UDGs chr 15-21", 0x1C78, 56, "chr 15=item, 16-21=tiles"),
    ("guardian_udgs chr 22+", 0x1CB0, 288, "runtime UDG workspace"),
    ("player_udg chr 58+", 0x1DD0, 48, "runtime (6 chars)"),
    ("screen_base", 0x1E00, 408, "24x17 tilemap from room PRG"),
    ("tail meta/colors/gdata", 0x1F98, 104, "meta_content_src @ $1F98"),
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
    room_base = 0x1A24
    room_size = 0x5DC

    total = prg_end - load_base
    overlap = prg_end - room_base

    print(f"PRG load: ${load_base:04X}-${prg_end - 1:04X}  ({total} bytes)")
    if overlap > 0:
        print(f"  *** {overlap} bytes (${room_base:04X}+) overlap room load area ***")
    print(f"Room LOAD overwrites: ${room_base:04X}-${room_base + room_size - 1:04X}  ({room_size} bytes)")
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
    print("Runtime RAM (absolute, during play):")
    for name, addr, size, note in RAM:
        print(f"  ${addr:04X}  {name:28} {size:4} B  ({note})")


if __name__ == "__main__":
    main()
