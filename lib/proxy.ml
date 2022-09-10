open Piaf

let proxy_handler
  (params : Request_info.t Server.ctx)
  (ctx : Ctx.t)
  additional_headers
  =
  let proxy_to = Uri.of_string ctx.variables.tezos_host in
  let uri = Uri.with_path proxy_to params.request.target in
  Logs.info (fun m -> m "Proxy to: %s" (Uri.to_string proxy_to));
  let response_client =
    Client.Oneshot.request
      ~headers:(Headers.to_list params.request.headers)
      ~body:params.request.body
      ~meth:params.request.meth
      ~sw:ctx.sw
      ctx.env
      uri
    |> Response.or_internal_error
  in
  let headers =
    Headers.to_list response_client.headers @ additional_headers
    |> Headers.of_list
  in
  Response.create ~headers ~body:response_client.body response_client.status
;;

let run ~port ~sw env handler =
  let config = Server.Config.create port in
  let server = Server.create ~config handler in
  let _command = Server.Command.start ~sw env server in
  Logs.info (fun m -> m "Server listening on port %d" port)
;;

let setup_pipeline (ctx : Ctx.t) next params = next params ctx

let start ~sw env (variables : Variables.t) =
  let storage = Memory_storage.create () in
  let ctx = Ctx.create sw env storage variables in
  setup_pipeline ctx
  @@ Middlewares.block_ip
  @@ Middlewares.rate_limite
  @@ proxy_handler
  |> run ~port:variables.port ~sw env
;;
