// Copyright 2025
//
// Licensed under the Apache License, Version 2.0

///|
/// A lightweight DFS + propagation solver (no learning).
pub struct Solver {
  model : @core.Model
  strategy : @search.DecisionStrategy
}

///|
pub fn Solver::new(model : @core.Model) -> Solver {
  { model, strategy: @search.DecisionStrategy::new() }
}

///|
/// Solve the model for feasibility.
pub fn Solver::solve(self : Solver) -> SolveResult {
  let init_state = initialize_state(self.model)
  match dfs(self.model, self.strategy, init_state) {
    None => SolveResult::unsat()
    Some(state) => extract_solution(state)
  }
}

///|
/// Build initial search state from modeling-time bounds.
fn initialize_state(model : @core.Model) -> @search.SearchState {
  let mut var_states : Array[@search.VarState] = []
  let int_vars = model.get_int_vars()
  let mut i = 0
  while i < int_vars.length() {
    let v = int_vars[i]
    let dom = @search.Domain::new(v.get_min(), v.get_max())
    var_states = [..var_states, @search.VarState::new(v.get_id(), dom)]
    i = i + 1
  }
  let bool_vars = model.get_bool_vars()
  let mut j = 0
  while j < bool_vars.length() {
    let b = bool_vars[j]
    let iv = b.to_int_var()
    let dom = @search.Domain::new(iv.get_min(), iv.get_max())
    var_states = [..var_states, @search.VarState::new(iv.get_id(), dom)]
    j = j + 1
  }
  @search.SearchState::new(var_states)
}

///|
fn dfs(
  model : @core.Model,
  strategy : @search.DecisionStrategy,
  state0 : @search.SearchState,
) -> @search.SearchState? {
  match propagate(model, state0) {
    None => None
    Some(state) => {
      if state.has_empty_domain() {
        return None
      }
      if state.all_fixed() {
        if is_consistent(model, state) {
          return Some(state)
        }
        return None
      }
      match strategy.make_decision(state) {
        None => None
        Some((var_id, value)) =>
          // Branch 1: try assign var_id = value
          match state.get_domain(var_id) {
            None => None
            Some(dom) => {
              if dom.contains(value) {
                let s1 = state.set_domain(
                  var_id,
                  @search.Domain::singleton(value),
                )
                match dfs(model, strategy, s1) {
                  Some(sol) => return Some(sol)
                  None => ()
                }
              }

              // Branch 2: forbid this value
              let s2 = state.set_domain(var_id, dom.remove_value(value))
              dfs(model, strategy, s2)
            }
          }
      }
    }
  }
}

///|
fn propagate(
  model : @core.Model,
  state0 : @search.SearchState,
) -> @search.SearchState? {
  let mut state = state0
  let constraints = model.get_constraints()
  let mut changed = true
  while changed {
    changed = false
    let mut i = 0
    while i < constraints.length() {
      match apply_constraint(constraints[i], state) {
        None => return None
        Some((s2, did_change)) => {
          state = s2
          if did_change {
            changed = true
          }
        }
      }
      i = i + 1
    }
    if state.has_empty_domain() {
      return None
    }
  }
  Some(state)
}

///|
fn apply_constraint(
  c : @core.Constraint,
  state : @search.SearchState,
) -> (@search.SearchState, Bool)? {
  match c {
    @core.Constraint::CMember(m) => {
      let v = m.get_var()
      match state.get_domain(v) {
        None => Some((state, false))
        Some(dom) => {
          let nd = dom.intersect_interval(m.get_min(), m.get_max())
          if nd.is_empty() {
            None
          } else if nd.equals(dom) {
            Some((state, false))
          } else {
            Some((state.set_domain(v, nd), true))
          }
        }
      }
    }
    @core.Constraint::CEqual(eq) => {
      let x = eq.get_x()
      let y = eq.get_y()
      match (state.get_domain(x), state.get_domain(y)) {
        (Some(dx), Some(dy)) => {
          let inter = dx.intersect(dy)
          if inter.is_empty() {
            None
          } else {
            let mut s2 = state
            let mut did = false
            if !dx.equals(inter) {
              s2 = s2.set_domain(x, inter)
              did = true
            }
            if !dy.equals(inter) {
              s2 = s2.set_domain(y, inter)
              did = true
            }
            Some((s2, did))
          }
        }
        _ => Some((state, false))
      }
    }
    @core.Constraint::CNotEqual(neq) => {
      let x = neq.get_x()
      let y = neq.get_y()
      match (state.get_domain(x), state.get_domain(y)) {
        (Some(dx), Some(dy)) =>
          match (dx.get_value(), dy.get_value()) {
            (Some(vx), Some(vy)) =>
              if vx == vy {
                None
              } else {
                Some((state, false))
              }
            (Some(vx), None) => {
              let nd = dy.remove_value(vx)
              if nd.is_empty() {
                None
              } else if nd.equals(dy) {
                Some((state, false))
              } else {
                Some((state.set_domain(y, nd), true))
              }
            }
            (None, Some(vy)) => {
              let nd = dx.remove_value(vy)
              if nd.is_empty() {
                None
              } else if nd.equals(dx) {
                Some((state, false))
              } else {
                Some((state.set_domain(x, nd), true))
              }
            }
            _ => Some((state, false))
          }
        _ => Some((state, false))
      }
    }
    @core.Constraint::CAllDifferent(ad) => {
      let vars = ad.get_vars()
      // collect fixed values, and check duplicates
      let mut fixed_vals : Array[Int] = []
      let mut i = 0
      while i < vars.length() {
        match state.get_domain(vars[i]) {
          None => ()
          Some(dom) =>
            match dom.get_value() {
              None => ()
              Some(v) => {
                // duplicate check
                let mut k = 0
                while k < fixed_vals.length() {
                  if fixed_vals[k] == v {
                    return None
                  }
                  k = k + 1
                }
                fixed_vals = [..fixed_vals, v]
              }
            }
        }
        i = i + 1
      }

      // remove fixed values from others
      let mut did = false
      let mut s2 = state
      let mut j = 0
      while j < vars.length() {
        let vid = vars[j]
        match s2.get_domain(vid) {
          None => ()
          Some(dom) =>
            if !dom.is_fixed() {
              let mut nd = dom
              let mut k = 0
              while k < fixed_vals.length() {
                nd = nd.remove_value(fixed_vals[k])
                k = k + 1
              }
              if nd.is_empty() {
                return None
              }
              if !nd.equals(dom) {
                s2 = s2.set_domain(vid, nd)
                did = true
              }
            }
        }
        j = j + 1
      }
      Some((s2, did))
    }
    @core.Constraint::CLinearLe(le) =>
      if linear_le_feasible(le, state) {
        Some((state, false))
      } else {
        None
      }
  }
}

///|
fn linear_le_feasible(le : @core.LinearLe, state : @search.SearchState) -> Bool {
  let vars = le.get_vars()
  let coeffs = le.get_coefficients()
  let rhs = le.get_constant()
  if vars.length() != coeffs.length() {
    return false
  }
  let mut min_sum = 0
  let mut i = 0
  while i < vars.length() {
    let vid = vars[i]
    let c = coeffs[i]
    match state.get_domain(vid) {
      None => return false
      Some(dom) => {
        let lo = dom.get_min()
        let hi = dom.get_max()
        if c >= 0 {
          min_sum = min_sum + c * lo
        } else {
          min_sum = min_sum + c * hi
        }
      }
    }
    i = i + 1
  }
  min_sum <= rhs
}

///|
fn is_consistent(model : @core.Model, state : @search.SearchState) -> Bool {
  let cs = model.get_constraints()
  let mut i = 0
  while i < cs.length() {
    if !constraint_ok(cs[i], state) {
      return false
    }
    i = i + 1
  }
  true
}

///|
fn constraint_ok(c : @core.Constraint, state : @search.SearchState) -> Bool {
  match c {
    @core.Constraint::CMember(m) =>
      match state.get_domain(m.get_var()) {
        None => false
        Some(dom) =>
          !dom.intersect_interval(m.get_min(), m.get_max()).is_empty()
      }
    @core.Constraint::CEqual(eq) =>
      match (state.get_domain(eq.get_x()), state.get_domain(eq.get_y())) {
        (Some(dx), Some(dy)) => !dx.intersect(dy).is_empty()
        _ => false
      }
    @core.Constraint::CNotEqual(neq) =>
      match (state.get_domain(neq.get_x()), state.get_domain(neq.get_y())) {
        (Some(dx), Some(dy)) =>
          match (dx.get_value(), dy.get_value()) {
            (Some(vx), Some(vy)) => vx != vy
            _ => true
          }
        _ => false
      }
    @core.Constraint::CAllDifferent(ad) => {
      let vars = ad.get_vars()
      let mut seen : Array[Int] = []
      let mut i = 0
      while i < vars.length() {
        match state.get_domain(vars[i]) {
          None => return false
          Some(dom) =>
            match dom.get_value() {
              None => ()
              Some(v) => {
                let mut k = 0
                while k < seen.length() {
                  if seen[k] == v {
                    return false
                  }
                  k = k + 1
                }
                seen = [..seen, v]
              }
            }
        }
        i = i + 1
      }
      true
    }
    @core.Constraint::CLinearLe(le) => linear_le_feasible(le, state)
  }
}

///|
fn extract_solution(state : @search.SearchState) -> SolveResult {
  let mut sol = Solution::new()
  let vars = state.get_all_states()
  let mut i = 0
  while i < vars.length() {
    let vs = vars[i]
    match vs.get_domain().get_value() {
      None => ()
      Some(v) => sol = sol.add(vs.get_var_id(), v)
    }
    i = i + 1
  }
  SolveResult::sat(sol)
}
