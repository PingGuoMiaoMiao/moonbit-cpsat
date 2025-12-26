// Copyright 2025
//
// Licensed under the Apache License, Version 2.0

///|
/// Solver result status.
pub enum SolveStatus {
  Sat
  Unsat
  Unknown
}

///|
/// Solver-level variable identifier (mirrors core/search VarId for now).
pub type VarId = Int

///|
/// Solution is a list of (VarId, value) assignments.
pub struct Solution {
  assignments : Array[(VarId, Int)]
}

///|
pub fn Solution::new() -> Solution {
  Solution::{ assignments: [] }
}

///|
/// Add an assignment (immutable).
pub fn Solution::add(self : Solution, var_id : VarId, value : Int) -> Solution {
  Solution::{ assignments: [..self.assignments, (var_id, value)] }
}

///|
/// Get an assignment value, if present.
pub fn Solution::get(self : Solution, var_id : VarId) -> Int? {
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
pub fn Solution::get_assignments(self : Solution) -> Array[(VarId, Int)] {
  self.assignments
}

///|
pub struct SolveResult {
  status : SolveStatus
  solution : Solution?
}

///|
pub fn SolveResult::sat(solution : Solution) -> SolveResult {
  SolveResult::{ status: Sat, solution: Some(solution) }
}

///|
pub fn SolveResult::unsat() -> SolveResult {
  SolveResult::{ status: Unsat, solution: None }
}

///|
pub fn SolveResult::unknown() -> SolveResult {
  SolveResult::{ status: Unknown, solution: None }
}

///|
pub fn SolveResult::get_status(self : SolveResult) -> SolveStatus {
  self.status
}

///|
pub fn SolveResult::get_solution(self : SolveResult) -> Solution? {
  self.solution
}
