///|
test "time span operations" {
  let morning : TimeSpan = { start: 480, end: 720 }
  let noon : TimeSpan = { start: 660, end: 780 }
  let evening : TimeSpan = { start: 840, end: 1020 }
  inspect(morning.duration(), content="240")
  inspect(morning.overlaps(noon), content="true")
  inspect(morning.overlaps(evening), content="false")
  inspect(morning.gap_to(evening), content="120")
}

///|
test "clock formatting" {
  inspect(minutes_to_clock(0), content="D0 00:00")
  inspect(minutes_to_clock(1505), content="D1 01:05")
}
