///|
test "candidate explanation distinguishes eligible and rejected" {
  let problem = test_problem()
  let shift = problem.shifts[0]
  let alice = problem.people[0]
  inspect(
    explain_candidate(problem, [], shift, 0, alice).eligible,
    content="true",
  )
  let bad = test_person("bad", [], [{ start: 0, end: 1440 }])
  inspect(
    explain_candidate(problem, [], shift, 0, bad).eligible,
    content="false",
  )
}

///|
test "most constrained slot is returned" {
  match most_constrained_slot(test_problem(), []) {
    Some(item) => inspect(item.shift_id, content="morning")
    None => fail("missing explanation")
  }
}

///|
test "fingerprint is deterministic and order independent" {
  let a : Assignment = { shift_id: "a", slot: 0, person_id: "x", locked: false }
  let b : Assignment = { shift_id: "b", slot: 0, person_id: "y", locked: false }
  inspect(
    schedule_fingerprint([a, b]) == schedule_fingerprint([b, a]),
    content="true",
  )
}

///|
test "audit solved roster is complete" {
  let problem = test_problem()
  let result = solve(problem)
  let audit = audit_schedule(problem, result.assignments)
  inspect(audit.complete, content="true")
  inspect(audit.coverage_percent, content="100")
}
