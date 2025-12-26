// Copyright 2025
//
// Licensed under the Apache License, Version 2.0

///|
/// Domain representation for integer variables.
/// Currently supports continuous intervals [min, max].
/// Future: may extend to sparse sets for non-contiguous domains.
pub struct Domain {
  min : Int
  max : Int
}

///|
/// Create a domain representing a continuous interval [min, max] (inclusive).
/// Returns None if min > max (invalid domain).
pub fn Domain::new(min : Int, max : Int) -> Domain? {
  if min > max {
    None
  } else {
    Some({ min, max })
  }
}

///|
/// Create a domain from a single value (fixed domain).
pub fn Domain::from_value(value : Int) -> Domain {
  { min: value, max: value }
}

///|
/// Create a domain representing all integers (unbounded).
/// For practical purposes, we use a large range.
/// In real implementation, this might need special handling.
pub fn Domain::unbounded() -> Domain {
  { min: -2147483648, max: 2147483647 }
}

///|
/// Get the minimum value in the domain.
pub fn Domain::get_min(self : Domain) -> Int {
  self.min
}

///|
/// Get the maximum value in the domain.
pub fn Domain::get_max(self : Domain) -> Int {
  self.max
}

///|
/// Get the size of the domain (number of possible values).
pub fn Domain::size(self : Domain) -> Int {
  if self.max < self.min {
    0
  } else {
    self.max - self.min + 1
  }
}

///|
/// Check if the domain is empty (no values).
pub fn Domain::is_empty(self : Domain) -> Bool {
  self.min > self.max
}

///|
/// Check if the domain is fixed (contains exactly one value).
pub fn Domain::is_fixed(self : Domain) -> Bool {
  self.min == self.max
}

///|
/// Get the fixed value if the domain is fixed, None otherwise.
pub fn Domain::get_value(self : Domain) -> Int? {
  if self.is_fixed() {
    Some(self.min)
  } else {
    None
  }
}

///|
/// Check if a value is in the domain.
pub fn Domain::contains(self : Domain, value : Int) -> Bool {
  self.min <= value && value <= self.max
}

///|
/// Remove a value from the domain by splitting into two intervals.
/// Returns the resulting domains after removal.
/// If value is at boundary, returns a single smaller domain.
/// If value is not in domain, returns original domain unchanged.
/// 
/// Note: This returns an array of domains. For interval domains,
/// removal of a single value creates a "hole", which would require
/// sparse set representation. For now, we return empty array if
/// removal would create a hole (indicating we need sparse sets).
/// 
/// TODO: Implement sparse set domain for non-contiguous domains.
pub fn Domain::remove(self : Domain, value : Int) -> Array[Domain] {
  if !self.contains(value) {
    [self]
  } else if self.is_fixed() {
    // Removing the only value makes domain empty
    []
  } else if value == self.min {
    // Remove from left boundary
    match Domain::new(self.min + 1, self.max) {
      None => []
      Some(d) => [d]
    }
  } else if value == self.max {
    // Remove from right boundary
    match Domain::new(self.min, self.max - 1) {
      None => []
      Some(d) => [d]
    }
  } else {
    // Removing from middle creates a hole - requires sparse set
    // For now, return empty to indicate we can't handle this
    // In full implementation, this would create a sparse set domain
    []
  }
}

///|
/// Remove all values less than the given value.
/// Returns None if domain becomes empty.
pub fn Domain::remove_below(self : Domain, value : Int) -> Domain? {
  let new_min = if value > self.min { value } else { self.min }
  Domain::new(new_min, self.max)
}

///|
/// Remove all values greater than the given value.
/// Returns None if domain becomes empty.
pub fn Domain::remove_above(self : Domain, value : Int) -> Domain? {
  let new_max = if value < self.max { value } else { self.max }
  Domain::new(self.min, new_max)
}

///|
/// Compute the intersection of two domains.
/// Returns None if intersection is empty.
pub fn Domain::intersect(self : Domain, other : Domain) -> Domain? {
  let new_min = if self.min > other.min { self.min } else { other.min }
  let new_max = if self.max < other.max { self.max } else { other.max }
  Domain::new(new_min, new_max)
}

///|
/// Check if two domains have any overlap.
pub fn Domain::overlaps(self : Domain, other : Domain) -> Bool {
  self.min <= other.max && other.min <= self.max
}

///|
/// Check if this domain is a subset of another domain.
pub fn Domain::is_subset(self : Domain, other : Domain) -> Bool {
  other.min <= self.min && self.max <= other.max
}

///|
/// Check if this domain equals another domain.
pub fn Domain::equals(self : Domain, other : Domain) -> Bool {
  self.min == other.min && self.max == other.max
}

///|
/// Create a copy of the domain.
pub fn Domain::copy(self : Domain) -> Domain {
  { min: self.min, max: self.max }
}
