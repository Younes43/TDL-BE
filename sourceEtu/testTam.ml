
open Compilateur

(* Changer le chemin d'accès du jar. *)
let runtamcmde = "java -jar ../../runtam.jar"
(* let runtamcmde = "java -jar /mnt/n7fs/.../tools/runtam/runtam.jar" *)

let show_error file output =
  try
    Scanf.sscanf output "Syntaxic error: asm.SyntaxicError: Error in line %d, column %d"
      (fun line column ->
        let ic = Unix.open_process_in ("sed -n "^string_of_int line ^"p "^file) in
        let err = input_line ic in
        close_in ic;
        let col = String.make (column-1) ' ' in
        Format.asprintf "%s\n%s^" err col)
  with Scanf.Scan_failure _ -> ""

(* Execute the TAM code obtained from the rat file and return the ouptut of this code *)
let runtamcode cmde ratfile =
  let tamcode = compiler ratfile in
  let (tamfile, chan) = Filename.open_temp_file "test" ".tam" in
  output_string chan tamcode;
  flush chan;
  close_out chan;
  let ic = Unix.open_process_in (cmde ^ " " ^ tamfile) in
  let printed = input_line ic in
  close_in ic;
  let error = show_error tamfile printed in
  Sys.remove tamfile;   (* à commenter si on veut étudier le code TAM. *)
  String.trim (printed^"\n"^error)

(* Compile and run ratfile, then print its output *)
let runtam ratfile =
  print_string (runtamcode runtamcmde ratfile)

(* requires ppx_expect in jbuild, and `opam install ppx_expect` *)
let%expect_test "testprintint" =
  runtam "../../fichiersRat/src-rat-tam-test/testprintint.rat";
  [%expect{| 42 |}]

let%expect_test "testprintbool" =
  runtam "../../fichiersRat/src-rat-tam-test/testprintbool.rat";
  [%expect{| true |}]

let%expect_test "testprintrat" =
   runtam "../../fichiersRat/src-rat-tam-test/testprintrat.rat";
   [%expect{| [4/5] |}]

let%expect_test "testaddint" =
  runtam "../../fichiersRat/src-rat-tam-test/testaddint.rat";
  [%expect{| 42 |}]

let%expect_test "testaddrat" =
  runtam "../../fichiersRat/src-rat-tam-test/testaddrat.rat";
  [%expect{| [7/6] |}]

let%expect_test "testmultint" =
  runtam "../../fichiersRat/src-rat-tam-test/testmultint.rat";
  [%expect{| 440 |}]

let%expect_test "testmultrat" =
  runtam "../../fichiersRat/src-rat-tam-test/testmultrat.rat";
  [%expect{| [14/3] |}]

let%expect_test "testnum" =
  runtam "../../fichiersRat/src-rat-tam-test/testnum.rat";
  [%expect{| 4 |}]

let%expect_test "testdenom" =
  runtam "../../fichiersRat/src-rat-tam-test/testdenom.rat";
  [%expect{| 7 |}]

let%expect_test "testwhile1" =
  runtam "../../fichiersRat/src-rat-tam-test/testwhile1.rat";
  [%expect{| 19 |}]

let%expect_test "testif1" =
  runtam "../../fichiersRat/src-rat-tam-test/testif1.rat";
  [%expect{| 18 |}]

let%expect_test "testif2" =
  runtam "../../fichiersRat/src-rat-tam-test/testif2.rat";
  [%expect{| 21 |}]

let%expect_test "factiter" =
  runtam "../../fichiersRat/src-rat-tam-test/factiter.rat";
  [%expect{| 120 |}]

let%expect_test "complique" =
  runtam "../../fichiersRat/src-rat-tam-test/complique.rat";
  [%expect{| [9/4][27/14][27/16][3/2] |}]

let%expect_test "factfun1" =
  runtam "../../fichiersRat/src-rat-tam-test/testfun1.rat";
  [%expect{| 1 |}]

let%expect_test "factfun2" =
  runtam "../../fichiersRat/src-rat-tam-test/testfun2.rat";
  [%expect{| 7 |}]

let%expect_test "factfun3" =
  runtam "../../fichiersRat/src-rat-tam-test/testfun3.rat";
  [%expect{| 10 |}]

let%expect_test "factfun4" =
  runtam "../../fichiersRat/src-rat-tam-test/testfun4.rat";
  [%expect{| 10 |}]

let%expect_test "factfuns" =
  runtam "../../fichiersRat/src-rat-tam-test/testfuns.rat";
  [%expect{| 28 |}]

let%expect_test "factrec" =
  runtam "../../fichiersRat/src-rat-tam-test/factrec.rat";
  [%expect{| 120 |}]

let%expect_test "pointeur1" =
  runtam "../../fichiersRat/src-rat-tam-test/pointeur1.rat";
  [%expect{| 3 |}]

let%expect_test "pointeur2" =
  runtam "../../fichiersRat/src-rat-tam-test/pointeur2.rat";
  [%expect{| 5 |}]

let%expect_test "enum2" =
  runtam "../../fichiersRat/src-rat-tam-test/enum2.rat";
  [%expect{| [9/4][27/14][27/16][3/2] |}]

let%expect_test "enum1" =
  runtam "../../fichiersRat/src-rat-tam-test/enum1.rat";
  [%expect{| truetruefalsefalse |}]

let%expect_test "enum3" =
  runtam "../../fichiersRat/src-rat-tam-test/enum3.rat";
  [%expect{| falsetrue |}]

let%expect_test "case1" = 
  runtam "../../fichiersRat/src-rat-tam-test/case1.rat";
  [%expect{| 910 |}]

let%expect_test "case2" = 
  runtam "../../fichiersRat/src-rat-tam-test/case2.rat";
  [%expect{| 78 |}]

let%expect_test "case3" = 
  runtam "../../fichiersRat/src-rat-tam-test/case3.rat";
  [%expect{| 3 |}]

let%expect_test "case4" = 
  runtam "../../fichiersRat/src-rat-tam-test/case4.rat";
  [%expect{| 7 |}]

let%expect_test "case5" = 
  runtam "../../fichiersRat/src-rat-tam-test/case5.rat";
  [%expect{| 2096 |}]

let%expect_test "case6" = 
  runtam "../../fichiersRat/src-rat-tam-test/case6.rat";
  [%expect{| 96 |}]

let%expect_test "case7" = 
  runtam "../../fichiersRat/src-rat-tam-test/case7.rat";
  [%expect{| 4278 |}]

let%expect_test "case8" = 
  runtam "../../fichiersRat/src-rat-tam-test/case8.rat";
  [%expect{| 19 |}]

let%expect_test "surcharge1" = 
  runtam "../../fichiersRat/src-rat-tam-test/testSurcharge1.rat";
  [%expect{| 12 |}]

let%expect_test "ultime" = 
  runtam "../../fichiersRat/src-rat-tam-test/testUltime.rat";
  [%expect{| [15/1][8/12][8/1][15/1][8/1][15/2] |}]

