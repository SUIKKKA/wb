///|
pub(all) enum RecordKind {
  PersonRecord
  SkillRecord
  AvailabilityRecord
  PreferenceRecord
  ShiftRecord
  RequirementRecord
  AssignmentRecord
  RuleRecord
  CommentRecord
  BlankRecord
  UnknownRecord
} derive(Debug, Eq)

///|
pub(all) struct ParseIssue {
  line : Int
  column : Int
  message : String
  source : String
} derive(Debug, Eq)

///|
pub(all) struct ParsedRoster {
  problem : ScheduleProblem
  issues : Array[ParseIssue]
} derive(Debug, Eq)

///|
pub fn trim_ascii(text : String) -> String {
  let chars : Array[Char] = text.iter().collect()
  let mut left = 0
  let mut right = chars.length()
  while left < right &&
        (chars[left] == ' ' || chars[left] == '\t' || chars[left] == '\r') {
    left = left + 1
  }
  while right > left &&
        (
          chars[right - 1] == ' ' ||
          chars[right - 1] == '\t' ||
          chars[right - 1] == '\r'
        ) {
    right = right - 1
  }
  let mut out = ""
  for i = left; i < right; i = i + 1 {
    out = out + chars[i].to_string()
  }
  out
}

///|
pub fn parse_integer(text : String) -> Int? {
  let value = trim_ascii(text)
  if value == "" {
    return None
  }
  let chars : Array[Char] = value.iter().collect()
  let mut index = 0
  let mut sign = 1
  if chars[0] == '-' {
    sign = -1
    index = 1
  } else if chars[0] == '+' {
    index = 1
  }
  if index >= chars.length() {
    return None
  }
  let mut number = 0
  while index < chars.length() {
    let c = chars[index]
    if c < '0' || c > '9' {
      return None
    }
    number = number * 10 + c.to_int() - '0'.to_int()
    index = index + 1
  }
  Some(number * sign)
}

///|
pub fn split_fields(line : String) -> Array[String] {
  line.split("|").map(part => trim_ascii(part.to_owned())).collect()
}

///|
pub fn record_kind(line : String) -> RecordKind {
  let value = trim_ascii(line)
  if value == "" {
    return BlankRecord
  }
  if value.has_prefix("#") {
    return CommentRecord
  }
  let fields = split_fields(value)
  if fields.length() == 0 {
    return UnknownRecord
  }
  match fields[0] {
    "person" => PersonRecord
    "skill" => SkillRecord
    "available" => AvailabilityRecord
    "prefer" => PreferenceRecord
    "shift" => ShiftRecord
    "require" => RequirementRecord
    "assign" => AssignmentRecord
    "rule" => RuleRecord
    _ => UnknownRecord
  }
}

///|
fn issue(
  line : Int,
  column : Int,
  message : String,
  source : String,
) -> ParseIssue {
  { line, column, message, source }
}

///|
fn empty_person(
  id : String,
  name : String,
  target : Int,
  maximum : Int,
) -> Person {
  {
    id,
    name,
    skills: [],
    availability: [],
    preferences: [],
    target_minutes: target,
    maximum_minutes: maximum,
    maximum_consecutive_shifts: 5,
  }
}

///|
fn find_person_index(people : Array[Person], id : String) -> Int {
  for i = 0; i < people.length(); i = i + 1 {
    if people[i].id == id {
      return i
    }
  }
  -1
}

///|
fn find_shift_index(shifts : Array[Shift], id : String) -> Int {
  for i = 0; i < shifts.length(); i = i + 1 {
    if shifts[i].id == id {
      return i
    }
  }
  -1
}

///|
fn update_person_skills(person : Person, skill : Skill) -> Person {
  let values = person.skills.copy()
  values.push(skill)
  { ..person, skills: values }
}

///|
fn update_person_availability(person : Person, span : TimeSpan) -> Person {
  let values = person.availability.copy()
  values.push(span)
  { ..person, availability: values }
}

///|
fn update_person_preferences(
  person : Person,
  preference : ShiftPreference,
) -> Person {
  let values = person.preferences.copy()
  values.push(preference)
  { ..person, preferences: values }
}

///|
fn update_shift_requirements(
  shift : Shift,
  requirement : SkillRequirement,
) -> Shift {
  let values = shift.requirements.copy()
  values.push(requirement)
  { ..shift, requirements: values }
}

///|
pub fn parse_roster(text : String) -> ParsedRoster {
  let people : Array[Person] = []
  let shifts : Array[Shift] = []
  let assignments : Array[Assignment] = []
  let issues : Array[ParseIssue] = []
  let mut minimum_rest = 0
  let mut fairness_weight = 1
  let mut preference_weight = 1
  let mut disruption_weight = 10
  let lines : Array[String] = text
    .split("\n")
    .map(value => value.to_owned())
    .collect()
  for line_index = 0; line_index < lines.length(); line_index = line_index + 1 {
    let source = lines[line_index]
    let fields = split_fields(source)
    match record_kind(source) {
      BlankRecord | CommentRecord => ()
      PersonRecord =>
        if fields.length() != 5 {
          issues.push(
            issue(
              line_index + 1,
              1,
              "person expects id|name|target|max",
              source,
            ),
          )
        } else {
          match (parse_integer(fields[3]), parse_integer(fields[4])) {
            (Some(target), Some(maximum)) =>
              people.push(empty_person(fields[1], fields[2], target, maximum))
            _ =>
              issues.push(
                issue(
                  line_index + 1,
                  4,
                  "person minute limits must be integers",
                  source,
                ),
              )
          }
        }
      SkillRecord =>
        if fields.length() != 4 {
          issues.push(
            issue(line_index + 1, 1, "skill expects person|name|level", source),
          )
        } else {
          let index = find_person_index(people, fields[1])
          match parse_integer(fields[3]) {
            Some(level) =>
              if index < 0 {
                issues.push(
                  issue(
                    line_index + 1,
                    2,
                    "skill references unknown person",
                    source,
                  ),
                )
              } else {
                people[index] = update_person_skills(people[index], {
                  name: fields[2],
                  level,
                })
              }
            None =>
              issues.push(
                issue(
                  line_index + 1,
                  4,
                  "skill level must be an integer",
                  source,
                ),
              )
          }
        }
      AvailabilityRecord =>
        if fields.length() != 4 {
          issues.push(
            issue(
              line_index + 1,
              1,
              "available expects person|start|end",
              source,
            ),
          )
        } else {
          let index = find_person_index(people, fields[1])
          match (parse_integer(fields[2]), parse_integer(fields[3])) {
            (Some(start), Some(end)) =>
              if index < 0 {
                issues.push(
                  issue(
                    line_index + 1,
                    2,
                    "availability references unknown person",
                    source,
                  ),
                )
              } else {
                people[index] = update_person_availability(people[index], {
                  start,
                  end,
                })
              }
            _ =>
              issues.push(
                issue(
                  line_index + 1,
                  3,
                  "availability bounds must be integers",
                  source,
                ),
              )
          }
        }
      PreferenceRecord =>
        if fields.length() != 4 {
          issues.push(
            issue(
              line_index + 1,
              1,
              "prefer expects person|shift|weight",
              source,
            ),
          )
        } else {
          let index = find_person_index(people, fields[1])
          match parse_integer(fields[3]) {
            Some(weight) =>
              if index < 0 {
                issues.push(
                  issue(
                    line_index + 1,
                    2,
                    "preference references unknown person",
                    source,
                  ),
                )
              } else {
                people[index] = update_person_preferences(people[index], {
                  shift_id: fields[2],
                  weight,
                })
              }
            None =>
              issues.push(
                issue(
                  line_index + 1,
                  4,
                  "preference weight must be an integer",
                  source,
                ),
              )
          }
        }
      ShiftRecord =>
        if fields.length() != 8 {
          issues.push(
            issue(
              line_index + 1,
              1,
              "shift expects id|label|start|end|people|priority|group",
              source,
            ),
          )
        } else {
          match
            (
              parse_integer(fields[3]),
              parse_integer(fields[4]),
              parse_integer(fields[5]),
              parse_integer(fields[6]),
            ) {
            (Some(start), Some(end), Some(required), Some(priority)) =>
              shifts.push({
                id: fields[1],
                label: fields[2],
                time: { start, end },
                required_people: required,
                requirements: [],
                priority,
                group: fields[7],
              })
            _ =>
              issues.push(
                issue(
                  line_index + 1,
                  4,
                  "shift numeric fields are invalid",
                  source,
                ),
              )
          }
        }
      RequirementRecord =>
        if fields.length() != 4 {
          issues.push(
            issue(
              line_index + 1,
              1,
              "require expects shift|skill|level",
              source,
            ),
          )
        } else {
          let index = find_shift_index(shifts, fields[1])
          match parse_integer(fields[3]) {
            Some(level) =>
              if index < 0 {
                issues.push(
                  issue(
                    line_index + 1,
                    2,
                    "requirement references unknown shift",
                    source,
                  ),
                )
              } else {
                shifts[index] = update_shift_requirements(shifts[index], {
                  skill: fields[2],
                  minimum_level: level,
                })
              }
            None =>
              issues.push(
                issue(
                  line_index + 1,
                  4,
                  "requirement level must be integer",
                  source,
                ),
              )
          }
        }
      AssignmentRecord =>
        if fields.length() != 5 {
          issues.push(
            issue(
              line_index + 1,
              1,
              "assign expects shift|slot|person|locked",
              source,
            ),
          )
        } else {
          match parse_integer(fields[2]) {
            Some(slot) =>
              assignments.push({
                shift_id: fields[1],
                slot,
                person_id: fields[3],
                locked: fields[4] == "true",
              })
            None =>
              issues.push(
                issue(
                  line_index + 1,
                  3,
                  "assignment slot must be integer",
                  source,
                ),
              )
          }
        }
      RuleRecord =>
        if fields.length() != 3 {
          issues.push(
            issue(line_index + 1, 1, "rule expects name|value", source),
          )
        } else {
          match parse_integer(fields[2]) {
            None =>
              issues.push(
                issue(line_index + 1, 3, "rule value must be integer", source),
              )
            Some(value) =>
              match fields[1] {
                "minimum_rest" => minimum_rest = value
                "fairness_weight" => fairness_weight = value
                "preference_weight" => preference_weight = value
                "disruption_weight" => disruption_weight = value
                _ =>
                  issues.push(
                    issue(line_index + 1, 2, "unknown rule name", source),
                  )
              }
          }
        }
      UnknownRecord =>
        issues.push(issue(line_index + 1, 1, "unknown record kind", source))
    }
  }
  {
    problem: {
      people,
      shifts,
      existing: assignments,
      minimum_rest_minutes: minimum_rest,
      fairness_weight,
      preference_weight,
      disruption_weight,
    },
    issues,
  }
}

///|
pub fn render_roster(problem : ScheduleProblem) -> String {
  let mut text = "# ShiftWeave roster v1\n"
  text = text + "rule|minimum_rest|\{problem.minimum_rest_minutes}\n"
  text = text + "rule|fairness_weight|\{problem.fairness_weight}\n"
  text = text + "rule|preference_weight|\{problem.preference_weight}\n"
  text = text + "rule|disruption_weight|\{problem.disruption_weight}\n"
  for person in problem.people {
    text = text +
      "person|\{person.id}|\{person.name}|\{person.target_minutes}|\{person.maximum_minutes}\n"
    for skill in person.skills {
      text = text + "skill|\{person.id}|\{skill.name}|\{skill.level}\n"
    }
    for span in person.availability {
      text = text + "available|\{person.id}|\{span.start}|\{span.end}\n"
    }
    for pref in person.preferences {
      text = text + "prefer|\{person.id}|\{pref.shift_id}|\{pref.weight}\n"
    }
  }
  for shift in problem.shifts {
    text = text +
      "shift|\{shift.id}|\{shift.label}|\{shift.time.start}|\{shift.time.end}|\{shift.required_people}|\{shift.priority}|\{shift.group}\n"
    for requirement in shift.requirements {
      text = text +
        "require|\{shift.id}|\{requirement.skill}|\{requirement.minimum_level}\n"
    }
  }
  for assignment in problem.existing {
    text = text +
      "assign|\{assignment.shift_id}|\{assignment.slot}|\{assignment.person_id}|\{assignment.locked}\n"
  }
  text
}
