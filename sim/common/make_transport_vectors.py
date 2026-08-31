#!/usr/bin/env python3
import json
import pathlib
import sys

source_path = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "sim/vectors/motion_protocol_v1.json")
output_dir = pathlib.Path(sys.argv[2] if len(sys.argv) > 2 else ".build/transport/vectors")
source = json.loads(source_path.read_text(encoding="utf-8"))
stride = 80


def little_unsigned(raw: bytes, offset: int, width: int) -> int:
    return int.from_bytes(raw[offset : offset + width], byteorder="little", signed=False)


def little_signed(raw: bytes, offset: int, width: int) -> int:
    return int.from_bytes(raw[offset : offset + width], byteorder="little", signed=True)


def append_field(packed: int, value: int, width: int) -> int:
    return (packed << width) | (value & ((1 << width) - 1))


def packed_sample(raw: bytes) -> str:
    fields = [
        (1, 1),
        (0, 1),
        (little_unsigned(raw, 4, 2), 16),
        (little_unsigned(raw, 6, 4), 32),
    ]
    fields.extend((little_signed(raw, offset, 2), 16) for offset in range(10, 30, 2))
    packed = 0
    for value, width in fields:
        packed = append_field(packed, value, width)
    return f"{packed:053x}"


framed_bytes = []
lengths = []
accepted = []
samples = []
calibrated = []

for vector in source["vectors"]:
    framed = bytes.fromhex(vector["framed_hex"])
    raw = bytes.fromhex(vector["raw_hex"])
    if len(framed) > stride:
        raise ValueError(f"{vector['name']} exceeds vector stride")
    lengths.append(f"{len(framed):02x}")
    accepted.append("1" if vector["accepted"] else "0")
    samples.append(packed_sample(raw) if vector["accepted"] else "0" * 53)
    calibrated.append("1" if vector["accepted"] and raw[3] & 1 else "0")
    framed_bytes.extend(f"{value:02x}" for value in framed)
    framed_bytes.extend("00" for _ in range(stride - len(framed)))

output_dir.mkdir(parents=True, exist_ok=True)
for name, values in {
    "framed_bytes.hex": framed_bytes,
    "lengths.hex": lengths,
    "accepted.hex": accepted,
    "samples.hex": samples,
    "calibrated.hex": calibrated,
}.items():
    (output_dir / name).write_text("\n".join(values) + "\n", encoding="ascii")

print(f"PASS: generated {len(source['vectors'])} RTL vector records from {source_path}")
