///|
test "solver_sat_equal" {
  let m0 = @core.Model::new()
  let (m1, x) = m0.add_int_var(@core.IntVar::new("x", 0, 1))
  let (m2, y) = m1.add_int_var(@core.IntVar::new("y", 0, 1))
  let m3 = m2.add_equal(x.get_id(), y.get_id())
  let solver = Solver::new(m3)
  let res = solver.solve()
  match res.get_status() {
    SolveStatus::Sat => ()
    _ => panic()
  }
}

///|
test "solver_unsat_equal_and_notequal" {
  let m0 = @core.Model::new()
  let (m1, x) = m0.add_int_var(@core.IntVar::new("x", 0, 0))
  let (m2, y) = m1.add_int_var(@core.IntVar::new("y", 0, 0))
  let m3 = m2
    .add_equal(x.get_id(), y.get_id())
    .add_not_equal(x.get_id(), y.get_id())
  let solver = Solver::new(m3)
  let res = solver.solve()
  match res.get_status() {
    SolveStatus::Unsat => ()
    _ => panic()
  }
}
