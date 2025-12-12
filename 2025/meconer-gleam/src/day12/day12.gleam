import gleam/int
import gleam/io
import gleam/list
import gleam/string

import utils

fn get_input(path: String) {
  utils.get_input_lines(path)
  |> list.map(fn(s) {
    string.trim(s)
    |> string.split(" ")
    |> list.map(fn(s) { string.slice(s, 1, string.length(s) - 2) })
  })
}

pub fn day12p1(path: String) -> Int {
  let inp = get_input(path)

  let res = 0
  io.println("Day 12 part 1 : " <> int.to_string(res))
  res
}

pub fn day12p2(path: String) -> Int {
  let inp = get_input(path)
  let res = 0
  io.println("Day 12 part 2 : " <> int.to_string(res))
  res
}
