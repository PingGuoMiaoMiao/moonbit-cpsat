// Copyright 2025
//
// Licensed under the Apache License, Version 2.0

import search/state { SearchState }

///|
/// Propagator identifier (for statistics / tracing).
pub type PropagatorId = Int

///|
/// Propagation status.
/// - Ok: returns possibly updated search state (domains tightened).
/// - Conflict: indicates inconsistency at current level.
pub enum PropagationStatus {
  Ok(SearchState)
  Conflict
}

///|
/// Propagator interface: each concrete constraint propagator should implement it.
pub trait Propagator {
  /// Propagate over the current search state.
  /// Should be idempotent and monotonic (only shrinks domains).
  propagate(self: Self, state: SearchState) -> PropagationStatus
}

///|
/// TODO: add explanation / reason objects to support conflict analysis (CLP/learning).
// Copyright 2025
//
// Licensed under the Apache License, Version 2.0

import variable { VarId }
import domain { Domain }
import search/state { SearchState }

///|
/// Propagation result.
pub enum PropagationResult {
  // Propagation succeeded, state may have been updated
  Propagated(SearchState)
  // Propagation failed (domain became empty), conflict detected
  Failed
  // No propagation needed (constraint already satisfied)
  NoChange
}

///|
/// Propagator interface.
/// Each constraint type implements this to perform domain reduction.
pub trait Propagator {
  // Propagate the constraint given current variable domains.
  // Returns updated state if propagation succeeded, or Failed if conflict detected.
  propagate(self: Self, state: SearchState) -> PropagationResult
  
  // Get variables involved in this constraint.
  get_variables(self: Self) -> Array[VarId]
}

///|
/// Check if propagation result indicates success.
pub fn PropagationResult::is_success(self: PropagationResult) -> Bool {
  match self {
    Propagated(_) => true
    NoChange => true
    Failed => false
  }
}

///|
/// Check if propagation result indicates failure.
pub fn PropagationResult::is_failure(self: PropagationResult) -> Bool {
  match self {
    Failed => true
    _ => false
  }
}

///|
/// Extract the updated state from propagation result.
pub fn PropagationResult::get_state(self: PropagationResult) -> Option[SearchState] {
  match self {
    Propagated(state) => Some(state)
    _ => None
  }
}

