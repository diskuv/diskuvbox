open Cmdliner

(* Error handling *)

let fail_if_error = function
  | Ok v -> v
  | Error msg -> (
      Logs.err (fun l -> l "FATAL: %s" msg);
      (* print stack trace if Debug or Info *)
      match Logs.level () with
      | Some Debug | Some Info -> failwith msg
      | _ -> exit 1)

let box_err s = fail_if_error (Error s)

(* Help sections common to all commands *)

let help_secs =
  [
    `S Manpage.s_common_options;
    `P "These options are common to all commands.";
    `S "MORE HELP";
    `P "Use `$(mname) $(i,COMMAND) --help' for help on a single command.";
    `S Manpage.s_bugs;
    `P "Check bug reports at https://github.com/diskuv/diskuvbox/issues";
  ]

(* Options common to all commands *)

let setup_log style_renderer level =
  Fmt_tty.setup_std_outputs ?style_renderer ();
  Logs.set_level level;
  Logs.set_reporter (Logs_fmt.reporter ());
  Log_config.create ?log_config_style_renderer:style_renderer
    ?log_config_level:level ()

let copts_t =
  Term.(const setup_log $ Fmt_cli.style_renderer () $ Logs_cli.level ())

(* Commands *)

let source_dirs_t ~verb =
  let doc =
    Fmt.str
      "One or more source directories %s. The command fails when a $(docv) \
       does not exist."
      verb
  in
  let stringdirlist_t =
    Arg.(non_empty & pos_left ~rev:true 0 dir [] & info [] ~doc ~docv:"SRCDIR")
  in
  Term.(const (List.map Fpath.v) $ stringdirlist_t)

let source_files_t ~verb =
  let doc =
    Fmt.str
      "One or more source files %s. The command fails when a $(docv) does not \
       exist."
      verb
  in
  let stringfilelist_t =
    Arg.(
      non_empty & pos_left ~rev:true 0 file [] & info [] ~doc ~docv:"SRCFILE")
  in
  Term.(const (List.map Fpath.v) $ stringfilelist_t)

let source_file_t ~verb =
  let doc =
    Fmt.str
      "The source file %s. The command fails when a $(docv) does not exist."
      verb
  in
  let stringfile_t =
    Arg.(required & pos 0 (some file) None & info [] ~doc ~docv:"SRCFILE")
  in
  Term.(const Fpath.v $ stringfile_t)

let dest_dir_t =
  let doc =
    "Destination directory. If $(docv) does not exist it will be created."
  in
  let stringdir_t =
    Arg.(
      required
      & pos ~rev:true 0 (some string) None
      & info [] ~doc ~docv:"DESTDIR")
  in
  Term.(const Fpath.v $ stringdir_t)

let dest_file_t =
  let doc =
    Fmt.str "Destination file. If $(docv) does not exist it will be created."
  in
  let stringfile_t =
    Arg.(required & pos 1 (some string) None & info [] ~doc ~docv:"DESTFILE")
  in
  Term.(const Fpath.v $ stringfile_t)

let copy_file_cmd =
  let doc = "Copy a source file to a destination file." in
  let man =
    [
      `S Manpage.s_description;
      `P
        "Copy the SRCFILE to the DESTFILE. $(b,copy-file) will follow symlinks.";
    ]
  in
  let copy_file (_ : Log_config.t) src dst =
    fail_if_error (Diskuvbox.copy_file ~err:box_err ~src ~dst ())
  in
  ( Term.(
      const copy_file $ copts_t $ source_file_t ~verb:"to copy" $ dest_file_t),
    Term.info "copy-file" ~doc ~exits:Term.default_exits ~man )

let copy_file_into_cmd =
  let doc = "Copy one or more files into a destination directory." in
  let man =
    [
      `S Manpage.s_description;
      `P
        "Copy one or more SRCFILE... files to the DESTDIR directory. \
         $(b,copy-files-into) will follow symlinks.";
    ]
  in
  let copy_file_into (_ : Log_config.t) source_files dest_dir =
    List.iter
      (fun source_file ->
        let dst = Fpath.(dest_dir / basename source_file) in
        fail_if_error
          (Diskuvbox.copy_file ~err:box_err ~src:source_file ~dst ()))
      source_files
  in
  ( Term.(
      const copy_file_into $ copts_t
      $ source_files_t ~verb:"to copy"
      $ dest_dir_t),
    Term.info "copy-file-into" ~doc ~exits:Term.default_exits ~man )

let copy_dir_cmd =
  let doc =
    "Copy content of one or more source directories to a destination directory."
  in
  let man =
    [
      `S Manpage.s_description;
      `P
        "Copy content of one or more SRCDIR... directories to the DESTDIR \
         directory. $(b,copy-dir) will follow symlinks.";
    ]
  in
  let copy_dir (_ : Log_config.t) source_dirs dest_dir =
    List.iter
      (fun source_dir ->
        fail_if_error
          (Diskuvbox.copy_dir ~err:box_err ~src:source_dir ~dst:dest_dir ()))
      source_dirs
  in
  ( Term.(const copy_dir $ copts_t $ source_dirs_t ~verb:"to copy" $ dest_dir_t),
    Term.info "copy-dir" ~doc ~exits:Term.default_exits ~man )

let help_cmd =
  let doc = "display help about diskuvbox and diskuvbox commands" in
  let help (_ : Log_config.t) = `Help (`Pager, None) in
  let man =
    [
      `S Manpage.s_description;
      `P "Prints help about diskuvbox commands and other subjects...";
      `Blocks help_secs;
    ]
  in
  ( Term.(ret (const help $ copts_t)),
    Term.info "help" ~doc ~exits:Term.default_exits ~man )

let default_cmd =
  let doc = "a box of utilities" in
  ( Term.(ret (const (fun (_ : Log_config.t) -> `Help (`Pager, None)) $ copts_t)),
    Term.info "diskuvbox" ~version:"%%VERSION%%" ~doc
      ~sdocs:Manpage.s_common_options )

let cmds = [ copy_dir_cmd; copy_file_cmd; copy_file_into_cmd; help_cmd ]

let () = Term.(exit @@ eval_choice default_cmd cmds)
