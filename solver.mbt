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
priv struct SearchAttempt {
  solution : Array[Assignment]?
  remaining_nodes : Int
  explored_nodes : Int
  propagated_values : Int
  budget_exhausted : Bool
}

///|
/// Search with one global node budget threaded through every branch.
fn search(
  problem : ScheduleProblem,
  current : Array[Assignment],
  remaining_nodes : Int,
) -> SearchAttempt {
  if remaining_nodes <= 0 {
    return {
      solution: None,
      remaining_nodes: 0,
      explored_nodes: 0,
      propagated_values: 0,
      budget_exhausted: true,
    }
  }
  let mut available_nodes = remaining_nodes - 1
  let mut explored = 1
  let propagated = propagate(problem, current)
  if !propagated.feasible {
    return {
      solution: None,
      remaining_nodes: available_nodes,
      explored_nodes: explored,
      propagated_values: propagated.forced_count,
      budget_exhausted: false,
    }
  }
  let domains = build_domains(problem, propagated.assignments)
  if domains.length() == 0 {
    return {
      solution: Some(propagated.assignments),
      remaining_nodes: available_nodes,
      explored_nodes: explored,
      propagated_values: propagated.forced_count,
      budget_exhausted: false,
    }
  }
  let index = smallest_domain_index(domains)
  if index < 0 || domains[index].people.length() == 0 {
    return {
      solution: None,
      remaining_nodes: available_nodes,
      explored_nodes: explored,
      propagated_values: propagated.forced_count,
      budget_exhausted: false,
    }
  }
  let domain = domains[index]
  let mut propagated_values = propagated.forced_count
  for person_id in ordered_candidates(problem, propagated.assignments, domain) {
    if available_nodes <= 0 {
      return {
        solution: None,
        remaining_nodes: 0,
        explored_nodes: explored,
        propagated_values,
        budget_exhausted: true,
      }
    }
    let next = propagated.assignments.copy()
    next.push({
      shift_id: domain.key.shift_id,
      slot: domain.key.slot,
      person_id,
      locked: false,
    })
    let attempt = search(problem, next, available_nodes)
    available_nodes = attempt.remaining_nodes
    explored = explored + attempt.explored_nodes
    propagated_values = propagated_values + attempt.propagated_values
    match attempt.solution {
      Some(solution) =>
        return {
          solution: Some(solution),
          remaining_nodes: available_nodes,
          explored_nodes: explored,
          propagated_values,
          budget_exhausted: false,
        }
      None =>
        if attempt.budget_exhausted {
          return {
            solution: None,
            remaining_nodes: available_nodes,
            explored_nodes: explored,
            propagated_values,
            budget_exhausted: true,
          }
        }
    }
  }
  {
    solution: None,
    remaining_nodes: available_nodes,
    explored_nodes: explored,
    propagated_values,
    budget_exhausted: false,
  }
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
  let attempt = search(problem, locked, options.maximum_nodes)
  match attempt.solution {
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
        explored_nodes: attempt.explored_nodes,
        propagated_values: attempt.propagated_values,
      }
    }
    None => {
      let propagation = propagate(problem, locked)
      let diagnostics = propagation.diagnostics
      if attempt.budget_exhausted {
        diagnostics.push({
          code: SearchBudgetExceeded,
          message: "global search node budget was exhausted",
          person_id: None,
          shift_id: None,
          slot: None,
          severity: 2,
        })
      }
      {
        status: if attempt.budget_exhausted {
          BudgetExceeded
        } else {
          Infeasible
        },
        assignments: locked,
        diagnostics,
        metrics: evaluate_schedule(problem, locked),
        explored_nodes: attempt.explored_nodes,
        propagated_values: attempt.propagated_values,
      }
    }
  }
}
