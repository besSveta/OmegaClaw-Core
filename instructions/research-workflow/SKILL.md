---
name: research-workflow
description: End-to-end research workflow for OmegaClaw. Iterative planning,
  data acquisition, experiments, and write-up.
---
# Research Workflow (OmegaClaw)
This workflow guides you through problem definition, online research,
and creating a detailed execution plan. Once the user approves the plan,
it replaces these instructions and you follow it step by step.
## Load Workflow specific skills description
call 
```
  (add-workflow-skills (py-str  ("- Create research project folders: (research-start slug_in_quotes topic_in_quotes)"
    "- Mark research step done: (research-step slug_in_quotes step_in_quotes result_in_quotes next_action_in_quotes)"
    "- Pause for user approval: (research-checkpoint slug_in_quotes message_in_quotes)"
    "- Finish research and unload workflow: (research-complete slug_in_quotes)"
    "- Load a generated file into active context: (load-gen-instructions slug_in_quotes filename_in_quotes)
    "- Get research directory: (researchDir)")))
```
these tools will help you to follow instructions. 
## Project Structure
All projects live under `(py-str ((researchDir) "/<slug>/"))`.
The `research-start` skill creates the base folders.
(researchDir)/<slug>/
  topic.txt            # created by research-start
  00_problem.md        # research question, scope, metrics
  01_theory.md         # data sources, methods, assumptions
  02_plan.md           # full execution plan with concrete commands
  src/                 # all scripts
  data/                # raw and processed data
  runs/                # configs + metrics (JSON)
  figures/             # plots and charts

## Step-by-Step
### Step 1 — Define the problem
- Call `(research-start "slug" "topic")` to create project folders
- Write research question, scope, success metrics, constraints:
  `(write-file (py-str ((researchDir) "/slug/00_problem.md")) "content")`
- `(research-step "slug" "problem-defined" "question: X metric: Y"
                  "search online for related methods and data sources")`
### Step 2 — Research and create plan
- Search online for related methods and data sources:
  `(tavily-search "query")`
- Save findings:
  `(write-file (py-str ((researchDir) "/slug/01_theory.md")) "content")`
- `(research-step "slug" "theory-saved" "sources: X methods: Y"
                  "create plan and present to user")`
- Create the full execution plan using findings and the Plan Template below
- Send plan to user for review:
  `(send "PROPOSED PLAN:\n<full plan text>")`
- `(research-checkpoint "slug" "Plan ready. Approve or suggest changes?")`
- **WAIT. Do NOT advance until user responds.**
### Step 3 — Plan approval
- If user approves:
  `(write-file (py-str ((researchDir) "/slug/02_plan.md")) "approved plan text")`
  `(research-step "slug" "plan-approved" "milestones A B C"
                  "follow plan from Milestone A")`
  `(load-dynamic-instructions-safe (researchDir) "slug" "02_plan.md")` - where `(researchDir)` - gets the directory where files for current research are located
- If user requests changes:
  Revise plan, send again, wait again
## Plan Template
When writing `02_plan.md`, include ALL sections below.
The plan must be self-contained — after loading it replaces this file.

# Research Plan: <topic>
## Operating Rules
- Work autonomously. Make your own decisions on implementation details.
- Use `pin` to track current step between iterations.
- All file paths must be built from `(researchDir)`: e.g. `(py-str ((researchDir) "/slug/..."))`
- Write code via `write-file`, run via `shell`. Never output code in `send`.
- Save seeds and versions in every script.
- Store metrics as JSON in `runs/`.
- Use `(research-step "slug" "step" "result" "next")` after each milestone.
- Do NOT advance past a checkpoint until user responds.
- When to ask the user (batch questions into one message):
  - Missing credentials, access, or files
  - Ambiguous goal or success metric
  - Methodological choice that materially changes results
## Milestone A — Data Ready + Baseline
### A1 — Prepare data and baseline
- `<concrete data source and acquisition method>`
- Write: `(write-file (py-str ((researchDir) "/slug/src/baseline.py")) "code")`
  Script: load data, preprocess, simple model, save runs/baseline.json
- Run: `(shell (py-str ("cd " (researchDir) "/slug && python src/baseline.py")))`
- `(research-step "slug" "data-ready" "N rows, baseline=X"
                  "call research-checkpoint")`
- `(research-checkpoint "slug" "Data ready. Baseline: X. Proceed?")`
- **WAIT for user.**
## Milestone B — Experiments
### B1 — <experiment name>
- Hypothesis: <what you expect>
- Write: `(write-file (py-str ((researchDir) "/slug/src/experiment_1.py")) "code")`
- Run: `(shell (py-str ("cd " (researchDir) "/slug && python src/experiment_1.py")))`
- Save: `(write-file (py-str ((researchDir) "/slug/runs/exp1.json")) "metrics")`
- `(research-step "slug" "experiment-1" "metric=Y" "next experiment")`
### B2 — <next experiment>
...
## Milestone C — Results + Conclusions
### C1 — Write results
- `(write-file (py-str ((researchDir) "/slug/05_results.md")) "content")`
- `(research-step "slug" "results-written" "best: X" "write conclusions")`
### C2 — Conclusions
- `(write-file (py-str ((researchDir) "/slug/06_conclusions.md")) "content")`
- `(research-step "slug" "conclusions-done" "summary"
                  "call research-checkpoint")`
- `(research-checkpoint "slug" "Results ready. Next iteration? Proceed?")`
- **WAIT for user.**
## Milestone D — Complete
- `(research-complete "slug")`
## Stop/Pivot Conditions
- `<when to stop or change approach>`