let remove_slash_end str =
  match String.ends_with ~suffix:"/" str with
  | true ->
    let len = String.length str in
    String.sub str 0 (len - 1)
  | false -> str
;;

let safe_shutdown_client client =
  try Piaf.Client.shutdown client with
  | exn -> Logs.err (fun m -> m "Client shutdown error: %a" Fmt.exn exn)
;;
