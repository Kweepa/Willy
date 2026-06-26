#!/usr/bin/env python3
"""Sanity-check title tune length and triplet count."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.title_tune_convert import (  # noqa: E402
    MOONLIGHT_TRIPLETS,
    TITLE_NOTE_COUNT,
    build_vic_tune,
)


def main() -> None:
    vic = build_vic_tune()
    assert vic[-1] == 0xFF
    assert len(vic) == TITLE_NOTE_COUNT + 1
    assert len(MOONLIGHT_TRIPLETS) * 3 == TITLE_NOTE_COUNT
    print(f"OK: {TITLE_NOTE_COUNT} notes, {len(MOONLIGHT_TRIPLETS)} triplets, {len(vic)} bytes incl. END")


if __name__ == "__main__":
    main()
