type t =
  { env : Eio.Stdenv.t
  ; storage : Memory_storage.t
  ; variables : Variables.t
  }

let create env storage variables = { env; storage; variables }
