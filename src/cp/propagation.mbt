// Copyright 2025
//
// Licensed under the Apache License, Version 2.0

///|
/// Propagation engine (stub implementation).
pub struct PropagationEngine {}

///|
pub fn PropagationEngine::new() -> PropagationEngine {
  PropagationEngine::{  }
}

///|
/// 迭代传播直到不再变化或发现冲突。当前为占位实现：直接返回输入状态。
pub fn PropagationEngine::propagate(
  _self : PropagationEngine,
  state : SearchState,
) -> SearchState? {
  if state.has_empty_domain() {
    None
  } else {
    Some(state)
  }
}

///|
/// 单约束传播（占位），直接返回 NoChange。
pub fn PropagationEngine::propagate_constraint(
  _self : PropagationEngine,
  state : SearchState,
) -> PropagationResult {
  if state.has_empty_domain() {
    Failed
  } else {
    NoChange
  }
}

///|
/// 传播器数量（占位，未注册传播器）
pub fn PropagationEngine::constraint_count(_self : PropagationEngine) -> Int {
  0
}
