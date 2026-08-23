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
```

The demo solves a seven-shift retail roster and prints two Markdown reports: the assignment result and an operational risk review. The latter identifies uncovered duties, replacement margin, rest-sensitive handovers, and concrete follow-up actions.

The current CLI intentionally exposes the built-in demonstration only; the reusable library API provides solving, repair, parsing, and reporting. `examples/store.roster` demonstrates the interchange format and can be parsed through `parse_roster` when embedded in an application.

## Install and use as a library

```bash
moon add SUIKKKA/shiftweave@0.1.1
```

```moonbit
let problem = @shiftweave.store_scenario()
let result = @shiftweave.solve(problem)
println(@shiftweave.render_markdown(problem, result))
```

For a disrupted roster, construct a `RepairRequest` and call `repair`. Search uses one deterministic global node budget; `ScheduleResult` reports the real explored-node and propagated-value counts and distinguishes an exhausted budget from a proven infeasible problem.

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
moon check --deny-warn
moon test --deny-warn
moon build
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

ShiftWeave is an original project implemented for this hackathon. It does not port third-party source code. Dependencies are limited to the MoonBit core/toolchain; repository contents are released under Apache-2.0. AI assistance and source provenance are documented in [PROVENANCE.md](PROVENANCE.md).

## License

Apache-2.0. See [LICENSE](LICENSE).
