///|
pub(all) struct PropagationResult {
  assignments : Array[Assignment]
  diagnostics : Array[Diagnostic]
  forced_count : Int
  feasible : Bool
} derive(Show, Eq)

///|
pub fn propagate(
  problem : ScheduleProblem,
  initial : Array[Assignment],
) -> PropagationResult {
  let current = initial.copy()
  let reasons : Array[Diagnostic] = []
  let mut forced = 0
  let mut changed = true
  let mut feasible = true
  while changed && feasible {
    changed = false
    let domains = build_domains(problem, current)
    for domain in domains {
      if domain.people.length() == 0 {
        feasible = false
        reasons.push({
          code: EmptyCandidateDomain,
          message: "no eligible person remains for slot",
          person_id: None,
          shift_id: Some(domain.key.shift_id),
          slot: Some(domain.key.slot),
          severity: 2,
        })
      } else if domain.people.length() == 1 {
        let assignment : Assignment = {
          shift_id: domain.key.shift_id,
          slot: domain.key.slot,
          person_id: domain.people[0],
          locked: false,
        }
        let mut exists = false
        for old in current {
          if old.shift_id == assignment.shift_id && old.slot == assignment.slot {
            exists = true
          }
        }
        if !exists {
          current.push(assignment)
          forced = forced + 1
          changed = true
          break
        }
      }
    }
  }
  { assignments: current, diagnostics: reasons, forced_count: forced, feasible }
}
