#use "topfind"

#require "bos"

#require "fmt"

#require "fpath"

open Bos

let print_result =
  Fmt.pr "Result: %a@\n"
    Rresult.R.(
      pp
        ~ok:
          Fmt.(
            const string "Ok ( Fpath.v {|" ++ Fpath.pp ++ const string "|} )")
        ~error:
          Fmt.(const string "Error ( `Msg {|" ++ pp_msg ++ const string "|} )"))
;;

print_endline "\n\n========= 20 MB ========\n\n";;
print_result @@ OS.File.must_exist (Fpath.v "_build/test_20m");;
print_endline "\n\n========= 5 GB ========\n\n";;
print_result @@ OS.File.must_exist (Fpath.v "_build/test_5gb")
