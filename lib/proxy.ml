open Piaf

let proxy_handler sw env proxy_to (params : Request_info.t Server.ctx) =
  let uri = Uri.with_path proxy_to params.request.target in
  Logs.info (fun m -> m "Proxy to: %s" (Uri.to_string proxy_to));
  Client.Oneshot.request
    ~headers:(Headers.to_list params.request.headers)
    ~body:params.request.body
    ~meth:params.request.meth
    ~sw
    env
    uri
  |> Response.or_internal_error
;;

let run ~port ~sw env handler =
  let config = Server.Config.create port in
  let server = Server.create ~config handler in
  let _command = Server.Command.start ~sw env server in
  Logs.info (fun m -> m "Server started on port %d" port)
;;

let start ~sw env (variables : Variables.t) =
  let proxy_to = Uri.of_string variables.tezos_host in
  let handlers =
    Middlewares.logging
    @@ Middlewares.block_ip variables
    @@ Middlewares.rate_limite
    @@ proxy_handler sw env proxy_to
  in
  run ~port:variables.port ~sw env handlers
;;
