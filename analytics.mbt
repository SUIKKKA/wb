///|
pub(all) struct PersonWorkload {
  person_id : PersonId
  assigned_minutes : Int
  target_minutes : Int
  difference : Int
  assignment_count : Int
  preference_score : Int
} derive(Show, Eq)

///|
pub(all) struct CoverageSummary {
  total_slots : Int
  covered_slots : Int
  uncovered_slots : Int
  coverage_percent : Int
  people_used : Int
  total_minutes : Int
} derive(Show, Eq)

///|
pub fn workload_for(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
  person : Person,
) -> PersonWorkload {
  let mut count = 0
  let mut prefs = 0
  for assignment in assignments {
    if assignment.person_id == person.id {
      count = count + 1
      prefs = prefs + preference_for(person, assignment.shift_id)
    }
  }
  let minutes = assigned_minutes(problem, assignments, person.id)
  {
    person_id: person.id,
    assigned_minutes: minutes,
    target_minutes: person.target_minutes,
    difference: minutes - person.target_minutes,
    assignment_count: count,
    preference_score: prefs,
  }
}

///|
pub fn all_workloads(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Array[PersonWorkload] {
  let values : Array[PersonWorkload] = []
  for person in problem.people {
    values.push(workload_for(problem, assignments, person))
  }
  values.sort_by((a, b) => {
    if a.assigned_minutes == b.assigned_minutes {
      a.person_id.compare(b.person_id)
    } else {
      b.assigned_minutes - a.assigned_minutes
    }
  })
  values
}

///|
pub fn coverage_summary(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> CoverageSummary {
  let mut total = 0
  for shift in problem.shifts {
    total = total + shift.required_people
  }
  let uncovered = count_uncovered(problem, assignments)
  let covered = total - uncovered
  let mut used = 0
  for person in problem.people {
    let mut found = false
    for assignment in assignments {
      if assignment.person_id == person.id {
        found = true
      }
    }
    if found {
      used = used + 1
    }
  }
  {
    total_slots: total,
    covered_slots: covered,
    uncovered_slots: uncovered,
    coverage_percent: if total == 0 {
      100
    } else {
      covered * 100 / total
    },
    people_used: used,
    total_minutes: total_scheduled_minutes(problem, assignments),
  }
}

///|
pub fn busiest_person(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> PersonId? {
  let workloads = all_workloads(problem, assignments)
  if workloads.length() == 0 {
    None
  } else {
    Some(workloads[0].person_id)
  }
}

///|
pub fn average_minutes(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Int {
  if problem.people.length() == 0 {
    0
  } else {
    total_scheduled_minutes(problem, assignments) / problem.people.length()
  }
}

///|
pub fn maximum_workload_gap(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Int {
  if problem.people.length() < 2 {
    return 0
  }
  let mut minimum = 2147483647
  let mut maximum = 0
  for person in problem.people {
    let minutes = assigned_minutes(problem, assignments, person.id)
    if minutes < minimum {
      minimum = minutes
    }
    if minutes > maximum {
      maximum = minutes
    }
  }
  maximum - minimum
}
