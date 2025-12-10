import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set

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

fn parse_p1(input) {
  input
  |> list.map(fn(lst) { list.take(lst, list.length(lst) - 1) })
  |> list.map(fn(lst) {
    case lst {
      [want_str, ..button_strs] -> {
        let wanted =
          string.to_graphemes(want_str)
          |> list.index_fold(0, fn(acc, gr, idx) {
            case gr {
              "." -> acc
              "#" -> acc + int.bitwise_shift_left(1, idx)
              _ -> panic as "Only # or . allowed"
            }
          })
        let buttons =
          list.map(button_strs, fn(butt_str) {
            string.split(butt_str, ",")
            |> list.map(fn(s) { int.parse(s) |> result.unwrap(-1) })
            |> list.fold(0, fn(acc, i) { acc + int.bitwise_shift_left(1, i) })
          })

        #(wanted, buttons)
      }
      _ -> panic as "Err in input"
    }
  })
}

fn parse_p2(input) {
  input
  |> list.map(fn(lst) {
    let button_strs = list.drop(lst, 1) |> list.take(list.length(lst) - 2)
    let j_levels =
      list.last(lst)
      |> result.unwrap("")
      |> string.split(",")
      |> list.map(fn(s) { int.parse(s) |> result.unwrap(-1) })
      |> list.index_map(fn(el, idx) { #(idx, el) })
      |> dict.from_list
    let buttons =
      list.map(button_strs, fn(butt_str) {
        string.split(butt_str, ",")
        |> list.map(fn(s) { int.parse(s) |> result.unwrap(-1) })
      })
      |> list.index_map(fn(btl, idx) { #(idx, btl) })
      |> dict.from_list
    #(j_levels, buttons)
  })
}

type State {
  State(buttons_pressed: List(Int), value: Int)
}

fn rec_try_buttons(
  queue: List(State),
  visited: set.Set(Int),
  target: Int,
  buttons: List(Int),
) -> Result(State, String) {
  case queue {
    [] -> Error("Target unreachable")
    [curr_state, ..rest] -> {
      case curr_state.value == target {
        True -> Ok(curr_state)
        False -> {
          let #(new_queue, new_visited) =
            list.fold(buttons, #(rest, visited), fn(acc, button) {
              let #(curr_queue, curr_visited) = acc
              let new_state =
                State(
                  value: int.bitwise_exclusive_or(curr_state.value, button),
                  buttons_pressed: [button, ..curr_state.buttons_pressed],
                )
              case set.contains(visited, new_state.value) {
                True -> acc
                False -> {
                  #(
                    list.append(curr_queue, [new_state]),
                    set.insert(curr_visited, new_state.value),
                  )
                }
              }
            })
          rec_try_buttons(new_queue, new_visited, target, buttons)
        }
      }
    }
  }
}

fn try_buttons(wanted: Int, buttons: List(Int)) -> State {
  let initial_state = State([], 0)
  let visited = set.new() |> set.insert(0)
  let queue = [initial_state]
  let final_state = rec_try_buttons(queue, visited, wanted, buttons)
  case final_state {
    Ok(state) -> state
    Error(s) -> panic as s
  }
}

pub fn day10p1(path: String) -> Int {
  let inp =
    get_input(path)
    |> parse_p1

  let res =
    list.map(inp, fn(part) {
      let #(wanted, buttons) = part
      let final_state = try_buttons(wanted, buttons)
      list.length(final_state.buttons_pressed)
    })
    |> list.fold(0, fn(acc, el) { acc + el })
  io.println("Day 10 part 1 : " <> int.to_string(res))
  res
}

type P2State {
  P2State(buttons_pressed: List(List(Int)), value: dict.Dict(Int, Int))
}

fn press_button(j_levels: dict.Dict(Int, Int), buttons) {
  list.fold(buttons, j_levels, fn(new_js, button) {
    let curr_count = dict.get(j_levels, button) |> result.unwrap(-1)
    dict.insert(new_js, button, curr_count + 1)
  })
}

fn overflowed_state(curr: dict.Dict(Int, Int), target: dict.Dict(Int, Int)) {
  list.range(0, dict.size(curr) - 1)
  |> list.any(fn(key) {
    let assert Ok(cv) = dict.get(curr, key)
    let assert Ok(tv) = dict.get(target, key)
    cv > tv
  })
}

fn rec_try_buttons_p2(
  queue: List(P2State),
  visited: set.Set(dict.Dict(Int, Int)),
  target: dict.Dict(Int, Int),
  buttons: List(List(Int)),
) -> Result(P2State, String) {
  case queue {
    [] -> Error("Target unreachable")

    [curr_state, ..rest] -> {
      case overflowed_state(curr_state.value, target) {
        True -> {
          rec_try_buttons_p2(rest, visited, target, buttons)
        }
        False -> {
          case curr_state.value == target {
            True -> Ok(curr_state)
            False -> {
              let #(new_queue, new_visited) =
                list.fold(buttons, #(rest, visited), fn(acc, button) {
                  let #(curr_queue, curr_visited) = acc
                  let new_state =
                    P2State(
                      value: press_button(curr_state.value, button),
                      buttons_pressed: [button, ..curr_state.buttons_pressed],
                    )
                  case set.contains(visited, new_state.value) {
                    True -> acc
                    False -> {
                      #(
                        list.append(curr_queue, [new_state]),
                        set.insert(curr_visited, new_state.value),
                      )
                    }
                  }
                })
              rec_try_buttons_p2(new_queue, new_visited, target, buttons)
            }
          }
        }
      }
    }
  }
}

fn try_buttons_p2(
  target: dict.Dict(Int, Int),
  buttons: List(List(Int)),
) -> Result(P2State, String) {
  let start_dict =
    list.range(0, dict.size(target) - 1)
    |> list.map(fn(idx) { #(idx, 0) })
    |> dict.from_list
  let initial_state = P2State([], start_dict)
  let visited = set.new() |> set.insert(start_dict)
  let queue = [initial_state]
  rec_try_buttons_p2(queue, visited, target, buttons)
}

fn find_solution_p2(
  target: dict.Dict(Int, a),
  buttons: dict.Dict(Int, List(Int)),
) {
  // For each target part, see which buttons are releveant to reach the wanted counter

  dict.fold(target, [], fn(acc, key, target_count) {
    let buttons_for_key =
      dict.filter(buttons, fn(key, target_count) {
        list.contains(counter_list, key)
      })
    case buttons_for_key {
      [] -> acc
      b_list -> [b_list, ..acc]
    }
  })
  |> list.reverse
  |> echo
}

pub fn day10p2(path: String) -> Int {
  let inp =
    get_input(path)
    |> parse_p2

  let assert Ok(f) = list.first(inp)

  let #(target, buttons) = f
  let sol = find_solution_p2(target, buttons)
  // let results =
  //   list.map(inp, fn(part) {
  //     let #(target, buttons) = part
  //     case try_buttons_p2(target, buttons) {
  //       Ok(final_state) -> {
  //         let l = list.length(final_state.buttons_pressed)
  //         echo l
  //       }
  //       Error(_) -> panic as "No result"
  //     }
  //   })
  // let res = list.fold(results, 0, fn(acc, ls) { acc + ls })
  let res = 0
  io.println("Day 10 part 2 : " <> int.to_string(res))
  res
}
