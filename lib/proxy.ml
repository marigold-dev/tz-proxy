open Piaf
open Eio

let or_error = function
  | Ok r -> r
  | Error err ->
    let body = Format.asprintf "Service unavailable: %a" Error.pp_hum err in
    Response.of_string ~body `Service_unavailable
;;

let proxy_handler
  (params : Request_info.t Server.ctx)
  (ctx : Ctx.t)
  additional_headers
  =
  let config = { Config.default with body_buffer_size = 0x1_000_000 } in
  let host = Utils.remove_slash_end ctx.variables.tezos_host in
  let target = host ^ params.request.target in
  let sw = params.ctx.sw in
  let uri = Uri.of_string (host ^ params.request.target) in
  Logs.debug (fun m -> m "Proxy to: %s" (Uri.to_string uri));
  let headers = Headers.to_list params.request.headers in
  let request =
    Request.create
      ~scheme:`HTTP
      ~version:params.request.version
      ~headers:(Headers.of_list headers)
      ~body:params.request.body
      ~meth:params.request.meth
      target
  in
  let client_result = Client.create ~config ~sw:params.ctx.sw ctx.env uri in
  match client_result with
  | Ok client ->
    let response_client = Client.send client request |> or_error in
    Fiber.fork ~sw (fun _ ->
      Fiber.first
        (fun () ->
          let clock = Stdenv.clock ctx.env in
          Eio.Time.sleep clock 60.;
          Utils.safe_shutdown_client client;
          Logs.err (fun m -> m "Client shutdown by timeout"))
        (fun () ->
          let closed = Body.closed response_client.body in
          match closed with
          | Ok () ->
            Utils.safe_shutdown_client client;
            Logs.debug (fun m -> m "Client shutdown")
          | Error err ->
            Logs.err (fun m ->
              m "Error on close connection: %a" Error.pp_hum err)));
    let headers =
      Headers.to_list response_client.headers @ additional_headers
      |> Headers.of_list
    in
    Response.create ~headers ~body:response_client.body response_client.status
  | Error err ->
    let body = Format.asprintf "Service unavailable: %a" Error.pp_hum err in
    Response.of_string ~body `Service_unavailable
;;

let run ~host ~port ~sw env handler =
  let config = Server.Config.create port in
  let server = Server.create ~config handler in
  let _command = Server.Command.start ~bind_to_address:host ~sw env server in
  Logs.info (fun m -> m "Server listening on port %d" port)
;;

let setup_pipeline (ctx : Ctx.t) next params = next params ctx

let start ~sw env (variables : Variables.t) =
  let storage = Memory_storage.create ~sw env in
  let ctx = Ctx.create env storage variables in
  let host = Ip.string_to_ip ctx.variables.host in
  setup_pipeline ctx
  @@ Middlewares.block_ip
  @@ Middlewares.rate_limite
  @@ proxy_handler
  |> run ~host ~port:variables.port ~sw env
;;
