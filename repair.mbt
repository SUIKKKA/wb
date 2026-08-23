///|
pub(all) struct RepairRequest {
  unavailable_people : Array[PersonId]
  removed_shifts : Array[ShiftId]
  unlocked_shifts : Array[ShiftId]
  preserve_unaffected : Bool
} derive(Debug, Eq)

///|
pub fn RepairRequest::empty() -> RepairRequest {
  {
    unavailable_people: [],
    removed_shifts: [],
    unlocked_shifts: [],
    preserve_unaffected: true,
  }
}

///|
fn contains_person(ids : Array[PersonId], id : PersonId) -> Bool {
  for item in ids {
    if item == id {
      return true
    }
  }
  false
}

///|
fn contains_shift(ids : Array[ShiftId], id : ShiftId) -> Bool {
  for item in ids {
    if item == id {
      return true
    }
  }
  false
}

///|
pub fn apply_repair_request(
  problem : ScheduleProblem,
  request : RepairRequest,
) -> ScheduleProblem {
  let people : Array[Person] = []
  for person in problem.people {
    if !contains_person(request.unavailable_people, person.id) {
      people.push(person)
    }
  }
  let shifts : Array[Shift] = []
  for shift in problem.shifts {
    if !contains_shift(request.removed_shifts, shift.id) {
      shifts.push(shift)
    }
  }
  let existing : Array[Assignment] = []
  for assignment in problem.existing {
    if !contains_person(request.unavailable_people, assignment.person_id) &&
      !contains_shift(request.removed_shifts, assignment.shift_id) {
      let should_lock = request.preserve_unaffected &&
        !contains_shift(request.unlocked_shifts, assignment.shift_id)
      existing.push({ ..assignment, locked: should_lock })
    }
  }
  { ..problem, people, shifts, existing }
}

///|
pub fn repair(
  problem : ScheduleProblem,
  request : RepairRequest,
  options? : SearchOptions = SearchOptions::default(),
) -> ScheduleResult {
  let adjusted = apply_repair_request(problem, request)
  solve(adjusted, options~)
}

///|
pub fn changed_assignments(
  before : Array[Assignment],
  after : Array[Assignment],
) -> Array[Assignment] {
  let changed : Array[Assignment] = []
  for item in after {
    let mut same = false
    for old in before {
      if same_assignment(item, old) {
        same = true
      }
    }
    if !same {
      changed.push(item)
    }
  }
  changed
}

///|
pub fn removed_assignments(
  before : Array[Assignment],
  after : Array[Assignment],
) -> Array[Assignment] {
  let removed : Array[Assignment] = []
  for item in before {
    let mut same = false
    for fresh in after {
      if same_assignment(item, fresh) {
        same = true
      }
    }
    if !same {
      removed.push(item)
    }
  }
  removed
}
