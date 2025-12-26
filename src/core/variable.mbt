// Copyright 2025
//
// Licensed under the Apache License, Version 2.0

///|
/// Variable identifier for internal use in the solver.
/// Variables are identified by unique integer IDs.
pub type VarId = Int

///|
/// Integer variable in CP-SAT model.
/// Represents a decision variable that can take integer values within a domain.
pub struct IntVar {
  id : VarId
  name : String
  min : Int
  max : Int
}

///|
/// Boolean variable in CP-SAT model.
/// Represents a decision variable that can be true or false.
/// Internally, BoolVar is a special case of IntVar with domain [0, 1].
pub struct BoolVar {
  id : VarId
  name : String
}

///|
/// Create a new integer variable with given name and domain bounds.
/// The domain is [min, max] (inclusive).
/// ID will be assigned by the model when registered.
pub fn IntVar::new(name : String, min : Int, max : Int) -> IntVar {
  { id: -1, name, min, max }
}

///|
/// Create a new boolean variable with given name.
pub fn BoolVar::new(name : String) -> BoolVar {
  { id: -1, name }
}

///|
/// Get the variable ID.
pub fn IntVar::get_id(self : IntVar) -> VarId {
  self.id
}

///|
/// Get the variable ID.
pub fn BoolVar::get_id(self : BoolVar) -> VarId {
  self.id
}

///|
/// Get the variable name.
pub fn IntVar::get_name(self : IntVar) -> String {
  self.name
}

///|
/// Get the variable name.
pub fn BoolVar::get_name(self : BoolVar) -> String {
  self.name
}

///|
/// Get the minimum value in the domain.
pub fn IntVar::get_min(self : IntVar) -> Int {
  self.min
}

///|
/// Get the maximum value in the domain.
pub fn IntVar::get_max(self : IntVar) -> Int {
  self.max
}

///|
/// Get the domain size (number of possible values).
pub fn IntVar::domain_size(self : IntVar) -> Int {
  if self.max < self.min {
    0
  } else {
    self.max - self.min + 1
  }
}

///|
/// Check if the variable is fixed (domain has only one value).
/// This is a modeling-time check, actual fixing happens during search.
pub fn IntVar::is_fixed(self : IntVar) -> Bool {
  self.min == self.max
}

///|
/// Convert boolean variable to integer variable for unified handling.
/// BoolVar -> IntVar with domain [0, 1]
pub fn BoolVar::to_int_var(self : BoolVar) -> IntVar {
  { id: self.id, name: self.name, min: 0, max: 1 }
}

///|
/// Set the variable ID (internal use, called by model when registering).
pub fn IntVar::set_id(self : IntVar, id : VarId) -> IntVar {
  { id, name: self.name, min: self.min, max: self.max }
}

///|
/// Set the variable ID (internal use, called by model when registering).
pub fn BoolVar::set_id(self : BoolVar, id : VarId) -> BoolVar {
  { id, name: self.name }
}

///|
/// Check if variable domain is valid (min <= max).
pub fn IntVar::is_valid(self : IntVar) -> Bool {
  self.min <= self.max
}

///|
/// Check if a value is in the variable's domain.
pub fn IntVar::contains(self : IntVar, value : Int) -> Bool {
  self.min <= value && value <= self.max
}
