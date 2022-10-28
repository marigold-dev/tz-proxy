open Piaf

let or_error = function
  | Ok r -> r
  | Error err ->
    let body = Format.asprintf "Bad Gateway Error: %a" Error.pp_hum err in
    Response.of_string ~body `Service_unavailable
;;

let proxy_handler
  (params : Request_info.t Server.ctx)
  (ctx : Ctx.t)
  additional_headers
  =
  let host = Utils.remove_slash_end ctx.variables.tezos_host in
  let target = host ^ params.request.target in
  let uri = Uri.of_string target in
  Logs.debug (fun m -> m "Proxy to: %s" (Uri.to_string uri));
  let request =
    Piaf.Request.create
      ~scheme:`HTTP
      ~headers:params.request.headers
      ~body:params.request.body
      ~meth:params.request.meth
      ~version:params.request.version
      target
  in
  let response_client = Piaf.Client.send ctx.client request |> or_error in
  let headers =
    Headers.to_list response_client.headers @ additional_headers
    |> Headers.of_list
  in
  Response.create ~headers ~body:response_client.body response_client.status
;;

let run ~host ~port ~sw env handler =
  let config = Server.Config.create port in
  let server = Server.create ~config handler in
  let _command = Server.Command.start ~bind_to_address:host ~sw env server in
  Logs.info (fun m -> m "Server listening on port %d" port)
;;

let setup_pipeline (ctx : Ctx.t) next params = next params ctx

let start ~sw env (variables : Variables.t) =
  let clock = Eio.Stdenv.clock env in
  let storage = Memory_storage.create ~sw ~clock in
  let piaf_config = Config.default in
  let tezos_uri = Uri.of_string variables.tezos_host in
  Logs.info (fun m ->
    m "Trying to connect to node: %s" (Uri.to_string tezos_uri));
  let client_result = Client.create ~config:piaf_config ~sw env tezos_uri in
  match client_result with
  | Error err ->
    Logs.err (fun m ->
      m "Error while connecting to node: %a" Error.pp_hum err);
    failwith "Error while connecting to node"
  | Ok client ->
    Logs.info (fun m -> m "Connected with node: %s" (Uri.to_string tezos_uri));
    let ctx = Ctx.create sw env storage variables client in
    let host = Ip.string_to_ip variables.host in
    setup_pipeline ctx
    @@ Middlewares.block_ip
    @@ Middlewares.rate_limite
    @@ proxy_handler
    |> run ~host ~port:variables.port ~sw env
;;
