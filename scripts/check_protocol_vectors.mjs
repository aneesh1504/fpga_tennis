import fs from "node:fs";

const path = process.argv[2] ?? "sim/vectors/motion_protocol_v1.json";
const document = JSON.parse(fs.readFileSync(path, "utf8"));
const failures = [];

function crc16CcittFalse(bytes) {
  let crc = 0xffff;
  for (const byte of bytes) {
    crc ^= byte << 8;
    for (let bit = 0; bit < 8; bit += 1) {
      crc = (crc & 0x8000) ? ((crc << 1) ^ 0x1021) & 0xffff : (crc << 1) & 0xffff;
    }
  }
  return crc;
}

function unframe(bytes) {
  if (bytes.at(-1) !== 0x0a) throw new Error("missing terminator");
  const decoded = [];
  for (let index = 0; index < bytes.length - 1; index += 1) {
    let byte = bytes[index];
    if (byte === 0x0a) throw new Error("unescaped terminator");
    if (byte === 0x7d) {
      index += 1;
      if (index >= bytes.length - 1 || ![0x2a, 0x5d].includes(bytes[index])) throw new Error("invalid escape");
      byte = bytes[index] ^ 0x20;
    }
    decoded.push(byte);
  }
  return Buffer.from(decoded);
}

for (const vector of document.vectors) {
  try {
    const raw = Buffer.from(vector.raw_hex, "hex");
    const framed = Buffer.from(vector.framed_hex, "hex");
    const decoded = unframe(framed);
    if (raw.length !== 32) throw new Error(`raw length ${raw.length}, expected 32`);
    if (!raw.equals(decoded)) throw new Error("framed data does not decode to raw data");
    if (raw[0] !== 1 || raw[1] !== 1 || ![1, 2].includes(raw[2])) throw new Error("invalid fixed header");
    if (raw.readUInt16LE(4) !== vector.sequence) throw new Error("sequence metadata mismatch");
    const computed = crc16CcittFalse(raw.subarray(0, 30));
    const stored = raw.readUInt16LE(30);
    if (computed.toString(16).padStart(4, "0") !== vector.expected_crc_hex) throw new Error("expected CRC metadata mismatch");
    if ((computed === stored) !== vector.accepted) throw new Error("accept/reject expectation does not match CRC result");
  } catch (error) {
    failures.push(`${vector.name}: ${error.message}`);
  }
}

const names = new Set(document.vectors.map(({ name }) => name));
for (const required of ["normal_values", "signed_limits", "escaped_terminator_and_escape", "bad_crc", "sequence_wrap_before", "sequence_wrap_after"]) {
  if (!names.has(required)) failures.push(`missing required vector ${required}`);
}
const escaped = document.vectors.find(({ name }) => name === "escaped_terminator_and_escape");
if (escaped && (!escaped.framed_hex.includes("7d2a") || !escaped.framed_hex.includes("7d5d"))) failures.push("escape vector lacks both encoded forms");
const before = document.vectors.find(({ name }) => name === "sequence_wrap_before");
const after = document.vectors.find(({ name }) => name === "sequence_wrap_after");
if (before && after && ((before.sequence + 1) & 0xffff) !== after.sequence) failures.push("sequence wrap pair is not consecutive modulo 65536");

if (failures.length) {
  console.error(failures.join("\n"));
  process.exit(1);
}
console.log(`PASS: ${document.vectors.length} motion protocol vectors validated (${path})`);
