open Uucd

let red fmt = Printf.sprintf ("\027[31m"^^fmt^^"\027[m")
let green fmt = Printf.sprintf ("\027[32m"^^fmt^^"\027[m")
let yellow fmt = Printf.sprintf ("\027[33m"^^fmt^^"\027[m")
let blue fmt = Printf.sprintf ("\027[36m"^^fmt^^"\027[m")

let red_s = red "%s"
let green_s = green "%s"
let yellow_s = yellow "%s"
let blue_s = blue "%s"

module Cpset = Set.Make (struct type t = int let compare n m = n - m end)

let collect p r =
  Cpmap.fold (fun cp ps m -> match find ps p with None -> m | Some x -> Cpmap.add cp x m) r Cpmap.empty

let ucd_or_die inf =
  try
    let ic = if inf = "-" then stdin else open_in inf in
    let d = Uucd.decoder (`Channel ic) in
    Printf.eprintf "Loading UCD data, please wait... %!";
    match Uucd.decode d with
    | `Ok db ->
      Printf.eprintf "done.\n%!";
      db
    | `Error e ->
      let (l0, c0), (l1, c1) = Uucd.decoded_range d in
      Printf.eprintf "Error: %s:%d.%d-%d.%d: %s\n%!" inf l0 c0 l1 c1 e;
      exit 1
  with
  | Sys_error e -> Printf.eprintf "Error: %s\n%!" e; exit 1

let select v p r =
  let s =
    Cpmap.fold (fun cp ps s ->
        match find ps p with None -> s | Some x -> if x = v then Cpset.add cp s else s) r Cpset.empty
  in
  Cpset.fold Cset.add s []

let alphabetic ucd =
  select true alphabetic ucd
let uppercase ucd =
  select true uppercase ucd
let lowercase ucd =
  select true lowercase ucd
let decimal_number ucd =
  select `Nd general_category ucd
let hex_digit ucd =
  select true hex_digit ucd
let control r =
  select `Cc general_category r
let space_separator r =
  select `Zs general_category r
let surrogate r =
  select `Cs general_category r
let unassigned r =
  select `Cn general_category r
let punctuation r =
  let s =
    Cpmap.fold (fun cp ps s ->
        match find ps general_category with
        | None -> s
        | Some (`Pc | `Pd | `Ps | `Pe | `Pi | `Pf | `Po) -> Cpset.add cp s
        | Some _ -> s) r Cpset.empty
  in
  Cpset.fold Cset.add s []
let white_space ucd =
  select true white_space ucd

let mark r =
  let s =
    Cpmap.fold (fun cp ps s ->
        match find ps general_category with
        | None -> s
        | Some (`Mn | `Mc | `Me) -> Cpset.add cp s
        | Some _ -> s) r Cpset.empty
  in
  Cpset.fold Cset.add s []

let connector_punctuation r =
  select `Pc general_category r

let join_control r =
  select true join_control r

let out ppf name cs =
  Format.fprintf ppf "@\n(* %d range(s) *)@\n" (List.length cs);
  Format.fprintf ppf "@[<hov 2>let %s =@ [@ " name;
  List.iter (fun (a, b) -> Format.fprintf ppf "(%i, %i);@ " a b) cs;
  Format.fprintf ppf "]@."

let collect_foldcases r =
  let h = Hashtbl.create 0 in
  let k = ref Cpset.empty in
  Cpmap.iter (fun cp ps ->
      match find ps simple_case_folding with
      | None | Some `Self -> ()
      | Some (`Cp cp') -> k := Cpset.add cp' !k; Hashtbl.add h cp' cp) r;
  Cpset.fold (fun cp l -> List.sort compare (cp :: Hashtbl.find_all h cp) :: l) !k []

let make_foldranges ll =
  let l = List.sort (fun (a, _) (a', _) -> a - a') ll in
  let rec loop = function
    | (a, b) :: rest ->
        let rec loop1 i = function
          | ((a', b') :: rest) as r ->
              if b' - a' = b - a && a' = a + i + 1 then
                loop1 (i + 1) rest
              else
                (a, a + i, b - a) :: loop r
          | [] ->
              []
        in
        loop1 0 rest
    | [] ->
        []
  in
  loop l

let out_foldcase ppf r =
  let ll = collect_foldcases r in
 let aux = function
    | x :: rest ->
        let rec loop a = function
          | b :: rest ->
              (a, b) :: loop b rest
          | [] ->
              (a, x) :: []
        in
        loop x rest
    | [] ->
        assert false
  in
  let ll = List.concat (List.map aux ll) in
  let ll = make_foldranges ll in
  Format.fprintf ppf "@\n@[<hov 2>let foldcase = [@\n";
  List.iter (fun (a, b, d) -> Format.fprintf ppf "(%i, %i, %i);@ " a b d) ll;
  Format.fprintf ppf "]@]@\n"

let ucd = "http://www.unicode.org/Public/7.0.0/ucdxml/ucd.all.grouped.zip"
let in_name = Filename.chop_extension (Filename.basename ucd) ^ ".xml"

let download_ucd () =
  let command fmt = Printf.ksprintf Sys.command fmt in
  Printf.eprintf "Downloading %s, please wait...\n%!" ucd;
  let ret = command "curl -O %s" ucd in
  if ret <> 0 then (Printf.eprintf "Error: %d.\n%!" ret; exit 1);
  Printf.eprintf "Unzipping %s, please wait...\n%!" ucd;
  let ret = command "unzip %s" (Filename.basename ucd) in
  if ret <> 0 then (Printf.eprintf "Error: %d.\n%!" ret; exit 1)

let main () =
  Arg.parse [] (fun _ -> ()) (Printf.sprintf "%s > lib/unicode_groups.ml" Sys.argv.(0));
  if not (Sys.file_exists in_name) then download_ucd ();
  let ucd = ucd_or_die in_name in
  let r = ucd.repertoire in
  let ppf = Format.std_formatter in
  Format.fprintf ppf "(* GENERATED BY %s; DO NOT EDIT. *)@\n" Sys.argv.(0);
  Format.fprintf ppf "(* %s > lib/unicode_groups.ml *)@\n" Sys.argv.(0);
  Format.fprintf ppf "@[<v 0>";
  out ppf "alphabetic" (alphabetic r);
  out ppf "punctuation" (punctuation r);
  out ppf "uppercase" (uppercase r);
  out ppf "lowercase" (lowercase r);
  out ppf "decimal_number" (decimal_number r);
  out ppf "hex_digit" (hex_digit r);
  out ppf "control" (control r);
  out ppf "white_space" (white_space r);
  out ppf "space_separator" (space_separator r);
  out ppf "unassigned" (unassigned r);
  out ppf "surrogate" (surrogate r);
  out ppf "mark" (mark r);
  out ppf "connector_punctuation" (connector_punctuation r);
  out ppf "join_control" (join_control r);
  out_foldcase ppf r;
  Format.fprintf ppf "@]@."

let _ =
  main ()