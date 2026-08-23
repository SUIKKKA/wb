///|
/// Operational analysis derived independently from the search algorithm.
pub(all) struct ShiftOperation {
  shift_id : ShiftId
  label : String
  group : String
  assigned : Int
  required : Int
  qualified : Int
  standby : Int
  coverage_percent : Int
  risk_score : Int
  risk_level : String
} derive(Debug, Eq)

///|
/// A transition between two adjacent duties performed by one person.
pub(all) struct Handover {
  person_id : PersonId
  from_shift : ShiftId
  to_shift : ShiftId
  gap_minutes : Int
  same_group : Bool
  risk_score : Int
} derive(Debug, Eq)

///|
/// Day-level summary for dashboards and post-run review.
pub(all) struct DayOperation {
  day : Int
  shift_count : Int
  required_slots : Int
  assigned_slots : Int
  uncovered_slots : Int
  people_used : Int
  scheduled_minutes : Int
  average_load : Int
  risk_score : Int
} derive(Debug, Eq)

///|
/// A concrete operational action generated from schedule evidence.
pub(all) struct OperationalAction {
  priority : Int
  category : String
  subject : String
  message : String
} derive(Debug, Eq)

///|
/// Full operational view; it remains useful even for a partial roster.
pub(all) struct OperationalReview {
  shifts : Array[ShiftOperation]
  days : Array[DayOperation]
  handovers : Array[Handover]
  actions : Array[OperationalAction]
  total_risk : Int
} derive(Debug, Eq)

///|
/// Count assignments attached to one shift.
fn operation_assignment_count(
  assignments : Array[Assignment],
  shift_id : ShiftId,
) -> Int {
  let mut count = 0
  for item in assignments {
    if item.shift_id == shift_id {
      count = count + 1
    }
  }
  count
}

///|
/// Count distinct people assigned inside a half-open time window.
fn distinct_people_in_window(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
  start : Int,
  end : Int,
) -> Int {
  let ids : Array[PersonId] = []
  for item in assignments {
    match find_shift(problem, item.shift_id) {
      Some(shift) =>
        if shift.time.start >= start && shift.time.start < end {
          let mut seen = false
          for id in ids {
            if id == item.person_id {
              seen = true
            }
          }
          if !seen {
            ids.push(item.person_id)
          }
        }
      None => ()
    }
  }
  ids.length()
}

///|
/// Determine whether a person is assigned to a shift.
fn is_assigned_to(
  assignments : Array[Assignment],
  person_id : PersonId,
  shift_id : ShiftId,
) -> Bool {
  for item in assignments {
    if item.person_id == person_id && item.shift_id == shift_id {
      return true
    }
  }
  false
}

///|
/// Count people who can serve as qualified standby for a shift.
fn standby_count(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
  shift : Shift,
) -> Int {
  let mut count = 0
  for person in problem.people {
    if !is_assigned_to(assignments, person.id, shift.id) &&
      is_available(person, shift) &&
      meets_requirements(person, shift) {
      count = count + 1
    }
  }
  count
}

///|
/// Count qualified and available people without depending on solver state.
fn qualified_count(problem : ScheduleProblem, shift : Shift) -> Int {
  let mut count = 0
  for person in problem.people {
    if is_available(person, shift) && meets_requirements(person, shift) {
      count = count + 1
    }
  }
  count
}

///|
/// Risk is intentionally transparent and bounded to 0..100.
fn shift_risk_score(
  required : Int,
  assigned : Int,
  qualified : Int,
  standby : Int,
  priority : Int,
) -> Int {
  let missing = if required > assigned { required - assigned } else { 0 }
  let shortage = if required > qualified { required - qualified } else { 0 }
  let mut score = missing * 35 + shortage * 20
  if assigned >= required && standby == 0 {
    score = score + 15
  } else if standby == 1 {
    score = score + 7
  }
  score = score + priority * missing * 3
  if score > 100 {
    100
  } else {
    score
  }
}

///|
/// Convert a numeric risk into a stable label for reports.
pub fn risk_level(score : Int) -> String {
  if score >= 70 {
    "critical"
  } else if score >= 40 {
    "high"
  } else if score >= 20 {
    "medium"
  } else {
    "low"
  }
}

///|
/// Analyze every shift, including uncovered ones.
pub fn analyze_shift_operations(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Array[ShiftOperation] {
  let values : Array[ShiftOperation] = []
  for shift in problem.shifts {
    let assigned = operation_assignment_count(assignments, shift.id)
    let qualified = qualified_count(problem, shift)
    let standby = standby_count(problem, assignments, shift)
    let score = shift_risk_score(
      shift.required_people,
      assigned,
      qualified,
      standby,
      shift.priority,
    )
    values.push({
      shift_id: shift.id,
      label: shift.label,
      group: shift.group,
      assigned,
      required: shift.required_people,
      qualified,
      standby,
      coverage_percent: if shift.required_people == 0 {
        100
      } else {
        assigned * 100 / shift.required_people
      },
      risk_score: score,
      risk_level: risk_level(score),
    })
  }
  values.sort_by((a, b) => {
    if a.risk_score == b.risk_score {
      a.shift_id.compare(b.shift_id)
    } else {
      b.risk_score - a.risk_score
    }
  })
  values
}

///|
/// Extract assignment pairs for a person and order them chronologically.
fn person_duties(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
  person_id : PersonId,
) -> Array[Shift] {
  let duties : Array[Shift] = []
  for item in assignments {
    if item.person_id == person_id {
      match find_shift(problem, item.shift_id) {
        Some(shift) => duties.push(shift)
        None => ()
      }
    }
  }
  duties.sort_by((a, b) => a.time.start - b.time.start)
  duties
}

///|
/// Analyze every adjacent duty transition.
pub fn analyze_handovers(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Array[Handover] {
  let values : Array[Handover] = []
  for person in problem.people {
    let duties = person_duties(problem, assignments, person.id)
    let mut index = 1
    while index < duties.length() {
      let previous = duties[index - 1]
      let next = duties[index]
      let gap = next.time.start - previous.time.end
      let same_group = previous.group == next.group
      let mut score = 0
      if gap < problem.minimum_rest_minutes {
        score = score + 60
      } else if gap < problem.minimum_rest_minutes * 2 {
        score = score + 20
      }
      if same_group {
        score = score + 5
      }
      if previous.time.end / 1440 != next.time.start / 1440 {
        score = score + 3
      }
      values.push({
        person_id: person.id,
        from_shift: previous.id,
        to_shift: next.id,
        gap_minutes: gap,
        same_group,
        risk_score: if score > 100 {
          100
        } else {
          score
        },
      })
      index = index + 1
    }
  }
  values.sort_by((a, b) => b.risk_score - a.risk_score)
  values
}

///|
/// Generate summaries only for days that contain at least one shift.
pub fn analyze_days(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Array[DayOperation] {
  let days : Array[DayOperation] = []
  let mut day = 0
  let mut maximum_day = 0
  for shift in problem.shifts {
    let value = shift.time.start / 1440
    if value > maximum_day {
      maximum_day = value
    }
  }
  while day <= maximum_day {
    let start = day * 1440
    let end = start + 1440
    let mut shift_count = 0
    let mut required = 0
    let mut assigned = 0
    let mut minutes = 0
    let mut risk = 0
    for shift in problem.shifts {
      if shift.time.start >= start && shift.time.start < end {
        shift_count = shift_count + 1
        required = required + shift.required_people
        let actual = operation_assignment_count(assignments, shift.id)
        assigned = assigned + actual
        minutes = minutes + actual * shift.time.duration()
        risk = risk +
          shift_risk_score(
            shift.required_people,
            actual,
            qualified_count(problem, shift),
            standby_count(problem, assignments, shift),
            shift.priority,
          )
      }
    }
    if shift_count > 0 {
      let people = distinct_people_in_window(problem, assignments, start, end)
      days.push({
        day,
        shift_count,
        required_slots: required,
        assigned_slots: assigned,
        uncovered_slots: required - assigned,
        people_used: people,
        scheduled_minutes: minutes,
        average_load: if people == 0 {
          0
        } else {
          minutes / people
        },
        risk_score: if risk > 100 {
          100
        } else {
          risk
        },
      })
    }
    day = day + 1
  }
  days
}

///|
/// Turn evidence into a short, deterministic action queue.
pub fn build_operational_actions(
  shifts : Array[ShiftOperation],
  handovers : Array[Handover],
) -> Array[OperationalAction] {
  let actions : Array[OperationalAction] = []
  for item in shifts {
    if item.assigned < item.required {
      actions.push({
        priority: 100 - item.risk_score,
        category: "coverage",
        subject: item.shift_id,
        message: "Fill \{item.required - item.assigned} uncovered slot(s); \{item.qualified} qualified people are known.",
      })
    } else if item.standby == 0 {
      actions.push({
        priority: 70,
        category: "resilience",
        subject: item.shift_id,
        message: "Nominate a qualified standby because the shift has no replacement margin.",
      })
    }
  }
  for item in handovers {
    if item.risk_score >= 40 {
      actions.push({
        priority: 20,
        category: "rest",
        subject: item.person_id,
        message: "Review the \{item.gap_minutes}-minute gap between \{item.from_shift} and \{item.to_shift}.",
      })
    }
  }
  actions.sort_by((a, b) => {
    if a.priority == b.priority {
      a.subject.compare(b.subject)
    } else {
      a.priority - b.priority
    }
  })
  actions
}

///|
/// Build the full operational review in one call.
pub fn review_operations(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> OperationalReview {
  let shifts = analyze_shift_operations(problem, assignments)
  let handovers = analyze_handovers(problem, assignments)
  let days = analyze_days(problem, assignments)
  let actions = build_operational_actions(shifts, handovers)
  let mut total = 0
  for item in shifts {
    total = total + item.risk_score
  }
  for item in handovers {
    total = total + item.risk_score
  }
  { shifts, days, handovers, actions, total_risk: total }
}

///|
/// Render a compact Markdown operations section.
pub fn render_operations_markdown(review : OperationalReview) -> String {
  let mut text = "# Operational review\n\n"
  text = text + "- Aggregate risk: **\{review.total_risk}**\n"
  text = text + "- Recommended actions: **\{review.actions.length()}**\n\n"
  text = text + "## Shift resilience\n\n"
  text = text +
    "| Shift | Coverage | Standby | Risk | Level |\n|---|---:|---:|---:|---|\n"
  for item in review.shifts {
    text = text +
      "| \{item.label} | \{item.assigned}/\{item.required} | \{item.standby} | \{item.risk_score} | \{item.risk_level} |\n"
  }
  if review.actions.length() > 0 {
    text = text + "\n## Actions\n\n"
    for action in review.actions {
      text = text +
        "- **\{action.category}** `\{action.subject}`: \{action.message}\n"
    }
  }
  text
}
