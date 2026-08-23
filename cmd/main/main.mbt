///|
fn main {
  let problem = @shiftweave.store_scenario()
  let result = @shiftweave.solve(problem)
  println(@shiftweave.render_markdown(problem, result))
  println(
    @shiftweave.render_operations_markdown(
      @shiftweave.review_operations(problem, result.assignments),
    ),
  )
}
