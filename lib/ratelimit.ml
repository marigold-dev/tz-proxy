type t =
  { seconds : float
  ; limit : int
  }

let create ~seconds ~limit = { seconds; limit }
