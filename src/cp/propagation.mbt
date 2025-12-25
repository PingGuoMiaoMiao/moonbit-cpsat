// Copyright 2025
//
// Licensed under the Apache License, Version 2.0

// Type aliases for cross-package imports
type SearchState = @search.state.SearchState
type PropagationStatus = @cp.propagator.PropagationStatus

///|
/// Propagation engine placeholder.
/// TODO: maintain a queue of propagators and iterate to fixpoint.
pub struct PropagationEngine {}

///|
pub fn PropagationEngine::new() -> PropagationEngine {
  {}
}

///|
/// Run propagation over current state.
/// For now, this is a stub returning Ok without changes.
/// Future: accept a list of propagators, enqueue constraints, iterate until stable or conflict.
pub fn PropagationEngine::run(self: PropagationEngine, state: SearchState) -> PropagationStatus {
  PropagationStatus::Ok(state)
}

///|
/// TODO:
/// - register propagators with IDs
/// - push initial events
/// - incremental wake-up based on domain changes
/// - conflict explanation hooks
// Copyright 2025
//
// Licensed under the Apache License, Version 2.0

import variable { VarId }
import search/state { SearchState }
import cp/propagator { Propagator, PropagationResult }

///|
/// Propagation engine.
/// Maintains a queue of constraints to propagate and coordinates propagation.
pub struct PropagationEngine {
  // Constraints to propagate (simplified: all constraints)
  // TODO: Implement proper constraint queue with dependency tracking
  constraints: Array[Propagator]
}

///|
/// Create a new propagation engine with constraints.
pub fn PropagationEngine::new(constraints: Array[Propagator]) -> PropagationEngine {
  { constraints: constraints }
}

///|
/// Propagate all constraints until fixpoint or failure.
/// Returns updated state if successful, or None if conflict detected.
pub fn PropagationEngine::propagate(mut self: PropagationEngine, state: SearchState) -> Option[SearchState] {
  let mut current_state = state
  let mut changed = true
  
  // Iterate until fixpoint (no more changes) or failure
  while changed {
    changed = false
    let mut i = 0
    
    while i < self.constraints.length() {
      let constraint = self.constraints[i]
      let result = constraint.propagate(current_state)
      
      match result {
        Propagated(new_state) => {
          current_state = new_state
          changed = true
        }
        Failed => {
          // Conflict detected
          return None
        }
        NoChange => {
          // No change, continue
        }
      }
      
      // Check if any domain became empty
      if current_state.has_empty_domain() {
        return None
      }
      
      i = i + 1
    }
  }
  
  Some(current_state)
}

///|
/// Propagate a single constraint.
/// Returns propagation result.
pub fn PropagationEngine::propagate_constraint(self: PropagationEngine, constraint: Propagator, state: SearchState) -> PropagationResult {
  constraint.propagate(state)
}

///|
/// Get the number of constraints in the engine.
pub fn PropagationEngine::constraint_count(self: PropagationEngine) -> Int {
  self.constraints.length()
}

