///|
fn ordered_candidates(
  problem : ScheduleProblem,
  current : Array[Assignment],
  domain : CandidateDomain,
) -> Array[PersonId] {
  let ids = domain.people.copy()
  ids.sort_by((a, b) => {
    match
      (
        find_person(problem, a),
        find_person(problem, b),
        find_shift(problem, domain.key.shift_id),
      ) {
      (Some(pa), Some(pb), Some(shift)) =>
        incremental_cost(problem, current, shift, pa) -
        incremental_cost(problem, current, shift, pb)
      _ => 0
    }
  })
  ids
}

///|
fn search(
  problem : ScheduleProblem,
  current : Array[Assignment],
  remaining_nodes : Int,
) -> Array[Assignment]? {
  if remaining_nodes <= 0 {
    return None
  }
  let propagated = propagate(problem, current)
  if !propagated.feasible {
    return None
  }
  let domains = build_domains(problem, propagated.assignments)
  if domains.length() == 0 {
    return Some(propagated.assignments)
  }
  let index = smallest_domain_index(domains)
  if index < 0 || domains[index].people.length() == 0 {
    return None
  }
  let domain = domains[index]
  for person_id in ordered_candidates(problem, propagated.assignments, domain) {
    let next = propagated.assignments.copy()
    next.push({
      shift_id: domain.key.shift_id,
      slot: domain.key.slot,
      person_id,
      locked: false,
    })
    match search(problem, next, remaining_nodes - 1) {
      Some(solution) => return Some(solution)
      None => ()
    }
  }
  None
}

///|
pub fn solve(
  problem : ScheduleProblem,
  options? : SearchOptions = SearchOptions::default(),
) -> ScheduleResult {
  let initial_diagnostics = validate_problem(problem)
  if has_errors(initial_diagnostics) {
    return {
      status: Infeasible,
      assignments: [],
      diagnostics: initial_diagnostics,
      metrics: ScheduleMetrics::empty(),
      explored_nodes: 0,
      propagated_values: 0,
    }
  }
  let locked : Array[Assignment] = []
  for assignment in problem.existing {
    if assignment.locked {
      locked.push(assignment)
    }
  }
  match search(problem, locked, options.maximum_nodes) {
    Some(assignments) => {
      let diagnostics = validate_assignments(problem, assignments)
      {
        status: if has_errors(diagnostics) {
          Partial
        } else {
          Solved
        },
        assignments,
        diagnostics,
        metrics: evaluate_schedule(problem, assignments),
        explored_nodes: options.maximum_nodes,
        propagated_values: 0,
      }
    }
    None => {
      let propagation = propagate(problem, locked)
      let diagnostics = propagation.diagnostics
      if diagnostics.length() == 0 {
        diagnostics.push({
          code: SearchBudgetExceeded,
          message: "search ended without a feasible schedule",
          person_id: None,
          shift_id: None,
          slot: None,
          severity: 2,
        })
      }
      {
        status: Infeasible,
        assignments: locked,
        diagnostics,
        metrics: evaluate_schedule(problem, locked),
        explored_nodes: options.maximum_nodes,
        propagated_values: propagation.forced_count,
      }
    }
  }
}
