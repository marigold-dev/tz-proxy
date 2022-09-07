open Piaf

let logging next (params : Request_info.t Server.ctx) =
  Logs.info (fun m ->
    m "Start of request: @?%a" Request.pp_hum params.request);
  let response = next params in
  Logs.info (fun m -> m "End of response: @?%a" Response.pp_hum response);
  response
;;

let block_ip
  (variables : Variables.t)
  next
  (params : Request_info.t Server.ctx)
  =
  let ip = Ip.real_ip params in
  let ip_str = Fmt.str "%a" Eio.Net.Ipaddr.pp ip in
  if List.mem ip_str variables.blocklist
  then (
    let body =
      Body.of_string
        "Your IP is blocked, please contact the infra@marigold.dev"
    in
    Response.create ~body `Forbidden)
  else next params
;;

let rate_limite next params =
  Logs.info (fun m -> m "Checking rate limit");
  next params
;;
