///|
pub(all) struct SlotKey {
  shift_id : ShiftId
  slot : Int
} derive(Debug, Eq)

///|
pub(all) struct CandidateDomain {
  key : SlotKey
  people : Array[PersonId]
  rejected : Array[Diagnostic]
} derive(Debug, Eq)

///|
pub fn build_domain(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
  shift : Shift,
  slot : Int,
) -> CandidateDomain {
  let people : Array[PersonId] = []
  let rejected : Array[Diagnostic] = []
  for person in problem.people {
    match can_assign(problem, assignments, shift, slot, person) {
      None => people.push(person.id)
      Some(reason) => rejected.push(reason)
    }
  }
  { key: { shift_id: shift.id, slot }, people, rejected }
}

///|
pub fn build_domains(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Array[CandidateDomain] {
  let domains : Array[CandidateDomain] = []
  for shift in problem.shifts {
    for slot = 0; slot < shift.required_people; slot = slot + 1 {
      let mut occupied = false
      for assignment in assignments {
        if assignment.shift_id == shift.id && assignment.slot == slot {
          occupied = true
        }
      }
      if !occupied {
        domains.push(build_domain(problem, assignments, shift, slot))
      }
    }
  }
  domains
}

///|
pub fn smallest_domain_index(domains : Array[CandidateDomain]) -> Int {
  if domains.length() == 0 {
    return -1
  }
  let mut best = 0
  for i = 1; i < domains.length(); i = i + 1 {
    if domains[i].people.length() < domains[best].people.length() {
      best = i
    }
  }
  best
}

///|
pub fn domain_contains(domain : CandidateDomain, person_id : PersonId) -> Bool {
  for id in domain.people {
    if id == person_id {
      return true
    }
  }
  false
}
