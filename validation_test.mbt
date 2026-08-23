///|
fn test_person(
  id : String,
  skills : Array[Skill],
  availability : Array[TimeSpan],
) -> Person {
  {
    id,
    name: id,
    skills,
    availability,
    preferences: [],
    target_minutes: 240,
    maximum_minutes: 600,
    maximum_consecutive_shifts: 3,
  }
}

///|
fn test_shift(id : String, start : Int, end : Int, skill : String) -> Shift {
  {
    id,
    label: id,
    time: { start, end },
    required_people: 1,
    requirements: [{ skill, minimum_level: 1 }],
    priority: 1,
    group: "test",
  }
}

///|
fn test_problem() -> ScheduleProblem {
  {
    people: [
      test_person("alice", [{ name: "cashier", level: 2 }], [
        { start: 0, end: 1440 },
      ]),
    ],
    shifts: [test_shift("morning", 480, 720, "cashier")],
    existing: [],
    minimum_rest_minutes: 60,
    fairness_weight: 1,
    preference_weight: 1,
    disruption_weight: 1,
  }
}

///|
test "valid candidate domain" {
  let problem = test_problem()
  let domain = build_domain(problem, [], problem.shifts[0], 0)
  inspect(domain.people.length(), content="1")
  inspect(domain.people[0], content="alice")
}

///|
test "skill mismatch explains rejection" {
  let problem = test_problem()
  let shift = test_shift("lab", 800, 900, "chemist")
  let domain = build_domain(problem, [], shift, 0)
  inspect(domain.people.length(), content="0")
  assert_eq(domain.rejected[0].code, SkillMismatch)
}

///|
test "independent validator reports uncovered slot" {
  let errors = validate_assignments(test_problem(), [])
  inspect(errors.length(), content="1")
  assert_eq(errors[0].code, UncoveredSlot)
}
