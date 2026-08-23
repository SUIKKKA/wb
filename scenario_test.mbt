///|
test "all bundled scenarios validate" {
  for name in scenario_names() {
    match scenario_by_name(name) {
      Some(problem) => inspect(validate_problem(problem).length(), content="0")
      None => fail("scenario name did not resolve")
    }
  }
}

///|
test "store scenario solves completely" {
  let problem = store_scenario()
  let result = solve(problem)
  inspect(result.status, content="Solved")
  inspect(count_uncovered(problem, result.assignments), content="0")
}

///|
test "laboratory scenario solves skill constraints" {
  let problem = laboratory_scenario()
  let result = solve(problem)
  inspect(result.status, content="Solved")
  inspect(
    count_policy_errors(run_all_policies(problem, result.assignments)),
    content="0",
  )
}

///|
test "volunteer scenario is deterministic" {
  let problem = volunteer_scenario()
  let first = solve(problem)
  let second = solve(problem)
  inspect(first.assignments, content=second.assignments.to_string())
}

///|
test "scenario expansion multiplies shifts" {
  let base = laboratory_scenario()
  let expanded = expand_days(base, 3)
  inspect(expanded.shifts.length(), content="15")
  inspect(expanded.people.length(), content="4")
}
