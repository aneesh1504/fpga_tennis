# Video assets

`scripts/build_assets.py` deterministically generates the checked-in palette-indexed sprite and font memories under `generated_mem/`.

- Palette index `00` is transparent.
- Player sprites have four poses: idle, forehand, backhand, and serve.
- The font is 8 by 8 pixels per ASCII glyph, with the 5-by-7 forms centered in each cell.

Regenerate with `python scripts/build_assets.py` and verify the committed outputs with `python scripts/build_assets.py --check`.
