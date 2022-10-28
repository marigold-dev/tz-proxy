let setup_log ?style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level ~all:true level;
  (* disable all non-proxy logs *)
  List.iter
    (fun src ->
      let src_name = Logs.Src.name src in
      if (not (String.starts_with ~prefix:"server" src_name))
         && not (String.equal src_name "application")
      then Logs.Src.set_level src (Some Logs.Error))
    (Logs.Src.list ());
  Logs.set_reporter (Logs_fmt.reporter ())
;;
