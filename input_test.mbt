///|
test "integer parser handles signs and rejects garbage" {
  assert_eq(parse_integer("42"), Some(42))
  assert_eq(parse_integer(" -17 "), Some(-17))
  assert_eq(parse_integer("x17"), None)
  assert_eq(parse_integer(""), None)
}

///|
test "roster parser builds solvable problem" {
  let source = "person|alice|Alice|240|480\nskill|alice|cashier|2\navailable|alice|0|1440\nshift|morning|Morning|480|720|1|1|store\nrequire|morning|cashier|1\nrule|minimum_rest|60\n"
  let parsed = parse_roster(source)
  inspect(parsed.issues.length(), content="0")
  assert_eq(solve(parsed.problem).status, Solved)
}

///|
test "roster parser reports source line" {
  let parsed = parse_roster("person|alice|Alice|bad|480")
  inspect(parsed.issues.length(), content="1")
  inspect(parsed.issues[0].line, content="1")
}

///|
test "roster round trip preserves shape" {
  let original = test_problem()
  let parsed = parse_roster(render_roster(original))
  inspect(parsed.issues.length(), content="0")
  inspect(parsed.problem.people.length(), content="1")
  inspect(parsed.problem.shifts.length(), content="1")
}
