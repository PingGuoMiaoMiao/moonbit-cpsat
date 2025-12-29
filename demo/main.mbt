///|
/// Sudoku demo:
/// - read `./demo/puzzle.txt` (9x9 digits, 0 means empty)
/// - solve with @solver.Solver
/// - write `./demo/solution.txt`

///|
/// 数独网格大小常量
const SIZE : Int = 9

///|
const BLOCK_SIZE : Int = 3

///|
const TOTAL_CELLS : Int = 81

///|
fn main {
  let input_path = "./demo/puzzle.txt"
  let output_path = "./demo/solution.txt"
  let content_res = try? @fs.read_file_to_string(input_path)
  let out = match content_res {
    Err(_) => "READ ERROR\n"
    Ok(content) => {
      let cells = parse_puzzle(content)
      let puzzle_str = render_grid(cells)
      let model = build_model(cells)
      let solver = @solver.Solver::new(model)
      let res = solver.solve()
      let solution_str = match res.get_solution() {
        None => "NO SOLUTION\n"
        Some(sol) => {
          let grid = extract_grid(sol)
          render_grid(grid)
        }
      }
      "原题:\n" + puzzle_str + "\n解答:\n" + solution_str
    }
  }
  let _ = try? @fs.write_string_to_file(output_path, out)
  println(out)
}

///|
/// 解析数独题目字符串为整数数组
/// 只提取数字字符（'0'-'9'），忽略其他字符
fn parse_puzzle(s : String) -> Array[Int] {
  let mut vals : Array[Int] = []
  let bytes = @encoding.encode(UTF8, s)
  let mut i = 0
  while i < bytes.length() {
    let c = bytes[i]
    let ci = c.to_int()
    // '0' = 48, '9' = 57
    if ci >= 48 && ci <= 57 {
      vals = [..vals, ci - 48]
    }
    i = i + 1
  }
  if vals.length() != TOTAL_CELLS {
    panic()
  }
  vals
}

///|
/// 构建 CP-SAT 模型
fn build_model(cells : Array[Int]) -> @core.Model {
  let mut m = @core.Model::new()
  let mut ids : Array[Int] = []

  // 创建变量：空单元格为 [1,9]，已填数字为固定值
  let mut idx = 0
  while idx < TOTAL_CELLS {
    let row = idx / SIZE
    let col = idx % SIZE
    let name = "v_" + row.to_string() + "_" + col.to_string()
    let value = cells[idx]
    let ivar = if value == 0 {
      @core.IntVar::new(name, 1, SIZE)
    } else {
      @core.IntVar::new(name, value, value)
    }
    let (m2, assigned) = m.add_int_var(ivar)
    m = m2
    ids = [..ids, assigned.get_id()]
    idx = idx + 1
  }

  // 添加行约束：每行数字互不相同
  let mut row = 0
  while row < SIZE {
    m = m.add_all_different(get_row_ids(ids, row))
    row = row + 1
  }

  // 添加列约束：每列数字互不相同
  let mut col = 0
  while col < SIZE {
    m = m.add_all_different(get_col_ids(ids, col))
    col = col + 1
  }

  // 添加块约束：每个 3x3 块内数字互不相同
  let mut block_row = 0
  while block_row < BLOCK_SIZE {
    let mut block_col = 0
    while block_col < BLOCK_SIZE {
      m = m.add_all_different(get_block_ids(ids, block_row, block_col))
      block_col = block_col + 1
    }
    block_row = block_row + 1
  }
  m
}

///|
/// 获取指定行的变量 ID 数组
fn get_row_ids(ids : Array[Int], row : Int) -> Array[Int] {
  let mut result : Array[Int] = []
  let mut col = 0
  while col < SIZE {
    result = [..result, ids[row * SIZE + col]]
    col = col + 1
  }
  result
}

///|
/// 获取指定列的变量 ID 数组
fn get_col_ids(ids : Array[Int], col : Int) -> Array[Int] {
  let mut result : Array[Int] = []
  let mut row = 0
  while row < SIZE {
    result = [..result, ids[row * SIZE + col]]
    row = row + 1
  }
  result
}

///|
/// 获取指定块的变量 ID 数组
fn get_block_ids(
  ids : Array[Int],
  block_row : Int,
  block_col : Int,
) -> Array[Int] {
  let mut result : Array[Int] = []
  let mut dr = 0
  while dr < BLOCK_SIZE {
    let mut dc = 0
    while dc < BLOCK_SIZE {
      let row = block_row * BLOCK_SIZE + dr
      let col = block_col * BLOCK_SIZE + dc
      result = [..result, ids[row * SIZE + col]]
      dc = dc + 1
    }
    dr = dr + 1
  }
  result
}

///|
/// 从求解结果中提取网格数组
fn extract_grid(sol : @solver.Solution) -> Array[Int] {
  let assigns = sol.get_assignments()
  // 初始化网格为全 0
  let mut grid : Array[Int] = []
  let mut i = 0
  while i < TOTAL_CELLS {
    grid = [..grid, 0]
    i = i + 1
  }
  // 填充赋值结果
  let mut j = 0
  while j < assigns.length() {
    let (var_id, value) = assigns[j]
    if var_id >= 0 && var_id < TOTAL_CELLS {
      grid[var_id] = value
    }
    j = j + 1
  }
  grid
}

///|
/// 渲染 9x9 网格为字符串
fn render_grid(grid : Array[Int]) -> String {
  let mut result = ""
  let mut row = 0
  while row < SIZE {
    let mut col = 0
    while col < SIZE {
      result = result + grid[row * SIZE + col].to_string()
      col = col + 1
    }
    result = result + "\n"
    row = row + 1
  }
  result
}
