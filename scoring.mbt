///|
pub fn person_minutes(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
  person_id : PersonId,
) -> Int {
  assigned_minutes(problem, assignments, person_id)
}

///|
pub fn total_scheduled_minutes(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Int {
  let mut total = 0
  for assignment in assignments {
    match find_shift(problem, assignment.shift_id) {
      Some(shift) => total = total + shift.time.duration()
      None => ()
    }
  }
  total
}

///|
pub fn preference_score(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Int {
  let mut total = 0
  for assignment in assignments {
    match find_person(problem, assignment.person_id) {
      Some(person) =>
        total = total + preference_for(person, assignment.shift_id)
      None => ()
    }
  }
  total
}

///|
pub fn absolute(value : Int) -> Int {
  if value < 0 {
    -value
  } else {
    value
  }
}

///|
pub fn fairness_penalty(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Int {
  let mut penalty = 0
  for person in problem.people {
    penalty = penalty +
      absolute(
        person_minutes(problem, assignments, person.id) - person.target_minutes,
      )
  }
  penalty
}

///|
pub fn disruption_count(
  existing : Array[Assignment],
  proposed : Array[Assignment],
) -> Int {
  let mut changes = 0
  for old in existing {
    let mut preserved = false
    for fresh in proposed {
      if same_assignment(old, fresh) {
        preserved = true
      }
    }
    if !preserved {
      changes = changes + 1
    }
  }
  for fresh in proposed {
    let mut known = false
    for old in existing {
      if same_assignment(old, fresh) {
        known = true
      }
    }
    if !known {
      changes = changes + 1
    }
  }
  changes
}

///|
pub fn count_uncovered(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Int {
  let mut missing = 0
  for shift in problem.shifts {
    for slot = 0; slot < shift.required_people; slot = slot + 1 {
      let mut found = false
      for assignment in assignments {
        if assignment.shift_id == shift.id && assignment.slot == slot {
          found = true
        }
      }
      if !found {
        missing = missing + 1
      }
    }
  }
  missing
}

///|
pub fn evaluate_schedule(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> ScheduleMetrics {
  let diagnostics = validate_assignments(
    problem,
    assignments,
    require_complete=false,
  )
  let mut violations = 0
  for item in diagnostics {
    if item.severity >= 2 {
      violations = violations + 1
    }
  }
  let uncovered = count_uncovered(problem, assignments)
  let pref = preference_score(problem, assignments)
  let fair = fairness_penalty(problem, assignments)
  let disruptions = disruption_count(problem.existing, assignments)
  let objective = violations * 1000000 +
    uncovered * 100000 -
    pref * problem.preference_weight +
    fair * problem.fairness_weight +
    disruptions * problem.disruption_weight
  {
    hard_violations: violations,
    uncovered_slots: uncovered,
    preference_score: pref,
    fairness_penalty: fair,
    disruption_count: disruptions,
    total_minutes: total_scheduled_minutes(problem, assignments),
    objective,
  }
}

///|
pub fn incremental_cost(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
  shift : Shift,
  person : Person,
) -> Int {
  let before = person_minutes(problem, assignments, person.id)
  let after = before + shift.time.duration()
  let fairness_delta = absolute(after - person.target_minutes) -
    absolute(before - person.target_minutes)
  let preference = preference_for(person, shift.id)
  let mut disruption = 1
  for old in problem.existing {
    if old.shift_id == shift.id && old.person_id == person.id {
      disruption = -1
    }
  }
  fairness_delta * problem.fairness_weight -
  preference * problem.preference_weight +
  disruption * problem.disruption_weight
}

///|
pub fn better_metrics(a : ScheduleMetrics, b : ScheduleMetrics) -> Bool {
  a.objective < b.objective
}
