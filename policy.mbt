///|
pub(all) enum FindingLevel {
  Info
  Warning
  Error
} derive(Show, Eq)

///|
pub(all) struct PolicyFinding {
  rule : String
  level : FindingLevel
  message : String
  person_id : PersonId?
  shift_id : ShiftId?
  measured : Int
  expected : Int
} derive(Show, Eq)

///|
fn finding(
  rule : String,
  level : FindingLevel,
  message : String,
  person_id? : PersonId = "",
  shift_id? : ShiftId = "",
  measured? : Int = 0,
  expected? : Int = 0,
) -> PolicyFinding {
  {
    rule,
    level,
    message,
    person_id: if person_id == "" {
      None
    } else {
      Some(person_id)
    },
    shift_id: if shift_id == "" {
      None
    } else {
      Some(shift_id)
    },
    measured,
    expected,
  }
}

///|
pub fn check_coverage_policy(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Array[PolicyFinding] {
  let out : Array[PolicyFinding] = []
  for shift in problem.shifts {
    let assigned = assignments_for_shift(assignments, shift.id).length()
    if assigned < shift.required_people {
      out.push(
        finding(
          "coverage",
          Error,
          "shift has uncovered slots",
          shift_id=shift.id,
          measured=assigned,
          expected=shift.required_people,
        ),
      )
    }
  }
  out
}

///|
pub fn check_capacity_policy(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Array[PolicyFinding] {
  let out : Array[PolicyFinding] = []
  for shift in problem.shifts {
    let assigned = assignments_for_shift(assignments, shift.id).length()
    if assigned > shift.required_people {
      out.push(
        finding(
          "capacity",
          Error,
          "shift is assigned above capacity",
          shift_id=shift.id,
          measured=assigned,
          expected=shift.required_people,
        ),
      )
    }
  }
  out
}

///|
pub fn check_maximum_minutes_policy(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Array[PolicyFinding] {
  let out : Array[PolicyFinding] = []
  for person in problem.people {
    let minutes = assigned_minutes(problem, assignments, person.id)
    if minutes > person.maximum_minutes {
      out.push(
        finding(
          "maximum-minutes",
          Error,
          "person exceeds maximum minutes",
          person_id=person.id,
          measured=minutes,
          expected=person.maximum_minutes,
        ),
      )
    }
  }
  out
}

///|
pub fn check_target_minutes_policy(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
  tolerance? : Int = 60,
) -> Array[PolicyFinding] {
  let out : Array[PolicyFinding] = []
  for person in problem.people {
    let minutes = assigned_minutes(problem, assignments, person.id)
    if absolute(minutes - person.target_minutes) > tolerance {
      out.push(
        finding(
          "target-minutes",
          Warning,
          "person is outside target tolerance",
          person_id=person.id,
          measured=minutes,
          expected=person.target_minutes,
        ),
      )
    }
  }
  out
}

///|
pub fn check_availability_policy(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Array[PolicyFinding] {
  let out : Array[PolicyFinding] = []
  for assignment in assignments {
    match
      (
        find_person(problem, assignment.person_id),
        find_shift(problem, assignment.shift_id),
      ) {
      (Some(person), Some(shift)) =>
        if !is_available(person, shift) {
          out.push(
            finding(
              "availability",
              Error,
              "assignment is outside availability",
              person_id=person.id,
              shift_id=shift.id,
            ),
          )
        }
      _ => ()
    }
  }
  out
}

///|
pub fn check_skill_policy(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Array[PolicyFinding] {
  let out : Array[PolicyFinding] = []
  for assignment in assignments {
    match
      (
        find_person(problem, assignment.person_id),
        find_shift(problem, assignment.shift_id),
      ) {
      (Some(person), Some(shift)) =>
        if !meets_requirements(person, shift) {
          out.push(
            finding(
              "skills",
              Error,
              "person lacks a required skill",
              person_id=person.id,
              shift_id=shift.id,
            ),
          )
        }
      _ => ()
    }
  }
  out
}

///|
pub fn check_overlap_policy(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Array[PolicyFinding] {
  let out : Array[PolicyFinding] = []
  for i = 0; i < assignments.length(); i = i + 1 {
    for j = i + 1; j < assignments.length(); j = j + 1 {
      let a = assignments[i]
      let b = assignments[j]
      if a.person_id == b.person_id {
        match
          (find_shift(problem, a.shift_id), find_shift(problem, b.shift_id)) {
          (Some(sa), Some(sb)) =>
            if sa.time.overlaps(sb.time) {
              out.push(
                finding(
                  "overlap",
                  Error,
                  "person has overlapping shifts",
                  person_id=a.person_id,
                  shift_id=a.shift_id,
                ),
              )
            }
          _ => ()
        }
      }
    }
  }
  out
}

///|
pub fn check_rest_policy(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Array[PolicyFinding] {
  let out : Array[PolicyFinding] = []
  for person in problem.people {
    let own = assignments_for_person(assignments, person.id)
    for i = 0; i < own.length(); i = i + 1 {
      for j = i + 1; j < own.length(); j = j + 1 {
        match
          (
            find_shift(problem, own[i].shift_id),
            find_shift(problem, own[j].shift_id),
          ) {
          (Some(a), Some(b)) => {
            let gap = a.time.gap_to(b.time)
            if gap >= 0 && gap < problem.minimum_rest_minutes {
              out.push(
                finding(
                  "minimum-rest",
                  Error,
                  "rest interval is too short",
                  person_id=person.id,
                  shift_id=b.id,
                  measured=gap,
                  expected=problem.minimum_rest_minutes,
                ),
              )
            }
          }
          _ => ()
        }
      }
    }
  }
  out
}

///|
pub fn check_duplicate_slot_policy(
  assignments : Array[Assignment],
) -> Array[PolicyFinding] {
  let out : Array[PolicyFinding] = []
  for i = 0; i < assignments.length(); i = i + 1 {
    for j = i + 1; j < assignments.length(); j = j + 1 {
      if assignments[i].shift_id == assignments[j].shift_id &&
        assignments[i].slot == assignments[j].slot {
        out.push(
          finding(
            "duplicate-slot",
            Error,
            "multiple people occupy one slot",
            shift_id=assignments[i].shift_id,
            measured=2,
            expected=1,
          ),
        )
      }
    }
  }
  out
}

///|
pub fn check_duplicate_person_in_shift_policy(
  assignments : Array[Assignment],
) -> Array[PolicyFinding] {
  let out : Array[PolicyFinding] = []
  for i = 0; i < assignments.length(); i = i + 1 {
    for j = i + 1; j < assignments.length(); j = j + 1 {
      if assignments[i].shift_id == assignments[j].shift_id &&
        assignments[i].person_id == assignments[j].person_id {
        out.push(
          finding(
            "duplicate-person-shift",
            Error,
            "one person occupies multiple slots in the same shift",
            person_id=assignments[i].person_id,
            shift_id=assignments[i].shift_id,
          ),
        )
      }
    }
  }
  out
}

///|
pub fn check_preference_policy(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
  threshold? : Int = -5,
) -> Array[PolicyFinding] {
  let out : Array[PolicyFinding] = []
  for assignment in assignments {
    match find_person(problem, assignment.person_id) {
      Some(person) => {
        let score = preference_for(person, assignment.shift_id)
        if score <= threshold {
          out.push(
            finding(
              "negative-preference",
              Warning,
              "assignment conflicts with a strong preference",
              person_id=person.id,
              shift_id=assignment.shift_id,
              measured=score,
              expected=threshold + 1,
            ),
          )
        }
      }
      None => ()
    }
  }
  out
}

///|
pub fn check_locked_assignment_policy(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Array[PolicyFinding] {
  let out : Array[PolicyFinding] = []
  for locked in problem.existing {
    if locked.locked {
      let mut found = false
      for item in assignments {
        if same_assignment(locked, item) {
          found = true
        }
      }
      if !found {
        out.push(
          finding(
            "locked-assignment",
            Error,
            "locked assignment was changed",
            person_id=locked.person_id,
            shift_id=locked.shift_id,
          ),
        )
      }
    }
  }
  out
}

///|
pub fn check_priority_policy(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
  minimum_priority? : Int = 5,
) -> Array[PolicyFinding] {
  let out : Array[PolicyFinding] = []
  for shift in problem.shifts {
    if shift.priority >= minimum_priority {
      let assigned = assignments_for_shift(assignments, shift.id).length()
      if assigned < shift.required_people {
        out.push(
          finding(
            "high-priority-coverage",
            Error,
            "high-priority shift is not fully covered",
            shift_id=shift.id,
            measured=assigned,
            expected=shift.required_people,
          ),
        )
      }
    }
  }
  out
}

///|
pub fn check_empty_skill_policy(
  problem : ScheduleProblem,
) -> Array[PolicyFinding] {
  let out : Array[PolicyFinding] = []
  for shift in problem.shifts {
    for requirement in shift.requirements {
      let mut qualified = 0
      for person in problem.people {
        if skill_level(person, requirement.skill) >= requirement.minimum_level {
          qualified = qualified + 1
        }
      }
      if qualified == 0 {
        out.push(
          finding(
            "skill-supply",
            Error,
            "no person can satisfy skill requirement",
            shift_id=shift.id,
            measured=0,
            expected=1,
          ),
        )
      } else if qualified < shift.required_people {
        out.push(
          finding(
            "skill-supply",
            Warning,
            "qualified person supply is fragile",
            shift_id=shift.id,
            measured=qualified,
            expected=shift.required_people,
          ),
        )
      }
    }
  }
  out
}

///|
pub fn check_availability_supply_policy(
  problem : ScheduleProblem,
) -> Array[PolicyFinding] {
  let out : Array[PolicyFinding] = []
  for shift in problem.shifts {
    let mut available = 0
    for person in problem.people {
      if is_available(person, shift) && meets_requirements(person, shift) {
        available = available + 1
      }
    }
    if available < shift.required_people {
      out.push(
        finding(
          "availability-supply",
          Error,
          "not enough eligible people are available",
          shift_id=shift.id,
          measured=available,
          expected=shift.required_people,
        ),
      )
    } else if available == shift.required_people {
      out.push(
        finding(
          "availability-supply",
          Warning,
          "shift has no backup candidate",
          shift_id=shift.id,
          measured=available,
          expected=shift.required_people + 1,
        ),
      )
    }
  }
  out
}

///|
pub fn check_fairness_gap_policy(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
  maximum_gap? : Int = 480,
) -> Array[PolicyFinding] {
  let gap = maximum_workload_gap(problem, assignments)
  if gap > maximum_gap {
    [
      finding(
        "fairness-gap",
        Warning,
        "workload gap exceeds configured limit",
        measured=gap,
        expected=maximum_gap,
      ),
    ]
  } else {
    []
  }
}

///|
pub fn run_all_policies(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Array[PolicyFinding] {
  let out : Array[PolicyFinding] = []
  for item in check_coverage_policy(problem, assignments) {
    out.push(item)
  }
  for item in check_capacity_policy(problem, assignments) {
    out.push(item)
  }
  for item in check_maximum_minutes_policy(problem, assignments) {
    out.push(item)
  }
  for item in check_target_minutes_policy(problem, assignments) {
    out.push(item)
  }
  for item in check_availability_policy(problem, assignments) {
    out.push(item)
  }
  for item in check_skill_policy(problem, assignments) {
    out.push(item)
  }
  for item in check_overlap_policy(problem, assignments) {
    out.push(item)
  }
  for item in check_rest_policy(problem, assignments) {
    out.push(item)
  }
  for item in check_duplicate_slot_policy(assignments) {
    out.push(item)
  }
  for item in check_duplicate_person_in_shift_policy(assignments) {
    out.push(item)
  }
  for item in check_preference_policy(problem, assignments) {
    out.push(item)
  }
  for item in check_locked_assignment_policy(problem, assignments) {
    out.push(item)
  }
  for item in check_priority_policy(problem, assignments) {
    out.push(item)
  }
  for item in check_empty_skill_policy(problem) {
    out.push(item)
  }
  for item in check_availability_supply_policy(problem) {
    out.push(item)
  }
  for item in check_fairness_gap_policy(problem, assignments) {
    out.push(item)
  }
  out
}

///|
pub fn count_policy_errors(findings : Array[PolicyFinding]) -> Int {
  let mut count = 0
  for item in findings {
    if item.level == Error {
      count = count + 1
    }
  }
  count
}

///|
pub fn count_policy_warnings(findings : Array[PolicyFinding]) -> Int {
  let mut count = 0
  for item in findings {
    if item.level == Warning {
      count = count + 1
    }
  }
  count
}
