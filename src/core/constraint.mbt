// Copyright 2025
//
// Licensed under the Apache License, Version 2.0

import variable { VarId }

///|
/// Constraint identifier for internal use.
pub type ConstraintId = Int

///|
/// Equality constraint: x == y
/// Both variables must have the same value in any solution.
pub struct Equal {
  id: ConstraintId
  x: VarId
  y: VarId
}

///|
/// Inequality constraint: x != y
/// Variables must have different values in any solution.
pub struct NotEqual {
  id: ConstraintId
  x: VarId
  y: VarId
}

///|
/// Linear inequality constraint: sum(coefficients[i] * vars[i]) <= constant
/// Represents linear constraints like x + 2*y <= 10
pub struct LinearLe {
  id: ConstraintId
  vars: Array[VarId]
  coefficients: Array[Int]
  constant: Int
}

///|
/// AllDifferent constraint: all variables must have distinct values.
/// Commonly used in scheduling, resource allocation, and assignment problems.
pub struct AllDifferent {
  id: ConstraintId
  vars: Array[VarId]
}

///|
/// Member constraint: variable must be in the given domain.
/// Represents constraints like x in [a, b] or x in {v1, v2, v3, ...}
pub struct Member {
  id: ConstraintId
  var: VarId
  min: Int
  max: Int
}

///|
/// Create an equality constraint: x == y
pub fn Equal::new(id: ConstraintId, x: VarId, y: VarId) -> Equal {
  { id: id, x: x, y: y }
}

///|
/// Create an inequality constraint: x != y
pub fn NotEqual::new(id: ConstraintId, x: VarId, y: VarId) -> NotEqual {
  { id: id, x: x, y: y }
}

///|
/// Create a linear inequality constraint.
/// The constraint is: sum(coefficients[i] * vars[i]) <= constant
/// 
/// Example: LinearLe::new(id, [x_id, y_id], [1, 2], 10)
/// represents: x + 2*y <= 10
pub fn LinearLe::new(id: ConstraintId, vars: Array[VarId], coefficients: Array[Int], constant: Int) -> LinearLe {
  { id: id, vars: vars, coefficients: coefficients, constant: constant }
}

///|
/// Create an AllDifferent constraint.
/// All variables in the array must have distinct values.
pub fn AllDifferent::new(id: ConstraintId, vars: Array[VarId]) -> AllDifferent {
  { id: id, vars: vars }
}

///|
/// Create a member constraint: var in [min, max]
pub fn Member::new(id: ConstraintId, var: VarId, min: Int, max: Int) -> Member {
  { id: id, var: var, min: min, max: max }
}

///|
/// Get constraint ID.
pub fn Equal::get_id(self: Equal) -> ConstraintId {
  self.id
}

///|
/// Get constraint ID.
pub fn NotEqual::get_id(self: NotEqual) -> ConstraintId {
  self.id
}

///|
/// Get constraint ID.
pub fn LinearLe::get_id(self: LinearLe) -> ConstraintId {
  self.id
}

///|
/// Get constraint ID.
pub fn AllDifferent::get_id(self: AllDifferent) -> ConstraintId {
  self.id
}

///|
/// Get constraint ID.
pub fn Member::get_id(self: Member) -> ConstraintId {
  self.id
}

///|
/// Get the first variable in equality constraint.
pub fn Equal::get_x(self: Equal) -> VarId {
  self.x
}

///|
/// Get the second variable in equality constraint.
pub fn Equal::get_y(self: Equal) -> VarId {
  self.y
}

///|
/// Get the first variable in inequality constraint.
pub fn NotEqual::get_x(self: NotEqual) -> VarId {
  self.x
}

///|
/// Get the second variable in inequality constraint.
pub fn NotEqual::get_y(self: NotEqual) -> VarId {
  self.y
}

///|
/// Get the variables in linear constraint.
pub fn LinearLe::get_vars(self: LinearLe) -> Array[VarId] {
  self.vars
}

///|
/// Get the coefficients in linear constraint.
pub fn LinearLe::get_coefficients(self: LinearLe) -> Array[Int] {
  self.coefficients
}

///|
/// Get the constant term in linear constraint.
pub fn LinearLe::get_constant(self: LinearLe) -> Int {
  self.constant
}

///|
/// Get the variables in AllDifferent constraint.
pub fn AllDifferent::get_vars(self: AllDifferent) -> Array[VarId] {
  self.vars
}

///|
/// Get the variable in member constraint.
pub fn Member::get_var(self: Member) -> VarId {
  self.var
}

///|
/// Get the minimum value in member constraint domain.
pub fn Member::get_min(self: Member) -> Int {
  self.min
}

///|
/// Get the maximum value in member constraint domain.
pub fn Member::get_max(self: Member) -> Int {
  self.max
}
