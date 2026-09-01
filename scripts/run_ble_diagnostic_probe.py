#!/usr/bin/env python3
"""Send a raw probe and one frozen valid frame to the Board A BLE diagnostic."""

from __future__ import annotations

import argparse
import asyncio
import json
from pathlib import Path

from bleak import BleakClient, BleakScanner


DEFAULT_NAME_PREFIX = "RD_BOOL_88723523033D"
DEFAULT_WRITE_UUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"


async def run(name_prefix: str, write_uuid: str, scan_seconds: float) -> None:
    devices = await BleakScanner.discover(timeout=scan_seconds)
    matches = [device for device in devices if (device.name or "").startswith(name_prefix)]
    if len(matches) != 1:
        names = sorted(device.name for device in devices if device.name)
        raise RuntimeError(
            f"expected exactly one {name_prefix!r} peripheral, found {len(matches)}; "
            f"named advertisements={names}"
        )

    device = matches[0]
    print(f"BLE_DIAGNOSTIC_DEVICE {device.name} {device.address}")
    vectors_path = Path(__file__).resolve().parents[1] / "sim" / "vectors" / "motion_protocol_v1.json"
    document = json.loads(vectors_path.read_text(encoding="utf-8"))
    vector = next(item for item in document["vectors"] if item["name"] == "normal_values")
    frame = bytes.fromhex(vector["framed_hex"])

    async with BleakClient(device) as client:
        characteristic = client.services.get_characteristic(write_uuid)
        if characteristic is None:
            raise RuntimeError(f"write characteristic {write_uuid} was not discovered")
        if "write" not in characteristic.properties:
            raise RuntimeError(
                f"characteristic {write_uuid} lacks write-with-response: {characteristic.properties}"
            )
        print(f"BLE_DIAGNOSTIC_WRITE_PROPERTIES {','.join(characteristic.properties)}")
        await client.write_gatt_char(characteristic, b"\x41\x0a", response=True)
        print("BLE_DIAGNOSTIC_PROBE_WRITE 410a")
        await asyncio.sleep(0.25)
        await client.write_gatt_char(characteristic, frame, response=True)
        print(f"BLE_DIAGNOSTIC_VECTOR_WRITE {vector['name']} {vector['framed_hex']}")
        await asyncio.sleep(0.25)

    print("BLE_DIAGNOSTIC_WRITE_PASS")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--name-prefix", default=DEFAULT_NAME_PREFIX)
    parser.add_argument("--write-uuid", default=DEFAULT_WRITE_UUID)
    parser.add_argument("--scan-seconds", type=float, default=15.0)
    args = parser.parse_args()
    asyncio.run(run(args.name_prefix, args.write_uuid, args.scan_seconds))


if __name__ == "__main__":
    main()
