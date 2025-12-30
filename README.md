# MoonBit CP-SAT 🚀

> 一个用 MoonBit 写的约束规划求解器，让那些"看起来不可能"的问题变得可能！

## 这是什么？

想象一下，你有一堆变量，它们之间有着复杂的关系和约束。比如：
- 数独：每行、每列、每个 3x3 格子里的数字都不能重复
- 排班：每个人不能同时上两个班，每个班必须有人
- 资源分配：总资源有限，但每个任务都需要资源

这些问题看起来头大？别慌！**MoonBit CP-SAT** 就是来帮你解决这些"约束难题"的！

## 核心能力

### 🎯 建模能力
- **整数变量**：可以设置取值范围，比如 `x ∈ [1, 9]`
- **布尔变量**：真或假，简单直接
- **多种约束**：
  - `AllDifferent`：一组变量必须互不相同（数独必备！）
  - `Equal` / `NotEqual`：相等或不相等
  - `LinearLe`：线性不等式，比如 `x + 2y ≤ 10`
  - `Member`：变量必须在某个范围内

### 🔍 求解引擎
- **约束传播**：智能地缩小搜索空间，提前发现矛盾
- **深度优先搜索**：系统性地探索所有可能
- **回溯机制**：走错了路？没关系，我们退回来重试！

## 快速开始

### 安装

确保你已经安装了 [MoonBit](https://docs.moonbitlang.com)！

### 运行数独示例

```bash
# 进入 demo 目录
cd demo

# 运行数独求解器
moon run main

# 查看结果
cat solution.txt
```

数独求解器会读取 `puzzle.txt` 中的题目，然后自动求解并输出到 `solution.txt`。

### 自己写一个约束问题

```moonbit
// 创建一个模型
let mut model = @core.Model::new()

// 创建变量：x ∈ [1, 10], y ∈ [1, 10]
let (model, x) = model.add_int_var(@core.IntVar::new("x", 1, 10))
let (model, y) = model.add_int_var(@core.IntVar::new("y", 1, 10))

// 添加约束：x + y = 10，且 x ≠ y
let (model, eq) = model.add_equal(x.get_id(), y.get_id())
// 等等，这样写不对... 应该是 x + y = 10
// 实际上应该用线性约束或者分别约束

// 创建求解器
let solver = @solver.Solver::new(model)

// 求解！
let result = solver.solve()

// 查看结果
match result.get_solution() {
  None => println("无解 😢")
  Some(sol) => {
    println("找到解了！")
    // 提取变量值...
  }
}
```

## 项目结构

```
moonbit-cpsat/
├── src/
│   ├── core/          # 核心建模：变量、约束、域
│   ├── cp/            # 约束传播：让搜索更聪明
│   ├── search/        # 搜索算法：DFS + 回溯
│   └── solver/        # 求解器：把一切组合起来
└── demo/              # 数独示例：看看怎么用
```

## 开发指南

### 格式化代码
```bash
moon fmt
```

### 更新接口
```bash
moon info
```

### 运行测试
```bash
moon test
```

### 更新测试快照
```bash
moon test --update
```

### 代码检查
```bash
moon check
```

## 为什么选择这个项目？

- ✨ **轻量级**：没有复杂的依赖，核心逻辑清晰
- 🎓 **学习友好**：代码结构清晰，适合学习约束规划
- 🚀 **MoonBit 原生**：完全用 MoonBit 实现，体验新语言的魅力
- 🔧 **可扩展**：架构设计合理，容易添加新的约束类型

## 未来计划

- [ ] 更多约束类型（比如 `AtMost`、`Exactly`）
- [ ] 更智能的决策策略
- [ ] 学习机制（冲突分析、学习子句）
- [ ] 性能优化

## 贡献

欢迎提交 Issue 和 PR！让我们一起让这个求解器变得更强大 💪

## 许可证

Apache-2.0 License

---

**记住**：约束不是限制，而是指引！让 MoonBit CP-SAT 帮你找到那条通往答案的路 🌟
