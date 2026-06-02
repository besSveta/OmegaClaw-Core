;; Build a safe path or empty string if validation fails
(= (safe-instruction-path $project_dir $slug $filename)
   (py-call (helper.safe_path (py-str ($project_dir)) (py-str ($slug)) (py-str ($filename)))))

; loads instructions created during workflow
(= (load-dynamic-instructions $project_dir $slug $filename)
   (if (not (valid-slug $slug))
       (send (py-str ("ERROR: invalid slug: " $slug)))
       (if (not (valid-filename $filename))
           (send (py-str ("ERROR: invalid filename: " $filename)))
           (let $path (safe-instruction-path $project_dir $slug $filename)
                (if (== $path "")
                    (send (py-str ("ERROR: path traversal rejected for " $slug "/" $filename)))
                    (load-dynamic-instructions-safe $path $slug $filename))))))

; actually loads the file (internal). Only called after validation.
(= (load-dynamic-instructions-safe $path $slug $filename)
   (if (not (exists-file $path))
       (send (py-str ("ERROR: file not found: " $path)))
       (let $content (read-file $path)
            (progn
              (change-state! &active_instructions $content)
              (appendToHistory ((get_time_as_string)
                                (newline)
                                (py-str ("LOADED [" $slug "/" $filename "]"))
                                (newline)))
              (pin (py-str ("ACTIVE: " $slug
                            " FILE: " $filename
                            " STATUS: executing"
                            " NEXT: follow loaded instructions")))
              (send (py-str ("Loaded " $filename " for " $slug ". Following instructions.")))
              $content))))


(= (researchDir)
   (let $dir (get-existing-dir (library memory/skills_workspace))
   (py-str ($dir "/research"))))


;; LLM decides to start research
;; creates folders for research and asks to create 00_problem.md then search online
(= (research-start $slug $topic)
    (if (valid-slug $slug)
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
              $slug)
        (send (py-str ("Invalid slug: " $slug ". Only a-z, 0-9, - and _ allowed.")))
       )
)

;; update current step
(= (research-step $slug $step $result $next)
    (if (valid-slug $slug)
       (progn (appendToHistory  ((get_time_as_string) (newline) (py-str  ("RESEARCH [" $slug "] done: " $step " — " $result)) (newline)) )
              (send (py-str ("[" $slug "] done: " $step)))
              (pin (py-str ("RESEARCH_ACTIVE: " $slug
                            " DONE: " $step
                            " RESULT: " $result
                            " NEXT: " $next)))
              (py-str ("Done: " $step)))
        (send (py-str ("Invalid slug: " $slug ". Only a-z, 0-9, - and _ allowed.")))
     )
)


;; Checkpoint: wait user's response
(= (research-checkpoint $slug $message)
    (if (valid-slug $slug)
        (progn (pin (py-str ("RESEARCH_ACTIVE: " $slug
                            " STATUS: WAITING_FOR_USER"
                            " DO_NOT_PROCEED"
                            )))
              (send (py-str ("CHECKPOINT [" $slug "]\n" $message "\n"
                             "Reply to continue.")))
              "Waiting for user")
        (send (py-str ("Invalid slug: " $slug ". Only a-z, 0-9, - and _ allowed.")))
     )
)

;; Unload research skill
(= (research-complete $slug)
    (if (valid-slug $slug)
        (progn (change-state! &active_instructions "")
              (send (py-str ("Research complete: " $slug
                             "\nResults in " (researchDir) "/" $slug "/"
                             "\nWorkflow unloaded from context.")))
              (appendToHistory  ((get_time_as_string) (newline) (py-str  ("RESEARCH [" $slug "] COMPLETED")) (newline)) )
              (pin "No active research. No active workflow.")
              "Research complete, workflow unloaded")
         (send (py-str ("Invalid slug: " $slug ". Only a-z, 0-9, - and _ allowed.")))
      )
)