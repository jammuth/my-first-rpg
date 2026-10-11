# CLAUDE.md

This file is read automatically by Claude Code at the start of every session in this repo. It has two kinds of content:

- **Universal** sections — how I work, true across all my projects.
- **Per-project** sections — marked `<!-- FILL IN PER PROJECT -->`, edit these first when you clone this template for a new repo.

---

## Project Overview

<!-- FILL IN PER PROJECT -->
<!-- 2-4 sentences: what this project is, who it's for, and any context that should change how Claude approaches it (e.g. "payment logic, correctness is non-negotiable" vs "hobby project, move fast"). -->

---

## Guardrails — ask before doing these

- **Never commit directly to `main`/`master`.** Always work on a feature branch (see Git Workflow below).
- **Never add a new dependency without asking first.** When proposing one, state *why that specific package* (not just "a dependency is needed") — what it does, why it's a better fit than writing it myself or using an existing dependency, and any notable footprint (native bindings, transitive deps, license).
- **Never push, open a PR, or merge unless explicitly told to.** See Git Workflow below for the full push/PR/cleanup process.

---

## Communication & Working Style

- **Never assume — ask.** For meaningful decisions (approach/architecture, scope, anything with a real tradeoff) that are ambiguous or underspecified, stop and ask a clarifying question or lay out the options rather than picking one silently. This does not apply to small implementation details (variable names, minor formatting, etc.) — use judgment there.

---

## Code Style & Conventions

- **Comments:** no comments explaining *what* code does — only *why*, and only when the logic is genuinely non-obvious (a hidden constraint, a workaround, a subtle invariant).

---

## Testing

- **Always write tests for new logic** as part of implementing it, not as a follow-up.
- **Run the new test immediately after implementation** to confirm it passes before moving on.
- **Run the full test suite before saying a task is done, and before committing.** A task isn't complete if the full suite hasn't been run and passed.

---

## Git Workflow

- **Start of work:** if not already on a feature branch, create one off `main` with a descriptive name (e.g. `feat/add-rate-limiting`, `fix/null-check-in-parser`).
- **"Ship it" / explicit push request:** push the feature branch, open a PR targeting `main`, and give me the PR link. Never merge it myself — I review and merge.
- **"Clean up the repo" (after I've merged the PR):** check out `main`, pull the latest changes, then delete stale branches — both local and remote (the merged feature branch, plus any other branches that are fully merged into `main`). Never delete a branch that has unmerged commits without confirming first.

---

## Commit Conventions

- **Conventional Commits format:** `<type>: <subject>` — e.g. `feat: add rate limiting to auth endpoint`, `fix: handle null user in session middleware`, `chore: bump lodash to 4.17.21`. Common types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`.
- **One commit per logical change** — don't bundle unrelated changes into one commit, and don't leave a string of WIP commits; each commit should stand on its own.
- **Include the `Co-Authored-By: Claude` trailer** on commits (this is this harness's default — no need to suppress it).

---

## Tech Stack Defaults

<!-- Tie-breakers when a project doesn't specify otherwise. Override per-project in that project's own CLAUDE.md section if it needs something different. -->

**JavaScript/TypeScript**
- Language: TypeScript by default for anything beyond a trivial script.
- Package manager: `pnpm`.
- Lint/format: ESLint + Prettier.

**Python**
- Package/env manager: `uv`.
- Lint/format: Ruff.

---

## Progress Reporting

- **Task tracking:** for any multi-step task, maintain a visible task list (create it up front, update status as steps complete) rather than narrating progress in plain text only.
- **In-progress updates:** short update at key moments — found the root cause, changed approach, hit a blocker. Not a running commentary on every action.
- **End-of-task summary — detailed, peer-review style.** Write it as if justifying the change to a senior dev reviewing the PR:
  - What changed and why (the reasoning behind the approach, not just the diff).
  - Files touched, and what changed in each.
  - Alternatives considered and why they were rejected, if any were meaningfully in play.
  - Tradeoffs or known limitations of the approach taken.
  - Test coverage added and results of running the suite.

---

## Security & Secrets

- **Never commit `.env`** (or any file holding real secret values). It must be in `.gitignore` from the start of the project.
- **Always maintain an `example.env`** alongside it — same keys, no real values, with a comment/hint on each line describing what should go there (where to get it, expected format, etc.). Keep it in sync whenever a new env var is introduced.
- **Proactively flag hardcoded secrets** (keys, tokens, passwords, connection strings) whenever encountered — including in pre-existing code, not just new code I write. Flag immediately and note that it needs rotating if it's already been committed.

