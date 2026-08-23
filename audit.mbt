///|
pub(all) struct AuditSummary {
  valid_problem : Bool
  complete : Bool
  hard_errors : Int
  warnings : Int
  coverage_percent : Int
  deterministic_fingerprint : String
  notes : Array[String]
} derive(Debug, Eq)

///|
fn mix_hash(value : Int, next : Int) -> Int {
  ((value * 16777619) ^ next) & 0x7fffffff
}

///|
pub fn schedule_fingerprint(assignments : Array[Assignment]) -> String {
  let values = assignments.copy()
  values.sort_by((a, b) => {
    let by_shift = a.shift_id.compare(b.shift_id)
    if by_shift != 0 {
      by_shift
    } else if a.slot != b.slot {
      a.slot - b.slot
    } else {
      a.person_id.compare(b.person_id)
    }
  })
  let mut hash = 216613626
  for item in values {
    for char in item.shift_id {
      hash = mix_hash(hash, char.to_int())
    }
    hash = mix_hash(hash, item.slot)
    for char in item.person_id {
      hash = mix_hash(hash, char.to_int())
    }
    hash = mix_hash(hash, if item.locked { 1 } else { 0 })
  }
  "sw-\{hash}-\{values.length()}"
}

///|
pub fn audit_schedule(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> AuditSummary {
  let problem_diagnostics = validate_problem(problem)
  let assignment_diagnostics = validate_assignments(problem, assignments)
  let findings = run_all_policies(problem, assignments)
  let coverage = coverage_summary(problem, assignments)
  let assignment_error = if has_errors(assignment_diagnostics) { 1 } else { 0 }
  let notes : Array[String] = []
  if problem_diagnostics.length() > 0 {
    notes.push("Problem definition contains validation diagnostics.")
  }
  if coverage.uncovered_slots > 0 {
    notes.push("Schedule is incomplete.")
  }
  if maximum_workload_gap(problem, assignments) > 480 {
    notes.push("Workload distribution has a large gap.")
  }
  if preference_score(problem, assignments) < 0 {
    notes.push("Net preference score is negative.")
  }
  {
    valid_problem: !has_errors(problem_diagnostics),
    complete: coverage.uncovered_slots == 0,
    hard_errors: count_policy_errors(findings) + assignment_error,
    warnings: count_policy_warnings(findings),
    coverage_percent: coverage.coverage_percent,
    deterministic_fingerprint: schedule_fingerprint(assignments),
    notes,
  }
}

///|
pub fn compare_schedules(
  problem : ScheduleProblem,
  left : Array[Assignment],
  right : Array[Assignment],
) -> String {
  let lm = evaluate_schedule(problem, left)
  let rm = evaluate_schedule(problem, right)
  let mut text = "# Schedule comparison\n\n"
  text = text + "| Metric | Left | Right | Delta |\n|---|---:|---:|---:|\n"
  text = text +
    "| Objective | \{lm.objective} | \{rm.objective} | \{rm.objective - lm.objective} |\n"
  text = text +
    "| Uncovered | \{lm.uncovered_slots} | \{rm.uncovered_slots} | \{rm.uncovered_slots - lm.uncovered_slots} |\n"
  text = text +
    "| Preference | \{lm.preference_score} | \{rm.preference_score} | \{rm.preference_score - lm.preference_score} |\n"
  text = text +
    "| Fairness penalty | \{lm.fairness_penalty} | \{rm.fairness_penalty} | \{rm.fairness_penalty - lm.fairness_penalty} |\n"
  text = text +
    "| Disruptions | \{lm.disruption_count} | \{rm.disruption_count} | \{rm.disruption_count - lm.disruption_count} |\n"
  text
}
