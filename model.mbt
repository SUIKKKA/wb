///|
pub type PersonId = String

///|
pub type ShiftId = String

///|
pub(all) struct TimeSpan {
  start : Int
  end : Int
} derive(Show, Eq)

///|
pub(all) struct SkillRequirement {
  skill : String
  minimum_level : Int
} derive(Show, Eq)

///|
pub(all) struct Skill {
  name : String
  level : Int
} derive(Show, Eq)

///|
pub(all) struct ShiftPreference {
  shift_id : ShiftId
  weight : Int
} derive(Show, Eq)

///|
pub(all) struct Person {
  id : PersonId
  name : String
  skills : Array[Skill]
  availability : Array[TimeSpan]
  preferences : Array[ShiftPreference]
  target_minutes : Int
  maximum_minutes : Int
  maximum_consecutive_shifts : Int
} derive(Show, Eq)

///|
pub(all) struct Shift {
  id : ShiftId
  label : String
  time : TimeSpan
  required_people : Int
  requirements : Array[SkillRequirement]
  priority : Int
  group : String
} derive(Show, Eq)

///|
pub(all) struct Assignment {
  shift_id : ShiftId
  slot : Int
  person_id : PersonId
  locked : Bool
} derive(Show, Eq)

///|
pub(all) struct ScheduleProblem {
  people : Array[Person]
  shifts : Array[Shift]
  existing : Array[Assignment]
  minimum_rest_minutes : Int
  fairness_weight : Int
  preference_weight : Int
  disruption_weight : Int
} derive(Show, Eq)

///|
pub(all) enum DiagnosticCode {
  InvalidTimeSpan
  DuplicatePerson
  DuplicateShift
  UnknownPerson
  UnknownShift
  InvalidSlot
  DuplicateAssignment
  OverlappingAssignment
  OutsideAvailability
  SkillMismatch
  MaximumMinutesExceeded
  InsufficientRest
  ConsecutiveLimitExceeded
  UncoveredSlot
  EmptyCandidateDomain
  SearchBudgetExceeded
  InvalidConfiguration
} derive(Show, Eq)

///|
pub(all) struct Diagnostic {
  code : DiagnosticCode
  message : String
  person_id : PersonId?
  shift_id : ShiftId?
  slot : Int?
  severity : Int
} derive(Show, Eq)

///|
pub(all) enum SolveStatus {
  Solved
  Partial
  Infeasible
  BudgetExceeded
} derive(Show, Eq)

///|
pub(all) struct ScheduleMetrics {
  hard_violations : Int
  uncovered_slots : Int
  preference_score : Int
  fairness_penalty : Int
  disruption_count : Int
  total_minutes : Int
  objective : Int
} derive(Show, Eq)

///|
pub(all) struct ScheduleResult {
  status : SolveStatus
  assignments : Array[Assignment]
  diagnostics : Array[Diagnostic]
  metrics : ScheduleMetrics
  explored_nodes : Int
  propagated_values : Int
} derive(Show, Eq)

///|
pub(all) struct SearchOptions {
  maximum_nodes : Int
  maximum_solutions : Int
  stop_at_first_feasible : Bool
  keep_explanations : Bool
} derive(Show, Eq)

///|
pub fn SearchOptions::default() -> SearchOptions {
  {
    maximum_nodes: 100000,
    maximum_solutions: 32,
    stop_at_first_feasible: false,
    keep_explanations: true,
  }
}

///|
pub fn ScheduleMetrics::empty() -> ScheduleMetrics {
  {
    hard_violations: 0,
    uncovered_slots: 0,
    preference_score: 0,
    fairness_penalty: 0,
    disruption_count: 0,
    total_minutes: 0,
    objective: 0,
  }
}
