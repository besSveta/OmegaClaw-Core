(= (getSkills)
   (;INTERNAL:
    "- Remember a particular string such as skills and memories: remember string"
    "- Query long-term embedding memory for skills and memories with short phrases only: query string"
    "- Episodes searches history for episodes around a time stamp, time format is same as in TIME: episodes time_string"
    "- Pin a certain string as short-term working memory item to keep track of task state: pin string"
    ;SHELL AND FILE I/O:
    "- Execute shell command without apostrophe in string, it returns the command output to you: shell string"
    "- Read file to string: read-file filename"
    "- Write string to file: write-file filename string"
    "- Append line to file: append-file filename string",
    ;COMMUNICATION CHANNELS:
    "- Send message to user: send string"
    "- Search the web: search string"
    "- Search the web using the Tavily Search Agent: tavily-search string"
    "- Get technical analysis for a stock ticker using the Technical Analysis Agent: technical-analysis ticker"
    ;CODE EXECUTION:
    "- Execute MeTTa expression: metta sexpression"
    "Example to invoke Non-Axiomatic Logic via MeTTa: "
    "metta (|- ((--> (× sam garfield) friend) (stv 1.0 0.9))"
    "          ((--> garfield animal) (stv 1.0 0.9)))"
    "metta (|- ((==> (--> (× $1 elephant) eat) (--> $1 ([] dangerous))) (stv 1.0 0.9))"
    "          ((--> (× tiger elephant) eat) (stv 1.0 0.9)))"
    "Also: note the $1 for independent variables, and for negated knowledge use (stv 0.0 0.9)"
    "Additionally |- also works for revision, to merge evidence even when the term of both premises is the same."
    "You can also use PLN:"
    "metta (|~ ((Implication (Inheritance $1 (IntSet Feathered))"
    "           (Inheritance $1 Bird)) (stv 1.0 0.9))"
    "          ((Inheritance Pingu (IntSet Feathered)) (stv 1.0 0.9)))"
    ;WORKFLOW:
    "- Load an existing workflow instructions into active context: (load-instructions workflow_name_in_quotes)"
    "  Available workflows: " (workflows-with-description)
    "- Unload active workflow from context: (unload-instructions)"))


(= (read-file $file)
   (progn (translatePredicate (exists_file $file))
          (translatePredicate (read_file_to_string $file $content ()))
          $content))

(= (write-file $file $str)
   (progn (translatePredicate (open $file write $Out))
          (translatePredicate (write $Out $str))
          (translatePredicate (close $Out))
          WRITE-FILE-SUCCESS))

(= (append-file $file $str)
   (progn (translatePredicate (exists_file $file))
          (translatePredicate (open $file append $Out))
          (translatePredicate (write $Out $str))
          (translatePredicate (nl $Out)),
          (translatePredicate (close $Out))
          APPEND-FILE-SUCCESS))

(= (tavily-search $query)
   (py-call (agentverse.tavily_search $query)))

(= (technical-analysis $ticker)
   (py-call (agentverse.technical_analysis $ticker)))

!(import_prolog_functions_from_file (library OmegaClaw-Core ./src/skills.pl) (shell first_char gc read_file_tail))

(= (metta $str)
   (let $code (sread $str)
        (repr (swrite (eval $code)))))

(= (pin $x)
   PIN-SUCCESS)

;; ============ WORKFLOW LOADER ============

(= (get-existing-dir $paths)
    (let $dir $paths
       (if (exists-directory $dir)
           $dir
           (empty)))
)

(= (instructionsDir) (get-existing-dir (library instructions)))
(= (load-instructions $name)
   (let $path (py-str ((instructionsDir) "/" $name "/SKILL.md"))
        (let $content (catch (read-file $path))
             (case $content
                 (((Error $a $b)
                   (send (py-str ("ERROR: skill file not found: " $path))))
                  ($else
                   (progn (change-state! &active_instructions $content)
                          (pin (py-str ("ACTIVE_WORKFLOW: " $name
                                        " STATUS: starting"
                                        " NEXT: follow workflow instructions")))
                          (send (py-str ("Loaded workflow: " $name
                                        ". Instructions active in context until completion.")))
                          (py-str ("Instructions loaded: " $name)))))))))

(= (unload-instructions)
   (progn (change-state! &active_instructions "")
          (pin "No active workflow.")
          ))
(= (valid-slug $slug)
   (if  (== (py-str ("valid")) (py-call (helper.validate_slug (py-str ($slug))))) True False)
 )
(= (load-gen-instructions $project_dir $slug $filename)
   (let $content (read-file (py-str ($project_dir "/" $slug "/" $filename)))
        (progn (change-state! &active_instructions $content)
               (appendToHistory  ((get_time_as_string) (newline) (py-str ("LOADED [" $slug "/" $filename "]")) (newline)) )
               (pin (py-str ("ACTIVE: " $slug
                             " FILE: " $filename
                             " STATUS: executing"
                             " NEXT: follow loaded instructions")))
               (send (py-str ("Loaded " $filename " for " $slug ". Following instructions.")))
               $content)))

;;========================== Functions to load workflow description =======================
;; returns workflow name and its description
(= (workflows-with-description)
   (let*  ( ($base (instructionsDir))
            ($dirs (directory-dirs $base)))
        (collect-description $dirs )))

;; collects workflow description from description.txt
(= (collect-description $dirs )
   (if (== $dirs () )
       ()
       (let*  (($tail  (cdr-atom $dirs))
              ($first (car-atom $dirs))
              ($path  (py-str ($first "/description.txt")))
              ($rest (collect-description $tail)))
         (if (safe-exists-file $path)
             (cons-atom (read-file $path) $rest)
            $rest))))