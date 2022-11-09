type t =
  { env : Eio.Stdenv.t
  ; storage : Memory_storage.t
  ; variables : Variables.t
  ; client : Piaf.Client.t
  }

let create env storage variables client = { env; storage; variables; client }
