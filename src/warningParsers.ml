open Types
open Helpers

(* agnostic extractors, turning err string into proper data structures *)
(* TODO: don't make these raise error *)

let warning_UnusedVariable code err fileInfo range = raise Not_found

(* need: what the variant is. If it's e.g. a list, instead of saying "doesn't
cover all the cases of the variant" we could say "doesn't cover all the possible
length of the list" *)
let warning_PatternNotExhaustive code err _ _ =
  let unmatchedR = {|this pattern-matching is not exhaustive.\nHere is an example of a value that is not matched:\n([\s\S]+)|} in
  let unmatchedRaw = get_match unmatchedR err in
  let unmatched = if (BatString.get unmatchedRaw 0) = '(' then
    (* format was (Variant1|Variant2|Variant3). We strip the surrounding parens *)
    unmatchedRaw
    |> BatString.lchop
    |> BatString.rchop
    |> split {|\|[\s]*|}
  else
    [unmatchedRaw]
  in
  Warning_PatternNotExhaustive {
    unmatched = unmatched;
  }

let warning_PatternUnused code err fileInfo range = raise Not_found

(* need: offending optional argument name from AST *)
(* need: offending function name *)
let warning_OptionalArgumentNotErased code err fileInfo range =
  (* assume error on one line *)
  let ((startRow, startColumn), (_, endColumn)) = range in
  (* Hardcoding 16 for now. We might one day switch to use the variant from
  https://github.com/ocaml/ocaml/blob/901c67559469acc58935e1cc0ced253469a8c77a/utils/warnings.ml#L20 *)
  let allR = {|this optional argument cannot be erased\.|} in
  let fileLine = BatList.at fileInfo.cachedContent startRow in
  let _ = get_match_n 0 allR err in
  Warning_OptionalArgumentNotErased {
    argumentName = BatString.slice ~first:startColumn ~last:endColumn fileLine;
  }

(* TODO: better logic using these codes *)
let parsers = [
  warning_UnusedVariable;
  warning_PatternNotExhaustive;
  warning_PatternUnused;
  warning_OptionalArgumentNotErased;
]
