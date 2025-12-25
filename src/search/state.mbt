// Copyright 2025
//
// Licensed under the Apache License, Version 2.0

// Type aliases for cross-package imports
type VarId = @core.variable.VarId
type Domain = @core.domain.Domain

///|
/// Variable state during search.
/// Tracks the current domain of each variable.
pub struct VarState {
  var_id: VarId
  domain: Domain
}

///|
/// Create a variable state.
pub fn VarState::new(var_id: VarId, domain: Domain) -> VarState {
  { var_id: var_id, domain: domain }
}

///|
/// Get the variable ID.
pub fn VarState::get_var_id(self: VarState) -> VarId {
  self.var_id
}

///|
/// Get the current domain.
pub fn VarState::get_domain(self: VarState) -> Domain {
  self.domain
}

///|
/// Update the domain (returns new state).
pub fn VarState::set_domain(self: VarState, domain: Domain) -> VarState {
  { var_id: self.var_id, domain: domain }
}

///|
/// Search state - tracks all variable domains during search.
pub struct SearchState {
  var_states: Array[VarState]
}

///|
/// Create a new search state with initial domains for all variables.
pub fn SearchState::new(var_states: Array[VarState]) -> SearchState {
  { var_states: var_states }
}

///|
/// Get the state of a specific variable.
pub fn SearchState::get_var_state(self: SearchState, var_id: VarId) -> Option[VarState] {
  let mut i = 0
  while i < self.var_states.length() {
    let state = self.var_states[i]
    if state.get_var_id() == var_id {
      return Some(state)
    }
    i = i + 1
  }
  None
}

///|
/// Get the domain of a specific variable.
pub fn SearchState::get_domain(self: SearchState, var_id: VarId) -> Option[Domain] {
  match self.get_var_state(var_id) {
    Some(state) => Some(state.get_domain())
    None => None
  }
}

///|
/// Update the domain of a variable (returns new state).
pub fn SearchState::set_domain(mut self: SearchState, var_id: VarId, domain: Domain) -> SearchState {
  let mut i = 0
  while i < self.var_states.length() {
    let state = self.var_states[i]
    if state.get_var_id() == var_id {
      let new_state = state.set_domain(domain)
      self.var_states[i] = new_state
      return self
    }
    i = i + 1
  }
  // Variable not found, add it
  let new_state = VarState::new(var_id, domain)
  self.var_states = self.var_states.push(new_state)
  self
}

///|
/// Check if all variables are fixed (assigned).
pub fn SearchState::all_fixed(self: SearchState) -> Bool {
  let mut i = 0
  while i < self.var_states.length() {
    let state = self.var_states[i]
    if !state.get_domain().is_fixed() {
      return false
    }
    i = i + 1
  }
  true
}

///|
/// Check if any variable has an empty domain (failure).
pub fn SearchState::has_empty_domain(self: SearchState) -> Bool {
  let mut i = 0
  while i < self.var_states.length() {
    let state = self.var_states[i]
    if state.get_domain().is_empty() {
      return true
    }
    i = i + 1
  }
  false
}

///|
/// Get all variable states.
pub fn SearchState::get_all_states(self: SearchState) -> Array[VarState] {
  self.var_states
}

///|
/// Get the number of unfixed variables.
pub fn SearchState::unfixed_count(self: SearchState) -> Int {
  let mut count = 0
  let mut i = 0
  while i < self.var_states.length() {
    let state = self.var_states[i]
    if !state.get_domain().is_fixed() {
      count = count + 1
    }
    i = i + 1
  }
  count
}

///|
/// Create a copy of the search state (for backtracking).
pub fn SearchState::copy(self: SearchState) -> SearchState {
  // Deep copy of all variable states
  let mut new_states: Array[VarState] = []
  let mut i = 0
  while i < self.var_states.length() {
    let state = self.var_states[i]
    let new_state = VarState::new(state.get_var_id(), state.get_domain())
    new_states = new_states.push(new_state)
    i = i + 1
  }
  { var_states: new_states }
}

