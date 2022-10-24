let remove_slash_end str =
  match String.ends_with ~suffix:"/" str with
  | true ->
    let len = String.length str in
    String.sub str 0 (len - 1)
  | false -> str
;;
