# FPGA Motion Tennis Planning Package

Start with [plan.md](plan.md). It contains the project brief, final outcome, fixed decisions, parallel-work routing, dependency gates, and the coding-agent operating contract.

An implementation agent should then read only:

1. `plan.md`
2. `STATUS.md`
3. `docs/01_architecture.md`
4. Its assigned track document
5. Its file under `status/`

The orchestration owner starts with `docs/00_interface_freeze.md`. After gate F0 passes, the iOS, transport, video, and gameplay tracks may run concurrently. Only the orchestration/integration owner edits shared top-level modules or the global status index.

Product requirements and hardware limitations are in `docs/00_requirements.md`. Track owners update only their own status files so parallel agents do not overwrite one another.
