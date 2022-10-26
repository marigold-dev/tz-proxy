module String_Hashtbl = Hashtbl.Make (String)

type storage_value =
  { count : int
  ; reset : float
  }

type t =
  { counters : storage_value String_Hashtbl.t
  ; mutex : Eio.Mutex.t
  }

let create () =
  { counters = String_Hashtbl.create 1000; mutex = Eio.Mutex.create () }
;;

let rec remove_all t ip =
  match String_Hashtbl.mem t.counters ip with
  | true ->
    String_Hashtbl.remove t.counters ip;
    remove_all t ip
  | false -> ()
;;

let add_or_replace t ip value =
  if String_Hashtbl.mem t.counters ip
  then String_Hashtbl.replace t.counters ip value
  else String_Hashtbl.add t.counters ip value
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
