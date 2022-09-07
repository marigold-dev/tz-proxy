open Piaf

let header_x_real_ip = "X-Real-Ip"
let header_x_forwarded_for = "X-Forwarded-For"

let real_ip (params : Request_info.t Server.ctx) =
  let forwarded_for =
    Headers.get params.request.headers header_x_forwarded_for
  in
  let real_ip = Headers.get params.request.headers header_x_real_ip in
  match forwarded_for, real_ip with
  | Some forwarded_for, _ when forwarded_for <> "" ->
    forwarded_for
    |> String.split_on_char ','
    |> (fun x -> List.nth x 0)
    |> Eio.Net.Ipaddr.of_raw
  | None, Some real_ip when real_ip <> "" -> Eio.Net.Ipaddr.of_raw real_ip
  | _, _ ->
    (match params.ctx.client_address with
     | `Tcp (ip, _port) -> ip
     | _ -> failwith "Not a TCP connection")
;;
