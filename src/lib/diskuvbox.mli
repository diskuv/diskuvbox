type box_error = string -> string
(** The type for managing errors during box operations.

    During a box operation, any error messages are given to this function.
    This function can log the error, modify the error message, or raise the
    error immediately. *)

val copy_dir :
  ?err:box_error -> src:Fpath.t -> dst:Fpath.t -> unit -> (unit, string) result
(** [copy_dir ?err ~src ~dst ()] copies the contents of [src] into [dst],
    creating [dst] and any parent directories as necessary.
    
    Any error is passed to [err] if it is specified. The default [err] is
    the identity function {!Fun.id}. *)
