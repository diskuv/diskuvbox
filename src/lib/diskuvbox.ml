open Bos

let map_rresult_error_to_string = function
  | Ok v -> Result.ok v
  | Error msg -> Result.error (Fmt.str "%a" Rresult.R.pp_msg msg)

module Monad_syntax_rresult = struct
  let ( let* ) = Rresult.R.bind

  let ( let+ ) x f = Rresult.R.map f x
end

let copy_dir ~src ~dst =
  let _copy_dir ~src ~dst =
    let open Monad_syntax_rresult in
    let raise_fold_error fpath result =
      Rresult.R.error_msgf
        "@[A copy directory operation errored out while visiting %a.@]@,\
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
      | Ok () ->
          let src = Fpath.(src // rel) and dst = Fpath.(dst // rel) in
          let* mode = OS.Path.Mode.get src in
          let* data = OS.File.read src in
          let* (_ : bool) = OS.Dir.create (Fpath.parent dst) in
          let+ () = OS.File.write ~mode dst data in
          ()
    in
    let* folds = OS.Path.fold ~err:raise_fold_error cp (Result.ok ()) [ src ] in
    match folds with
    | Ok () -> Result.ok ()
    | Error msg ->
        Rresult.R.error_msg
          (Fmt.str
             "@[@[Failed to copy the directory@]@[@ from %a@]@[@ to %a@]@ .@]@ \
              @[%a@]"
             Fpath.pp src Fpath.pp dst Rresult.R.pp_msg msg)
  in
  map_rresult_error_to_string (_copy_dir ~src ~dst)
