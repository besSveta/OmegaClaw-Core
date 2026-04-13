---
name: research-workflow
description: End-to-end research workflow for MettaClaw. Iterative planning,
  data acquisition, experiments, and write-up. For tasks like building
  predictive models, comparing algorithms, analyzing data.
---

# Research Workflow (MettaClaw)

Follow this workflow when solving research tasks.
Produce reproducible artifacts and an evolving write-up.

## Project Structure

All projects live under `/workspace/research/<slug>/`.
The `research-start` skill creates the base folders.
You create the markdown files as you go.

/workspace/research/<slug>/
  topic.txt            # created by research-start
  00_problem.md        # research question, scope, metrics
  01_theory.md         # data sources, methods, assumptions
  02_plan.md           # plan with milestones A B C
  03_sanity_checks.md  # data integrity, baseline results
  04_experiments.md    # experiment log
  05_results.md        # final results, tables, interpretation
  06_conclusions.md    # findings, validation, next iteration
  src/                 # all scripts
  data/                # raw and processed data
  runs/                # configs + metrics (JSON)
  figures/             # plots and charts


## Operating Mode

- Work autonomously with a **10-hour wall-time budget** per request unless the user changes it. Make your own decisions on implementation details.
- Use `pin` to track current step and status between iterations.
- Use `query` to recall the plan or previous results if context is lost.
- All file paths must be absolute: `/workspace/research/slug/...`
- Write code via `write-file`, run via `shell`. Never output code in `send`.
- Save seeds and versions in every script.
- Store metrics as JSON in `runs/`.

### When to ask the user (batch questions into one message):
- Missing credentials, access, or files
- Ambiguous goal or success metric
- Methodological choice that materially changes results
- Compute constraints (experiment won't finish)

### User checkpoints (mandatory pauses):
1. **Checkpoint 1 (Data Ready):** data acquired, cleaned, sanity-checked,
   simple baseline run. Call `research-checkpoint` and WAIT.
2. **Checkpoint 2 (Results Ready):** first experiment sweep done,
   results summarized, next iteration proposed.
   Call `research-checkpoint` and WAIT.

**Do NOT advance past a checkpoint until the user responds.**

## Step-by-Step

### Step 1 — Define the problem
- Call `(research-start "slug" "topic")` to create project folders
- Write research question, scope, success metrics, constraints:
  `(write-file "/workspace/research/slug/00_problem.md" "content")`
- `(research-step "slug" "problem-defined" "question: X metric: Y"
                  "search online for related methods and data sources")`

### Step 2 — Research and plan
- Search online for related methods and data sources:
   `(tavily-search "query")`
- Save findings:
  `(write-file "/workspace/research/slug/01_theory.md" "content")`
- `(research-step "slug" "theory-saved" "sources: X methods: Y"
                  "write 02_plan.md based on findings")`
- Based on findings write detailed plan:
  - Data: sources, format, splits, leakage risks
  - Methods: models/algorithms to try
  - Milestones A (data ready), B (experiments), C (results)
  - Stop/pivot conditions
- `(write-file "/workspace/research/slug/02_plan.md" "content")`
- `(remember "RESEARCH_PLAN [slug]: milestones A B C ...")`
- `(research-step "slug" "plan-created" "milestones A B C"
                 "prepare data and run baseline")`

### Step 3 — Prepare data + sanity checks

Depends on the environment:

**Local (default):**
- Write a baseline script that acquires data and runs a simple model:
  `(write-file "/workspace/research/slug/src/baseline.py" "code")`
  `(shell "cd /workspace/research/slug && python src/baseline.py")`
  The script should: load/download data, basic preprocessing,
  simple model or heuristic, save metrics to `runs/baseline.json`
- Check output, fix issues, iterate

**Colab notebook (if user requests):**
- Generate a notebook with all cells: data acquisition, preprocessing,
  baseline model, metrics output
  `(write-file "/workspace/research/slug/src/baseline.ipynb" "content")`
- Send it to user:
  `(send "Notebook ready at /workspace/research/slug/src/baseline.ipynb")`
- Ask user to run it and share the output before proceeding
- **WAIT for output. Do NOT advance until user shares results.**

**Other tools (R, SQL, etc.) — use whatever fits the task.**

- Document findings:
  `(write-file "/workspace/research/slug/03_sanity_checks.md" "content")`
  Include: data shape, distributions, missing values, baseline metric
- `(research-step "slug" "data-ready" "N rows, baseline metric=X"
                  "call research-checkpoint and wait for user")`
- `(research-checkpoint "slug" "Data ready. Baseline: X. Proceed with experiments?")`
- **WAIT. Do NOT advance until user responds.**

### Step 4 — Run experiments
- After user responds: `(query "research plan slug")` to recall plan
- Write experiment scripts in `src/`, run via `shell`
- Store configs and metrics in `runs/*.json`
- Update `04_experiments.md` with each run:
  hypothesis, config, seed, metrics
- After EACH experiment:
  `(research-step "slug" "experiment-N" "config=X metric=Y"
                  "run next experiment or write results")`

### Step 5 — Write results !!!!!!!
- Add tables, interpretation, limitations:
  `(write-file "/workspace/research/slug/05_results.md" "content")`
- `(research-step "slug" "results-written" "best: model=X metric=Y"
                  "write conclusions")`

### Step 6 — Conclude and validate
- Summarize findings, validate against success criteria,
  identify next research iteration:
  `(write-file "/workspace/research/slug/06_conclusions.md" "content")`
- `(research-step "slug" "conclusions-done" "summary"
                  "call research-checkpoint and wait for user")`
- `(research-checkpoint "slug" "Results ready. Finding: X. Next iteration: Y. Proceed?")`
- **WAIT. Do NOT advance until user responds.**

### Step 7 — Complete
- When user approves or says stop:
  `(research-complete "slug")`