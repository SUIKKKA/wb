///|
pub fn find_person(problem : ScheduleProblem, id : PersonId) -> Person? {
  for person in problem.people {
    if person.id == id {
      return Some(person)
    }
  }
  None
}

///|
pub fn find_shift(problem : ScheduleProblem, id : ShiftId) -> Shift? {
  for shift in problem.shifts {
    if shift.id == id {
      return Some(shift)
    }
  }
  None
}

///|
pub fn skill_level(person : Person, name : String) -> Int {
  for skill in person.skills {
    if skill.name == name {
      return skill.level
    }
  }
  0
}

///|
pub fn meets_requirements(person : Person, shift : Shift) -> Bool {
  for requirement in shift.requirements {
    if skill_level(person, requirement.skill) < requirement.minimum_level {
      return false
    }
  }
  true
}

///|
pub fn is_available(person : Person, shift : Shift) -> Bool {
  for span in person.availability {
    if span.contains(shift.time) {
      return true
    }
  }
  false
}

///|
pub fn preference_for(person : Person, shift_id : ShiftId) -> Int {
  for preference in person.preferences {
    if preference.shift_id == shift_id {
      return preference.weight
    }
  }
  0
}

///|
pub fn assignments_for_person(
  assignments : Array[Assignment],
  person_id : PersonId,
) -> Array[Assignment] {
  let result : Array[Assignment] = []
  for assignment in assignments {
    if assignment.person_id == person_id {
      result.push(assignment)
    }
  }
  result
}

///|
pub fn assignments_for_shift(
  assignments : Array[Assignment],
  shift_id : ShiftId,
) -> Array[Assignment] {
  let result : Array[Assignment] = []
  for assignment in assignments {
    if assignment.shift_id == shift_id {
      result.push(assignment)
    }
  }
  result
}

///|
pub fn same_assignment(a : Assignment, b : Assignment) -> Bool {
  a.shift_id == b.shift_id && a.slot == b.slot && a.person_id == b.person_id
}
