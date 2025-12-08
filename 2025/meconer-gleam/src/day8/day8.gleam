import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/set
import gleam/string
import utils

type Coord {
  Coord(x: Int, y: Int, z: Int)
}

fn sq_dist(p1: Coord, p2: Coord) -> Int {
  // Calculate the squared dist between p1 and p2
  // No need to take the square root since we dont care
  // about the real distance, just the order
  let dx = p2.x - p1.x
  let dy = p2.y - p1.y
  let dz = p2.z - p1.z
  dx * dx + dy * dy + dz * dz
}

fn get_input(path: String) -> dict.Dict(Int, Coord) {
  // Read input and make a dictionary with the line index as key
  let junctions =
    utils.get_input_lines(path)
    |> list.map(fn(l) {
      string.split(l, ",")
      |> list.map(fn(s) {
        let assert Ok(n) = int.parse(s)
        n
      })
    })
    |> list.map(fn(l) {
      case l {
        [x, y, z] -> Coord(x, y, z)
        _ -> panic as "Wrong coords"
      }
    })
  list.index_fold(junctions, dict.new(), fn(coord_dict, coord, idx) {
    dict.insert(coord_dict, idx, coord)
  })
}

fn calc_all_dists(junctions: dict.Dict(Int, Coord)) -> List(#(#(Int, Int), Int)) {
  // Calculate the distance between all combinations of junction coords
  list.range(0, dict.size(junctions) - 1)
  |> list.combination_pairs()
  |> list.fold([], fn(acc, pair) {
    let #(k1, k2) = pair
    let assert Ok(coord1) = dict.get(junctions, k1)
    let assert Ok(coord2) = dict.get(junctions, k2)
    let sd = sq_dist(coord1, coord2)
    [#(pair, sd), ..acc]
  })
  |> list.sort(fn(a, b) {
    let #(_, dista) = a
    let #(_, distb) = b
    int.compare(dista, distb)
  })
}

fn do_connections(
  pair_dists: List(#(#(Int, Int), Int)),
  connect_cnt: Int,
  coord_size: Int,
) -> List(set.Set(Int)) {
  // Make a list of start_sets with each junction in a separate set
  // so all junctions are in a set. 
  let start_sets =
    list.range(0, coord_size - 1)
    |> list.map(fn(n) { set.new() |> set.insert(n) })
  list.take(pair_dists, connect_cnt)
  // Use only the first connect_cnt pairs, 10 resp 1000 in the example and real problem
  |> list.fold(start_sets, fn(acc, pair_dist) {
    let #(#(k1, k2), _dist) = pair_dist
    let assert Ok(k1_set) = list.find(acc, fn(kset) { set.contains(kset, k1) })
    let assert Ok(k2_set) = list.find(acc, fn(kset) { set.contains(kset, k2) })
    let new_set = set.union(k1_set, k2_set)
    let other_sets =
      list.filter(acc, fn(kset) {
        // remove the sets that contains k1 or k2
        !{ set.contains(kset, k1) || set.contains(kset, k2) }
      })
    [new_set, ..other_sets]
  })
}

fn do_connections_p2(
  pair_dists: List(#(#(Int, Int), Int)),
  coord_size: Int,
) -> #(#(Int, Int), List(set.Set(Int))) {
  // Make a list of start_sets with each junction in a separate set
  // so all junctions are in a set. This simplifies the fold_until below
  let start_sets =
    list.range(0, coord_size - 1)
    |> list.map(fn(n) { set.new() |> set.insert(n) })
  pair_dists
  |> list.fold_until(#(#(0, 0), start_sets), fn(acc, pair_dist) {
    let #(#(k1, k2), _dist) = pair_dist
    let #(_, conn_sets) = acc
    // Find the sets containing k1 and k2
    let assert Ok(k1_set) =
      list.find(conn_sets, fn(kset) { set.contains(kset, k1) })
    let assert Ok(k2_set) =
      list.find(conn_sets, fn(kset) { set.contains(kset, k2) })
    // Join the sets. They could be the same
    let new_set = set.union(k1_set, k2_set)
    let other_sets =
      list.filter(conn_sets, fn(kset) {
        // remove the sets that contains k1 or k2
        !{ set.contains(kset, k1) || set.contains(kset, k2) }
      })
    case list.is_empty(other_sets) {
      // If these two sets are the only sets left, we should stop and return this pair
      True -> list.Stop(#(#(k1, k2), [new_set]))
      // There are other sets left. Continue to connect
      False -> list.Continue(#(#(0, 0), [new_set, ..other_sets]))
    }
  })
}

pub fn day8p1(path: String, conn_cnt: Int) -> Int {
  let junctions = get_input(path)
  let pair_dists = calc_all_dists(junctions)
  let connections = do_connections(pair_dists, conn_cnt, dict.size(junctions))
  let conn_sizes =
    list.map(connections, fn(conn_set) { set.size(conn_set) })
    |> list.sort(fn(a, b) { int.compare(b, a) })
  let res =
    list.take(conn_sizes, 3)
    |> list.fold(1, fn(acc, n) { acc * n })
  io.println("Day 8 part 1 : " <> int.to_string(res))
  res
}

pub fn day8p2(path: String) -> Int {
  let junctions = get_input(path)
  let pair_dists = calc_all_dists(junctions)
  let #(last_pair, _connections) =
    do_connections_p2(pair_dists, dict.size(junctions))
  let assert Ok(c1) = dict.get(junctions, last_pair.0)
  let assert Ok(c2) = dict.get(junctions, last_pair.1)
  let res = c1.x * c2.x
  io.println("Day 8 part 2 : " <> int.to_string(res))
  res
}
