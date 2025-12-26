// Copyright 2025
//
// Licensed under the Apache License, Version 2.0

///|
/// Decision level in the search tree.
pub type DecisionLevel = Int

///|
/// A decision point in the search tree.
/// Records a variable assignment decision.
pub struct Decision {
  level : DecisionLevel
  var_id : VarId
  value : Int
}

///|
/// Create a decision.
pub fn Decision::new(
  level : DecisionLevel,
  var_id : VarId,
  value : Int,
) -> Decision {
  { level, var_id, value }
}

///|
/// Get the decision level.
pub fn Decision::get_level(self : Decision) -> DecisionLevel {
  self.level
}

///|
/// Get the variable ID in this decision.
pub fn Decision::get_var_id(self : Decision) -> VarId {
  self.var_id
}

///|
/// Get the value assigned in this decision.
pub fn Decision::get_value(self : Decision) -> Int {
  self.value
}

///|
/// A checkpoint captures search state at a specific decision level.
pub struct Checkpoint {
  level : DecisionLevel
  state : SearchState
}

///|
/// Backtrack trail - maintains a stack of search states for backtracking.
pub struct Trail {
  checkpoints : Array[Checkpoint]
  decisions : Array[Decision]
  current_level : DecisionLevel
}

///|
/// Create a new empty trail.
pub fn Trail::new() -> Trail {
  { checkpoints: [], decisions: [], current_level: 0 }
}

///|
/// Push a checkpoint (state snapshot at current level or given level).
pub fn Trail::push_checkpoint(
  self : Trail,
  level : DecisionLevel,
  state : SearchState,
) -> Trail {
  let cp = { level, state }
  Trail::{
    checkpoints: [..self.checkpoints, cp],
    decisions: self.decisions,
    current_level: self.current_level,
  }
}

///|
/// Push a decision onto the trail.
pub fn Trail::push_decision(self : Trail, decision : Decision) -> Trail {
  Trail::{
    checkpoints: self.checkpoints,
    decisions: [..self.decisions, decision],
    current_level: decision.get_level(),
  }
}

///|
/// Get the current decision level.
pub fn Trail::get_current_level(self : Trail) -> DecisionLevel {
  self.current_level
}

///|
/// Get the number of saved states.
pub fn Trail::state_count(self : Trail) -> Int {
  self.checkpoints.length()
}

///|
/// Get the number of decisions.
pub fn Trail::decision_count(self : Trail) -> Int {
  self.decisions.length()
}

///|
/// Pop states back to a specific decision level.
/// Returns the restored state and remaining trail.
pub fn Trail::backtrack_to_level(
  self : Trail,
  target_level : DecisionLevel,
) -> (SearchState, Trail) {
  // Filter checkpoints up to target_level, keep the last one
  let mut new_checkpoints : Array[Checkpoint] = []
  let mut restored_state = SearchState::new([])
  let mut i = 0
  while i < self.checkpoints.length() {
    let cp = self.checkpoints[i]
    if cp.level <= target_level {
      new_checkpoints = [..new_checkpoints, cp]
      restored_state = cp.state
    }
    i = i + 1
  }

  // Remove decisions at levels > target_level
  let mut new_decisions : Array[Decision] = []
  let mut j = 0
  while j < self.decisions.length() {
    let decision = self.decisions[j]
    if decision.get_level() <= target_level {
      new_decisions = [..new_decisions, decision]
    }
    j = j + 1
  }
  let new_trail = Trail::{
    checkpoints: new_checkpoints,
    decisions: new_decisions,
    current_level: target_level,
  }
  (restored_state, new_trail)
}

///|
/// Get the last decision.
pub fn Trail::get_last_decision(self : Trail) -> Decision? {
  if self.decisions.length() > 0 {
    Some(self.decisions[self.decisions.length() - 1])
  } else {
    None
  }
}

///|
/// Get all decisions at a specific level.
pub fn Trail::get_decisions_at_level(
  self : Trail,
  level : DecisionLevel,
) -> Array[Decision] {
  let mut result : Array[Decision] = []
  let mut i = 0
  while i < self.decisions.length() {
    let decision = self.decisions[i]
    if decision.get_level() == level {
      result = [..result, decision]
    }
    i = i + 1
  }
  result
}

///|
/// Check if the trail is empty (no decisions made).
pub fn Trail::is_empty(self : Trail) -> Bool {
  self.decisions.length() == 0
}

///|
/// Increment decision level and return new level.
pub fn Trail::next_level(self : Trail) -> DecisionLevel {
  self.current_level + 1
}

///|
/// TODO: add helper to record domain modifications incrementally instead of full state copies.
