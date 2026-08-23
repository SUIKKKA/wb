# ShiftWeave

ShiftWeave is an explainable workforce scheduling and minimal-disruption repair engine written in MoonBit. It assigns qualified and available people to shift slots, validates hard constraints, scores fairness and preferences, explains infeasible rosters, and repairs an existing roster after leave or demand changes.

> Status: active development for the 2026 MoonBit Open Source Ecosystem August Hackathon.

## Why ShiftWeave

Small teams often schedule with spreadsheets. A spreadsheet can display a roster, but it rarely explains why a shift cannot be filled or how to repair a roster without changing everyone else's assignment. ShiftWeave treats scheduling as a constrained search problem and keeps evidence for every rejection.

The project is deliberately domain-facing rather than a MoonBit language tool. Typical uses include retail shifts, laboratory equipment duty, volunteer events, and small service teams.

## Planned command line

```bash
moon run cmd/main -- demo
moon run cmd/main -- validate examples/store.roster
moon run cmd/main -- solve examples/store.roster
moon run cmd/main -- repair examples/store.roster examples/store.leave
```

## Development

```bash
moon check
moon test
moon fmt
```

## Project boundaries

- Offline core and CLI; no cloud account or attendance tracking.
- Configurable work/rest rules; no jurisdiction-specific legal advice.
- Deterministic results for the same input and search budget.
- A verifier checks every emitted roster independently of the solver.

## License

Apache-2.0. See [LICENSE](LICENSE).
