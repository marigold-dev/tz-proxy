type t =
  { host : string
  ; port : int
  ; tezos_host : string
  ; ratelimit_enable : bool
  ; blocklist_enable : bool
  ; blocklist_msg : string
  ; blocklist : string list
  ; ratelimit : Ratelimit.t
  }

let as_default default opt =
  match opt with
  | Some value -> value
  | None -> default
;;

let load_variables () =
  let tezos_host =
    Sys.getenv_opt "TEZOS_URL" |> as_default "http://127.0.0.1:8732"
  in
  let host = Sys.getenv_opt "HOST" |> as_default "http://127.0.0.1" in
  let port = Sys.getenv_opt "PORT" |> as_default "8080" |> int_of_string in
  let limit =
    Sys.getenv_opt "RATE_LIMIT_MAX" |> as_default "300" |> int_of_string
  in
  let seconds =
    Sys.getenv_opt "RATE_LIMIT_SECONDS" |> as_default "60." |> float_of_string
  in
  let ratelimit_enable =
    Sys.getenv_opt "RATE_LIMIT_ENABLE" |> as_default "true" |> bool_of_string
  in
  let blocklist_enable =
    Sys.getenv_opt "BLOCKLIST_ENABLE" |> as_default "true" |> bool_of_string
  in
  let blocklist_msg =
    Sys.getenv_opt "BLOCKLIST_MSG"
    |> as_default "Your IP is blocked"
  in
  let blocklist =
    match Sys.getenv_opt "BLOCKLIST" with
    | Some str ->
      String.split_on_char ',' str
      |> List.map String.trim
      |> List.filter (fun x -> x <> "")
    | None -> []
  in
  { host
  ; port
  ; tezos_host
  ; ratelimit_enable
  ; blocklist_enable
  ; blocklist_msg
  ; blocklist
  ; ratelimit = Ratelimit.create ~limit ~seconds
  }
;;