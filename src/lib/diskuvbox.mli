(******************************************************************************)
(*  Copyright 2022 Diskuv, Inc.                                               *)
(*                                                                            *)
(*  Licensed under the Apache License, Version 2.0 (the "License");           *)
(*  you may not use this file except in compliance with the License.          *)
(*  You may obtain a copy of the License at                                   *)
(*                                                                            *)
(*      http://www.apache.org/licenses/LICENSE-2.0                            *)
(*                                                                            *)
(*  Unless required by applicable law or agreed to in writing, software       *)
(*  distributed under the License is distributed on an "AS IS" BASIS,         *)
(*  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  *)
(*  See the License for the specific language governing permissions and       *)
(*  limitations under the License.                                            *)
(******************************************************************************)

type box_error = string -> string
(** The type for managing errors during box operations.

    During a box operation, any error messages are given to this function.
    This function can log the error, modify the error message, or raise the
    error immediately. *)

(** The type of path seen during a {!walk_down} operation *)
type walk_path = Root | File of Fpath.t | Directory of Fpath.t

(** Attributes of the path *)
type path_attribute = First_in_directory | Last_in_directory

module Path_attributes : Set.S with type elt = path_attribute

val walk_down :
  ?err:box_error ->
  ?max_depth:int ->
  from_path:Fpath.t ->
  f:
    (depth:int ->
    path_attributes:Path_attributes.t ->
    walk_path ->
    (unit, string) result) ->
  unit ->
  (unit, string) result
(** [walk_down ?err ?max_depth ~from_path ~f ()] visits the file [from_path]
    or walks down a directory tree [file_path], executing
    [f ~depth ~path_attributes path] on every file and directory.
    
    Symlinks are followed.
  
    When [from_path] is a file, [f] will be called on [from_path] and that
    is the completion of the [walk_down] procedure.

    When [from_path] is a directory, the traversal is pre-order, meaning that
    [f] is called on a directory ["A"] before [f] is called on any children of
    directory ["A"]. All children in a directory are traversed in lexographical
    order.

    The [path] in [f ~depth ~path_attributes path] will be [Root] if the
    current file or directory is [from_path]; otherwise the
    [path = File relpath] or [path = Directory relpath] has a [relpath]
    which is a relative path from [from_path] to the current file or directory.

    The [depth] in [f ~depth ~path_attributes path] will be an integer from 0
    to [max_depth], inclusive.
    
    At most [max_depth] descendants of [from_path] will be walked. When
    [max_depth] is [0] no descent into a directory is ever conducted.
    The default [max_depth] is 0.
    
    Any error is passed to [err] if it is specified. The default [err] is
    the identity function {!Fun.id}. *)

val find_up :
  ?err:box_error ->
  ?max_ascent:int ->
  from_dir:Fpath.t ->
  basenames:Fpath.t list ->
  unit ->
  (Fpath.t option, string) result
(** [find_up ?err ?max_ascent ~from_dir ~basenames ()] searches the directory
    [from_dir] for any file with a name in the list [basenames]. If not found,
    the parent directory of [from_dir] is searched for the file named in
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
  ?err:box_error ->
  ?mode:int ->
  src:Fpath.t ->
  dst:Fpath.t ->
  unit ->
  (unit, string) result
(** [copy_file ?err ?mode ~src ~dst ()] copies the file [src] to the file [dst],
    creating [dst]'s parent directories as necessary.
    
    If [mode] is specified, the chmod [mode] will be applied to [dst]. Otherwise
    the chmod mode is copied from [src].
    
    Any error is passed to [err] if it is specified. The default [err] is
    the identity function {!Fun.id}. *)

val copy_dir :
  ?err:box_error -> src:Fpath.t -> dst:Fpath.t -> unit -> (unit, string) result
(** [copy_dir ?err ~src ~dst ()] copies the contents of [src] into [dst],
      creating [dst] and any parent directories as necessary.
      
      Any error is passed to [err] if it is specified. The default [err] is
      the identity function {!Fun.id}. *)
