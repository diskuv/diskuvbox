open Bos

(* Error Handling *)

type box_error = string -> string

let rresult_error_to_string ~err msg = err (Fmt.str "%a" Rresult.R.pp_msg msg)

let map_rresult_error_to_string ~err = function
  | Ok v -> Result.ok v
  | Error msg -> Result.error (rresult_error_to_string ~err msg)

let map_string_to_rresult_error = function
  | Ok v -> Result.ok v
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
  if Fpath.is_abs fp then Result.ok (Fpath.normalize fp)
  else
    match current_directory ~err () with
    | Ok pwd -> Result.ok Fpath.(normalize (pwd // fp))
    | Error e -> Error e

let copy_file ?(err = Fun.id) ~src ~dst () =
  let open Monad_syntax_rresult (struct
    let box_error = err
  end) in
  map_rresult_error_to_string ~err
    (let* mode = OS.Path.Mode.get src in
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
      OS.Path.fold ~err:raise_fold_error ~dotfiles:true cp (Result.ok ())
        [ src ]
    in
    match folds with
    | Ok () -> Result.ok ()
    | Error msg ->
        Rresult.R.error_msg
          (Fmt.str
             "@[[copy_dir] @[Failed to copy the directory@]@[@ from %a@]@[@ to \
              %a@]@]@ @[(%a)@]"
             Fpath.pp src Fpath.pp dst Rresult.R.pp_msg msg)
  in
  map_rresult_error_to_string ~err
    (let* abs_src = map_string_to_rresult_error (absolute_path src) in
     let* abs_dst = map_string_to_rresult_error (absolute_path dst) in
     do_copy_dir ~src:abs_src ~dst:abs_dst)
