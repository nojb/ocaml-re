(*
   RE - A regular expression library

   Copyright (C) 2014 Nicolas Ojeda Bar
   email: n.oje.bar@gmail.com

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation, with
   linking exception; either version 2.1 of the License, or (at
   your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
*)

(** Module [Re]: regular expressions commons *)

type t
(** Regular expression *)

type re
(** Compiled regular expression *)

type substrings
(** Match informations *)

(** {2 Compilation and execution of a regular expression} *)

val compile : t -> re
(** Compile a regular expression into an executable version that can be
    used to match strings, e.g. with {!exec}. *)

val exec :
  re -> string -> substrings
(** [exec re str] matches [str] against the compiled expression [re],
    and returns the matched groups if any.
    @param pos optional beginning of the string (default 0)
    @param len length of the substring of [str] that can be matched (default [-1],
      meaning to the end of the string
    @raise Not_found if the regular expression can't be found in [str]
*)

val execp :
  re -> string -> bool
(** Similar to {!exec}, but returns [true] if the expression matches,
    and [false] if it doesn't *)

val exec_partial :
  re -> string -> [ `Full | `Partial | `Mismatch ]
(* More detailed version of {!exec_p} *)

(** {2 Substring extraction} *)

val get : substrings -> int -> string
(** Raise [Not_found] if the group did not match *)

val get_ofs : substrings -> int -> int * int
(** Raise [Not_found] if the group did not match *)

val get_all : substrings -> string array
(** Return the empty string for each group which did not match *)

val get_all_ofs : substrings -> (int * int) array
(** Return [(-1,-1)] for each group which did not match *)

val test : substrings -> int -> bool
(** Test whether a group matched *)

(** {2 High Level Operations} *)

type 'a gen = unit -> 'a option

val all :
  re -> string -> substrings list
(** Repeatedly calls {!exec} on the given string, starting at given
    position and length.*)

val all_gen :
  re -> string -> substrings gen
(** Same as {!all} but returns a generator *)

val matches :
  re -> string -> string list
(** Same as {!all}, but extracts the matched substring rather than
    returning the whole group. This basically iterates over matched
    strings *)

val matches_gen :
  re -> string -> string gen
(** Same as {!matches}, but returns a generator. *)

val split :
  re -> string -> string list
(** [split re s] splits [s] into chunks separated by [re]. It yields
    the chunks themselves, not the separator. For instance
    this can be used with a whitespace-matching re such as ["[\t ]+"]. *)

val split_gen :
  re -> string -> string gen

type split_token =
  [ `Text of string  (** Text between delimiters *)
  | `Delim of substrings (** Delimiter *)
  ]

val split_full :
  re -> string -> split_token list

val split_full_gen :
  re -> string -> split_token gen

val replace :
  ?all:bool ->   (** Default: true. Otherwise only replace first occurrence *)
  re ->          (** matched groups *)
  f:(substrings -> string) ->  (* how to replace *)
  string ->     (** string to replace in *)
  string
(** [replace ~all re ~f s] iterates on [s], and replaces every occurrence
    of [re] with [f substring] where [substring] is the current match.
    If [all = false], then only the first occurrence of [re] is replaced. *)

type uchar = int

(** {2 String expressions (literal match)} *)

(* val str : string -> t *)
val char : uchar -> t

(** {2 Basic operations on regular expressions} *)

val bos : t
(** Beginning of string *)

val eos : t
(** End of string *)

val alt : t list -> t
(** Alternative *)

val seq : t list -> t
(** Sequence *)

val empty : t
(** Match nothing *)

val epsilon : t
(** Empty word *)

val rep : t -> t
(** 0 or more matches *)

val rep1 : t -> t
(** 1 or more matches *)

val repn : t -> int -> int option -> t
(** Repeated matches *)

val opt : t -> t
(** 0 or 1 matches *)

(** {2 Match semantics} *)

val longest : t -> t
(** Longest match *)

val shortest : t -> t
(** Shortest match *)

val first : t -> t
(** First match *)

(** {2 Repeated match modifiers} *)

val greedy : t -> t
(** Greedy *)

val non_greedy : t -> t
(** Non-greedy *)

(** {2 Groups (or submatches)} *)

val group : t -> t
(** Delimit a group *)

val no_group : t -> t
(** Remove all groups *)

val nest : t -> t
(** when matching against [nest e], only the group matching in the
       last match of e will be considered as matching *)

(** {2 Character sets} *)

val set : string -> t
(** Any character of the string *)

val rg : uchar -> uchar -> t
(** Character ranges *)

(** {2 Predefined character sets} *)

val any : t
(** Any character *)

val notnl : t
(** Any character but a newline '\n' *)

val alnum : t
val wordc : t
val alpha : t
val ascii : t
val blank : t
val cntrl : t
val digit : t
val graph : t
val lower : t
val print : t
val punct : t
val space : t
val upper : t
val xdigit : t

(** {2 Case modifiers} *)

val case : t -> t
(** Case sensitive matching *)

val no_case : t -> t
(** Case insensitive matching *)
