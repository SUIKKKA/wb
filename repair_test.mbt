///|
test "repair removes unavailable person and preserves unaffected assignment" {
  let base = test_problem()
  let bob = test_person("bob", [{ name: "cashier", level: 1 }], [
    { start: 0, end: 1440 },
  ])
  let existing : Assignment = {
    shift_id: "morning",
    slot: 0,
    person_id: "alice",
    locked: false,
  }
  let problem : ScheduleProblem = {
    ..base,
    people: [base.people[0], bob],
    existing: [existing],
  }
  let request : RepairRequest = {
    unavailable_people: ["alice"],
    removed_shifts: [],
    unlocked_shifts: [],
    preserve_unaffected: true,
  }
  let result = repair(problem, request)
  assert_eq(result.status, Solved)
  inspect(result.assignments[0].person_id, content="bob")
}

///|
test "coverage and workload analytics" {
  let problem = test_problem()
  let result = solve(problem)
  let coverage = coverage_summary(problem, result.assignments)
  inspect(coverage.coverage_percent, content="100")
  inspect(
    all_workloads(problem, result.assignments)[0].assigned_minutes,
    content="240",
  )
}

///|
test "reports contain stable headers" {
  let problem = test_problem()
  let result = solve(problem)
  inspect(
    render_csv(problem, result).has_prefix("shift_id,shift_label"),
    content="true",
  )
  inspect(
    render_json(problem, result).has_prefix("{\"status\":\"solved\""),
    content="true",
  )
  inspect(
    render_markdown(problem, result).has_prefix("# ShiftWeave schedule report"),
    content="true",
  )
}
