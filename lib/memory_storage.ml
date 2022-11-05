module String_Hashtbl = Hashtbl.Make (String)

type storage_value =
  { count : int
  ; reset : float
  }

type t =
  { counters : storage_value String_Hashtbl.t
  ; mutex : Eio.Mutex.t
  }

let remove_all_expireds t now =
  Eio.Mutex.use_rw ~protect:true t.mutex (fun () ->
    Logs.info (fun m ->
      m
        "Starting purge state with length: %d"
        (String_Hashtbl.length t.counters));
    String_Hashtbl.to_seq_keys t.counters
    |> Seq.filter (fun ip ->
         let { reset; _ } = String_Hashtbl.find t.counters ip in
         reset <= now)
    |> Seq.iter (fun ip -> String_Hashtbl.remove t.counters ip);
    Logs.info (fun m ->
      m "Purged, with length state is: %d" (String_Hashtbl.length t.counters)))
;;

let add_or_replace t ip value =
  if String_Hashtbl.mem t.counters ip
  then String_Hashtbl.replace t.counters ip value
  else String_Hashtbl.add t.counters ip value
;;

let rec purge env t =
  let clock = Eio.Stdenv.clock env in
  let now = Eio.Time.now clock in
  Eio_unix.sleep 3600.;
  remove_all_expireds t now;
  Gc.full_major ();
  purge env t
;;

let create ~sw env =
  let counters = String_Hashtbl.create 100 in
  let t = { counters; mutex = Eio.Mutex.create () } in
  Eio.Fiber.fork ~sw (fun () -> purge env t);
  t
;;

let increment ~clock ip t expiration =
  Eio.Mutex.use_rw ~protect:true t.mutex (fun () ->
    let value = String_Hashtbl.find_opt t.counters ip in
    let now = Eio.Time.now clock in
    let counter =
      match value with
      | None -> { count = 1; reset = now +. expiration }
      | Some { count; reset } ->
        if reset < now
        then { count = 1; reset = now +. expiration }
        else { count = count + 1; reset }
    in
    add_or_replace t ip counter;
    counter)
;;
