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

open Bos

type box_error = string -> string

type walk_path = Root | File of Fpath.t | Directory of Fpath.t

type path_attribute = First_in_directory | Last_in_directory [@@deriving ord]

module Path_attributes = Set.Make (struct
  type t = path_attribute

  let compare = compare_path_attribute
end)

(* Error Handling *)

let rresult_error_to_string ~err msg = err (Fmt.str "%a" Rresult.R.pp_msg msg)

let map_rresult_error_to_string ~err = function
  | Ok v -> Result.Ok v
  | Error msg -> Result.Error (rresult_error_to_string ~err msg)

let map_string_to_rresult_error = function
  | Ok v -> Result.Ok v
  | Error s -> Rresult.R.error_msg s

module type ERROR_HANDLER = sig
  val box_error : box_error
end

module Monad_syntax_rresult (Error_handler : ERROR_HANDLER) = struct
  let ( let* ) r (f : 'a -> ('c, 'b) result) =
    Rresult.R.bind r (fun a ->
        match f a with
        | Ok v -> Ok v
        | Error msg ->
            Rresult.R.error_msg
              (Error_handler.box_error
                 (rresult_error_to_string ~err:Fun.id msg)))

  let ( let+ ) x f = Rresult.R.map f x
end

let dir_dot = Fpath.v "."

(** {1 Windows 260 character limit friendly functions}

    Any failures with these functions will tell you to look at the 260
    character limit as an explanation. *)

let windows_max_path = 260

(** [bos_tmp_name_max] is the maximum length of the basename of
    a temporary file created by the Opam/findlib package ["bos"]. *)
let bos_tmp_name_max = String.length "bos-837f7c.tmp"

let dirsep_length = String.length Fpath.dir_sep

(** [has_windows_path_problem file] gives true if either the length of [file]
    exceeds the Windows maximum {!windows_max_path} or if a temporary file
    created by the Opam/findlib package ["bos"] in the directory of [file]
    would exceed the Windows maximum {!windows_max_path} *)
let has_windows_path_problem file =
  Sys.win32
  && (String.length (Fpath.to_string file) >= windows_max_path
     || String.length (Fpath.to_string (Fpath.parent file))
        + dirsep_length + bos_tmp_name_max
        >= windows_max_path)

let write ?mode file content =
  match OS.File.write ?mode file content with
  | Ok v -> Ok v
  | Error m when has_windows_path_problem file ->
      Rresult.R.(
        error_msg
          (Fmt.str
             "We recommend that you rename your directories to be smaller \
              because there was a failure writing to the pathname %a. It is \
              likely caused by that pathname (or a temporary filename like \
              bos-837f7c.tmp in the same directory) exceeding the default \
              Windows %d character pathname limit. It may also be what the \
              system reported: %a."
             Fpath.pp file windows_max_path pp_msg m))
  | Error msg -> Error msg

(* Public Functions *)

let current_directory ?(err = Fun.id) () =
  map_rresult_error_to_string ~err (OS.Dir.current ())

let absolute_path ?(err = Fun.id) fp =
  if Fpath.is_abs fp then Result.Ok (Fpath.normalize fp)
  else
    match current_directory ~err () with
    | Ok pwd -> Result.Ok Fpath.(normalize (pwd // fp))
    | Error e -> Error e

let walk_down ?(err = Fun.id) ?(max_depth = 0) ~from_path ~f () =
  let open Monad_syntax_rresult (struct
    let box_error = err
  end) in
  let rec walk walk_path path_on_fs path_attributes depth =
    (* pre-order traversal: visit the path first *)
    let* () =
      map_string_to_rresult_error (f ~depth ~path_attributes walk_path)
    in
    let* path_is_dir, child_pathize =
      match walk_path with
      | Root ->
          let* dir_exists = OS.Dir.exists path_on_fs in
          Ok (dir_exists, fun child -> child)
      | File relpath ->
          let raise_err _child =
            failwith
              (Fmt.str
                 "Should be impossible to descend below the File %a. Started \
                  from %a and got to %a"
                 Fpath.pp relpath Fpath.pp from_path Fpath.pp path_on_fs)
          in
          Ok (false, raise_err)
      | Directory relpath -> Ok (true, fun child -> Fpath.(relpath // child))
    in
    match path_is_dir with
    | true ->
        if depth < max_depth then
          (* pre-order traversal: descend last *)
          let rec siblings ~first = function
            | [] -> Ok ()
            | hd :: tl ->
                let child_path_attributes =
                  match (first, tl = []) with
                  | false, true -> Path_attributes.of_list [ Last_in_directory ]
                  | true, true ->
                      Path_attributes.of_list
                        [ First_in_directory; Last_in_directory ]
                  | true, _ -> Path_attributes.of_list [ First_in_directory ]
                  | _ -> Path_attributes.empty
                in
                let child_path_on_fs = Fpath.(path_on_fs // hd) in
                let* child_dir_exists = OS.Dir.exists child_path_on_fs in
                let* () =
                  match child_dir_exists with
                  | true ->
                      walk
                        (Directory (child_pathize hd))
                        child_path_on_fs child_path_attributes (depth + 1)
                  | false ->
                      walk
                        (File (child_pathize hd))
                        child_path_on_fs child_path_attributes (depth + 1)
                in
                siblings ~first:false tl
          in
          let* dir_entries = OS.Dir.contents ~rel:true path_on_fs in
          let sorted_dir_entries = List.sort Fpath.compare dir_entries in
          let* () = siblings ~first:true sorted_dir_entries in
          Ok ()
        else Ok ()
    | false -> Ok ()
  in
  map_rresult_error_to_string ~err
    (let* from_path = OS.Path.must_exist from_path in
     walk Root from_path Path_attributes.empty 0)

let find_up ?(err = Fun.id) ?(max_ascent = 20) ~from_dir ~basenames () =
  let open Monad_syntax_rresult (struct
    let box_error = err
  end) in
  let rec validate = function
    | [] -> Ok ()
    | hd :: tl -> (
        let basename_norm = Fpath.normalize hd in
        match List.length (Fpath.segs basename_norm) with
        | 1 -> validate tl
        | 0 ->
            Rresult.R.error_msgf
              "No basename can be empty. The find-up search was given the \
               following basenames: %a"
              Fmt.(Dump.list Fpath.pp)
              basenames
        | _ ->
            Rresult.R.error_msgf
              "Basenames cannot have directory separators. The find-up search \
               was given the invalid basename: %a"
              Fpath.pp hd)
  in
  let rec search path basenames_remaining ascents_remaining =
    if ascents_remaining <= 0 || Fpath.is_root path then Ok None
    else
      match basenames_remaining with
      | [] ->
          let basedir, _rel = Fpath.split_base path in
          search basedir basenames (ascents_remaining - 1)
      | hd :: tl ->
          let candidate = Fpath.(path // hd) in
          let* exists = OS.File.exists candidate in
          if exists then Ok (Some candidate)
          else search path tl ascents_remaining
  in
  map_rresult_error_to_string ~err
    (let* () = validate basenames in
     let* from_dir = OS.Dir.must_exist from_dir in
     search (Fpath.normalize from_dir)
       (List.map Fpath.normalize basenames)
       max_ascent)

let touch_file ?(err = Fun.id) ~file () =
  let open Monad_syntax_rresult (struct
    let box_error = err
  end) in
  map_rresult_error_to_string ~err
    (let parent_file = Fpath.parent file in
     let* created = OS.Dir.create parent_file in
     if created then
       Logs.debug (fun l ->
           l "[touch_file] Created directory %a" Fpath.pp parent_file);
     let* exists = OS.File.exists file in
     if exists then
       (* Modify access and modification times to the current time (0.0). *)
       Ok (Unix.utimes (Fpath.to_string file) 0.0 0.0)
     else (* Write empty file *)
       write ~mode:0o644 file "")

let copy_file ?(err = Fun.id) ?mode ~src ~dst () =
  let open Monad_syntax_rresult (struct
    let box_error = err
  end) in
  map_rresult_error_to_string ~err
    (let* src = OS.File.must_exist src in
     let* mode =
       match mode with Some m -> Ok m | None -> OS.Path.Mode.get src
     in
     let* data = OS.File.read src in
     let parent_dst = Fpath.parent dst in
     let* created = OS.Dir.create parent_dst in
     if created then
       Logs.debug (fun l ->
           l "[copy_file] Created directory %a" Fpath.pp parent_dst);
     OS.File.write ~mode dst data)

let copy_dir ?(err = Fun.id) ~src ~dst () =
  let open Monad_syntax_rresult (struct
    let box_error = err
  end) in
  let do_copy_dir ~src ~dst =
    let raise_fold_error fpath result =
      Rresult.R.error_msgf
        "@[[copy_dir] A copy directory operation errored out while visiting \
         %a.@]@,\
         @[  @[%a@]@]" Fpath.pp fpath
        (Rresult.R.pp
           ~ok:(Fmt.any "<unknown copy_dir problem>")
           ~error:Rresult.R.pp_msg)
        result
    in
    let cp rel = function
      | Error _ as e ->
          (* no more copying if we had an error *)
          e
      | Ok () -> (
          let* rel =
            match (Fpath.equal src rel, Fpath.relativize ~root:src rel) with
            | true, _ -> Ok dir_dot
            | false, Some r -> Ok r
            | false, None ->
                Rresult.R.error_msg
                  (Fmt.str
                     "During copy found a path %a that was not a subpath of \
                      the source directory %a"
                     Fpath.pp rel Fpath.pp src)
          in
          let src = Fpath.(normalize (src // rel))
          and dst = Fpath.(normalize (dst // rel)) in
          let* isdir = OS.Dir.exists src in
          match isdir with
          | true ->
              let+ created = OS.Dir.create dst in
              if created then
                Logs.debug (fun l ->
                    l "[copy_dir] Created directory %a" Fpath.pp dst);
              ()
          | false ->
              let* mode = OS.Path.Mode.get src in
              let* data = OS.File.read src in
              let parent_dst = Fpath.parent dst in
              let* created = OS.Dir.create parent_dst in
              if created then
                Logs.debug (fun l ->
                    l "[copy_dir] Created directory %a" Fpath.pp parent_dst);
              let* () =
                if Sys.win32 then (
                  (* Avoid the error:
                        rename Z:\\source\\dkml-install-api\\_opam\\.opam-switch\\build\\dkml-installer-network-ocaml.0.4.0\\_build\\installer-work\\archive\\generic\\staging\\staging-unixutils\\generic\\bos-7a2f24.tmp to Z:\\source\\dkml-install-api\\_opam\\.opam-switch\\build\\dkml-installer-network-ocaml.0.4.0\\_build\\installer-work\\archive\\generic\\staging\\staging-unixutils\\generic\\unix_install.bc.exe: Permission denied
                     Windows does not allow renames if the target file exists.

                     But if we simply delete it we get the true error:
                        delete file Z:\\source\\dkml-install-api\\_opam\\.opam-switch\\build\\dkml-installer-network-ocaml.0.4.0\\_build\\installer-work\\archive\\generic\\staging\\staging-unixutils\\generic\\unix_install.bc.exe: Permission denied
                     which has permissions:
                        -r-xr-xr-x

                     So bos.0.2.1 is probably trying to delete but not checking
                     for success, or not deleting at all. Either way it needs
                     a chmod. Need to upstream a fix with bos.0.2.1 or perhaps
                     Stdlib!
                  *)
                  let* exists = OS.File.exists dst in
                  if exists then Unix.chmod (Fpath.to_string dst) 0o644;
                  Ok ())
                else Ok ()
              in
              let+ () = write ~mode dst data in
              ())
    in
    let* folds =
      OS.Path.fold ~err:raise_fold_error ~dotfiles:true cp (Result.Ok ())
        [ src ]
    in
    match folds with
    | Ok () -> Result.Ok ()
    | Error msg ->
        Rresult.R.error_msg
          (Fmt.str
             "@[[copy_dir] @[Failed to copy the directory@]@[@ from %a@]@[@ to \
              %a@]@]@ @[(%a)@]"
             Fpath.pp src Fpath.pp dst Rresult.R.pp_msg msg)
  in
  map_rresult_error_to_string ~err
    (let* src = OS.Dir.must_exist src in
     let* abs_src = map_string_to_rresult_error (absolute_path src) in
     let* abs_dst = map_string_to_rresult_error (absolute_path dst) in
     do_copy_dir ~src:abs_src ~dst:abs_dst)
