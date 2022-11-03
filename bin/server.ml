open Tzproxy

let () =
  Gc.set
    { (Gc.get ()) with
      Gc.minor_heap_size = 1024 * 1024
    ; Gc.space_overhead = 20
    };
  let variables = Variables.load_variables () in
  Log.setup_log (Some variables.logs_level);
  Eio_main.run (fun env ->
    Eio.Switch.run (fun sw -> Proxy.start ~sw env variables))
;;
