open Piaf

let ip_to_string ip = Fmt.str "%a" Eio.Net.Ipaddr.pp ip

let block_ip next (params : Request_info.t Server.ctx) (ctx : Ctx.t) =
  let ip = Ip.real_ip params |> ip_to_string in
  if List.mem ip ctx.variables.blocklist
  then (
    let body = Body.of_string ctx.variables.blocklist_msg in
    Response.create ~body `Forbidden)
  else next params ctx
;;

let rate_limite next params (ctx : Ctx.t) =
  let ip = Ip.real_ip params |> ip_to_string in
  let counter =
    Memory_storage.increment
      ~sw:ctx.sw
      ~env:ctx.env
      ip
      ctx.storage
      ctx.variables.ratelimit.seconds
  in
  let remaining =
    if ctx.variables.ratelimit.limit >= counter.count
    then ctx.variables.ratelimit.limit - counter.count
    else 0
  in
  Logs.info (fun m ->
    m "Ratelimit for IP: %s with counter: %d" ip counter.count);
  let headers_str =
    [ "X-RateLimit-Limit", ctx.variables.ratelimit.limit |> string_of_int
    ; "X-RateLimit-Remaining", remaining |> string_of_int
    ; "X-RateLimit-Reset", counter.reset |> string_of_float ]
  in
  let headers = headers_str |> Piaf.Headers.of_list in
  if remaining <= 0
  then (
    let body =
      Body.of_string ("Too Many Requests on " ^ params.request.target)
    in
    let too_many_requests = Status.of_code 429 in
    Response.create ~headers ~body too_many_requests)
  else next params ctx headers_str
;;
