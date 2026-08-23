///|
test "solver fills a simple shift" {
  let problem = test_problem()
  let result = solve(problem)
  assert_eq(result.status, Solved)
  inspect(result.assignments.length(), content="1")
  inspect(result.assignments[0].person_id, content="alice")
}

///|
test "solver explains impossible skill requirement" {
  let base = test_problem()
  let impossible : ScheduleProblem = {
    ..base,
    shifts: [test_shift("lab", 480, 720, "chemist")],
  }
  let result = solve(impossible)
  assert_eq(result.status, Infeasible)
  assert_eq(result.diagnostics[0].code, EmptyCandidateDomain)
}

///|
test "scoring rewards preferences" {
  let base = test_problem()
  let alice = base.people[0]
  let liked : Person = {
    ..alice,
    preferences: [{ shift_id: "morning", weight: 10 }],
  }
  let problem : ScheduleProblem = { ..base, people: [liked] }
  let result = solve(problem)
  inspect(result.metrics.preference_score, content="10")
}

///|
test "global node budget is reported exactly" {
  let result = solve(store_scenario(), options={
    ..SearchOptions::default(),
    maximum_nodes: 1,
  })
  assert_eq(result.status, BudgetExceeded)
  inspect(result.explored_nodes, content="1")
  assert_eq(result.diagnostics[0].code, SearchBudgetExceeded)
}

///|
test "successful search reports real work below the budget" {
  let maximum = 1000
  let result = solve(store_scenario(), options={
    ..SearchOptions::default(),
    maximum_nodes: maximum,
  })
  assert_eq(result.status, Solved)
  inspect(result.explored_nodes > 0, content="true")
  inspect(result.explored_nodes < maximum, content="true")
  inspect(result.propagated_values >= 0, content="true")
}
