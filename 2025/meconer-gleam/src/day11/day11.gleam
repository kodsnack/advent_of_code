import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import utils

fn get_input(path: String) {
  let parts =
    utils.get_input_lines(path)
    |> list.map(fn(s) {
      let parts =
        string.trim(s)
        |> string.split(":")
      let assert [in, outs] = parts
      let outputs =
        string.trim(outs)
        |> string.split(" ")
      #(in, outputs)
    })
  dict.from_list(parts)
}

fn count_paths(conns, start, target) {
  case start == target {
    True -> 1
    False -> {
      case dict.get(conns, start) {
        Ok(outputs) -> {
          list.fold(outputs, 0, fn(acc, dev) {
            acc + count_paths(conns, dev, target)
          })
        }
        Error(_) -> 0
      }
    }
  }
}

fn count_paths_p2(
  conns: dict.Dict(String, List(String)),
  curr_dev: String,
  target: String,
  path: List(String),
  memo: dict.Dict(String, Int),
) -> #(Int, dict.Dict(String, Int)) {
  case curr_dev == target {
    True -> {
      #(1, memo)
    }
    False -> {
      case dict.has_key(memo, curr_dev) {
        True -> {
          // We counted from here already. 
          #(dict.get(memo, curr_dev) |> result.unwrap(-1), memo)
        }
        False -> {
          case dict.get(conns, curr_dev) {
            Ok(outputs) -> {
              list.fold(outputs, #(0, memo), fn(acc, dev) {
                let #(cnt, n_memo) =
                  count_paths_p2(conns, dev, target, [dev, ..path], acc.1)
                let new_memo =
                  dict.merge(acc.1, n_memo)
                  |> dict.insert(dev, cnt)
                #(acc.0 + cnt, new_memo)
              })
            }
            Error(_) -> #(0, memo)
          }
        }
      }
    }
  }
}

pub fn day11p1(path: String) -> Int {
  let conns = get_input(path)

  let res = count_paths(conns, "you", "out")
  io.println("Day 11 part 1 : " <> int.to_string(res))
  res
}

pub fn day11p2(path: String) -> Int {
  let conns = get_input(path)

  let memo: dict.Dict(String, Int) = dict.new()
  let #(res1, _memo) = count_paths_p2(conns, "svr", "fft", [], memo)
  let #(res2, _memo) = count_paths_p2(conns, "fft", "dac", [], memo)
  let #(res3, _memo) = count_paths_p2(conns, "dac", "out", [], memo)
  let res = res1 * res2 * res3
  io.println("Day 11 part 2 : " <> int.to_string(res))
  res
}
