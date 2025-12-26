// Copyright 2025
//
// Licensed under the Apache License, Version 2.0

///|
/// Local identifiers and search state stubs for CP layer.
pub type VarId = Int

///|
pub struct SearchState {
  has_empty : Bool
}

///|
pub fn SearchState::new_empty() -> SearchState {
  { has_empty: false }
}

///|
pub fn SearchState::has_empty_domain(self : SearchState) -> Bool {
  self.has_empty
}

///|
/// Propagator identifier (for statistics / tracing).
pub type PropagatorId = Int

///|
/// Propagation result.
/// - Propagated: domains tightened, returns updated state
/// - Failed: conflict detected (empty domain)
/// - NoChange: constraint already satisfied / no pruning
pub enum PropagationResult {
  Propagated(SearchState)
  Failed
  NoChange
}

///|
/// Propagator interface.
/// Each constraint type implements this to perform domain reduction.
pub trait Propagator {
  /// Propagate the constraint given current variable domains.
  /// Should be monotonic (only shrinks domains).
  propagate(self : Self, state : SearchState) -> PropagationResult

  /// Variables involved in this constraint (for wake-up scheduling).
  get_variables(self : Self) -> Array[VarId]
}

///|
/// Check if propagation result indicates success.
pub fn PropagationResult::is_success(self : PropagationResult) -> Bool {
  match self {
    Propagated(_) => true
    NoChange => true
    Failed => false
  }
}

///|
/// Check if propagation result indicates failure.
pub fn PropagationResult::is_failure(self : PropagationResult) -> Bool {
  match self {
    Failed => true
    _ => false
  }
}

///|
/// Extract the updated state from propagation result.
pub fn PropagationResult::get_state(self : PropagationResult) -> SearchState? {
  match self {
    Propagated(state) => Some(state)
    _ => None
  }
}
