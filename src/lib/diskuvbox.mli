val copy_dir : src:Fpath.t -> dst:Fpath.t -> (unit, string) result
(** [copy_dir ~src ~dst] copies the contents of [src] into [dst], creating
    [dst] and any parent directories as necessary. *)
