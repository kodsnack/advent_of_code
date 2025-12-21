import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
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

type Machine {
  Machine(joltages: dict.Dict(Int, Int), buttons: dict.Dict(Int, List(Int)))
}

fn parse_p2(input) {
  input
  |> list.map(fn(lst) {
    let button_strs = list.drop(lst, 1) |> list.take(list.length(lst) - 2)
    let j_levels =
      list.last(lst)
      |> result.unwrap("")
      |> string.split(",")
      |> list.index_map(fn(s, idx) {
        let j = int.parse(s) |> result.unwrap(-1)
        #(idx, j)
      })
      |> dict.from_list
    let buttons =
      list.map(button_strs, fn(butt_str) {
        string.split(butt_str, ",")
        |> list.map(fn(s) { int.parse(s) |> result.unwrap(-1) })
      })
      |> list.index_map(fn(el, idx) { #(idx, el) })
      |> dict.from_list

    Machine(j_levels, buttons)
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

// This worked for part 1
fn try_buttons_p1(wanted: Int, buttons: List(Int)) -> State {
  let initial_state = State([], 0)
  let visited = set.new() |> set.insert(0)
  let queue = [initial_state]
  let final_state =
    rec_try_buttons(queue, visited, wanted, buttons)
    |> echo
  case final_state {
    Ok(state) -> state
    Error(s) -> panic as s
  }
}

fn find_odd_joltages(machine: Machine) {
  let size = dict.size(machine.joltages)
  list.range(0, size - 1)
  |> list.map(fn(key) {
    let assert Ok(joltage) = dict.get(machine.joltages, key)
    case is_even(joltage) {
      True -> 0
      False -> 1
    }
  })
}

fn is_even(joltage: Int) -> Bool {
  joltage % 2 == 0
}

fn is_odd(val: Int) -> Bool {
  !is_even(val)
}

pub fn day10p1(path: String) -> Int {
  let inp =
    get_input(path)
    |> parse_p1

  let res =
    list.map(inp, fn(part) {
      let #(wanted, buttons) = part
      let final_state = try_buttons_p1(wanted, buttons)
      list.length(final_state.buttons_pressed)
    })
    |> int.sum
  io.println("Day 10 part 1 : " <> int.to_string(res))
  res
}

fn solve_mach(machine: Machine) {
  let button_combos = rec_find_solution(machine)
}

fn find_btn_combos(machine: Machine) -> List(List(Int)) {
  let button_count = dict.size(machine.buttons)
  // No of combos is 2^button count

  let combo_count = int.bitwise_shift_left(1, button_count)
  // Generate all combinations of button presses 0 or 1 time
  let combos =
    list.range(0, combo_count - 1)
    |> list.map(fn(el) {
      int.to_base2(el)
      |> string.pad_start(button_count, "0")
      |> string.to_graphemes
      |> list.map(fn(el) { int.parse(el) |> result.unwrap(-1) })
    })
  combos
}

fn rec_find_solution(machine: Machine) {
  case is_all_zeros(machine) {
    True -> 0
    False -> {
      case has_negatives(machine) {
        True ->
          // This was no solution. Return a big number
          999_999_999
        False -> {
          // Make a list of 1:s for each odd joltage or
          // 0 for each even joltage level
          let odds = find_odd_joltages(machine)
          let combos = find_btn_combos(machine)
          let joltage_deltas_and_counts =
            find_joltage_deltas_and_counts(combos, machine, odds)
          let machines_with_odds_removed =
            list.map(joltage_deltas_and_counts, fn(delta_and_count) {
              let #(delta, count) = delta_and_count
              let new_jolts =
                dict.fold(delta, machine.joltages, fn(acc, key, dval) {
                  dict.upsert(acc, key, fn(opt_val) {
                    case opt_val {
                      option.Some(v) -> v - dval
                      option.None -> panic as "Err in dict.fold"
                    }
                  })
                })

              #(Machine(new_jolts, machine.buttons), count)
              |> echo
            })

          let halved_machines =
            list.map(machines_with_odds_removed, fn(machine_and_count) {
              let #(machine, count) = machine_and_count
              let half_mach =
                calc_half_joltages(machine)
                |> echo
              #(half_mach, count)
            })
          0
        }
      }
    }
  }
}

fn calc_half_joltages(machine: Machine) {
  let new_jolts = dict.map_values(machine.joltages, fn(key, val) { val / 2 })
  Machine(new_jolts, machine.buttons)
}

fn has_negatives(machine: Machine) -> Bool {
  list.any(dict.values(machine.joltages), fn(el) { el < 0 })
}

fn is_all_zeros(machine: Machine) -> Bool {
  list.all(dict.values(machine.joltages), fn(el) { el == 0 })
}

fn find_joltage_deltas_and_counts(
  combos: List(List(Int)),
  machine: Machine,
  odds: List(Int),
) -> List(#(dict.Dict(Int, Int), Int)) {
  list.map(combos, fn(combo) {
    let deltas =
      list.index_fold(combo, dict.new(), fn(acc, el, idx) {
        case el == 1 {
          True -> {
            // Press the button with number idx
            let buttons_to_press =
              dict.get(machine.buttons, idx) |> result.unwrap([])
            list.fold(buttons_to_press, acc, fn(acc, button) {
              dict.upsert(acc, button, fn(opt_jolt) {
                case opt_jolt {
                  option.Some(val) -> val + 1
                  option.None -> 1
                }
              })
            })
          }
          False -> acc
        }
      })
    let btn_press_cnt = int.sum(combo)
    #(deltas, btn_press_cnt)
  })
  |> list.filter(fn(deltas) {
    list.index_fold(odds, True, fn(acc, should_be_odd, idx) {
      let delta = dict.get(deltas.0, idx) |> result.unwrap(0)
      case should_be_odd == 1 {
        True -> acc && is_odd(delta)
        False -> acc && is_even(delta)
      }
    })
  })
  |> echo
}

pub fn day10p2(path: String) -> Int {
  let inp =
    get_input(path)
    |> parse_p2

  let assert Ok(f) =
    inp
    |> list.first

  solve_mach(f)

  let res = 0

  // let res =
  //   list.map(inp, fn(mach) { solve_p2(mach) })
  //   |> echo
  //   |> int.sum
  io.println("Day 10 part 2 : " <> int.to_string(res))
  res
}
