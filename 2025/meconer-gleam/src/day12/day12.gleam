import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string

import utils

fn get_input(path: String) {
  utils.read_input(path)
  |> string.split("\n\n")
  |> list.map(fn(s) {
    string.trim(s)
    |> string.split("\n")
  })
}

fn parse_inp(path) {
  let inp = get_input(path)
  let shapes =
    list.take(inp, 6)
    |> list.map(fn(sh_desc) {
      let assert Ok(shape_no_str) = list.first(sh_desc)
      let shape_no =
        string.drop_end(shape_no_str, 1)
        |> int.parse()
        |> result.unwrap(-1)
      let shape = list.drop(sh_desc, 1)
      #(shape_no, shape)
    })
  let assert Ok(area_strs) = list.last(inp)
  let areas =
    area_strs
    |> list.map(fn(area_str) {
      let #(dim_str, shape_cnts) = case string.split(area_str, " ") {
        [dim_str, ..shape_cnts] -> #(dim_str, shape_cnts)
        _ -> panic as "area_str err"
      }
      let #(width, height) = case
        string.drop_end(dim_str, 1)
        |> string.split("x")
        |> list.map(fn(s) { int.parse(s) |> result.unwrap(-1) })
      {
        [width, height] -> #(width, height)
        _ -> panic as "dim err"
      }
      let shape_cnts =
        shape_cnts
        |> list.map(fn(s) { int.parse(s) |> result.unwrap(-1) })
      #(width, height, shape_cnts)
    })
  #(shapes, areas)
}

fn easy_count_fits(areas: List(#(Int, Int, List(Int)))) -> Int {
  list.fold(areas, 0, fn(counter, area) {
    let #(width, height, count_list) = area
    let horizontal_size = width / 3
    // How many shapes that fits horizontally
    let vertical_size = height / 3
    // How many shapes that fits vertically
    let no_of_possible_shapes_without_nesting = horizontal_size * vertical_size
    let no_of_required_shapes =
      list.fold(count_list, 0, fn(acc, cnt) { acc + cnt })
    case no_of_required_shapes < no_of_possible_shapes_without_nesting {
      True -> 1 + counter
      False -> counter
    }
  })
}

fn count_pixels_for_each_shape(shapes) {
  list.map(shapes, fn(shape) {
    let #(shape_no, shape_lines) = shape
    let pixel_count_for_this_shape =
      list.fold(shape_lines, 0, fn(acc, shape_line) {
        list.fold(string.to_graphemes(shape_line), acc, fn(acc, gr) {
          case gr {
            "#" -> acc + 1
            _ -> acc
          }
        })
      })
    #(shape_no, pixel_count_for_this_shape)
  })
  |> dict.from_list
}

fn has_enough_room_for_all_pixels(
  areas: List(#(Int, Int, List(Int))),
  pixels_by_shape: dict.Dict(Int, Int),
) -> Int {
  // This function checks if the area has enough space for all the required shapes
  list.fold(areas, 0, fn(counter, area) {
    let #(width, height, count_list) = area
    let no_of_pixels_in_area = width * height
    let no_of_pixels_for_required_shapes =
      list.index_fold(count_list, 0, fn(acc, count, idx) {
        let pixels_of_this_shape =
          dict.get(pixels_by_shape, idx) |> result.unwrap(-1)
        acc + pixels_of_this_shape * count
      })
    case no_of_pixels_for_required_shapes <= no_of_pixels_in_area {
      True -> counter + 1
      False -> counter
    }
  })
}

pub fn day12p1(path: String) -> Int {
  let #(shapes, areas) = parse_inp(path)
  let _easy_count = easy_count_fits(areas)
  let pixels_by_shape = count_pixels_for_each_shape(shapes)
  let possible_count = has_enough_room_for_all_pixels(areas, pixels_by_shape)
  let res = possible_count
  io.println("Day 12 part 1 : " <> int.to_string(res))
  res
}
