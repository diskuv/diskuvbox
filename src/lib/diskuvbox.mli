type box_error = string -> string
(** The type for managing errors during box operations.

    During a box operation, any error messages are given to this function.
    This function can log the error, modify the error message, or raise the
    error immediately. *)

val find_up :
  ?err:box_error ->
  ?max_ascent:int ->
  from_dir:Fpath.t ->
  basenames:Fpath.t list ->
  unit ->
  (Fpath.t option, string) result
(** [find_up ?err ?max_ascent ~from_dir ~basenames] searches the directory [from_dir]
    for any file with a name in the list [basenames]. If not found, the
    parent directory of [from_dir] is searched for the file named in
    [basenames].
    
    At most [max_ascent] ancestors of [from_dir] will be searched
    until the file is found. The default [max_ascent] is 20. If the file is
    still not found, the function returns [Ok None].    
    
    An error is reported if [from_dir] is not an existing directory.

    An error is reported if any of the [basenames] names are not true
    basenames (there should be no directory components like "." or ".." or "/").

    Any error is passed to [err] if it is specified. The default [err] is
    the identity function {!Fun.id}. *)

val touch_file : ?err:box_error -> file:Fpath.t -> unit -> (unit, string) result
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
