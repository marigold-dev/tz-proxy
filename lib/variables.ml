type t =
  { host : string
  ; port : int
  ; tezos_host : string
  ; ratelimit_enable : bool
  ; blocklist_enable : bool
  ; blocklist : string list
  }

let load_variables () =
  let host =
    match Sys.getenv_opt "HOST" with
    | Some host -> host
    | None -> "http://127.0.0.1"
  in
  let port =
    match Sys.getenv_opt "PORT" with
    | Some port -> int_of_string port
    | None -> 8080
  in
  let tezos_host =
    match Sys.getenv_opt "TEZOS_URL" with
    | Some tezos_url -> tezos_url
    | None -> "http://127.0.0.1:8732"
  in
  let ratelimit_enable =
    match Sys.getenv_opt "RATE_LIMIT_ENABLE" with
    | Some str -> bool_of_string str
    | None -> true
  in
  let blocklist_enable =
    match Sys.getenv_opt "BLOCKLIST_ENABLE" with
    | Some str -> bool_of_string str
    | None -> true
  in
  let blocklist =
    match Sys.getenv_opt "BLOCKLIST" with
    | Some str ->
      String.split_on_char ',' str
      |> List.map String.trim
      |> List.filter (fun x -> x <> "")
    | None -> []
  in
  { host; port; tezos_host; ratelimit_enable; blocklist_enable; blocklist }
;;
