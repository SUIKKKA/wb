///|
fn status_text(status : SolveStatus) -> String {
  match status {
    Solved => "solved"
    Partial => "partial"
    Infeasible => "infeasible"
    BudgetExceeded => "budget-exceeded"
  }
}

///|
fn diagnostic_code_text(code : DiagnosticCode) -> String {
  match code {
    InvalidTimeSpan => "invalid-time-span"
    DuplicatePerson => "duplicate-person"
    DuplicateShift => "duplicate-shift"
    UnknownPerson => "unknown-person"
    UnknownShift => "unknown-shift"
    InvalidSlot => "invalid-slot"
    DuplicateAssignment => "duplicate-assignment"
    OverlappingAssignment => "overlapping-assignment"
    OutsideAvailability => "outside-availability"
    SkillMismatch => "skill-mismatch"
    MaximumMinutesExceeded => "maximum-minutes-exceeded"
    InsufficientRest => "insufficient-rest"
    ConsecutiveLimitExceeded => "consecutive-limit-exceeded"
    UncoveredSlot => "uncovered-slot"
    EmptyCandidateDomain => "empty-candidate-domain"
    SearchBudgetExceeded => "search-budget-exceeded"
    InvalidConfiguration => "invalid-configuration"
  }
}

///|
pub fn render_markdown(
  problem : ScheduleProblem,
  result : ScheduleResult,
) -> String {
  let mut text = "# ShiftWeave schedule report\n\n"
  text = text + "- Status: **\{status_text(result.status)}**\n"
  text = text +
    "- Covered slots: \{coverage_summary(problem, result.assignments).covered_slots}/\{coverage_summary(problem, result.assignments).total_slots}\n"
  text = text + "- Objective: \{result.metrics.objective}\n"
  text = text + "- Preference score: \{result.metrics.preference_score}\n"
  text = text + "- Fairness penalty: \{result.metrics.fairness_penalty}\n"
  text = text + "- Disruptions: \{result.metrics.disruption_count}\n\n"
  text = text +
    "## Assignments\n\n| Shift | Time | Slot | Person | Locked |\n|---|---|---:|---|---|\n"
  for shift in problem.shifts {
    for assignment in result.assignments {
      if assignment.shift_id == shift.id {
        text = text +
          "| \{shift.label} | \{minutes_to_clock(shift.time.start)}–\{minutes_to_clock(shift.time.end)} | \{assignment.slot + 1} | \{assignment.person_id} | \{assignment.locked} |\n"
      }
    }
  }
  text = text +
    "\n## Workloads\n\n| Person | Minutes | Target | Difference | Assignments | Preference |\n|---|---:|---:|---:|---:|---:|\n"
  for load in all_workloads(problem, result.assignments) {
    text = text +
      "| \{load.person_id} | \{load.assigned_minutes} | \{load.target_minutes} | \{load.difference} | \{load.assignment_count} | \{load.preference_score} |\n"
  }
  if result.diagnostics.length() > 0 {
    text = text + "\n## Diagnostics\n\n"
    for item in result.diagnostics {
      text = text + "- `\{diagnostic_code_text(item.code)}`: \{item.message}\n"
    }
  }
  text
}

///|
pub fn render_csv(problem : ScheduleProblem, result : ScheduleResult) -> String {
  let mut text = "shift_id,shift_label,start,end,slot,person_id,locked\n"
  for assignment in result.assignments {
    match find_shift(problem, assignment.shift_id) {
      Some(shift) =>
        text = text +
          "\{shift.id},\{shift.label},\{shift.time.start},\{shift.time.end},\{assignment.slot},\{assignment.person_id},\{assignment.locked}\n"
      None => ()
    }
  }
  text
}

///|
pub fn render_json(
  problem : ScheduleProblem,
  result : ScheduleResult,
) -> String {
  let mut text = "{\"status\":\"\{status_text(result.status)}\",\"objective\":\{result.metrics.objective},\"assignments\":["
  let mut first = true
  for assignment in result.assignments {
    if !first {
      text = text + ","
    }
    first = false
    text = text +
      "{\"shift_id\":\"\{assignment.shift_id}\",\"slot\":\{assignment.slot},\"person_id\":\"\{assignment.person_id}\",\"locked\":\{assignment.locked}}"
  }
  text + "]}"
}
