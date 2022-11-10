open Piaf
open Eio

let or_error = function
  | Ok r -> r
  | Error err ->
    let body = Format.asprintf "Service unavailable: %a" Error.pp_hum err in
    Response.of_string ~body `Service_unavailable
;;

(*  Hop-by-hop headers. These are removed when sent to the backend.
    As of RFC 7230, hop-by-hop headers are required to appear in the
    Connection header field. These are the headers defined by the
    obsoleted RFC 2616 (section 13.5.1) and are used for backward
    compatibility. *)
let hop_headers =
  [ "connection"; "proxy-connection"; "keep-alive"; "proxy-authenticate"
  ; "proxy-authorization"; "te"; "trailer"; "transfer-encoding"; "upgrade" ]
;;

let proxy_handler
  (params : Request_info.t Server.ctx)
  (ctx : Ctx.t)
  additional_headers
  =
  let host = Utils.remove_slash_end ctx.variables.tezos_host in
  let target = host ^ params.request.target in
  let uri = Uri.of_string (host ^ params.request.target) in
  Logs.debug (fun m -> m "Proxy to: %s" (Uri.to_string uri));
  let headers = Headers.to_list params.request.headers in
  let headers_filtered =
    List.filter
      (fun (header, _) ->
        not (List.mem (header |> String.lowercase_ascii) hop_headers))
      headers
  in
  let request =
    Request.create
      ~scheme:`HTTP
      ~version:params.request.version
      ~headers:(Headers.of_list headers_filtered)
      ~body:params.request.body
      ~meth:params.request.meth
      target
  in
  let res_client = Client.send ctx.client request |> or_error in
  let headers =
    Headers.to_list res_client.headers @ additional_headers |> Headers.of_list
  in
  Response.create ~headers ~body:res_client.body res_client.status
;;

let run ~sw ~env ~host ~port ~backlog handler =
  let config = Server.Config.create ~backlog ~address:host port in
  let server = Server.create ~config handler in
  let _command = Server.Command.start ~sw env server in
  Logs.info (fun m -> m "Server listening on port %d" port)
;;

let setup_pipeline (ctx : Ctx.t) next params = next params ctx

let rec start ~sw env (variables : Variables.t) =
  Logs.info (fun m -> m "Starting proxy server");
  let config = { Config.default with body_buffer_size = 0x100_000 } in
  let uri = Uri.of_string (variables.tezos_host ^ "/version") in
  let client_result = Client.create ~config ~sw env uri in
  match client_result with
  | Ok client ->
    Logs.info (fun m -> m "Connected to Tezos node");
    Switch.on_release sw (fun () -> Client.shutdown client);
    let storage = Memory_storage.create ~sw env in
    let ctx = Ctx.create env storage variables client in
    let host = Ip.string_to_ip ctx.variables.host in
    setup_pipeline ctx
    @@ Middlewares.block_ip
    @@ Middlewares.rate_limite
    @@ proxy_handler
    |> run ~sw ~env ~host ~port:variables.port ~backlog:variables.backlog
  | Error err ->
    Logs.err (fun m -> m "Error on client creation: %a" Error.pp_hum err);
    Eio_unix.sleep 5.0;
    start ~sw env variables
;;
