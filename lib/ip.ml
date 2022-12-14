open Piaf

let string_to_ip str = Unix.inet_addr_of_string str |> Eio_unix.Ipaddr.of_unix

let real_ip (params : Request_info.t Server.ctx) =
  let forwarded_for =
    Headers.get params.request.headers Consts.header_x_forwarded_for
  in
  let real_ip = Headers.get params.request.headers Consts.header_x_real_ip in
  match forwarded_for, real_ip with
  | Some forwarded_for, _ when forwarded_for <> "" ->
    forwarded_for
    |> String.split_on_char ','
    |> (fun ip_list -> List.nth ip_list 0)
    |> string_to_ip
  | None, Some real_ip when real_ip <> "" -> string_to_ip real_ip
  | _, _ ->
    (match params.ctx.client_address with
     | `Tcp (ip, _port) -> ip
     | _ -> failwith "Not a TCP connection")
;;
