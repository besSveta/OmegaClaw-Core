!(import_prolog_function atomic_list_concat)
!(import_prolog_function split_string)
!(import_prolog_function read_line_to_string)
!(import_prolog_function get_time)
!(import_prolog_function string_length)
!(import_prolog_function sub_string)
!(import_prolog_function swrite)
!(import_prolog_function sread)
!(import_prolog_function string_concat)

(= (sleep $t)
   (progn (translatePredicate (sleep $t))
          True))

(= (exists-file $file)
   (progn (translatePredicate (exists_file $file))
          True))

!(import_prolog_functions_from_file (library OmegaClaw-Core ./src/utils.pl) (safe_exists_directory safe_exists_file))

(= (string-replace $str $a $b)
   (atomic_list_concat (split_string $str $a "") $b))

(= (string-safe $str)
   (string-replace (string-replace (string-replace $str "\"\"" "_quote_") "\n" "_newline_") "'" "_apostrophe_"))

(= (get_time_as_string)
   (progn (translatePredicate (format_time (Predicate (string $String)) "%Y-%m-%d %H:%M:%S" (get_time)))
          $String))

(= (last_chars $String $N)
   (let $Len (string_length $String)
        (sub_string $String (max 0 (- $Len $N)) $_ 0)))

(= (configure $name $default)
   (let $value (argk $name $default)
        (add-atom &self (= ($name) $value))))
   

(= (take $k ()) ())
(= (take $k (cons $h $t))
   (if (== $k 0)
       ()
       (cons $h (take (- $k 1) $t))))

(= (newline)
   (progn (translatePredicate (atom_codes $NL (10)))
          $NL))

(= (atom_to_number $str)
   (let $res (collapse (progn (translatePredicate (atom_number $str $num)) $num))
        (if (== () $res)
            $str
            (car-atom $res))))

(= (argk $Prefix)
   (let $Atom (argv $1)
         (let $KeyEq (string_concat $Prefix "=")
            (progn
               (translatePredicate (atom_string $Atom $Str))
               (translatePredicate (sub_string $Str 0 $KeyLen $After $KeyEq))
               (translatePredicate (sub_string $Str $KeyLen $After 0 $Value))
               (translatePredicate (atom_string $Res $Value))
               (atom_to_number $Res)))))

(= (argk $Prefix $default)
   (let $res (collapse (argk $Prefix))
        (if (== $res ())
            $default
            (car-atom $res))))

( = (directory-files $dir)
   (progn (translatePredicate (directory_files $dir $files))
          $files)
)

( = (directory-dirs $dir)
  (let $f (directory-files $dir)
       (filter-dirs  $f $dir)
   )
)


(= (filter-dirs $files $dir)
   (if (== $files ())
       ()
       (progn (translatePredicate (atom_string (car-atom $files) $first))
               (let* (
                      ($tail     (cdr-atom $files))
                      ($fullpath (py-str ($dir "/" $first)))
                      ($rest     (filter-dirs $tail $dir)))
                         (if (or (== $first ".") (== $first ".."))
                             $rest
                             (if (safe_exists_directory $fullpath)
                                 (cons-atom $first $rest)
                                 $rest))
                 )
        )
    )
)
