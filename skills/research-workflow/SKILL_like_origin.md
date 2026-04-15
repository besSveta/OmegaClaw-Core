---
name: research-workflow
description: End-to-end scientific/ML research workflow with iterative planning, data acquisition, sanity checks, experiment logging. Use for tasks like building predictive models, comparing algorithms, training models on collected data. Default mode is autonomous execution with explicit user checkpoints: (1) after data is prepared + sanity-checked and ready for real experiments, (2) after a first full experiment sweep with results + proposed next iteration.
---

# Research Workflow

Follow this workflow to solve research tasks while producing reproducible artifacts.

## Project Structure

Create a project folder under `/workspace/research/` using a short slug name:
/workspace/research/<slug>/
  00_problem.md
  01_theory.md
  02_plan.md
  03_sanity_checks.md
  04_experiments.md
  05_results.md
  06_conclusions.md
  src/
  data/
  runs/               # configs + metrics snapshots (JSON)
  figures/


## Operating Mode

- Work autonomously by default.
- Use `pin` to track current step between iterations.
- Use `query` to recall plan or findings if context is lost.
- Always run scripts via `shell`, write code via `write-file`.
- **User checkpoints (default):**
  1. **Checkpoint 1 (Data Ready):** data acquired/loaded, cleaned, documented; baseline run complete.
  2. **Checkpoint 2 (Results + Next Iteration):** first experiment sweep complete; results summarized; next iteration proposed.
- **Question policy:**
  - Self-serve small to medium decisions.
  - Ask user only if blocked by: missing credentials/access, ambiguous goal or metric, compute constraints, choices that materially change results.
  - Batch questions into one message.

## Step-by-Step

1. **Define the problem** (`00_problem.md`)
   - Research question, scope, success criteria/metrics, constraints.

2. **Research and plan**
   - Search online for related methods and data sources.
   - Save findings to `01_theory.md`: data sources, schema, splits, leakage risks, relevant methods.
   - Based on findings write detailed plan to `02_plan.md`:
     milestones A (data ready), B (experiments), C (results), stop/pivot conditions.
   - Save plan to long-term memory via `remember`.

3. **Prepare data + sanity checks** (`03_sanity_checks.md`)
   - Write a baseline script that acquires data and runs a simple model.
   - If task requires other tools (notebooks, R, SQL) — use them instead.
   - Save reproducible artifacts: seeds and versions in code, metrics in `runs/baseline.json`.
   - Document findings in `03_sanity_checks.md`: data shape, distributions, missing values, baseline metric.
   - Reach **Checkpoint 1** and ask the user to approve the experiment sweep.

4. **Run experiments with logging** (`04_experiments.md`, `runs/`)
   - Recall plan via `query` after checkpoint.
   - Track each run: hypothesis, config, seed, metrics in `runs/*.json`.
   - Update `04_experiments.md` and `02_plan.md` with results.

5. **Write results** (`05_results.md`)
   - Add tables, interpret results, note limitations.

6. **Conclude + validate** (`06_conclusions.md`)
   - Summarize findings, validate against success criteria.
   - Identify next research iteration.
   - Reach **Checkpoint 2** and ask the user for direction.

## Execution Notes

- Prefer deterministic scripts in `src/`.
- Record versions and random seeds in every script.
- Store metrics in machine-readable form (`runs/*.json`).
- All file paths must be absolute: `/workspace/research/slug/...`