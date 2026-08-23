///|
test "policy suite accepts solved simple roster" {
  let problem = test_problem()
  let result = solve(problem)
  let findings = run_all_policies(problem, result.assignments)
  inspect(count_policy_errors(findings), content="0")
}

///|
test "coverage policy identifies missing slot" {
  let findings = check_coverage_policy(test_problem(), [])
  inspect(findings.length(), content="1")
  inspect(findings[0].rule, content="coverage")
}

///|
test "duplicate slot policy identifies conflict" {
  let a : Assignment = { shift_id: "s", slot: 0, person_id: "a", locked: false }
  let b : Assignment = { shift_id: "s", slot: 0, person_id: "b", locked: false }
  inspect(check_duplicate_slot_policy([a, b]).length(), content="1")
}

///|
test "fairness policy reports large gap" {
  let base = test_problem()
  let bob = test_person("bob", [{ name: "cashier", level: 1 }], [
    { start: 0, end: 1440 },
  ])
  let problem : ScheduleProblem = { ..base, people: [base.people[0], bob] }
  let assigned : Assignment = {
    shift_id: "morning",
    slot: 0,
    person_id: "alice",
    locked: false,
  }
  inspect(
    check_fairness_gap_policy(problem, [assigned], maximum_gap=60).length(),
    content="1",
  )
}
