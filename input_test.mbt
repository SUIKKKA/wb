///|
test "integer parser handles signs and rejects garbage" {
  inspect(parse_integer("42"), content="Some(42)")
  inspect(parse_integer(" -17 "), content="Some(-17)")
  inspect(parse_integer("x17"), content="None")
  inspect(parse_integer(""), content="None")
}

///|
test "roster parser builds solvable problem" {
  let source = "person|alice|Alice|240|480\nskill|alice|cashier|2\navailable|alice|0|1440\nshift|morning|Morning|480|720|1|1|store\nrequire|morning|cashier|1\nrule|minimum_rest|60\n"
  let parsed = parse_roster(source)
  inspect(parsed.issues.length(), content="0")
  inspect(solve(parsed.problem).status, content="Solved")
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
