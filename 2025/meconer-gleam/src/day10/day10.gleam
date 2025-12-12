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

fn do_press(
  curr_joltage_levels: dict.Dict(Int, Int),
  curr_press_count: Int,
  curr_level_idx: Int,
) -> dict.Dict(Int, Int) {
  let curr_level =
    dict.get(curr_joltage_levels, curr_level_idx) |> result.unwrap(-1)
  dict.insert(
    curr_joltage_levels,
    curr_level_idx,
    curr_level + curr_press_count,
  )
}

fn try_buttons_p2(
  curr_press_count: Int,
  curr_level_idx: Int,
  curr_joltage_levels: dict.Dict(Int, Int),
  target_joltage_levels: dict.Dict(Int, Int),
  max_presses: dict.Dict(Int, Int),
  cnt,
) {
  case curr_joltage_levels == target_joltage_levels {
    True -> Ok(cnt)
    False -> {
      let new_joltages =
        do_press(curr_joltage_levels, curr_press_count, curr_level_idx)

      Ok(-1)
    }
  }
}

// fn find_solution_p2(
//   joltage_levels: dict.Dict(Int, Int),
//   button_combs: List(List(Int)),
// ) {
//   // For each target part, see which buttons are releveant to reach the wanted counter
//   let conn_cnt = dict.size(joltage_levels)
//   let max_presses =
//     button_combs
//     |> list.fold([], fn(acc, button_comb) {
//       let max_press =
//         list.fold(button_comb, 99_999, fn(acc, button_no) {
//           let presses_to_reach_target =
//             dict.get(joltage_levels, button_no) |> result.unwrap(-1)
//           case presses_to_reach_target < acc {
//             True -> presses_to_reach_target
//             False -> acc
//           }
//         })
//       [max_press, ..acc]
//     })
//     |> list.reverse
//     |> list.index_map(fn(el, idx) { #(idx, el) })
//     |> dict.from_list
//   let start_joltages =
//     list.range(0, conn_cnt - 1)
//     |> list.map(fn(el) { #(el, 0) })
//     |> dict.from_list
//   let first_max = dict.get(max_presses, 0) |> result.unwrap(-1)
//   let first_press_range =
//     list.range(0, first_max)
//     |> list.map(fn(pc){
//       list.range(1,conn_cnt-1)

//     })
//     |> echo
//   let sol =
//     try_buttons_p2(
//       first_press_range,
//       level_no,
//       start_joltages,
//       joltage_levels,
//       max_presses,
//       0,
//     )
// }

pub fn day10p2(path: String) -> Int {
  let inp =
    get_input(path)
    |> parse_p2

  let assert Ok(f) = list.first(inp)

  let #(target, buttons) = f
  // let sol = find_solution_p2(target, buttons)
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
