module String_Map = Map.Make (String)

type storage_value =
  { count : int
  ; reset : float
  }

type t = { counters : storage_value String_Map.t ref }

let create () = { counters = ref String_Map.empty }

let increment ~sw ~env ip t expiration =
  let value = String_Map.find_opt ip !(t.counters) in
  let counter =
    match value with
    | None ->
      let clock = Eio.Stdenv.clock env in
      Eio.Fiber.fork ~sw (fun () ->
        Eio.Time.sleep clock expiration;
        Logs.debug (fun m -> m "Removing %s from the map" ip);
        t.counters := String_Map.remove ip !(t.counters));
      let now = Eio.Time.now clock in
      { count = 1; reset = now +. expiration }
    | Some { count; reset } ->
      let new_value = count + 1 in
      { count = new_value; reset }
  in
  t.counters := String_Map.add ip counter !(t.counters);
  counter
;;
