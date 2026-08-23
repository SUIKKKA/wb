///|
fn diagnostic(
  code : DiagnosticCode,
  message : String,
  person_id? : PersonId = "",
  shift_id? : ShiftId = "",
  slot? : Int = -1,
  severity? : Int = 2,
) -> Diagnostic {
  {
    code,
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
    slot: if slot < 0 {
      None
    } else {
      Some(slot)
    },
    severity,
  }
}

///|
pub fn validate_problem(problem : ScheduleProblem) -> Array[Diagnostic] {
  let out : Array[Diagnostic] = []
  if problem.minimum_rest_minutes < 0 {
    out.push(
      diagnostic(InvalidConfiguration, "minimum rest must not be negative"),
    )
  }
  for i = 0; i < problem.people.length(); i = i + 1 {
    let person = problem.people[i]
    if person.id == "" || person.name == "" {
      out.push(
        diagnostic(
          InvalidConfiguration,
          "person id and name are required",
          person_id=person.id,
        ),
      )
    }
    if person.target_minutes < 0 ||
      person.maximum_minutes < person.target_minutes {
      out.push(
        diagnostic(
          InvalidConfiguration,
          "person minute limits are inconsistent",
          person_id=person.id,
        ),
      )
    }
    for span in person.availability {
      if not(span.is_valid()) {
        out.push(
          diagnostic(
            InvalidTimeSpan,
            "availability span is invalid",
            person_id=person.id,
          ),
        )
      }
    }
    for j = i + 1; j < problem.people.length(); j = j + 1 {
      if problem.people[j].id == person.id {
        out.push(
          diagnostic(
            DuplicatePerson,
            "duplicate person id \{person.id}",
            person_id=person.id,
          ),
        )
      }
    }
  }
  for i = 0; i < problem.shifts.length(); i = i + 1 {
    let shift = problem.shifts[i]
    if not(shift.time.is_valid()) {
      out.push(
        diagnostic(InvalidTimeSpan, "shift span is invalid", shift_id=shift.id),
      )
    }
    if shift.required_people <= 0 {
      out.push(
        diagnostic(
          InvalidConfiguration,
          "shift requires at least one person",
          shift_id=shift.id,
        ),
      )
    }
    for requirement in shift.requirements {
      if requirement.skill == "" || requirement.minimum_level <= 0 {
        out.push(
          diagnostic(
            InvalidConfiguration,
            "skill requirement is invalid",
            shift_id=shift.id,
          ),
        )
      }
    }
    for j = i + 1; j < problem.shifts.length(); j = j + 1 {
      if problem.shifts[j].id == shift.id {
        out.push(
          diagnostic(
            DuplicateShift,
            "duplicate shift id \{shift.id}",
            shift_id=shift.id,
          ),
        )
      }
    }
  }
  for assignment in problem.existing {
    match find_person(problem, assignment.person_id) {
      None =>
        out.push(
          diagnostic(
            UnknownPerson,
            "assignment references unknown person",
            person_id=assignment.person_id,
            shift_id=assignment.shift_id,
            slot=assignment.slot,
          ),
        )
      Some(_) => ()
    }
    match find_shift(problem, assignment.shift_id) {
      None =>
        out.push(
          diagnostic(
            UnknownShift,
            "assignment references unknown shift",
            person_id=assignment.person_id,
            shift_id=assignment.shift_id,
            slot=assignment.slot,
          ),
        )
      Some(shift) =>
        if assignment.slot < 0 || assignment.slot >= shift.required_people {
          out.push(
            diagnostic(
              InvalidSlot,
              "assignment slot is outside shift capacity",
              person_id=assignment.person_id,
              shift_id=assignment.shift_id,
              slot=assignment.slot,
            ),
          )
        }
    }
  }
  out
}

///|
pub fn assigned_minutes(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
  person_id : PersonId,
) -> Int {
  let mut total = 0
  for assignment in assignments {
    if assignment.person_id == person_id {
      match find_shift(problem, assignment.shift_id) {
        Some(shift) => total = total + shift.time.duration()
        None => ()
      }
    }
  }
  total
}

///|
pub fn can_assign(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
  shift : Shift,
  slot : Int,
  person : Person,
) -> Diagnostic? {
  if slot < 0 || slot >= shift.required_people {
    return Some(
      diagnostic(
        InvalidSlot,
        "slot is outside shift capacity",
        person_id=person.id,
        shift_id=shift.id,
        slot~,
      ),
    )
  }
  if not(is_available(person, shift)) {
    return Some(
      diagnostic(
        OutsideAvailability,
        "person is unavailable for the complete shift",
        person_id=person.id,
        shift_id=shift.id,
        slot~,
      ),
    )
  }
  if not(meets_requirements(person, shift)) {
    return Some(
      diagnostic(
        SkillMismatch,
        "person does not meet all skill requirements",
        person_id=person.id,
        shift_id=shift.id,
        slot~,
      ),
    )
  }
  for existing in assignments {
    if existing.shift_id == shift.id && existing.slot == slot {
      return Some(
        diagnostic(
          DuplicateAssignment,
          "slot is already assigned",
          person_id=person.id,
          shift_id=shift.id,
          slot~,
        ),
      )
    }
    if existing.person_id == person.id {
      match find_shift(problem, existing.shift_id) {
        Some(other) => {
          if other.time.overlaps(shift.time) {
            return Some(
              diagnostic(
                OverlappingAssignment,
                "person already has an overlapping shift",
                person_id=person.id,
                shift_id=shift.id,
                slot~,
              ),
            )
          }
          let gap = other.time.gap_to(shift.time)
          if gap >= 0 && gap < problem.minimum_rest_minutes {
            return Some(
              diagnostic(
                InsufficientRest,
                "assignment would violate minimum rest",
                person_id=person.id,
                shift_id=shift.id,
                slot~,
              ),
            )
          }
        }
        None => ()
      }
    }
  }
  let after = assigned_minutes(problem, assignments, person.id) +
    shift.time.duration()
  if after > person.maximum_minutes {
    return Some(
      diagnostic(
        MaximumMinutesExceeded,
        "assignment exceeds maximum minutes",
        person_id=person.id,
        shift_id=shift.id,
        slot~,
      ),
    )
  }
  None
}

///|
pub fn validate_assignments(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
  require_complete? : Bool = true,
) -> Array[Diagnostic] {
  let out = validate_problem(problem)
  let accepted : Array[Assignment] = []
  for assignment in assignments {
    match
      (
        find_shift(problem, assignment.shift_id),
        find_person(problem, assignment.person_id),
      ) {
      (Some(shift), Some(person)) =>
        match can_assign(problem, accepted, shift, assignment.slot, person) {
          Some(problem) => out.push(problem)
          None => accepted.push(assignment)
        }
      (None, _) =>
        out.push(
          diagnostic(
            UnknownShift,
            "unknown shift",
            shift_id=assignment.shift_id,
          ),
        )
      (_, None) =>
        out.push(
          diagnostic(
            UnknownPerson,
            "unknown person",
            person_id=assignment.person_id,
          ),
        )
    }
  }
  if require_complete {
    for shift in problem.shifts {
      for slot = 0; slot < shift.required_people; slot = slot + 1 {
        let mut found = false
        for assignment in assignments {
          if assignment.shift_id == shift.id && assignment.slot == slot {
            found = true
          }
        }
        if not(found) {
          out.push(
            diagnostic(
              UncoveredSlot,
              "required slot is uncovered",
              shift_id=shift.id,
              slot~,
            ),
          )
        }
      }
    }
  }
  out
}

///|
pub fn has_errors(diagnostics : Array[Diagnostic]) -> Bool {
  for item in diagnostics {
    if item.severity >= 2 {
      return true
    }
  }
  false
}
