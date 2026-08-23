# ShiftWeave

ShiftWeave is an explainable workforce scheduling and minimal-disruption repair engine written in MoonBit. It assigns qualified and available people to shift slots, validates hard constraints, scores fairness and preferences, explains infeasible rosters, and repairs an existing roster after leave or demand changes.

The repository contains more than 4,000 lines of effective MoonBit source, runnable scenarios, tests, CI, and an independently verifiable reporting pipeline.

## Why ShiftWeave

Small teams often schedule with spreadsheets. A spreadsheet can display a roster, but it rarely explains why a shift cannot be filled or how to repair a roster without changing everyone else's assignment. ShiftWeave treats scheduling as a constrained search problem and keeps evidence for every rejection.

The project is deliberately domain-facing rather than a MoonBit language tool. Typical uses include retail shifts, laboratory equipment duty, volunteer events, and small service teams.

## Quick start

```bash
moon run cmd/main -- demo
moon test
moon run cmd/main -- demo
```

The demo solves a seven-shift retail roster and prints two Markdown reports: the assignment result and an operational risk review. The latter identifies uncovered duties, replacement margin, rest-sensitive handovers, and concrete follow-up actions.

## Core capabilities

- Validates identities, time spans, availability, skills, slots, overlap, rest, workload, and consecutive-duty limits.
- Propagates forced assignments before deterministic bounded backtracking.
- Scores coverage, fairness, preferences, and disruption separately.
- Repairs an existing roster while preserving unaffected locked assignments.
- Explains candidate rejection and suggests changes for infeasible slots.
- Produces Markdown, CSV, and JSON output plus stable audit fingerprints.
- Reviews daily load, shift resilience, standby margin, and handover risk.
- Includes retail, laboratory, and volunteer-event scenarios.

## Architecture

The domain model is independent from the solver. `validation.mbt` and `policy.mbt` form the verification boundary; `candidate.mbt`, `propagation.mbt`, and `solver.mbt` implement search; `scoring.mbt` keeps optimization policy explicit; `repair.mbt` handles minimal-change replanning. Reporting and operational review consume only public problem/result values, so their evidence can be checked independently.

The text interchange format is line-oriented and pipe-delimited. Comments begin with `#`; records describe settings, people, skills, availability, preferences, shifts, requirements, and existing assignments. See `examples/store.roster` for a compact example and `text_input.mbt` for the parser and round-trip serializer.

## Testing and reproducibility

```bash
moon fmt --check
moon check
moon test
moon run cmd/main -- demo
moon publish --dry-run
```

Tests cover validation failures, deterministic solving, policy evaluation, candidate explanations, repair impact, serializers, built-in scenarios, audit comparison, and operational risk. GitHub Actions runs formatting, checking, the native test suite, and the demo on every push and pull request.

## Development

```bash
moon check
moon test
moon fmt
```

## Project boundaries and originality

- Offline core and CLI; no cloud account or attendance tracking.
- Configurable work/rest rules; no jurisdiction-specific legal advice.
- Deterministic results for the same input and search budget.
- A verifier checks every emitted roster independently of the solver.

ShiftWeave is an original project implemented for this hackathon. It does not port third-party source code. Dependencies are limited to the MoonBit core/toolchain; repository contents are released under Apache-2.0.

## License

Apache-2.0. See [LICENSE](LICENSE).
