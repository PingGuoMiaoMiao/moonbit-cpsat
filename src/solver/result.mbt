// Copyright 2025
//
// Licensed under the Apache License, Version 2.0

import search/state { SearchState }

///|
/// Solver status.
pub enum SolveStatus {
  Sat
  Unsat
  Unknown
}

///|
/// Solver result container.
pub struct SolveResult {
  status: SolveStatus
  state: Option[SearchState]
}

///|
pub fn SolveResult::sat(state: SearchState) -> SolveResult {
  { status: SolveStatus::Sat, state: Some(state) }
}

///|
pub fn SolveResult::unsat() -> SolveResult {
  { status: SolveStatus::Unsat, state: None }
}

///|
pub fn SolveResult::unknown() -> SolveResult {
  { status: SolveStatus::Unknown, state: None }
}

///|
pub fn SolveResult::get_status(self: SolveResult) -> SolveStatus {
  self.status
}

///|
pub fn SolveResult::get_state(self: SolveResult) -> Option[SearchState] {
  self.state
}
// Copyright 2025
//
// Licensed under the Apache License, Version 2.0

import variable { VarId }

///|
/// Solver result status.
pub enum SolveStatus {
  SAT       // Satisfiable - a solution was found
  UNSAT     // Unsatisfiable - no solution exists
  UNKNOWN   // Unknown - solver could not determine (timeout, etc.)
}

///|
/// Solution representation.
/// Maps variable IDs to their assigned values.
pub struct Solution {
  assignments: Array[(VarId, Int)]
}

///|
/// Create an empty solution.
pub fn Solution::new() -> Solution {
  { assignments: [] }
}

///|
/// Add a variable assignment to the solution.
pub fn Solution::add(mut self: Solution, var_id: VarId, value: Int) -> Solution {
  self.assignments = self.assignments.push((var_id, value))
  self
}

///|
/// Get the value assigned to a variable, or None if not assigned.
pub fn Solution::get(self: Solution, var_id: VarId) -> Option[Int] {
  let mut i = 0
  while i < self.assignments.length() {
    let (vid, val) = self.assignments[i]
    if vid == var_id {
      return Some(val)
    }
    i = i + 1
  }
  None
}

///|
/// Get all assignments as an array.
pub fn Solution::get_assignments(self: Solution) -> Array[(VarId, Int)] {
  self.assignments
}

///|
/// Check if a variable is assigned in this solution.
pub fn Solution::is_assigned(self: Solution, var_id: VarId) -> Bool {
  match self.get(var_id) {
    Some(_) => true
    None => false
  }
}

///|
/// Complete solver result.
pub struct SolveResult {
  status: SolveStatus
  solution: Option[Solution]
}

///|
/// Create a SAT result with a solution.
pub fn SolveResult::sat(solution: Solution) -> SolveResult {
  { status: SAT, solution: Some(solution) }
}

///|
/// Create an UNSAT result.
pub fn SolveResult::unsat() -> SolveResult {
  { status: UNSAT, solution: None }
}

///|
/// Create an UNKNOWN result.
pub fn SolveResult::unknown() -> SolveResult {
  { status: UNKNOWN, solution: None }
}

///|
/// Get the solve status.
pub fn SolveResult::get_status(self: SolveResult) -> SolveStatus {
  self.status
}

///|
/// Get the solution if available.
pub fn SolveResult::get_solution(self: SolveResult) -> Option[Solution] {
  self.solution
}

///|
/// Check if the result is SAT.
pub fn SolveResult::is_sat(self: SolveResult) -> Bool {
  match self.status {
    SAT => true
    _ => false
  }
}

///|
/// Check if the result is UNSAT.
pub fn SolveResult::is_unsat(self: SolveResult) -> Bool {
  match self.status {
    UNSAT => true
    _ => false
  }
}

///|
/// Check if the result is UNKNOWN.
pub fn SolveResult::is_unknown(self: SolveResult) -> Bool {
  match self.status {
    UNKNOWN => true
    _ => false
  }
}

