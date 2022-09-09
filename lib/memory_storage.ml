module String_Map = Map.Make (String)

type storage_value = { count : int }
type t = { counters : storage_value String_Map.t ref }

let create () = { counters = ref String_Map.empty }

let increment ip t =
  let value = String_Map.find_opt ip !(t.counters) in
  match value with
  | None ->
    t.counters := String_Map.add ip { count = 1 } !(t.counters);
    1
  | Some { count } ->
    let new_value = count + 1 in
    t.counters := String_Map.add ip { count = new_value } !(t.counters);
    new_value
;;
