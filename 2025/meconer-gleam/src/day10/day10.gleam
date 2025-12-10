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

pub fn day10p2(path: String) -> Int {
  let points = get_input(path)
  let res = 0
  io.println("Day 10 part 2 : " <> int.to_string(res))
  res
}
