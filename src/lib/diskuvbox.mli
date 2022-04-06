type box_error = string -> string
(** The type for managing errors during box operations.

    During a box operation, any error messages are given to this function.
    This function can log the error, modify the error message, or raise the
    error immediately. *)

val touch_file :
  ?err:box_error -> file:Fpath.t -> unit -> (unit, string) result
(** [touch_file ?err ~file ()] creates the file [file] if it does not exist,
    creating [file]'s parent directories as necessary. If the [file]
    already exists its access and modification times are updated.
      
    Any error is passed to [err] if it is specified. The default [err] is
    the identity function {!Fun.id}. *)

val copy_file :
  ?err:box_error -> src:Fpath.t -> dst:Fpath.t -> unit -> (unit, string) result
(** [copy_file ?err ~src ~dst ()] copies the file [src] to the file [dst],
    creating [dst]'s parent directories as necessary.
    
    Any error is passed to [err] if it is specified. The default [err] is
    the identity function {!Fun.id}. *)

val copy_dir :
  ?err:box_error -> src:Fpath.t -> dst:Fpath.t -> unit -> (unit, string) result
(** [copy_dir ?err ~src ~dst ()] copies the contents of [src] into [dst],
      creating [dst] and any parent directories as necessary.
      
      Any error is passed to [err] if it is specified. The default [err] is
      the identity function {!Fun.id}. *)
