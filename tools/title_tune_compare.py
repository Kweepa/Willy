#!/usr/bin/env python3
"""Sanity-check title tune length and triplet count."""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.title_tune_convert import (  # noqa: E402
    TITLE_BAR_COUNT,
    TITLE_NOTE_COUNT,
    active_arrangement,
    build_dual_tables,
    build_triplets,
)


def main() -> None:
    arrangement = active_arrangement()
    if arrangement == "dual":
        lh_lut, _lh_ids, rh_lut, _rh_ids, bar_seq = build_dual_tables()
        assert len(bar_seq) == TITLE_BAR_COUNT
        assert len(lh_lut) == 7
        assert len(rh_lut) == 11
        data_bytes = len(bar_seq) + len(lh_lut) * 3 + len(rh_lut) * 3
        print(
            f"OK: dual {TITLE_BAR_COUNT} bars, {TITLE_NOTE_COUNT} ticks, "
            f"{data_bytes} bytes tune data"
        )
        return
    triplets = build_triplets(arrangement)
    assert len(triplets) * 3 == TITLE_NOTE_COUNT
    print(
        f"OK: {TITLE_NOTE_COUNT} notes, {len(triplets)} triplets, "
        f"{TITLE_NOTE_COUNT + 1} bytes incl. END"
    )


if __name__ == "__main__":
    main()
