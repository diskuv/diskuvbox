type t = {
  log_config_style_renderer : Fmt.style_renderer option;
  log_config_level : Logs.level option;
}
(** the type of log configuration *)

(** [create ?log_config_style_renderer ?log_config_level ()] creates log configuration *)
let create ?log_config_style_renderer ?log_config_level () =
  { log_config_style_renderer; log_config_level }

(** [to_args] translates the configuration to {!Bos.Cmd.t} *)
let to_args { log_config_style_renderer; log_config_level } =
  let color =
    match log_config_style_renderer with
    | None -> "auto"
    | Some `None -> "never"
    | Some `Ansi_tty -> "always"
  in
  Bos.Cmd.(
    empty
    % ("--verbosity=" ^ Logs.level_to_string log_config_level)
    % ("--color=" ^ color))
