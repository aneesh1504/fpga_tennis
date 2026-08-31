#!/usr/bin/env python3
"""Deterministically build compact palette-indexed video ROM images."""

from __future__ import annotations

import argparse
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "generated_mem"

GLYPHS = {
    "0": [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."],
    "1": ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."],
    "2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
    "3": ["####.", "....#", "....#", ".###.", "....#", "....#", "####."],
    "4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
    "5": ["#####", "#....", "#....", "####.", "....#", "....#", "####."],
    "6": [".###.", "#....", "#....", "####.", "#...#", "#...#", ".###."],
    "7": ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."],
    "8": [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."],
    "9": [".###.", "#...#", "#...#", ".####", "....#", "....#", ".###."],
    "A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
    "C": [".####", "#....", "#....", "#....", "#....", "#....", ".####"],
    "D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
    "E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
    "F": ["#####", "#....", "#....", "####.", "#....", "#....", "#...."],
    "G": [".####", "#....", "#....", "#.###", "#...#", "#...#", ".###."],
    "H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
    "I": [".###.", "..#..", "..#..", "..#..", "..#..", "..#..", ".###."],
    "J": ["..###", "...#.", "...#.", "...#.", "...#.", "#..#.", ".##.."],
    "K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
    "L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
    "M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
    "N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
    "O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
    "Q": [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"],
    "R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
    "S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
    "T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
    "U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
    "V": ["#...#", "#...#", "#...#", "#...#", ".#.#.", ".#.#.", "..#.."],
    "W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
    "X": ["#...#", ".#.#.", "..#..", "..#..", "..#..", ".#.#.", "#...#"],
    "Y": ["#...#", ".#.#.", "..#..", "..#..", "..#..", "..#..", "..#.."],
    "Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
    ":": [".....", "..#..", "..#..", ".....", "..#..", "..#..", "....."],
    "-": [".....", ".....", ".....", ".###.", ".....", ".....", "....."],
}


def sprite_pixel(width: int, height: int, frame: int, x: int, y: int) -> int:
    center = width // 2
    head_radius = max(2, width // 6)
    head_y = max(3, height // 5)
    if (x - center) ** 2 + (y - head_y) ** 2 <= head_radius**2:
        return 1
    body_top = head_y + head_radius
    body_bottom = height - max(5, height // 4)
    if center - max(2, width // 6) <= x <= center + max(2, width // 6) and body_top <= y <= body_bottom:
        return 2
    if y > body_bottom and y < height - 1:
        leg_offset = max(1, (y - body_bottom) // 3)
        if x in (center - leg_offset, center + leg_offset):
            return 3

    arm_y = body_top + max(1, (body_bottom - body_top) // 3)
    if frame == 0 and abs(y - arm_y) <= 1 and abs(x - center) <= width // 3:
        return 1
    if frame == 1 and abs(y - (arm_y - (x - center) // 2)) <= 1 and center <= x < width - 1:
        return 1
    if frame == 2 and abs(y - (arm_y + (x - center) // 2)) <= 1 and 0 < x <= center:
        return 1
    if frame == 3 and abs(x - center) <= 1 and max(0, arm_y - height // 3) <= y <= arm_y:
        return 1

    racket_x = width - 2 if frame in (0, 1, 3) else 1
    racket_y = max(2, arm_y - (4 if frame == 3 else 1))
    if abs(x - racket_x) <= 1 and abs(y - racket_y) <= 2:
        return 4
    return 0


def build_sprite(width: int, height: int) -> str:
    values = [
        sprite_pixel(width, height, frame, x, y)
        for frame in range(4)
        for y in range(height)
        for x in range(width)
    ]
    return "".join(f"{value:02x}\n" for value in values)


def build_font() -> str:
    rows: list[int] = []
    for code in range(32, 128):
        pattern = GLYPHS.get(chr(code), ["....."] * 7)
        for row_index in range(8):
            value = 0
            if row_index < 7:
                for column, pixel in enumerate(pattern[row_index]):
                    if pixel == "#":
                        value |= 1 << (6 - column)
            rows.append(value)
    return "".join(f"{value:02x}\n" for value in rows)


def generated_files() -> dict[str, str]:
    palette = [
        0x000000, 0xF2B38A, 0xF04B5A, 0x243A73,
        0xE7EEF8, 0x52D6FF, 0xFFB84A, 0x83E377,
        0xFFFFFF, 0xB8C5CF, 0x1769AA, 0x176B52,
        0x29324F, 0x3B4669, 0x10182E, 0xFFF7DC,
    ]
    return {
        "player_near.mem": build_sprite(16, 24),
        "player_far.mem": build_sprite(12, 18),
        "font8x8.mem": build_font(),
        "palette_rgb888.mem": "".join(f"{value:06x}\n" for value in palette),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="verify outputs without writing")
    args = parser.parse_args()
    expected = generated_files()
    failures: list[str] = []
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for name, content in expected.items():
        path = OUTPUT / name
        if args.check:
            if not path.exists() or path.read_text(encoding="ascii") != content:
                failures.append(str(path.relative_to(ROOT)))
        else:
            path.write_text(content, encoding="ascii", newline="\n")
    if failures:
        print("FAIL: generated assets differ: " + ", ".join(failures))
        return 1
    action = "verified" if args.check else "generated"
    total_bytes = sum(len(content.splitlines()) for content in expected.values())
    print(f"PASS: {action} {len(expected)} deterministic video memories ({total_bytes} entries)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
