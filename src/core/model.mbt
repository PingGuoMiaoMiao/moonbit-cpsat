// Copyright 2025
//
// Licensed under the Apache License, Version 2.0

import variable { IntVar, BoolVar, VarId }
import constraint { ConstraintId, Equal, NotEqual, LinearLe, AllDifferent, Member }

///|
/// Model builder for CP-SAT problems.
/// Users create variables and add constraints through this interface.
pub struct Model {
  next_var_id: VarId
  next_constraint_id: ConstraintId
  int_vars: Array[IntVar]
  bool_vars: Array[BoolVar]
  constraints: Array[Constraint]
}

///|
/// Constraint type union for storing different constraint types.
pub enum Constraint {
  CEqual(Equal)
  CNotEqual(NotEqual)
  CLinearLe(LinearLe)
  CAllDifferent(AllDifferent)
  CMember(Member)
}

///|
/// Create a new empty model.
pub fn Model::new() -> Model {
  {
    next_var_id: 0
    next_constraint_id: 0
    int_vars: []
    bool_vars: []
    constraints: []
  }
}

///|
/// Add an integer variable to the model.
/// Returns the variable with assigned ID.
pub fn Model::add_int_var(mut self: Model, var: IntVar) -> (Model, IntVar) {
  let assigned_var = var.set_id(self.next_var_id)
  self.next_var_id = self.next_var_id + 1
  self.int_vars = self.int_vars.push(assigned_var)
  (self, assigned_var)
}

///|
/// Add a boolean variable to the model.
/// Returns the variable with assigned ID.
pub fn Model::add_bool_var(mut self: Model, var: BoolVar) -> (Model, BoolVar) {
  let assigned_var = var.set_id(self.next_var_id)
  self.next_var_id = self.next_var_id + 1
  self.bool_vars = self.bool_vars.push(assigned_var)
  (self, assigned_var)
}

///|
/// Add an equality constraint: x == y
pub fn Model::add_equal(mut self: Model, x: VarId, y: VarId) -> Model {
  let constraint = Equal::new(self.next_constraint_id, x, y)
  self.next_constraint_id = self.next_constraint_id + 1
  self.constraints = self.constraints.push(CEqual(constraint))
  self
}

///|
/// Add an inequality constraint: x != y
pub fn Model::add_not_equal(mut self: Model, x: VarId, y: VarId) -> Model {
  let constraint = NotEqual::new(self.next_constraint_id, x, y)
  self.next_constraint_id = self.next_constraint_id + 1
  self.constraints = self.constraints.push(CNotEqual(constraint))
  self
}

///|
/// Add a linear inequality constraint: sum(coefficients[i] * vars[i]) <= constant
pub fn Model::add_linear_le(mut self: Model, vars: Array[VarId], coefficients: Array[Int], constant: Int) -> Model {
  let constraint = LinearLe::new(self.next_constraint_id, vars, coefficients, constant)
  self.next_constraint_id = self.next_constraint_id + 1
  self.constraints = self.constraints.push(CLinearLe(constraint))
  self
}

///|
/// Add an AllDifferent constraint: all variables must have distinct values.
pub fn Model::add_all_different(mut self: Model, vars: Array[VarId]) -> Model {
  let constraint = AllDifferent::new(self.next_constraint_id, vars)
  self.next_constraint_id = self.next_constraint_id + 1
  self.constraints = self.constraints.push(CAllDifferent(constraint))
  self
}

///|
/// Add a member constraint: var in [min, max]
pub fn Model::add_member(mut self: Model, var: VarId, min: Int, max: Int) -> Model {
  let constraint = Member::new(self.next_constraint_id, var, min, max)
  self.next_constraint_id = self.next_constraint_id + 1
  self.constraints = self.constraints.push(CMember(constraint))
  self
}

///|
/// Get all integer variables in the model.
pub fn Model::get_int_vars(self: Model) -> Array[IntVar] {
  self.int_vars
}

///|
/// Get all boolean variables in the model.
pub fn Model::get_bool_vars(self: Model) -> Array[BoolVar] {
  self.bool_vars
}

///|
/// Get all constraints in the model.
pub fn Model::get_constraints(self: Model) -> Array[Constraint] {
  self.constraints
}

///|
/// Get the number of variables in the model.
pub fn Model::var_count(self: Model) -> Int {
  self.int_vars.length() + self.bool_vars.length()
}

///|
/// Get the number of constraints in the model.
pub fn Model::constraint_count(self: Model) -> Int {
  self.constraints.length()
}

///|
/// Validate the model (check variable references are valid).
/// Returns true if valid, false otherwise.
/// TODO: Implement detailed validation with error messages.
pub fn Model::validate(self: Model) -> Bool {
  // Basic check: ensure we have variables and constraints reference valid variable IDs
  let max_var_id = self.next_var_id - 1
  let mut valid = true
  let mut i = 0
  while i < self.constraints.length() {
    let constraint = self.constraints[i]
    match constraint {
      CEqual(c) => {
        if c.get_x() < 0 || c.get_x() > max_var_id || c.get_y() < 0 || c.get_y() > max_var_id {
          valid = false
          break
        }
      }
      CNotEqual(c) => {
        if c.get_x() < 0 || c.get_x() > max_var_id || c.get_y() < 0 || c.get_y() > max_var_id {
          valid = false
          break
        }
      }
      CLinearLe(c) => {
        let vars = c.get_vars()
        let mut j = 0
        while j < vars.length() {
          if vars[j] < 0 || vars[j] > max_var_id {
            valid = false
            break
          }
          j = j + 1
        }
        if !valid {
          break
        }
      }
      CAllDifferent(c) => {
        let vars = c.get_vars()
        let mut j = 0
        while j < vars.length() {
          if vars[j] < 0 || vars[j] > max_var_id {
            valid = false
            break
          }
          j = j + 1
        }
        if !valid {
          break
        }
      }
      CMember(c) => {
        if c.get_var() < 0 || c.get_var() > max_var_id {
          valid = false
          break
        }
      }
    }
    i = i + 1
  }
  valid
}

