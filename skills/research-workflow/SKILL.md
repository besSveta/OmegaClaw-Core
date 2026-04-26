---
name: research-workflow
description: End-to-end research workflow for OmegaClaw. Iterative planning,
  data acquisition, experiments, and write-up.
---

# Research Workflow (OmegaClaw)

This workflow guides you through problem definition, online research,
and creating a detailed execution plan. Once the user approves the plan,
it replaces these instructions and you follow it step by step.

## Project Structure

All projects live under `/workspace/research/<slug>/`.
The `research-start` skill creates the base folders.
/workspace/research/<slug>/
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
  `(write-file "/workspace/research/slug/00_problem.md" "content")`
- `(research-step "slug" "problem-defined" "question: X metric: Y"
                  "search online for related methods and data sources")`

### Step 2 — Research and create full plan
- Search online for related methods and data sources:
  `(tavily-search "query")`
- Save findings:
  `(write-file "/workspace/research/slug/01_theory.md" "content")`
- `(research-step "slug" "theory-saved" "sources: X methods: Y"
                  "write full 02_plan.md")`
- Write the full execution plan using the Plan Template below:
  `(write-file "/workspace/research/slug/02_plan.md" "content")`
- `(remember "RESEARCH_PLAN [slug]: milestones A B C ...")`
- `(research-step "slug" "plan-created" "milestones A B C"
                  "present plan to user for approval")`

### Step 3 — Plan approval
- Present plan to user:
  `(send "Plan ready. Review 02_plan.md. Approve or suggest changes.")`
- `(research-checkpoint "slug" "Plan ready. Approve or suggest changes?")`
- **WAIT. Do NOT advance until user responds.**
- If user approves: `(load-gen-skill "slug" "02_plan.md")`
- If user requests changes: update 02_plan.md, present again, wait again
- If user approves: `(load-gen-skill "slug" "02_plan.md")`
---

## Plan Template

When writing `02_plan.md`, include ALL sections below.
The plan must be self-contained — after loading it replaces this file.


# Research Plan: <topic>

## Operating Rules
- Work autonomously. Make your own decisions on implementation details.
- Use `pin` to track current step between iterations.
- Use `(query "research plan slug")` if you lose track of the plan.
- All file paths must be absolute: `/workspace/research/slug/...`
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
- Write: `(write-file "/workspace/research/slug/src/baseline.py" "code")`
  Script: load data, preprocess, simple model, save runs/baseline.json
- Run: `(shell "cd /workspace/research/slug && python src/baseline.py")`
- `(research-step "slug" "data-ready" "N rows, baseline=X"
                  "call research-checkpoint")`
- `(research-checkpoint "slug" "Data ready. Baseline: X. Proceed?")`
- **WAIT for user.**

## Milestone B — Experiments

### B1 — <experiment name>
- Hypothesis: <what you expect>
- Write: `(write-file ".../src/experiment_1.py" "code")`
- Run: `(shell "cd ... && python src/experiment_1.py")`
- Save: `(write-file ".../runs/exp1.json" "metrics")`
- `(research-step "slug" "experiment-1" "metric=Y" "next experiment")`

### B2 — <next experiment>
...

## Milestone C — Results + Conclusions

### C1 — Write results
- `(write-file ".../05_results.md" "content")`
- `(research-step "slug" "results-written" "best: X" "write conclusions")`

### C2 — Conclusions
- `(write-file ".../06_conclusions.md" "content")`
- `(research-step "slug" "conclusions-done" "summary"
                  "call research-checkpoint")`
- `(research-checkpoint "slug" "Results ready. Next iteration? Proceed?")`
- **WAIT for user.**

## Milestone D — Complete
- `(research-complete "slug")`

## Stop/Pivot Conditions
- `<when to stop or change approach>`
