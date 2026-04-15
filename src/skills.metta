(= (getSkills)
   (;INTERNAL:
    "- Remember a particular string such as skills and memories: (remember string_in_quotes)"
    "- Query long-term embedding memory for skills and memories with short phrases only: (query string_in_quotes)"
    "- Episodes searches history for episodes around a time stamp, time format is same as in TIME: (episodes time_string_in_quotes)"
    "- Pin a certain string as short-term working memory item to keep track of task state: (pin string_in_quotes)"
    ;SHELL AND FILE I/O:
    "- Execute shell command without apostrophe in string, it returns the command output to you: (shell string_in_quotes)"
    "- Read file to string: (read-file filename_in_quotes)"
    "- Write string to file: (write-file filename_in_quotes string_in_quotes)"
    "- Append line to file: (append-file filename_in_quotes string_in_quotes)"
    ;COMMUNICATION CHANNELS:
    "- Send message to user: (send string_in_quotes)"
    "- Search the web: (search string_in_quotes)"
    "- Search the web using the Tavily Search Agent: (tavily-search string_in_quotes)"
    "- Get technical analysis for a stock ticker using the Technical Analysis Agent: (technical-analysis ticker_in_quotes)"
    ;CODE EXECUTION:
    "- Execute MeTTa expression: (metta sexpression)"
    "Example to invoke Non-Axiomatic Logic via MeTTa: "
    "(metta (|- ((--> (× sam garfield) friend) (stv 1.0 0.9))"
    "           ((--> garfield animal) (stv 1.0 0.9))))"
    "(metta (|- ((==> (--> (× $1 elephant) eat) (--> $1 ([] dangerous))) (stv 1.0 0.9))"
    "           ((--> (× tiger elephant) eat) (stv 1.0 0.9))))"
    "Also: note the $1 for independent variables, and for negated knowledge use (stv 0.0 0.9)"
    "Additionally |- also works for revision, to merge evidence even when the term of both premises is the same."
    ;WORKFLOW:
    "- Load a workflow skill into active context: (load-skill skillname_in_quotes)"
    "  Available workflows: research-workflow"
    "- Unload active workflow from context: (unload-skill)"
    ;RESEARCH:
    "- Every time when user asks to show current folder respond with result of next function: (shell \"pwd\")"
    "- Every time when user asks to Test folder creation, it should create folder in current directory: (test-research-folders)"
    "- Every time user asks to start research task, investigate, study, analyze, or build ML model load research-workflow skill :(load-skill \"research-workflow\")"
    "- Create research project folders: (research-start slug_in_quotes topic_in_quotes)"
    "- Mark research step done: (research-step slug_in_quotes step_in_quotes result_in_quotes next_action_in_quotes)"
    "- Pause for user approval: (research-checkpoint slug_in_quotes message_in_quotes)"
    "- Finish research and unload workflow: (research-complete slug_in_quotes)"
    "- Recall plan: (query \"research plan slug\")"))


(= (read-file $file)
   (progn (translatePredicate (exists_file $file))
          (translatePredicate (read_file_to_string $file $content ()))
          $content))

(= (write-file $file $str)
   (progn (translatePredicate (open $file write $Out))
          (translatePredicate (write $Out $str))
          (translatePredicate (close $Out))
          True))

(= (append-file $file $str)
   (progn (translatePredicate (exists_file $file))
          (translatePredicate (open $file append $Out))
          (translatePredicate (write $Out $str))
          (translatePredicate (nl $Out)),
          (translatePredicate (close $Out))
          True))

(= (tavily-search $query)
   (py-call (agentverse.tavily_search $query)))

(= (technical-analysis $ticker)
   (py-call (agentverse.technical_analysis $ticker)))

!(import_prolog_functions_from_file (library OmegaClaw-Core ./src/skills.pl) (shell first_char))

(= (metta $str)
   (let $code (sread $str)
        (eval $code)))



;; ============ WORKFLOW LOADER ============
( = (skillsDir) "./repos/OmegaClaw-Core/skills")
(= (load-skill $name)
   (let $path (py-str ((skillsDir) "/" $name "/SKILL.md"))
        (let $content (catch (read-file $path))
             (case $content
                 (((Error $a $b)
                   (send (py-str ("ERROR: skill file not found: " $path))))
                  ($else
                   (progn (change-state! &active_skill $content)
                          (pin (py-str ("ACTIVE_WORKFLOW: " $name
                                        " STATUS: starting"
                                        " NEXT: follow workflow instructions")))
                          (send (py-str ("Loaded workflow: " $name
                                        ". Instructions active in context until completion.")))
                          (py-str ("Skill loaded: " $name)))))))))

(= (unload-skill)
   (progn (change-state! &active_skill "")
          (pin "No active workflow.")
          (send "Workflow unloaded from context.")
          "Skill unloaded"))

;=======================Research========================================
(= (researchDir) "/workspace/research")


;; проверка что модуль загружен
(= (rrresearch)
   "ssearch")

;; Тест создания папок
(= (test-research-folders)
   (shell (py-str ("mkdir -p " (researchDir) "/rrresearch")))
 )

;; LLM decides to start research
;; creates folders for research and asks to create 00_problem.md then search online
(= (research-start $slug $topic)
   (progn (shell (py-str ("mkdir -p " (researchDir) "/" $slug "/src")))
          (shell (py-str ("mkdir -p " (researchDir) "/" $slug "/data")))
          (shell (py-str ("mkdir -p " (researchDir) "/" $slug "/runs")))
          (shell (py-str ("mkdir -p " (researchDir) "/" $slug "/figures")))
          (write-file (py-str ((researchDir) "/" $slug "/topic.txt")) $topic)
          (send (py-str ("Created project: " (researchDir) "/" $slug "\n"
                         "Folders: src/ data/ runs/ figures/")))
          (pin (py-str ("RESEARCH_ACTIVE: " $slug
                        " DIR: " (researchDir) "/" $slug
                        " TOPIC: " $topic
                        " STEP: 1-problem"
                        " ACTION_REQUIRED: Write 00_problem.md then search online"
                        " for related methods and data sources.")))
          $slug))

;; update current step
(= (research-step $slug $step $result $next)
   (progn (remember (py-str ("RESEARCH [" $slug "] done: " $step " — " $result)))
          (send (py-str ("[" $slug "] done: " $step)))
          (pin (py-str ("RESEARCH_ACTIVE: " $slug
                        " DONE: " $step
                        " RESULT: " $result
                        " NEXT: " $next)))
          (py-str ("Done: " $step))))


;; Checkpoint: wait user's response
(= (research-checkpoint $slug $message)
   (progn (pin (py-str ("RESEARCH_ACTIVE: " $slug
                        " STATUS: WAITING_FOR_USER"
                        " DO_NOT_PROCEED"
                        " RESUME: call (query \"research plan " $slug "\") when user responds")))
          (send (py-str ("CHECKPOINT [" $slug "]\n" $message "\n"
                         "Reply to continue.")))
          "Waiting for user"))

;; Unload research skill
(= (research-complete $slug)
   (progn (change-state! &active_skill "")
          (send (py-str ("Research complete: " $slug
                         "\nResults in " (researchDir) "/" $slug "/"
                         "\nWorkflow unloaded from context.")))
          (remember (py-str ("RESEARCH [" $slug "] COMPLETED")))
          (pin "No active research. No active workflow.")
          "Research complete, workflow unloaded"))