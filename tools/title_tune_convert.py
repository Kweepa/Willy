#!/usr/bin/env python3
"""Build title-screen Moonlight Sonata from JSW $85FB bass-line arrangement.

99 notes (33 triplets) + 255. Pitch classes from the original Spectrum title
tune (Richard Hallas); no full-score melody intrusions. Octaves voiced for VIC.

VIC poke is monotonic: lower value = lower pitch; semitone/octave up = larger value.
"""

from __future__ import annotations

TITLE_NOTE_COUNT = 99

SCORE_SOURCES = [
    "https://skoolkit.ca/disassemblies/jet_set_willy/asm/34299.html",
    "http://jswremakes.emuunlim.com/Mmt/A%20Miner%20Triad.htm",
]

CHROMATIC = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]

# Original ZX Spectrum Jet Set Willy title tune @ $85FB (99 bytes).
JSW_SPEC_TUNE: list[int] = [
    0x51, 0x3C, 0x33, 0x51, 0x3C, 0x33, 0x51, 0x3C, 0x33, 0x51, 0x3C, 0x33,
    0x51, 0x3C, 0x33, 0x51, 0x3C, 0x33, 0x51, 0x3C, 0x33, 0x51, 0x3C, 0x33,
    0x4C, 0x3C, 0x33, 0x4C, 0x3C, 0x33, 0x4C, 0x39, 0x2D, 0x4C, 0x39, 0x2D,
    0x51, 0x40, 0x2D, 0x51, 0x3C, 0x33, 0x51, 0x3C, 0x36, 0x5B, 0x40, 0x36,
    0x66, 0x51, 0x3C, 0x51, 0x3C, 0x33, 0x51, 0x3C, 0x33, 0x28, 0x3C, 0x28,
    0x28, 0x36, 0x2D, 0x51, 0x36, 0x2D, 0x51, 0x36, 0x2D, 0x28, 0x36, 0x28,
    0x28, 0x3C, 0x33, 0x51, 0x3C, 0x33, 0x26, 0x3C, 0x2D, 0x4C, 0x3C, 0x2D,
    0x28, 0x40, 0x33, 0x51, 0x40, 0x33, 0x2D, 0x40, 0x36, 0x20, 0x40, 0x36,
    0x3D, 0x79, 0x3D,
]

# Richard Hallas tone chart (value, label); '#' = semitone between naturals.
CHART_ROWS: list[tuple[int, str]] = [
    (16, "C"),
    (17, "B"),
    (18, "#"),
    (19, "A"),
    (20, "#"),
    (22, "G"),
    (23, "#"),
    (24, "F"),
    (25, "E"),
    (27, "#"),
    (29, "D"),
    (31, "#"),
    (32, "C"),
    (34, "B"),
    (36, "#"),
    (38, "A"),
    (40, "#"),
    (43, "G"),
    (45, "#"),
    (48, "F"),
    (51, "E"),
    (54, "#"),
    (57, "D"),
    (60, "#"),
    (64, "C"),
    (68, "B"),
    (72, "#"),
    (76, "A"),
    (81, "#"),
    (86, "G"),
    (91, "#"),
    (96, "F"),
    (102, "E"),
    (108, "#"),
    (115, "D"),
    (121, "#"),
    (128, "C"),
]

# Approximate bar labels for comments (33 triplets ~ mm.1-9).
BAR_LABELS: list[str] = [
    *["m1"] * 4,
    *["m2"] * 4,
    "m3",
    "m3",
    "m3",
    "m3",
    "m4",
    "m4",
    "m4",
    "m4",
    "m5",
    "m5",
    "m5",
    "m5",
    "m6",
    "m6",
    "m6",
    "m6",
    "m7",
    "m7",
    "m7",
    "m7",
    "m8",
    "m8",
    "m8",
    "m8",
    "m9",
]

# VIC-20 Programmer's Reference Guide, appendix F (rows low -> high pitch).
VIC_ROWS: list[dict[str, int]] = [
    {
        "C": 135,
        "C#": 143,
        "D": 147,
        "D#": 151,
        "E": 159,
        "F": 163,
        "F#": 167,
        "G": 175,
        "G#": 179,
        "A": 183,
        "A#": 187,
        "B": 191,
    },
    {
        "C": 195,
        "C#": 199,
        "D": 201,
        "D#": 203,
        "E": 207,
        "F": 209,
        "F#": 212,
        "G": 215,
        "G#": 217,
        "A": 219,
        "A#": 221,
        "B": 223,
    },
    {
        "C": 225,
        "C#": 227,
        "D": 228,
        "D#": 229,
        "E": 231,
        "F": 232,
        "F#": 233,
        "G": 235,
        "G#": 236,
        "A": 237,
        "A#": 238,
        "B": 239,
    },
]

OCTAVE_TO_ROW: dict[int, int] = {3: 0, 4: 1, 5: 2}


def _build_hallas() -> dict[int, str]:
    out: dict[int, str] = {}
    for i, (val, label) in enumerate(CHART_ROWS):
        if label != "#":
            out[val] = label
            continue
        lo_name = hi_name = None
        for j in range(i - 1, -1, -1):
            if CHART_ROWS[j][1] != "#":
                lo_name = CHART_ROWS[j][1]
                break
        for j in range(i + 1, len(CHART_ROWS)):
            if CHART_ROWS[j][1] != "#":
                hi_name = CHART_ROWS[j][1]
                break
        if hi_name is None:
            raise ValueError(f"unresolved # at chart value {val}")
        # '#' sits a semitone above the lower-pitch natural (higher chart value).
        out[val] = CHROMATIC[(CHROMATIC.index(hi_name) + 1) % 12]
    return out


HALLAS = _build_hallas()


def _nearest_spec(v: int) -> int:
    if v in HALLAS:
        return v
    return min(HALLAS, key=lambda k: abs(k - v))


def pitch_from_spec(v: int) -> str:
    return HALLAS[_nearest_spec(v)]


def midi_note(pitch: str, octave: int) -> int:
    return (octave + 1) * 12 + CHROMATIC.index(pitch)


def assign_octaves(pitches: list[str], spec_vals: list[int]) -> list[int]:
    """Voice a triplet low->high; first byte is the bass note of the arpeggio."""
    octaves: list[int] = []
    prev_midi = -1
    for v, pitch in zip(spec_vals, pitches):
        pc = CHROMATIC.index(pitch)
        if not octaves:
            octave = 4 if v >= 64 else 3
        else:
            octave = octaves[-1]
        midi = midi_note(pitch, octave)
        while midi <= prev_midi:
            octave += 1
            midi = midi_note(pitch, octave)
        if octave > 5:
            raise ValueError(f"voicing out of range: {list(zip(pitches, spec_vals))}")
        octaves.append(octave)
        prev_midi = midi
    return octaves


def build_triplets_from_jsw() -> list[tuple[str, list[str], list[int]]]:
    if len(JSW_SPEC_TUNE) != TITLE_NOTE_COUNT:
        raise ValueError(f"expected {TITLE_NOTE_COUNT} spec bytes, got {len(JSW_SPEC_TUNE)}")
    triplets: list[tuple[str, list[str], list[int]]] = []
    for t in range(TITLE_NOTE_COUNT // 3):
        spec = JSW_SPEC_TUNE[t * 3 : t * 3 + 3]
        pitches = [pitch_from_spec(v) for v in spec]
        octaves = assign_octaves(pitches, spec)
        triplets.append((BAR_LABELS[t], pitches, octaves))
    return triplets


MOONLIGHT_TRIPLETS = build_triplets_from_jsw()


def vic_for(pitch: str, octave: int) -> int:
    return VIC_ROWS[OCTAVE_TO_ROW[octave]][pitch]


def build_vic_tune() -> list[int]:
    out: list[int] = []
    for _bar, triplet, octaves in MOONLIGHT_TRIPLETS:
        for pitch, octave in zip(triplet, octaves):
            out.append(vic_for(pitch, octave))
    out.append(255)
    return out


def triplet_table() -> list[tuple[int, str, list[str], list[int], list[int]]]:
    rows: list[tuple[int, str, list[str], list[int], list[int]]] = []
    for t, (bar, pitches, octaves) in enumerate(MOONLIGHT_TRIPLETS, 1):
        regs = [vic_for(p, o) for p, o in zip(pitches, octaves)]
        rows.append((t, bar, pitches, octaves, regs))
    return rows


def asm_triplet_lines() -> list[str]:
    lines = ["title_tune_notes"]
    for t, bar, pitches, octaves, regs in triplet_table():
        score = ",".join(f"{p}{o}" for p, o in zip(pitches, octaves))
        decs = ",".join(str(b) for b in regs)
        lines.append(f"    !byte {decs}      ; T{t:02d} {bar:3s}  {score}")
    lines.append("    !byte 255                ; END")
    return lines


def check_scale_monotonic() -> list[str]:
    bad: list[str] = []
    for row_idx, row in enumerate(VIC_ROWS):
        prev_midi = prev_vic = None
        for pitch in CHROMATIC:
            midi = midi_note(pitch, 3 + row_idx)
            vic = row[pitch]
            if prev_midi is not None and midi > prev_midi and vic <= prev_vic:
                bad.append(f"row {row_idx}: {pitch} vic {vic} <= {prev_vic}")
            prev_midi, prev_vic = midi, vic
    for pitch in CHROMATIC:
        for oct in (3, 4):
            v0 = vic_for(pitch, oct)
            v1 = vic_for(pitch, oct + 1)
            if v1 <= v0:
                bad.append(f"{pitch}{oct}->{oct + 1}: vic {v0}->{v1}")
    return bad


def main() -> None:
    print("Moonlight Sonata title tune (JSW $85FB bass-line arrangement)")
    print("VIC rule: lower poke = lower pitch; semitone/octave up = larger poke.")
    print("Sources:")
    for url in SCORE_SOURCES:
        print(f"  {url}")
    bad = check_scale_monotonic()
    if bad:
        print("\nSCALE ERRORS:")
        for line in bad:
            print(f"  {line}")
    else:
        print("\nScale monotonicity OK")
    print()
    print(f"{'T':>3}  {'Score':^22}  {'Spec':^12}  {'VIC':^16}  Bar")
    print("-" * 72)
    for t, bar, pitches, octaves, regs in triplet_table():
        score = "-".join(f"{p}{o}" for p, o in zip(pitches, octaves))
        spec = JSW_SPEC_TUNE[(t - 1) * 3 : (t - 1) * 3 + 3]
        spec_s = ",".join(f"{b:3d}" for b in spec)
        decs = ",".join(f"{r:3d}" for r in regs)
        print(f"{t:3d}  {score:22s}  {spec_s:12s}  {decs:16s}  {bar}")
    print()
    for line in asm_triplet_lines():
        print(line)


if __name__ == "__main__":
    main()
