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


(= (valid-slug $slug)
   (if  (== (py-str ("valid")) (py-call (helper.validate_slug (py-str ($slug))))) True False)
 )

(= (instructionsDir) (get-existing-dir (library instructions)))
(= (load-instructions $name)
   (if (not (valid-slug $name))
       (send (py-str ("ERROR: invalid workflow name: " $name)))
       (let $path (py-str ((instructionsDir) "/" $name "/SKILL.md"))
            (if (not (exists-file $path))
                (send (py-str ("ERROR: skill file not found: " $path)))
                (let $content (read-file $path)
                     (progn
                       (change-state! &active_instructions $content)
                       (pin (py-str ("ACTIVE_WORKFLOW: " $name
                                     " STATUS: starting"
                                     " NEXT: follow workflow instructions")))
                       (send (py-str ("Loaded workflow: " $name
                                     ". Instructions active in context until completion.")))
                       (py-str ("Instructions loaded: " $name))))))))

(= (unload-instructions)
   (progn (change-state! &active_instructions "")
          (unload-workflow-skills)
          (pin "No active workflow. Workflow skills cleared.")
          ))

;; Validate filename
(= (valid-filename $filename)
   (if (== (py-str ("valid")) (py-call (helper.validate_filename (py-str ($filename)))))
       True
       False))


; to load skills descriptions which are defined only  for current workflow
(= (add-workflow-skills $skills)
   (progn (change-state! &workflow_skills $skills)
          (pin (py-str ("Workflow skills loaded: " $skills)))))

; to load skills descriptions
(= (unload-workflow-skills)
   (change-state! &workflow_skills ""))

;;========================== Functions to load workflow description =======================
;; returns workflow name and its description
(= (workflows-with-description)
   (let*  ( ($base (instructionsDir))
            ($dirs (directory-dirs $base)))
        (collect-description $dirs $base)))

;; collects workflow description from description.txt
(= (collect-description $dirs $base)
   (if (== $dirs () )
       ()
       (let*  (($tail  (cdr-atom $dirs))
              ($first (car-atom $dirs))
              ($path  (py-str ($base "/" $first "/description.txt")))
              ($rest (collect-description $tail $base)))
         (if (safe-exists-file $path)
             (cons-atom (py-str ($first ": " (read-file $path))) $rest)
            $rest))))