# GOAL — DRM.jl ↔ drmTMB catch-up lane (IMMUTABLE — re-read at the top of EVERY arc)

Read this first, every cycle. Auto-compact eats messages, not this file. Unsure
after a compaction? Re-read THIS, then `checkpoint.md`, then continue.

## Mission

Close the **measured** drmTMB parity gaps in DRM.jl, each backed by a
native-vs-Julia parity fixture, **without ever claiming more than the twin does**.

## Definition of done

- [ ] All in-fence arcs landed on `main` with **green CI**
- [ ] `tools/parity_ledger.py` re-run and the countdown recorded
- [ ] Plan-vs-actual reconciled to `docs/dev-log/plan-actual/`

## Headline

The ledger countdown falls. Every capability shipped is parity-verified against
**installed drmTMB 0.7.0**, and every boundary drmTMB declares is mirrored rather
than quietly exceeded.

## Anchor

drmTMB **0.7.0**, installed. `origin/main` was `f5ec53634` at A0 and had already
moved to `859c0f6e6` — **the twin moves fast**. Re-run before trusting any count:

```bash
python3 tools/parity_ledger.py --drmtmb ../drmTMB --ref origin/main
```

At lane start: **22 export gaps · 11 capability rows · 14 closed gates · CLOSURE PASS**.

## Invariants (never violate, even to finish faster)

- Verification means reading the **LOG** and inspecting the **ARTEFACT**, never
  the exit code.
- A narrow or negative search is not proof. "No X exists" usually means the query
  missed X.
- Destructive or irreversible ⇒ **STOP and surface**, even if it feels urgent.
- A genuine surprise that invalidates the plan ⇒ **STOP**, back to G0. Do not
  patch around it mid-loop.
- **Tolerances are MEASURED, never guessed.** Multi-seed spread first, then set
  the bound. Arc A-fix exists because this was broken once: a tolerance fitted to
  one Julia 1.10 run failed on 1.12, where `log(ν−2)` deviated **0.5198** against
  a 0.25 bound. **Julia 1.12 is installed locally — reproduce version-specific
  failures rather than guessing** (`julia +1.12`).
- Close every arc by stating what it did **NOT** cover.

## Gate policy

**DRM.jl (owner-approved this run):** push, open PR, **auto-merge on green CI**.
Two structural rules, because the failure already happened twice — arming
auto-merge, then pushing more onto that branch, so later work rode an earlier
approval:

- **One branch per arc.**
- **Auto-merge is the LAST action on a branch**, after the final commit, and only
  once the arc is complete.

**drmTMB — STOP GATE. Open a PR, never merge.** That repo has **9 live lanes**
and an open 0.7.0 release slice (#959). Merging into another team's active
release unattended is *not* covered by the DRM.jl approval. **Config cannot
enforce this** — `gh pr merge` permission patterns are global, not per-repo. It
is a discipline rule. Hold it.

**Also STOP for:** `sigma()`'s public contract (arc A-sigma) before it lands.

## Out of scope (the fence — do NOT drift here)

- Issue **#136** stays OPEN — never `close`/`fix`/`resolve` near that number.
- **#49 / FIML / missing data** — PARKED.
- **Registrator / Julia General** — D-111 forbids.
- **GPL vendoring** from drmTMB — DRM.jl is MIT; parity uses generated outputs.
- The verified **q=4 core** (2.18×, logLik −256.51) — never regress it.
- drmTMB edits outside the narrow lane (`R/julia-bridge.R`,
  `tests/testthat/test-julia-*`, `vignettes/julia-engine.Rmd`).
- Staging `.worktrees/` or `.codex/agents/shannon-coordinator.toml`; unscoped
  `git add -A`.

## Per-arc verification (non-negotiable)

- Targeted Julia suites during an arc (~2–5 min); **full suite at the PR boundary**
  via CI (`test (1)` + `test (1.10)` + `docs`).
- **`DRM_PARITY_TESTS=1` mandatory** on any arc touching `bf()` / formula grammar.
- **Every new capability gets a `tools/parity_fixture.R` cell** (native-vs-Julia,
  tol 1e-4) which must PASS before the arc closes.
- AGENTS.md DoD: impl + tests + docstrings + worked example +
  `docs/dev-log/check-log.d/` entry + after-task report + Rose claim-vs-evidence.

## Authoritative WHAT

`LOOP/ultra-plan.md` holds the binding detail. This file wins on "what must never
be lost".
