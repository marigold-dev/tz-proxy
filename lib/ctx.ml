type t =
  { sw : Eio.Switch.t
  ; env : Eio.Stdenv.t
  ; storage : Memory_storage.t
  ; variables : Variables.t
  ; client: Piaf.Client.t
  }

let create sw env storage variables client = { sw; env; storage; variables; client }
