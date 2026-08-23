///|
pub(all) struct CandidateExplanation {
  person_id : PersonId
  eligible : Bool
  incremental_cost : Int
  reasons : Array[String]
} derive(Debug, Eq)

///|
pub(all) struct SlotExplanation {
  shift_id : ShiftId
  slot : Int
  candidates : Array[CandidateExplanation]
  eligible_count : Int
  rejected_count : Int
  forced : Bool
} derive(Debug, Eq)

///|
fn diagnostic_reason(item : Diagnostic) -> String {
  match item.code {
    InvalidSlot => "slot is outside shift capacity"
    OutsideAvailability => "person is not available for the whole shift"
    SkillMismatch => "person does not meet the shift skill requirements"
    DuplicateAssignment => "the slot already has an assignment"
    OverlappingAssignment => "person has an overlapping assignment"
    InsufficientRest => "person would receive insufficient rest"
    MaximumMinutesExceeded => "person would exceed maximum minutes"
    UnknownPerson => "person is unknown"
    UnknownShift => "shift is unknown"
    _ => item.message
  }
}

///|
pub fn explain_candidate(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
  shift : Shift,
  slot : Int,
  person : Person,
) -> CandidateExplanation {
  match can_assign(problem, assignments, shift, slot, person) {
    None =>
      {
        person_id: person.id,
        eligible: true,
        incremental_cost: incremental_cost(problem, assignments, shift, person),
        reasons: ["eligible"],
      }
    Some(reason) =>
      {
        person_id: person.id,
        eligible: false,
        incremental_cost: 1000000,
        reasons: [diagnostic_reason(reason)],
      }
  }
}

///|
pub fn explain_slot(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
  shift : Shift,
  slot : Int,
) -> SlotExplanation {
  let candidates : Array[CandidateExplanation] = []
  let mut eligible = 0
  let mut rejected = 0
  for person in problem.people {
    let detail = explain_candidate(problem, assignments, shift, slot, person)
    candidates.push(detail)
    if detail.eligible {
      eligible = eligible + 1
    } else {
      rejected = rejected + 1
    }
  }
  candidates.sort_by((a, b) => {
    if a.eligible && !b.eligible {
      -1
    } else if !a.eligible && b.eligible {
      1
    } else {
      a.incremental_cost - b.incremental_cost
    }
  })
  {
    shift_id: shift.id,
    slot,
    candidates,
    eligible_count: eligible,
    rejected_count: rejected,
    forced: eligible == 1,
  }
}

///|
pub fn explain_problem(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Array[SlotExplanation] {
  let output : Array[SlotExplanation] = []
  for shift in problem.shifts {
    for slot = 0; slot < shift.required_people; slot = slot + 1 {
      let mut occupied = false
      for assignment in assignments {
        if assignment.shift_id == shift.id && assignment.slot == slot {
          occupied = true
        }
      }
      if !occupied {
        output.push(explain_slot(problem, assignments, shift, slot))
      }
    }
  }
  output
}

///|
pub fn most_constrained_slot(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> SlotExplanation? {
  let explanations = explain_problem(problem, assignments)
  if explanations.length() == 0 {
    return None
  }
  let mut best = 0
  for i = 1; i < explanations.length(); i = i + 1 {
    if explanations[i].eligible_count < explanations[best].eligible_count {
      best = i
    }
  }
  Some(explanations[best])
}

///|
pub fn forced_slots(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Array[SlotExplanation] {
  let values : Array[SlotExplanation] = []
  for item in explain_problem(problem, assignments) {
    if item.forced {
      values.push(item)
    }
  }
  values
}

///|
pub fn impossible_slots(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Array[SlotExplanation] {
  let values : Array[SlotExplanation] = []
  for item in explain_problem(problem, assignments) {
    if item.eligible_count == 0 {
      values.push(item)
    }
  }
  values
}

///|
pub fn render_slot_explanation(
  problem : ScheduleProblem,
  explanation : SlotExplanation,
) -> String {
  let mut title = explanation.shift_id
  match find_shift(problem, explanation.shift_id) {
    Some(shift) => title = shift.label
    None => ()
  }
  let mut text = "## \{title} / slot \{explanation.slot + 1}\n\n"
  text = text +
    "Eligible candidates: \{explanation.eligible_count}; rejected: \{explanation.rejected_count}.\n\n"
  for candidate in explanation.candidates {
    let marker = if candidate.eligible { "eligible" } else { "rejected" }
    text = text +
      "- **\{candidate.person_id}** — \{marker}, cost \{candidate.incremental_cost}: "
    let mut first = true
    for reason in candidate.reasons {
      if !first {
        text = text + "; "
      }
      first = false
      text = text + reason
    }
    text = text + "\n"
  }
  text
}

///|
pub fn render_problem_explanation(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> String {
  let mut text = "# ShiftWeave decision explanation\n\n"
  let explanations = explain_problem(problem, assignments)
  text = text + "Open slots: \{explanations.length()}\n\n"
  for item in explanations {
    text = text + render_slot_explanation(problem, item) + "\n"
  }
  text
}

///|
pub fn summarize_infeasibility(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Array[String] {
  let messages : Array[String] = []
  let impossible = impossible_slots(problem, assignments)
  if impossible.length() == 0 {
    messages.push(
      "No locally impossible slot was found; infeasibility may result from combinations of assignments.",
    )
  }
  for slot in impossible {
    let mut message = "Shift \{slot.shift_id} slot \{slot.slot + 1} has no eligible candidate."
    let mut availability = 0
    let mut skills = 0
    let mut conflicts = 0
    for candidate in slot.candidates {
      for reason in candidate.reasons {
        if reason.contains("available") {
          availability = availability + 1
        }
        if reason.contains("skill") {
          skills = skills + 1
        }
        if reason.contains("overlap") || reason.contains("rest") {
          conflicts = conflicts + 1
        }
      }
    }
    message = message +
      " Rejections: availability=\{availability}, skills=\{skills}, schedule-conflicts=\{conflicts}."
    messages.push(message)
  }
  messages
}

///|
pub fn suggested_actions(
  problem : ScheduleProblem,
  assignments : Array[Assignment],
) -> Array[String] {
  let actions : Array[String] = []
  for slot in impossible_slots(problem, assignments) {
    let mut lacks_skill = false
    let mut lacks_availability = false
    let mut conflicts = false
    for candidate in slot.candidates {
      for reason in candidate.reasons {
        if reason.contains("skill") {
          lacks_skill = true
        }
        if reason.contains("available") {
          lacks_availability = true
        }
        if reason.contains("overlap") || reason.contains("rest") {
          conflicts = true
        }
      }
    }
    if lacks_skill {
      actions.push(
        "Add or train a person with the skills required by shift \{slot.shift_id}.",
      )
    }
    if lacks_availability {
      actions.push(
        "Extend availability or move shift \{slot.shift_id} to a covered time.",
      )
    }
    if conflicts {
      actions.push(
        "Unlock a nearby assignment or reduce the rest constraint around shift \{slot.shift_id}.",
      )
    }
    if !lacks_skill && !lacks_availability && !conflicts {
      actions.push("Increase staffing capacity for shift \{slot.shift_id}.")
    }
  }
  actions
}
