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
