import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import utils

type Coord {
  Coord(col: Int, row: Int)
}

type Line {
  Line(p1: Coord, p2: Coord)
}

type Rect {
  Rect(p1: Coord, p2: Coord)
}

fn get_input(path: String) -> List(Coord) {
  utils.get_input_lines(path)
  |> list.map(fn(s) {
    string.trim(s)
    |> string.split(",")
    |> list.map(fn(s) {
      let assert Ok(n) = int.parse(s)
      n
    })
  })
  |> list.map(fn(el) {
    case el {
      [c, r] -> Coord(c, r)
      _ -> panic as "Not valid coord in get_input"
    }
  })
}

pub fn day9p1(path: String) -> Int {
  let input = get_input(path)
  let pairs = list.combination_pairs(input)
  let res =
    list.fold(pairs, 0, fn(acc, pl) {
      case pl {
        #(Coord(c1, r1), Coord(c2, r2)) -> {
          let area =
            { int.absolute_value(r2 - r1) + 1 }
            * { int.absolute_value(c2 - c1) + 1 }
          int.max(area, acc)
        }
      }
    })
  io.println("Day 9 part 1 : " <> int.to_string(res))
  res
}

fn get_rows(lst: List(Coord)) {
  lst
  |> list.map(fn(p) { p.row })
  |> list.sort(int.compare)
  |> list.unique
}

fn get_columns(lst: List(Coord)) {
  lst
  |> list.map(fn(p) { p.col })
  |> list.sort(int.compare)
  |> list.unique
}

fn get_hor_lines(rows, points: List(Coord)) {
  rows
  |> list.map(fn(row) {
    let points = list.filter(points, fn(point) { point.row == row })
    points |> list.sized_chunk(2)
  })
  |> list.map(fn(points_at_row) {
    list.map(points_at_row, fn(points) {
      case points {
        [p1, p2] -> Line(p1, p2)
        _ -> panic as "should be pairwise points"
      }
    })
  })
}

fn get_vert_lines(cols: List(Int), points: List(Coord)) -> List(List(Line)) {
  cols
  |> list.map(fn(col) {
    let points = list.filter(points, fn(point) { point.col == col })
    points |> list.sized_chunk(2)
  })
  |> list.map(fn(points_at_col) {
    list.map(points_at_col, fn(points) {
      case points {
        [p1, p2] -> Line(p1, p2)
        _ -> panic as "should be pairwise points"
      }
    })
  })
}

fn is_crossing(hor_line: Line, vert_line: Line) -> Bool {
  let rv_top = int.min(vert_line.p1.row, vert_line.p2.row)
  let rv_bot = int.max(vert_line.p1.row, vert_line.p2.row)
  let ch_left = int.min(hor_line.p1.col, hor_line.p2.col)
  let ch_right = int.max(hor_line.p1.col, hor_line.p2.col)
  {
    hor_line.p1.row > rv_top
    && hor_line.p1.row < rv_bot
    && vert_line.p1.col > ch_left
    && vert_line.p1.col < ch_right
  }
}

fn is_inside_box(box: Rect, point: Coord) -> Bool {
  let top_row = int.min(box.p1.row, box.p2.row)
  let bot_row = int.max(box.p1.row, box.p2.row)
  let left_col = int.min(box.p1.col, box.p2.col)
  let right_col = int.max(box.p1.col, box.p2.col)
  point.col > left_col
  && point.col < right_col
  && point.row > top_row
  && point.row < bot_row
}

fn is_valid_rect(
  box: Rect,
  hor_lines: List(Line),
  vert_lines: List(Line),
) -> Bool {
  let top_row = int.min(box.p1.row, box.p2.row)
  let bot_row = int.max(box.p1.row, box.p2.row)
  let left_col = int.min(box.p1.col, box.p2.col)
  let right_col = int.max(box.p1.col, box.p2.col)
  let left_vertical = Line(Coord(left_col, top_row), Coord(left_col, bot_row))
  let right_vertical =
    Line(Coord(right_col, top_row), Coord(right_col, bot_row))
  let top_horizontal = Line(Coord(left_col, top_row), Coord(right_col, top_row))
  let bot_horizontal = Line(Coord(left_col, bot_row), Coord(right_col, bot_row))
  let is_crossing_any_hor_line =
    [left_vertical, right_vertical]
    |> list.any(fn(vert_line) {
      list.any(hor_lines, fn(hor_line) { is_crossing(hor_line, vert_line) })
    })
  let is_crossing_any_vert_line =
    [top_horizontal, bot_horizontal]
    |> list.any(fn(hor_line) {
      list.any(vert_lines, fn(vert_line) { is_crossing(hor_line, vert_line) })
    })
  case is_crossing_any_hor_line || is_crossing_any_vert_line {
    True -> False
    False -> {
      // No lines crossing. Check if any of the end points are inside the rectangle
      case
        hor_lines
        |> list.any(fn(hor_line) {
          is_inside_box(box, hor_line.p1) || is_inside_box(box, hor_line.p2)
        })
      {
        True -> False
        False -> True
      }
    }
  }
}

fn area_of_box(box: Rect) -> Int {
  { int.absolute_value(box.p2.col - box.p1.col) + 1 }
  * { int.absolute_value(box.p2.row - box.p1.row) + 1 }
}

pub fn day9p2(path: String) -> Int {
  let points = get_input(path)
  let columns = points |> get_columns
  let rows =
    points
    |> get_rows
  let hor_lines =
    get_hor_lines(rows, points)
    |> list.flatten
  let vert_lines =
    get_vert_lines(columns, points)
    |> list.flatten
  let corner_pairs =
    list.combination_pairs(points)
    |> list.map(fn(pair) { Rect(pair.0, pair.1) })

  // let try = is_valid_rect(Rect(Coord(7, 1), Coord(8, 5)), hor_lines, vert_lines)
  // echo try
  let valid_rects =
    list.filter(corner_pairs, fn(corner_pair) {
      is_valid_rect(corner_pair, hor_lines, vert_lines)
    })
    |> list.map(fn(box) { area_of_box(box) })
    |> list.sort(int.compare)
    |> list.reverse
  let res =
    valid_rects
    |> list.first
    |> result.unwrap(0)
  // Annoying. Works on real input but does not invalidate some rects on the test input
  io.println("Day 9 part 2 : " <> int.to_string(res))
  res
}
