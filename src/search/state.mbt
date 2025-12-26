// Copyright 2025
//
// Licensed under the Apache License, Version 2.0

///|
/// Variable identifier in search module (local alias for simplicity).
pub type VarId = Int

///|
/// Search-domain representation.
///
/// - `Interval(min, max)` represents a continuous range.
/// - `Bits(base_min, base_max, bits)` represents a (small) discrete set inside [base_min, base_max].
///   bit i corresponds to value (base_min + i).
pub enum Domain {
  Interval(Int, Int)
  Bits(Int, Int, Int)
}

///|
fn popcount(x0 : Int) -> Int {
  let mut x = x0
  let mut c = 0
  while x != 0 {
    x = x & (x - 1)
    c = c + 1
  }
  c
}

///|
fn bits_full(span : Int) -> Int {
  // span is (max - min), so we need (span + 1) bits.
  // assume 0 <= span <= 60
  (1 << (span + 1)) - 1
}

///|
/// Create a domain [min, max].
/// For small ranges (<= 61 values) we use `Bits` so we can remove single values (needed for Sudoku).
pub fn Domain::new(min : Int, max : Int) -> Domain {
  if min > max {
    Interval(min, max)
  } else {
    let span = max - min
    if span <= 60 {
      Bits(min, max, bits_full(span))
    } else {
      Interval(min, max)
    }
  }
}

///|
pub fn Domain::singleton(value : Int) -> Domain {
  Bits(value, value, 1)
}

///|
pub fn Domain::is_empty(self : Domain) -> Bool {
  match self {
    Interval(min, max) => min > max
    Bits(_, _, bits) => bits == 0
  }
}

///|
pub fn Domain::is_fixed(self : Domain) -> Bool {
  match self {
    Interval(min, max) => min == max
    Bits(_, _, bits) => bits != 0 && (bits & (bits - 1)) == 0
  }
}

///|
pub fn Domain::size(self : Domain) -> Int {
  match self {
    Interval(min, max) => if min > max { 0 } else { max - min + 1 }
    Bits(_, _, bits) => popcount(bits)
  }
}

///|
pub fn Domain::get_min(self : Domain) -> Int {
  match self {
    Interval(min, _) => min
    Bits(base_min, base_max, bits) =>
      if bits == 0 {
        base_max + 1
      } else {
        let mut i = 0
        let span = base_max - base_min
        while i <= span {
          if ((bits >> i) & 1) == 1 {
            return base_min + i
          }
          i = i + 1
        }
        base_max + 1
      }
  }
}

///|
pub fn Domain::get_max(self : Domain) -> Int {
  match self {
    Interval(_, max) => max
    Bits(base_min, base_max, bits) =>
      if bits == 0 {
        base_min - 1
      } else {
        let mut i = base_max - base_min
        while i >= 0 {
          if ((bits >> i) & 1) == 1 {
            return base_min + i
          }
          i = i - 1
        }
        base_min - 1
      }
  }
}

///|
pub fn Domain::contains(self : Domain, value : Int) -> Bool {
  match self {
    Interval(min, max) => min <= value && value <= max
    Bits(base_min, base_max, bits) =>
      if value < base_min || value > base_max {
        false
      } else {
        let i = value - base_min
        ((bits >> i) & 1) == 1
      }
  }
}

///|
pub fn Domain::get_value(self : Domain) -> Int? {
  if self.is_fixed() {
    Some(self.get_min())
  } else {
    None
  }
}

///|
/// Equality check (exact for small `Bits` domains).
pub fn Domain::equals(self : Domain, other : Domain) -> Bool {
  match (self, other) {
    (Interval(a, b), Interval(c, d)) => a == c && b == d
    (Bits(a0, a1, ab), Bits(b0, b1, bb)) => a0 == b0 && a1 == b1 && ab == bb
    _ => {
      // fallback: compare value sets for small spans
      let min = if self.get_min() < other.get_min() {
        self.get_min()
      } else {
        other.get_min()
      }
      let max = if self.get_max() > other.get_max() {
        self.get_max()
      } else {
        other.get_max()
      }
      let span = max - min
      if span <= 60 {
        let mut i = min
        while i <= max {
          if self.contains(i) != other.contains(i) {
            return false
          }
          i = i + 1
        }
        true
      } else {
        false
      }
    }
  }
}

///|
/// Remove a single value from the domain (may create holes; uses Bits when possible).
pub fn Domain::remove_value(self : Domain, value : Int) -> Domain {
  match self {
    Interval(min, max) =>
      if value < min || value > max {
        Interval(min, max)
      } else if min == max {
        Interval(1, 0)
      } else if value == min {
        Domain::new(min + 1, max)
      } else if value == max {
        Domain::new(min, max - 1)
      } else {
        let span = max - min
        if span <= 60 {
          let mut bits = bits_full(span)
          let i = value - min
          bits = bits & (bits ^ (1 << i))
          Bits(min, max, bits)
        } else {
          // can't represent holes in large interval
          Interval(min, max)
        }
      }
    Bits(base_min, base_max, bits) =>
      if value < base_min || value > base_max {
        Bits(base_min, base_max, bits)
      } else {
        let i = value - base_min
        Bits(base_min, base_max, bits & (bits ^ (1 << i)))
      }
  }
}

///|
/// Intersect with a closed interval [lo, hi].
pub fn Domain::intersect_interval(self : Domain, lo : Int, hi : Int) -> Domain {
  if lo > hi {
    return Interval(1, 0)
  }
  match self {
    Interval(min, max) => {
      let nmin = if min > lo { min } else { lo }
      let nmax = if max < hi { max } else { hi }
      Domain::new(nmin, nmax)
    }
    Bits(base_min, base_max, bits) => {
      let nmin = if base_min > lo { base_min } else { lo }
      let nmax = if base_max < hi { base_max } else { hi }
      if nmin > nmax {
        Interval(1, 0)
      } else {
        let span = nmax - nmin
        if span <= 60 {
          let mut nb = 0
          let mut v = nmin
          while v <= nmax {
            if Domain::contains(Bits(base_min, base_max, bits), v) {
              nb = nb | (1 << (v - nmin))
            }
            v = v + 1
          }
          Bits(nmin, nmax, nb)
        } else {
          Interval(nmin, nmax)
        }
      }
    }
  }
}

///|
/// Intersect with another domain (exact for small spans).
pub fn Domain::intersect(self : Domain, other : Domain) -> Domain {
  if self.is_empty() || other.is_empty() {
    return Interval(1, 0)
  }
  let lo = if self.get_min() > other.get_min() {
    self.get_min()
  } else {
    other.get_min()
  }
  let hi = if self.get_max() < other.get_max() {
    self.get_max()
  } else {
    other.get_max()
  }
  if lo > hi {
    return Interval(1, 0)
  }
  let span = hi - lo
  if span <= 60 {
    let mut bits = 0
    let mut v = lo
    while v <= hi {
      if self.contains(v) && other.contains(v) {
        bits = bits | (1 << (v - lo))
      }
      v = v + 1
    }
    Bits(lo, hi, bits)
  } else {
    // best-effort: interval overlap
    Interval(lo, hi)
  }
}

///|
/// Variable state during search.
/// Tracks the current domain of each variable.
pub struct VarState {
  var_id : VarId
  domain : Domain
}

///|
/// Create a variable state.
pub fn VarState::new(var_id : VarId, domain : Domain) -> VarState {
  { var_id, domain }
}

///|
/// Get the variable ID.
pub fn VarState::get_var_id(self : VarState) -> VarId {
  self.var_id
}

///|
/// Get the current domain.
pub fn VarState::get_domain(self : VarState) -> Domain {
  self.domain
}

///|
/// Update the domain (returns new state).
pub fn VarState::set_domain(self : VarState, domain : Domain) -> VarState {
  { var_id: self.var_id, domain }
}

///|
/// Search state - tracks all variable domains during search.
pub struct SearchState {
  var_states : Array[VarState]
}

///|
/// Create a new search state with initial domains for all variables.
pub fn SearchState::new(var_states : Array[VarState]) -> SearchState {
  { var_states, }
}

///|
/// Get the state of a specific variable.
pub fn SearchState::get_var_state(
  self : SearchState,
  var_id : VarId,
) -> VarState? {
  let mut i = 0
  while i < self.var_states.length() {
    let state = self.var_states[i]
    if state.get_var_id() == var_id {
      return Some(state)
    }
    i = i + 1
  }
  None
}

///|
/// Get the domain of a specific variable.
pub fn SearchState::get_domain(self : SearchState, var_id : VarId) -> Domain? {
  match self.get_var_state(var_id) {
    Some(state) => Some(state.get_domain())
    None => None
  }
}

///|
/// Update the domain of a variable (returns new state).
pub fn SearchState::set_domain(
  self : SearchState,
  var_id : VarId,
  domain : Domain,
) -> SearchState {
  let mut i = 0
  let mut found = false
  let mut new_states : Array[VarState] = []
  while i < self.var_states.length() {
    let state = self.var_states[i]
    if state.get_var_id() == var_id {
      new_states = [..new_states, state.set_domain(domain)]
      found = true
    } else {
      new_states = [..new_states, state]
    }
    i = i + 1
  }
  if !found {
    new_states = [..new_states, VarState::new(var_id, domain)]
  }
  SearchState::{ var_states: new_states }
}

///|
/// Check if all variables are fixed (assigned).
pub fn SearchState::all_fixed(self : SearchState) -> Bool {
  let mut i = 0
  while i < self.var_states.length() {
    let state = self.var_states[i]
    if !state.get_domain().is_fixed() {
      return false
    }
    i = i + 1
  }
  true
}

///|
/// Check if any variable has an empty domain (failure).
pub fn SearchState::has_empty_domain(self : SearchState) -> Bool {
  let mut i = 0
  while i < self.var_states.length() {
    let state = self.var_states[i]
    if state.get_domain().is_empty() {
      return true
    }
    i = i + 1
  }
  false
}

///|
/// Get all variable states.
pub fn SearchState::get_all_states(self : SearchState) -> Array[VarState] {
  self.var_states
}

///|
/// Get the number of unfixed variables.
pub fn SearchState::unfixed_count(self : SearchState) -> Int {
  let mut count = 0
  let mut i = 0
  while i < self.var_states.length() {
    let state = self.var_states[i]
    if !state.get_domain().is_fixed() {
      count = count + 1
    }
    i = i + 1
  }
  count
}

///|
/// Create a copy of the search state (for backtracking).
pub fn SearchState::copy(self : SearchState) -> SearchState {
  // Deep copy of all variable states
  let mut new_states : Array[VarState] = []
  let mut i = 0
  while i < self.var_states.length() {
    let state = self.var_states[i]
    let new_state = VarState::new(state.get_var_id(), state.get_domain())
    new_states = [..new_states, new_state]
    i = i + 1
  }
  { var_states: new_states }
}
