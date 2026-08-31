# Coding-Agent Handoff

This project is organized for four concurrent implementation agents plus one orchestration/integration owner. Do not give every agent the entire documentation set.

## Orchestration owner instruction

> Read `plan.md`, `STATUS.md`, `docs/00_interface_freeze.md`, `docs/01_architecture.md`, and `status/integration.md`. Complete gate F0 before dispatching implementation tracks. Assign exactly one owner per path in the master ownership table. Once F0 passes, dispatch iOS, transport, video, and gameplay concurrently. Monitor their status files, coordinate versioned interface changes, and keep `STATUS.md` as the global index. Do not claim tests or hardware evidence you did not collect. Begin full integration only after C2, C3, and G1 pass at recorded commits.

## First task — gate F0

1. Create the repository skeleton from `docs/01_architecture.md`.
2. Create the normative protocol document, compiling shared packages, golden vectors, and cross-track stubs.
3. Run the interface smoke tests in `docs/00_interface_freeze.md`.
4. Record owners, test commands/results, review acknowledgements, and the F0 commit in `STATUS.md`.
5. Mark all four tracks ready and dispatch them only after the F0 commit is shared.

## Track-agent instruction template

> You own the **TRACK_NAME** track. Read only `plan.md`, `STATUS.md`, `docs/01_architecture.md`, **TRACK_DOCUMENT**, and **TRACK_STATUS**. Confirm F0 is passed, then work only in the paths assigned to your track. Run the track's simulations and hardware checks; never claim evidence you did not collect. Do not guess BLE UUIDs, XDC pins, connector positions, Vivado IP versions, or measured limits. Do not edit frozen contracts or another track's files. Put cross-owner requests, discovered hardware facts, exact tests/results, commit hashes, risks, and your next action only in your track status file. Stop and request a versioned contract change if the frozen interface is insufficient.

| Track | `TRACK_DOCUMENT` | `TRACK_STATUS` |
|---|---|---|
| iOS | `docs/02_track_ios_controller.md` | `status/ios.md` |
| Transport | `docs/03_track_transport.md` | `status/transport.md` |
| Video | `docs/04_track_video.md` | `status/video.md` |
| Gameplay | `docs/05_track_gameplay.md` | `status/gameplay.md` |

## Integration instruction

> Read `plan.md`, `STATUS.md`, `docs/01_architecture.md`, `docs/06_integration.md`, every track status file, and only the detailed track documents implicated by a failed handoff. Verify that C2, C3, and G1 commits are present. Merge shared contracts first, then transport/iOS, video, gameplay, and integration changes. Re-run each gate on the merged base. Route subsystem defects back to their owner instead of patching around them in `rtl/board_a_top.sv`. Consolidate verified hardware facts into the manifest and record integration evidence in `status/integration.md` and `STATUS.md`.

If stock BLE behavior, vendor IP, or physical hardware contradicts the plan, record the observed evidence and stop only the dependent work. Independent video and simulated gameplay work continues.
