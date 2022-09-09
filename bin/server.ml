open Tzproxy

let () =
  let variables = Variables.load_variables () in
  Log.setup_log (Some Info);
  Eio_main.run (fun env ->
    Eio.Switch.run (fun sw -> Proxy.start ~sw env variables))
;;
