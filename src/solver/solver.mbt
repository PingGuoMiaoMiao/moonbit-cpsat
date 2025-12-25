// Copyright 2025
//
// Licensed under the Apache License, Version 2.0

// Type aliases for cross-package imports
type Domain = @core.domain.Domain
type SearchState = @search.state.SearchState
type Trail = @search.backtrack.Trail
type Decision = @search.backtrack.Decision
type DecisionLevel = @search.backtrack.DecisionLevel
type PropagationEngine = @cp.propagation.PropagationEngine
type PropagationStatus = @cp.propagator.PropagationStatus
type SolveResult = @solver.result.SolveResult
type SolveStatus = @solver.result.SolveStatus

///|
/// Top-level solver (DFS with basic propagation).
/// TODO: plug real propagators and better branching/restarts.
pub struct Solver {
  propagation: PropagationEngine
}

///|
pub fn Solver::new() -> Solver {
  { propagation: PropagationEngine::new() }
}

///|
/// Entry point: solve from an initial search state.
pub fn Solver::solve(self: Solver, state: SearchState) -> SolveResult {
  let trail = Trail::new()
  let (result, _) = self.dfs(state, trail, 0)
  result
}

///|
/// Depth-first search with trail-based backtracking.
fn Solver::dfs(self: Solver, state: SearchState, trail: Trail, level: DecisionLevel) -> (SolveResult, Trail) {
  // Propagate
  match self.propagation.run(state) {
    PropagationStatus::Conflict => {
      (SolveResult::unsat(), trail)
    }
    PropagationStatus::Ok(new_state) => {
      if new_state.all_fixed() {
        return (SolveResult::sat(new_state), trail)
      }

      // Choose decision
      match select_mrv(new_state) {
        None => (SolveResult::sat(new_state), trail)
        Some(decision) => {
          let next_level = trail.next_level()
          let trail_with_cp = trail
            .push_checkpoint(next_level, new_state.copy())
            .push_decision(Decision::new(next_level, decision.get_var_id(), decision.get_value()))

          // Assign chosen value (naive: pick min only)
          let assigned_domain = Domain::from_value(decision.get_value())
          let branched_state = new_state.set_domain(decision.get_var_id(), assigned_domain)

          let (res, trail_after) = self.dfs(branched_state, trail_with_cp, next_level)
          match res.get_status() {
            SolveStatus::Sat => (res, trail_after)
            _ => {
              // Backtrack to parent level
              let (restored, trail_back) = trail_after.backtrack_to_level(level)
              (SolveResult::unsat(), trail_back)
            }
          }
        }
      }
    }
  }
}

///|
/// TODO:
/// - Explore alternative values on conflict instead of immediate UNSAT.
/// - Add nogood recording / conflict analysis hooks.
/// - Integrate real propagators and event queues.
// Copyright 2025
//
// Licensed under the Apache License, Version 2.0

import variable { VarId, IntVar }
import domain { Domain }
import core/model { Model }
import search/state { SearchState, VarState }
import search/backtrack { Trail, Decision, DecisionLevel }
import search/decision { DecisionStrategy }
import solver/result { SolveResult, Solution, SolveStatus }
import cp/propagation { PropagationEngine }

///|
/// CP-SAT solver.
/// Coordinates model, search, and propagation to find solutions.
pub struct Solver {
  model: Model
  strategy: DecisionStrategy
  // TODO: Add propagation engine when constraint propagators are implemented
}

///|
/// Create a new solver from a model.
pub fn Solver::new(model: Model) -> Solver {
  {
    model: model
    strategy: DecisionStrategy::new()
  }
}

///|
/// Solve the model using depth-first search with backtracking.
/// This is a basic implementation - constraint propagation will be added later.
pub fn Solver::solve(self: Solver) -> SolveResult {
  // Initialize search state from model
  let initial_state = self.initialize_state()
  
  // Check if already solved (all variables fixed)
  if initial_state.all_fixed() {
    return self.extract_solution(initial_state)
  }
  
  // Check if already failed (empty domain)
  if initial_state.has_empty_domain() {
    return SolveResult::unsat()
  }
  
  // Start DFS search
  let trail = Trail::new()
  match self.search(initial_state, trail) {
    Some(solution_state) => self.extract_solution(solution_state)
    None => SolveResult::unsat()
  }
}

///|
/// Initialize search state from model.
fn Solver::initialize_state(self: Solver) -> SearchState {
  let mut var_states: Array[VarState] = []
  
  // Add integer variables
  let int_vars = self.model.get_int_vars()
  let mut i = 0
  while i < int_vars.length() {
    let var = int_vars[i]
    let domain = Domain::new(var.get_min(), var.get_max())
    let var_state = VarState::new(var.get_id(), domain)
    var_states = var_states.push(var_state)
    i = i + 1
  }
  
  // Add boolean variables (as integer variables with domain [0, 1])
  let bool_vars = self.model.get_bool_vars()
  let mut i = 0
  while i < bool_vars.length() {
    let var = bool_vars[i]
    let int_var = var.to_int_var()
    let domain = Domain::new(int_var.get_min(), int_var.get_max())
    let var_state = VarState::new(int_var.get_id(), domain)
    var_states = var_states.push(var_state)
    i = i + 1
  }
  
  SearchState::new(var_states)
}

///|
/// Depth-first search with backtracking.
fn Solver::search(self: Solver, state: SearchState, trail: Trail) -> Option[SearchState] {
  // Base case: all variables fixed
  if state.all_fixed() {
    return Some(state)
  }
  
  // Base case: empty domain (failure)
  if state.has_empty_domain() {
    return None
  }
  
  // Make a decision
  match self.strategy.make_decision(state) {
    Some((var_id, value)) => {
      // Try assigning the value
      match state.get_domain(var_id) {
        Some(domain) => {
          if domain.contains(value) {
            // Create new state with variable fixed to this value
            let new_domain = Domain::singleton(value)
            let new_state = state.set_domain(var_id, new_domain)
            
            // TODO: Propagate constraints here
            // For now, just continue search
            
            // Recursive search
            let next_level = trail.next_level()
            let decision = Decision::new(next_level, var_id, value)
            let new_trail = trail.push_decision(decision)
            
            match self.search(new_state, new_trail) {
              Some(solution) => Some(solution)
              None => {
                // Backtrack: try next value or return failure
                // For now, simple implementation: if assignment fails, return failure
                // TODO: Implement proper backtracking with alternative values
                None
              }
            }
          } else {
            // Value not in domain, failure
            None
          }
        }
        None => None  // Variable not found
      }
    }
    None => {
      // No decision possible (should not happen if state is valid)
      None
    }
  }
}

///|
/// Extract solution from search state.
fn Solver::extract_solution(self: Solver, state: SearchState) -> SolveResult {
  let mut solution = Solution::new()
  let var_states = state.get_all_states()
  
  let mut i = 0
  while i < var_states.length() {
    let var_state = var_states[i]
    let domain = var_state.get_domain()
    match domain.get_value() {
      Some(value) => {
        solution = solution.add(var_state.get_var_id(), value)
      }
      None => {
        // Variable not fixed - this should not happen in a complete solution
        // Return UNKNOWN
        return SolveResult::unknown()
      }
    }
    i = i + 1
  }
  
  SolveResult::sat(solution)
}

///|
/// Get the model.
pub fn Solver::get_model(self: Solver) -> Model {
  self.model
}

