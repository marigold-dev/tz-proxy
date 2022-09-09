open Piaf

let ip_to_string ip = Fmt.str "%a" Eio.Net.Ipaddr.pp ip

let block_ip next (params : Request_info.t Server.ctx) (ctx : Ctx.t) =
  Logs.info (fun m -> m "Started block");
  let ip = Ip.real_ip params |> ip_to_string in
  if List.mem ip ctx.variables.blocklist
  then (
    let body = Body.of_string ctx.variables.blocklist_msg in
    Response.create ~body `Forbidden)
  else next params ctx
;;

let rate_limite next params (ctx : Ctx.t) =
  let ip = Ip.real_ip params |> ip_to_string in
  Logs.info (fun m -> m "IP: %s" ip);
  let counter = Memory_storage.increment ip ctx.storage |> string_of_int in
  let headers =
    [ "X-RateLimit-Limit", "10"; "X-RateLimit-Remaining", counter
    ; "X-RateLimit-Reset", "10" ]
  in
  next params ctx headers
;;
