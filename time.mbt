///|
pub fn TimeSpan::duration(self : TimeSpan) -> Int {
  if self.end <= self.start {
    0
  } else {
    self.end - self.start
  }
}

///|
pub fn TimeSpan::overlaps(self : TimeSpan, other : TimeSpan) -> Bool {
  self.start < other.end && other.start < self.end
}

///|
pub fn TimeSpan::contains(self : TimeSpan, other : TimeSpan) -> Bool {
  self.start <= other.start && self.end >= other.end
}

///|
pub fn TimeSpan::gap_to(self : TimeSpan, other : TimeSpan) -> Int {
  if self.end <= other.start {
    other.start - self.end
  } else if other.end <= self.start {
    self.start - other.end
  } else {
    -1
  }
}

///|
pub fn TimeSpan::is_valid(self : TimeSpan) -> Bool {
  self.start >= 0 && self.end > self.start
}

///|
pub fn minutes_to_clock(minutes : Int) -> String {
  let day = minutes / 1440
  let within = minutes % 1440
  let hour = within / 60
  let minute = within % 60
  let hh = if hour < 10 { "0\{hour}" } else { "\{hour}" }
  let mm = if minute < 10 { "0\{minute}" } else { "\{minute}" }
  "D\{day} \{hh}:\{mm}"
}

///|
pub fn same_day(a : TimeSpan, b : TimeSpan) -> Bool {
  a.start / 1440 == b.start / 1440
}
