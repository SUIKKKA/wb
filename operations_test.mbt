///|
test "solved store scenario has complete operational coverage" {
  let problem = store_scenario()
  let result = solve(problem)
  let review = review_operations(problem, result.assignments)
  inspect(review.shifts.length(), content=problem.shifts.length().to_string())
  for item in review.shifts {
    inspect(item.assigned, content=item.required.to_string())
  }
}

///|
test "empty roster produces coverage actions" {
  let problem = store_scenario()
  let review = review_operations(problem, [])
  inspect(review.actions.length() > 0, content="true")
  inspect(review.shifts[0].risk_score > 0, content="true")
}

///|
test "risk labels have stable thresholds" {
  inspect(risk_level(0), content="low")
  inspect(risk_level(20), content="medium")
  inspect(risk_level(40), content="high")
  inspect(risk_level(70), content="critical")
}

///|
test "day review accounts for every store shift" {
  let problem = store_scenario()
  let result = solve(problem)
  let days = analyze_days(problem, result.assignments)
  let mut shifts = 0
  for day in days {
    shifts = shifts + day.shift_count
  }
  inspect(shifts, content=problem.shifts.length().to_string())
}

///|
test "operation markdown contains evidence tables" {
  let problem = store_scenario()
  let result = solve(problem)
  let text = render_operations_markdown(
    review_operations(problem, result.assignments),
  )
  inspect(text.contains("Shift resilience"), content="true")
  inspect(text.contains("Aggregate risk"), content="true")
}
