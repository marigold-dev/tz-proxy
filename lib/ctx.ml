type t =
  { sw : Eio.Switch.t
  ; env : Eio.Stdenv.t
  ; storage : Memory_storage.t
  ; variables : Variables.t
  }

let create sw env storage variables = { sw; env; storage; variables }
