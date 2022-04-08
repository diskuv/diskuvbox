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

(* Cmdliner 1.0 -> 1.1 deprecated a lot of things. But until Cmdliner 1.1
   is in common use in Opam packages we should provide backwards compatibility.
   In fact, Diskuv OCaml is not even using Cmdliner 1.1. *)
[@@@alert "-deprecated"]

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

let touch_files_t =
  let doc =
    Fmt.str
      "One or more files to touch. If a $(docv) does not exist it will be \
       created."
  in
  let filelist_t =
    Arg.(non_empty & pos_all string [] & info [] ~doc ~docv:"FILE")
  in
  Term.(const (List.map Fpath.v) $ filelist_t)

let basenames_t =
  let doc =
    Fmt.str
      "One or more basenames to search. The command fails when a $(docv) is \
       blank or has a directory separator."
  in
  let stringfilelist_t =
    Arg.(non_empty & pos_right 0 string [] & info [] ~doc ~docv:"BASENAME")
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

let dir_t ~verb ~docv =
  let doc =
    Fmt.str "Directory %s. The command fails when $(docv) does not exist." verb
  in
  let stringfile_t =
    Arg.(required & pos 0 (some dir) None & info [] ~doc ~docv)
  in
  Term.(const Fpath.v $ stringfile_t)

let path_printer_t =
  let doc =
    Fmt.str
      "Print files and directories in native format. On Windows the native \
       format uses backslashes as directory separators, while on Unix \
       (including macOS) the native format uses forward slashes. If $(opt) is \
       not specified then all files and directories are printed with the \
       directory separators as forward slashes."
  in
  let native_t = Arg.(value & flag & info [ "native" ] ~doc) in
  let path_printer native =
    if native then Fpath.pp
    else fun fmt path ->
      Format.pp_print_string fmt
        (let s = Fmt.str "%a" Fpath.pp path in
         String.map (function '\\' -> '/' | c -> c) s)
  in
  Term.(const path_printer $ native_t)

let chmod_mode_opt_t =
  let doc =
    "The chmod mode permission of the destination file, in octal. If not \
     specified then the chmod mode permission of the source file is used. \
     Examples: 644, 755."
  in
  let modestring_opt_t =
    Arg.(value & opt (some string) None & info [ "m"; "mode" ] ~doc)
  in
  let from_octal s_opt =
    match s_opt with Some s -> int_of_string_opt ("0o" ^ s) | None -> None
  in
  Term.(const from_octal $ modestring_opt_t)

let copy_file_cmd =
  let doc = "Copy a source file to a destination file." in
  let man =
    [
      `S Manpage.s_description;
      `P
        "Copy the SRCFILE to the DESTFILE. $(b,copy-file) will follow symlinks.";
    ]
  in
  let copy_file (_ : Log_config.t) src dst chmod_mode_opt =
    fail_if_error
      (Diskuvbox.copy_file ~err:box_err ?mode:chmod_mode_opt ~src ~dst ())
  in
  ( Term.(
      const copy_file $ copts_t
      $ source_file_t ~verb:"to copy"
      $ dest_file_t $ chmod_mode_opt_t),
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
  let copy_file_into (_ : Log_config.t) source_files dest_dir chmod_mode_opt =
    List.iter
      (fun source_file ->
        let dst = Fpath.(dest_dir / basename source_file) in
        fail_if_error
          (Diskuvbox.copy_file ~err:box_err ?mode:chmod_mode_opt
             ~src:source_file ~dst ()))
      source_files
  in
  ( Term.(
      const copy_file_into $ copts_t
      $ source_files_t ~verb:"to copy"
      $ dest_dir_t $ chmod_mode_opt_t),
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

let touch_file_cmd =
  let doc = "Touch one or more files." in
  let man =
    [ `S Manpage.s_description; `P "Touch one or more FILE... files." ]
  in
  let touch_file (_ : Log_config.t) files =
    List.iter
      (fun file -> fail_if_error (Diskuvbox.touch_file ~err:box_err ~file ()))
      files
  in
  ( Term.(const touch_file $ copts_t $ touch_files_t),
    Term.info "touch-file" ~doc ~exits:Term.default_exits ~man )

let find_up_cmd =
  let doc = "Find a file in the current directory or one of its ancestors." in
  let man =
    [
      `S Manpage.s_description;
      `P
        "Find a file that matches the name as one or more specified FILE... \
         files in the FROMDIR directory.";
      `P "Will print the matching file if found. Otherwise will print nothing.";
    ]
  in
  let find_up (_ : Log_config.t) from_dir basenames path_printer =
    let result =
      fail_if_error (Diskuvbox.find_up ~err:box_err ~from_dir ~basenames ())
    in
    match result with
    | Some path -> print_endline (Fmt.str "%a" path_printer path)
    | None -> ()
  in
  ( Term.(
      const find_up $ copts_t
      $ dir_t ~verb:"to search" ~docv:"FROMDIR"
      $ basenames_t $ path_printer_t),
    Term.info "find-up" ~doc ~exits:Term.default_exits ~man )

let max_depth_t =
  let doc =
    "Maximum depth to print. A maximum depth of 0 will never print deeper than \
     the name of the starting directory. A maximum depth of 1 will, at most, \
     print the contents of the starting directory. Defaults to 0"
  in
  Arg.(value & opt int 0 & info [ "d"; "max-depth" ] ~doc)

type charsets = Ascii | Utf8

type print_char_pairs = {
  down : string;
  down_halfright : string;
  halfdown_halfright : string;
  right : string;
  halfright : string;
}

type encoding = { print_char_pairs : print_char_pairs }

let encoding_t =
  let l = [ ("ASCII", Ascii); ("UTF-8", Utf8) ] in
  let doc =
    Fmt.str
      "The encoding of the graphic characters printed: %a. Defaults to ASCII"
      Fmt.(list ~sep:comma (pair ~sep:nop string nop))
      l
  in
  let v = Arg.(value & opt (enum l) Ascii & info [ "e"; "encoding" ] ~doc) in
  let f = function
    | Ascii ->
        {
          print_char_pairs =
            {
              down = "| ";
              down_halfright = "|-";
              halfdown_halfright = "`-";
              right = "--";
              halfright = "- ";
            };
        }
    | Utf8 ->
        {
          print_char_pairs =
            {
              down = "│ ";
              down_halfright = "├─";
              halfdown_halfright = "└─";
              right = "──";
              halfright = "─ ";
            };
        }
  in
  Term.(const f $ v)

let tree_cmd =
  let doc = "Print a directory tree." in
  let man =
    [
      `S Manpage.s_description;
      `P "Print the directory tree starting at the DIR directory.";
    ]
  in
  let tree (_ : Log_config.t) dir max_depth path_printer { print_char_pairs } =
    let _padding d = String.make d ' ' in
    let entry_pp fmt = function
      | Diskuvbox.Directory relpath ->
          Fmt.pf fmt "%a/" path_printer (Fpath.base relpath)
      | File relpath -> Fmt.pf fmt "%a" path_printer (Fpath.base relpath)
      | Root -> failwith "Should never have entry_pp on a Root"
    in
    let dirs_finished = Array.make max_depth false in
    let veins ~last depth =
      if depth <= 0 then [||]
      else
        let char_pairs = Array.make (depth * 2) "  " in
        (* set all but the last 2 pairs of characters *)
        if depth >= 2 then
          for d_i = 0 to depth - 2 do
            if not dirs_finished.(d_i) then
              Array.set char_pairs (d_i * 2) print_char_pairs.down
          done;
        (* set the 2nd last pair of characters *)
        Array.set char_pairs
          ((depth * 2) - 2)
          (if last then print_char_pairs.halfdown_halfright
          else if dirs_finished.(depth - 1) then print_char_pairs.right
          else print_char_pairs.down_halfright);
        (* set the last pair of characters *)
        Array.set char_pairs ((depth * 2) - 1) print_char_pairs.halfright;
        char_pairs
    in
    let veins_pp = Fmt.(array ~sep:nop string) in
    let f ~depth ~path_attributes walk_path =
      let open Diskuvbox in
      match
        (depth, Path_attributes.mem Last_in_directory path_attributes, walk_path)
      with
      | 0, _, _ ->
          print_endline @@ Fmt.str "%a" path_printer dir;
          Ok ()
      | _, false, _ ->
          Array.set dirs_finished (depth - 1) false;
          print_endline
          @@ Fmt.str "%a%a" veins_pp (veins ~last:false depth) entry_pp
               walk_path;
          Ok ()
      | _, true, _ ->
          print_endline
          @@ Fmt.str "%a%a" veins_pp (veins ~last:true depth) entry_pp walk_path;
          Array.set dirs_finished (depth - 1) true;
          Ok ()
    in
    fail_if_error
      (Diskuvbox.walk_down ~err:box_err ~max_depth ~from_path:dir ~f ())
  in
  ( Term.(
      const tree $ copts_t
      $ dir_t ~verb:"to print" ~docv:"DIR"
      $ max_depth_t $ path_printer_t $ encoding_t),
    Term.info "tree" ~doc ~exits:Term.default_exits ~man )

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

let cmds =
  [
    copy_dir_cmd;
    copy_file_cmd;
    copy_file_into_cmd;
    touch_file_cmd;
    find_up_cmd;
    tree_cmd;
    help_cmd;
  ]

let () = Term.(exit @@ eval_choice default_cmd cmds)
