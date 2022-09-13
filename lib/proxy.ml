open Piaf

let call sw ?(_config = Config.default) env uri request =
  let promiser, resolver = Eio.Promise.create () in
  Eio.Fiber.fork_sub
    ~sw
    ~on_error:(fun exn -> Logs.err (fun m -> m "%a" Fmt.exn exn))
    (fun sw_fork ->
      let t =
        Piaf.Client.create ~config:_config ~sw:sw_fork env uri
        |> Result.get_ok
      in
      let send_promiser =
        Eio.Fiber.fork_promise ~sw:sw_fork (fun _ ->
          Piaf.Client.send t request)
      in
      let send_result = Eio.Promise.await_exn send_promiser in
      Piaf.Client.shutdown t;
      Eio.Promise.resolve resolver send_result);
  Eio.Promise.await promiser
;;

let proxy_handler
  (params : Request_info.t Server.ctx)
  (ctx : Ctx.t)
  additional_headers
  =
  let proxy_to = Uri.of_string ctx.variables.tezos_host in
  let uri = Uri.with_path proxy_to params.request.target in
  Logs.info (fun m -> m "Proxy to: %s" (Uri.to_string proxy_to));
  let response_client =
    call ctx.sw ctx.env uri params.request |> Response.or_internal_error
  in
  (* let response_client = *)
  (*   Client.Oneshot.request *)
  (*     ~headers:(Headers.to_list params.request.headers) *)
  (*     ~body:params.request.body *)
  (*     ~meth:params.request.meth *)
  (*     ~sw:ctx.sw *)
  (*     ctx.env *)
  (*     uri *)
  (*   |> Response.or_internal_error *)
  (* in *)
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
