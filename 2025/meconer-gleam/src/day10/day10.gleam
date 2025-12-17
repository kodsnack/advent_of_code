import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/set

import gleam/string

import utils

pub type Machine {
  Machine(
    light_diagram: List(Int),
    buttons: List(List(Int)),
    joltages: List(Int),
  )
}

fn get_input(path: String) {
  utils.get_input_lines(path)
  |> list.map(fn(s) {
    string.trim(s)
    |> string.split(" ")
    |> list.map(fn(s) { string.slice(s, 1, string.length(s) - 2) })
  })
}

pub fn parse_lil(input: String) -> List(Machine) {
  let assert Ok(hash) = string.utf_codepoint(35)

  utils.parsed_lines(input, fn(line) {
    let assert [light_diagram, ..rest] = string.split(line, " ")
      as "Expected at least two fields"
    let light_diagram =
      string.drop_start(light_diagram, 1)
      |> string.drop_end(1)
      |> string.to_utf_codepoints
      |> list.index_fold([], fn(acc, c, i) {
        case c == hash {
          True -> [i, ..acc]
          False -> acc
        }
      })
      |> list.reverse
    let assert [joltages, ..buttons] =
      list.reverse(rest)
      |> list.map(fn(f) {
        string.drop_start(f, 1)
        |> string.drop_end(1)
        |> string.split(",")
        |> list.map(utils.unsafe_int_parse)
      })
      as "Expected at least two fields"
    let buttons = list.reverse(buttons)
    Machine(light_diagram:, buttons:, joltages:)
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

type MachineP2 {
  MachineP2(joltages: dict.Dict(Int, Int), buttons: List(Int))
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
        |> list.fold(0, fn(acc, i) { acc + int.bitwise_shift_left(1, i) })
      })

    MachineP2(j_levels, buttons)
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

// Another try to make it work for finding the buttons 
// to press for pushing the odd counts for p2
fn try_buttons(
  wanted: Int,
  wanted_size: Int,
  buttons: List(Int),
) -> List(List(Int)) {
  // Find out how many combinations there are if we press any button 0 or 1 time
  let no_of_combos = int.bitwise_shift_left(1, list.length(buttons))

  // Find out which buttons we need to press to get the odds toggled
  list.range(0, no_of_combos - 1)
  // First make the button combinations
  |> list.map(fn(combo) {
    int.to_base2(combo)
    |> string.pad_start(wanted_size, "0")
    |> string.to_graphemes
    |> list.map(fn(el) { int.parse(el) |> result.unwrap(-1) })
  })
  // Return the combinations that gets the wanted value
  |> list.filter(fn(button_press) {
    press_button_from_zero(button_press, buttons) == wanted
  })
}

fn press_button_from_zero(button_press: List(Int), buttons: List(Int)) -> Int {
  list.map2(buttons, button_press, fn(b, bp) {
    case bp {
      1 -> b
      _ -> 0
    }
  })
  |> list.fold(0, fn(acc, el) { int.bitwise_exclusive_or(acc, el) })
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

fn target_subtract(targets: List(Int), odds: Int) {
  echo "targets"
  echo targets
  echo int.to_base2(odds)
  let subtracted =
    targets
    |> list.index_map(fn(target, idx) {
      let tv = int.bitwise_shift_left(1, idx)
      case int.bitwise_and(odds, tv) != 0 {
        True -> target - 1
        False -> target
      }
    })
    |> echo
}

fn remaining_after_removing_odds(machine: MachineP2) {
  let targets = machine.joltages
  let buttons = machine.buttons
  echo "buttons"
  echo buttons
  let odds =
    dict.fold(targets, 0, fn(acc, key, target) {
      case target % 2 == 0 {
        True -> acc
        False -> int.bitwise_or(acc, int.bitwise_shift_left(1, key))
      }
    })
  echo int.to_base2(odds)
  let working_combos = try_buttons(odds, list.length(buttons), buttons)
  echo "working_combos"
  echo working_combos
  let counts =
    list.map(working_combos, fn(working_combo) {
      let count = int.sum(working_combo)
      let remaining_joltages = press_buttons(machine, working_combo)
      #(count, remaining_joltages)
    })

  counts
}

fn press_buttons(machine: MachineP2, working_combo: List(Int)) -> Dict(Int, Int) {
  list.fold(working_combo, machine.joltages, fn(acc, combo) {
    let size = dict.size(machine.joltages)
    let counts =
      list.range(0, size - 1)
      |> list.fold(dict.new(), fn(acc, idx) {
        let bit = int.bitwise_shift_left(1, idx)
        case int.bitwise_and(bit, combo) != 0 {
          True -> {
            dict.upsert(acc, idx, fn(v) {
              case v {
                option.Some(v) -> v + 1
                option.None -> 1
              }
            })
          }

          False -> acc
        }
      })
    dict.fold(counts, acc, fn(acc, key, count) {
      dict.upsert(acc, key, fn(opt) {
        case opt {
          option.Some(v) -> v - count
          option.None -> panic as "No entry with key"
        }
      })
    })
  })
}

fn remaining_joltages_are_zero(machine: MachineP2) -> Bool {
  dict.fold(machine.joltages, True, fn(acc, key, value) {
    case value != 0 {
      True -> False
      False -> acc
    }
  })
}

fn solve_p2(machine: MachineP2) {
  case remaining_joltages_are_zero(machine) {
    True -> 1
    False -> {
      let res = remaining_after_removing_odds(machine)
      let new_target =
        dict.map_values(machine.joltages, fn(_key, el) { el / 2 })
        |> echo
      let new_machine = MachineP2(new_target, machine.buttons)
      count + 2 * solve_p2(new_machine)
    }
  }
}

pub fn day10p2(path: String) -> Int {
  let inp =
    get_input(path)
    |> parse_p2

  let assert Ok(f) = list.drop(inp, 1) |> list.first

  let res = solve_p2(f)

  // let res =
  //   list.map(inp, fn(mach) { solve_p2(mach) })
  //   |> echo
  //   |> int.sum
  io.println("Day 10 part 2 : " <> int.to_string(res))
  res
}

fn add_ones(n: Int, acc: Int) -> Int {
  case n {
    0 -> acc
    _ -> add_ones(int.bitwise_and(n, n - 1), acc + 1)
  }
}

pub fn min_presses_pt_2(
  joltages: List(Int),
  joltage_drop_map: Dict(Int, List(Int)),
  joltage_parity_map: Dict(Int, List(Int)),
) -> Result(Int, Nil) {
  use <- bool.guard(list.all(joltages, fn(x) { x == 0 }), return: Ok(0))
  use <- bool.guard(list.any(joltages, fn(x) { x < 0 }), return: Error(Nil))
  use button_combinations <- result.try(dict.get(
    joltage_parity_map,
    list.fold(joltages, 0, fn(acc, x) { 2 * acc + x % 2 }),
  ))
  use min, button_combination <- list.fold(button_combinations, Error(Nil))
  let assert Ok(joltage_drops) = dict.get(joltage_drop_map, button_combination)
    as "Invalid button combination"
  let joltages =
    list.map(list.zip(joltages, joltage_drops), fn(p) { { p.0 - p.1 } / 2 })
  case min_presses_pt_2(joltages, joltage_drop_map, joltage_parity_map) {
    Ok(new_min) -> {
      let new_min = add_ones(button_combination, 2 * new_min)
      case min {
        Ok(cur_min) if cur_min < new_min -> min
        _ -> Ok(new_min)
      }
    }
    Error(Nil) -> min
  }
}

pub fn pt_2(machines: List(Machine)) -> Int {
  list.map(machines, fn(m) {
    let #(joltage_drop_map, joltage_parity_map) =
      list.range(0, int.bitwise_shift_left(1, list.length(m.buttons)) - 1)
      |> list.fold(#(dict.new(), dict.new()), fn(acc, button_combination) {
        let #(joltage_drop_map, joltage_parity_map) = acc
        let joltage_drops =
          list.index_map(m.joltages, fn(_, i) {
            list.index_fold(m.buttons, 0, fn(acc, b, j) {
              case
                int.bitwise_shift_left(1, j)
                |> int.bitwise_and(button_combination)
                != 0
                && list.contains(b, i)
              {
                True -> acc + 1
                False -> acc
              }
            })
          })
        #(
          dict.insert(joltage_drop_map, button_combination, joltage_drops),
          dict.upsert(
            joltage_parity_map,
            list.fold(joltage_drops, 0, fn(acc, i) { 2 * acc + i % 2 }),
            fn(bcs) { [button_combination, ..option.unwrap(bcs, [])] },
          ),
        )
      })
    let assert Ok(min) =
      min_presses_pt_2(m.joltages, joltage_drop_map, joltage_parity_map)
      as "No solution found for machine"
    min
  })
  |> int.sum
}

pub fn day10p2_lil(path: String) -> Int {
  let inp = parse_lil(utils.read_input(path))
  // let first = list.first(inp) |> result.unwrap(Machine([], [], []))
  let res = pt_2(inp)
  io.println("Day 10 part 2 : " <> int.to_string(res))
  res
}
