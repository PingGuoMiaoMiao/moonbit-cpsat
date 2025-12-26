///|
/// Sudoku demo:
/// - read `./demo/puzzle.txt` (9x9 digits, 0 means empty)
/// - solve with @solver.Solver
/// - write `./demo/solution.txt`
fn main {
  let input_path = "./demo/puzzle.txt"
  let output_path = "./demo/solution.txt"
  let content_res = try? @fs.read_file_to_string(input_path)
  let out = match content_res {
    Err(_) => "READ ERROR\n"
    Ok(content) => {
      let cells = parse_puzzle(content)
      let model = build_model(cells)
      let solver = @solver.Solver::new(model)
      let res = solver.solve()
      match res.get_solution() {
        None => "NO SOLUTION\n"
        Some(sol) => render_solution(sol)
      }
    }
  }
  let _ = try? @fs.write_string_to_file(output_path, out)
  println(out)
}

///|
fn parse_puzzle(s : String) -> Array[Int] {
  let mut vals : Array[Int] = []
  // avoid deprecated String::to_bytes()
  let bytes = @encoding.encode(UTF8, s)
  let mut i = 0
  while i < bytes.length() {
    let c = bytes[i]
    let ci = c.to_int()
    if ci >= 48 && ci <= 57 {
      vals = [..vals, ci - 48]
    }
    i = i + 1
  }
  if vals.length() != 81 {
    panic()
  }
  vals
}

///|
fn build_model(cells : Array[Int]) -> @core.Model {
  let mut m = @core.Model::new()
  let mut ids : Array[Int] = []

  // create vars
  let mut idx = 0
  while idx < 81 {
    let r = idx / 9
    let c = idx % 9
    let name = "v_" + r.to_string() + "_" + c.to_string()
    let v = cells[idx]
    let ivar = if v == 0 {
      @core.IntVar::new(name, 1, 9)
    } else {
      @core.IntVar::new(name, v, v)
    }
    let (m2, assigned) = m.add_int_var(ivar)
    m = m2
    ids = [..ids, assigned.get_id()]
    idx = idx + 1
  }

  // rows
  let mut r = 0
  while r < 9 {
    let mut row : Array[Int] = []
    let mut c = 0
    while c < 9 {
      row = [..row, ids[r * 9 + c]]
      c = c + 1
    }
    m = m.add_all_different(row)
    r = r + 1
  }

  // cols
  let mut c = 0
  while c < 9 {
    let mut col : Array[Int] = []
    let mut r = 0
    while r < 9 {
      col = [..col, ids[r * 9 + c]]
      r = r + 1
    }
    m = m.add_all_different(col)
    c = c + 1
  }

  // blocks
  let mut br = 0
  while br < 3 {
    let mut bc = 0
    while bc < 3 {
      let mut blk : Array[Int] = []
      let mut dr = 0
      while dr < 3 {
        let mut dc = 0
        while dc < 3 {
          let rr = br * 3 + dr
          let cc = bc * 3 + dc
          blk = [..blk, ids[rr * 9 + cc]]
          dc = dc + 1
        }
        dr = dr + 1
      }
      m = m.add_all_different(blk)
      bc = bc + 1
    }
    br = br + 1
  }
  m
}

///|
fn render_solution(sol : @solver.Solution) -> String {
  let assigns = sol.get_assignments()
  // ids are 0..80 in this demo (creation order), so build array directly
  let mut grid : Array[Int] = []
  let mut i = 0
  while i < 81 {
    grid = [..grid, 0]
    i = i + 1
  }
  let mut j = 0
  while j < assigns.length() {
    let (vid, v) = assigns[j]
    if vid >= 0 && vid < 81 {
      grid[vid] = v
    }
    j = j + 1
  }
  let mut out = ""
  let mut r = 0
  while r < 9 {
    let mut c = 0
    while c < 9 {
      out = out + grid[r * 9 + c].to_string()
      c = c + 1
    }
    out = out + "\n"
    r = r + 1
  }
  out
}
