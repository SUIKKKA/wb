///|
pub fn make_person(
  id : String,
  name : String,
  skills : Array[Skill],
  availability : Array[TimeSpan],
  target : Int,
  maximum : Int,
  preferences? : Array[ShiftPreference] = [],
) -> Person {
  {
    id,
    name,
    skills,
    availability,
    preferences,
    target_minutes: target,
    maximum_minutes: maximum,
    maximum_consecutive_shifts: 5,
  }
}

///|
pub fn make_shift(
  id : String,
  label : String,
  start : Int,
  end : Int,
  required : Int,
  requirements : Array[SkillRequirement],
  priority? : Int = 1,
  group? : String = "default",
) -> Shift {
  {
    id,
    label,
    time: { start, end },
    required_people: required,
    requirements,
    priority,
    group,
  }
}

///|
pub fn store_scenario() -> ScheduleProblem {
  let all_week : Array[TimeSpan] = [{ start: 0, end: 10080 }]
  let alice = make_person(
    "alice",
    "Alice",
    [
      { name: "cashier", level: 3 },
      { name: "keyholder", level: 2 },
      { name: "stock", level: 1 },
    ],
    all_week,
    1440,
    1920,
    preferences=[
      { shift_id: "mon-open", weight: 6 },
      { shift_id: "fri-close", weight: -4 },
    ],
  )
  let bob = make_person(
    "bob",
    "Bob",
    [{ name: "cashier", level: 2 }, { name: "stock", level: 3 }],
    [{ start: 0, end: 4320 }, { start: 5760, end: 10080 }],
    1200,
    1800,
    preferences=[{ shift_id: "sat-open", weight: 5 }],
  )
  let chen = make_person(
    "chen",
    "Chen",
    [{ name: "cashier", level: 2 }, { name: "keyholder", level: 1 }],
    all_week,
    1200,
    1680,
    preferences=[{ shift_id: "wed-close", weight: 4 }],
  )
  let dia = make_person(
    "dia",
    "Dia",
    [{ name: "cashier", level: 1 }, { name: "stock", level: 2 }],
    [{ start: 0, end: 7200 }],
    960,
    1440,
  )
  let shifts : Array[Shift] = [
    make_shift(
      "mon-open",
      "Monday opening",
      480,
      960,
      2,
      [{ skill: "cashier", minimum_level: 1 }],
      priority=5,
      group="open",
    ),
    make_shift(
      "mon-close",
      "Monday closing",
      960,
      1320,
      2,
      [{ skill: "cashier", minimum_level: 1 }],
      priority=4,
      group="close",
    ),
    make_shift(
      "wed-open",
      "Wednesday opening",
      3360,
      3840,
      2,
      [{ skill: "cashier", minimum_level: 1 }],
      priority=5,
      group="open",
    ),
    make_shift(
      "wed-close",
      "Wednesday closing",
      3840,
      4200,
      2,
      [{ skill: "cashier", minimum_level: 1 }],
      priority=4,
      group="close",
    ),
    make_shift(
      "fri-open",
      "Friday opening",
      6240,
      6720,
      2,
      [{ skill: "cashier", minimum_level: 1 }],
      priority=5,
      group="open",
    ),
    make_shift(
      "fri-close",
      "Friday closing",
      6720,
      7080,
      2,
      [{ skill: "cashier", minimum_level: 1 }],
      priority=4,
      group="close",
    ),
    make_shift(
      "sat-open",
      "Saturday opening",
      7680,
      8160,
      2,
      [{ skill: "cashier", minimum_level: 1 }],
      priority=5,
      group="open",
    ),
  ]
  {
    people: [alice, bob, chen, dia],
    shifts,
    existing: [],
    minimum_rest_minutes: 480,
    fairness_weight: 1,
    preference_weight: 20,
    disruption_weight: 120,
  }
}

///|
pub fn laboratory_scenario() -> ScheduleProblem {
  let week : Array[TimeSpan] = [{ start: 0, end: 10080 }]
  let iman = make_person(
    "iman",
    "Iman",
    [
      { name: "spectrometer", level: 3 },
      { name: "safety", level: 3 },
      { name: "sample", level: 2 },
    ],
    week,
    960,
    1440,
  )
  let jules = make_person(
    "jules",
    "Jules",
    [{ name: "spectrometer", level: 2 }, { name: "safety", level: 2 }],
    [{ start: 0, end: 5000 }],
    720,
    1200,
  )
  let kai = make_person(
    "kai",
    "Kai",
    [{ name: "sample", level: 3 }, { name: "safety", level: 1 }],
    week,
    720,
    1200,
  )
  let lin = make_person(
    "lin",
    "Lin",
    [
      { name: "spectrometer", level: 1 },
      { name: "sample", level: 2 },
      { name: "safety", level: 2 },
    ],
    week,
    720,
    1200,
  )
  let shifts : Array[Shift] = [
    make_shift(
      "calibrate-a",
      "Calibrate instrument A",
      540,
      720,
      1,
      [
        { skill: "spectrometer", minimum_level: 3 },
        { skill: "safety", minimum_level: 2 },
      ],
      priority=8,
      group="instrument",
    ),
    make_shift(
      "batch-a",
      "Process sample batch A",
      720,
      1020,
      2,
      [{ skill: "sample", minimum_level: 2 }],
      priority=6,
      group="sample",
    ),
    make_shift(
      "calibrate-b",
      "Calibrate instrument B",
      3420,
      3600,
      1,
      [
        { skill: "spectrometer", minimum_level: 2 },
        { skill: "safety", minimum_level: 2 },
      ],
      priority=8,
      group="instrument",
    ),
    make_shift(
      "batch-b",
      "Process sample batch B",
      3600,
      3900,
      2,
      [{ skill: "sample", minimum_level: 2 }],
      priority=6,
      group="sample",
    ),
    make_shift(
      "audit",
      "Weekly safety audit",
      6480,
      6720,
      2,
      [{ skill: "safety", minimum_level: 2 }],
      priority=9,
      group="safety",
    ),
  ]
  {
    people: [iman, jules, kai, lin],
    shifts,
    existing: [],
    minimum_rest_minutes: 180,
    fairness_weight: 2,
    preference_weight: 10,
    disruption_weight: 200,
  }
}

///|
pub fn volunteer_scenario() -> ScheduleProblem {
  let event : Array[TimeSpan] = [{ start: 0, end: 2880 }]
  let ava = make_person(
    "ava",
    "Ava",
    [{ name: "welcome", level: 3 }, { name: "first-aid", level: 2 }],
    event,
    360,
    600,
  )
  let ben = make_person(
    "ben",
    "Ben",
    [{ name: "welcome", level: 2 }, { name: "logistics", level: 2 }],
    event,
    360,
    600,
  )
  let cy = make_person(
    "cy",
    "Cy",
    [{ name: "stage", level: 3 }, { name: "logistics", level: 1 }],
    event,
    360,
    600,
  )
  let dev = make_person(
    "dev",
    "Dev",
    [{ name: "first-aid", level: 3 }, { name: "welcome", level: 1 }],
    event,
    360,
    600,
  )
  let eli = make_person(
    "eli",
    "Eli",
    [{ name: "stage", level: 2 }, { name: "logistics", level: 3 }],
    event,
    360,
    600,
  )
  let shifts : Array[Shift] = [
    make_shift(
      "setup",
      "Venue setup",
      360,
      600,
      2,
      [{ skill: "logistics", minimum_level: 1 }],
      priority=7,
      group="setup",
    ),
    make_shift(
      "welcome-am",
      "Morning welcome desk",
      600,
      840,
      2,
      [{ skill: "welcome", minimum_level: 1 }],
      priority=6,
      group="welcome",
    ),
    make_shift(
      "stage-am",
      "Morning stage support",
      600,
      840,
      1,
      [{ skill: "stage", minimum_level: 2 }],
      priority=6,
      group="stage",
    ),
    make_shift(
      "aid-am",
      "Morning first aid",
      600,
      840,
      1,
      [{ skill: "first-aid", minimum_level: 2 }],
      priority=9,
      group="safety",
    ),
    make_shift(
      "welcome-pm",
      "Afternoon welcome desk",
      900,
      1140,
      2,
      [{ skill: "welcome", minimum_level: 1 }],
      priority=6,
      group="welcome",
    ),
    make_shift(
      "stage-pm",
      "Afternoon stage support",
      900,
      1140,
      1,
      [{ skill: "stage", minimum_level: 2 }],
      priority=6,
      group="stage",
    ),
    make_shift(
      "aid-pm",
      "Afternoon first aid",
      900,
      1140,
      1,
      [{ skill: "first-aid", minimum_level: 2 }],
      priority=9,
      group="safety",
    ),
    make_shift(
      "teardown",
      "Venue teardown",
      1140,
      1380,
      2,
      [{ skill: "logistics", minimum_level: 1 }],
      priority=7,
      group="setup",
    ),
  ]
  {
    people: [ava, ben, cy, dev, eli],
    shifts,
    existing: [],
    minimum_rest_minutes: 30,
    fairness_weight: 4,
    preference_weight: 10,
    disruption_weight: 100,
  }
}

///|
pub fn scenario_by_name(name : String) -> ScheduleProblem? {
  match name {
    "store" => Some(store_scenario())
    "laboratory" | "lab" => Some(laboratory_scenario())
    "volunteer" => Some(volunteer_scenario())
    _ => None
  }
}

///|
pub fn scenario_names() -> Array[String] {
  ["store", "laboratory", "volunteer"]
}

///|
pub fn expand_days(base : ScheduleProblem, copies : Int) -> ScheduleProblem {
  if copies <= 1 {
    return base
  }
  let shifts : Array[Shift] = []
  for copy = 0; copy < copies; copy = copy + 1 {
    let offset = copy * 10080
    for shift in base.shifts {
      shifts.push({
        ..shift,
        id: "\{shift.id}-w\{copy + 1}",
        label: "\{shift.label} week \{copy + 1}",
        time: { start: shift.time.start + offset, end: shift.time.end + offset },
      })
    }
  }
  let people : Array[Person] = []
  for person in base.people {
    let availability : Array[TimeSpan] = []
    for copy = 0; copy < copies; copy = copy + 1 {
      let offset = copy * 10080
      for span in person.availability {
        availability.push({ start: span.start + offset, end: span.end + offset })
      }
    }
    people.push({
      ..person,
      availability,
      target_minutes: person.target_minutes * copies,
      maximum_minutes: person.maximum_minutes * copies,
    })
  }
  { ..base, people, shifts, existing: [] }
}
