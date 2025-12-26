// Copyright 2025
//
// Licensed under the Apache License, Version 2.0

///|
/// Result of a decision: choose a variable and a value to try.
pub struct DecisionResult {
  var_id : VarId
  value : Int
}

///|
/// Create a decision result.
pub fn DecisionResult::new(var_id : VarId, value : Int) -> DecisionResult {
  { var_id, value }
}

///|
/// Get variable id.
pub fn DecisionResult::get_var_id(self : DecisionResult) -> VarId {
  self.var_id
}

///|
/// Get chosen value.
pub fn DecisionResult::get_value(self : DecisionResult) -> Int {
  self.value
}

///|
/// Basic MRV (Minimum Remaining Values) decision:
/// - pick an unfixed variable with the smallest domain size
/// - choose its minimum value (leftmost value)
/// Returns None if all variables are fixed or no variables exist.
pub fn select_mrv(state : SearchState) -> DecisionResult? {
  let mut best_var : VarId = -1
  let mut best_domain : Domain? = None
  let vars = state.get_all_states()
  let mut i = 0
  while i < vars.length() {
    let var_state = vars[i]
    let dom = var_state.get_domain()
    if dom.is_fixed() {
      i = i + 1
      continue
    }
    match best_domain {
      None => {
        best_var = var_state.get_var_id()
        best_domain = Some(dom)
      }
      Some(d) =>
        if dom.size() < d.size() {
          best_var = var_state.get_var_id()
          best_domain = Some(dom)
        }
    }
    i = i + 1
  }
  match best_domain {
    None => None
    Some(dom) =>
      // choose the smallest value in domain for determinism
      Some(DecisionResult::new(best_var, dom.get_min()))
  }
}

///|
/// Decision strategy for variable and value selection.
/// This is a framework that can be extended with different heuristics.
pub struct DecisionStrategy {
  // Strategy name for debugging
  name : String
}

///|
/// Create a default decision strategy (MRV - Minimum Remaining Values).
pub fn DecisionStrategy::new() -> DecisionStrategy {
  { name: "MRV" }
}

///|
/// Create a decision strategy with a custom name.
pub fn DecisionStrategy::with_name(name : String) -> DecisionStrategy {
  { name, }
}

///|
/// Select the next variable to branch on.
/// Returns the variable ID and its current domain, or None if all variables are fixed.
/// Default strategy: MRV (Minimum Remaining Values) - choose variable with smallest domain.
pub fn DecisionStrategy::select_variable(
  _self : DecisionStrategy,
  state : SearchState,
) -> (VarId, Domain)? {
  let states = state.get_all_states()
  let mut best_var_id : VarId? = None
  let mut best_domain : Domain? = None
  let mut best_size = 2147483647
  let mut i = 0
  while i < states.length() {
    let var_state = states[i]
    let domain = var_state.get_domain()

    // Skip fixed variables
    if !domain.is_fixed() {
      let size = domain.size()
      if size < best_size {
        best_size = size
        best_var_id = Some(var_state.get_var_id())
        best_domain = Some(domain)
      }
    }
    i = i + 1
  }
  match best_var_id {
    Some(var_id) =>
      match best_domain {
        Some(domain) => Some((var_id, domain))
        None => None
      }
    None => None
  }
}

///|
/// Select the next value to try for a variable.
/// Returns the value to assign.
/// Default strategy: choose the minimum value in the domain.
pub fn DecisionStrategy::select_value(
  _self : DecisionStrategy,
  domain : Domain,
) -> Int? {
  if domain.is_empty() {
    None
  } else {
    Some(domain.get_min())
  }
}

///|
/// Make a decision: select variable and value.
/// Returns (var_id, value) if a decision can be made, None otherwise.
pub fn DecisionStrategy::make_decision(
  self : DecisionStrategy,
  state : SearchState,
) -> (VarId, Int)? {
  match self.select_variable(state) {
    Some((var_id, domain)) =>
      match self.select_value(domain) {
        Some(value) => Some((var_id, value))
        None => None
      }
    None => None
  }
}

///|
/// Get the strategy name.
pub fn DecisionStrategy::get_name(self : DecisionStrategy) -> String {
  self.name
}
