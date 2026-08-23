///|
test "solver fills a simple shift" {
  let problem = test_problem()
  let result = solve(problem)
  inspect(result.status, content="Solved")
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
  inspect(result.status, content="Infeasible")
  inspect(result.diagnostics[0].code, content="EmptyCandidateDomain")
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
