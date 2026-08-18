## ARC CARD — mean-RE REML (Gaussian `(1 | g)`)

**Mode:** size
**Requested outcome:** capability-status row `REML with ordinary random effects (Gaussian mean)` moves `rejected` → `implemented` after real `src/` + a standalone test (not a docs-only flip)
**G0:** PRE-APPROVED 2026-08-17. Overnight conductor executes.
**Mechanism authority:** new GitHub issue; Noether + maintainer OK to edit `src/gaussian_core.jl` + `src/gaussian_ranef.jl`; **invert** `test/test_reml.jl:121-128` (already in default suite); standalone `test/test_reml_ordinary_ranef.jl`; DoD docs. **Explicit exclusions:** `test/runtests.jl` include-list; `src/DRM.jl`; σ-RE; slopes; non-Gaussian REML; q4; AI-REML; TSV; parity-complete; #136; #49; D-111; steal #423/#428
**Recommended arc:** ~3 h (range 2.5–3.5 h)
**Time contract:** ceiling ~3.5 h for Arc 0
**Estimate confidence:** inferred — FE REML `#11` / `test/test_reml.jl` is the analogue; Woodbury ML already lives in `_fit_ranef_gaussian`; the rejected row is an explicit `ArgumentError` at `src/gaussian_core.jl:413–423`
**Arc 0 outcome:** opt-in `method = :REML` fits Gaussian mean `(1 | g)` on the Woodbury spine; ML remains the default; guard still rejects σ-RE / slopes / non-Gaussian REML
**State transition:** `rejected` (guard throws) → `implemented` (src + `test/test_reml_ordinary_ranef.jl`). Default-suite include is a later Option A slice, same pattern as #434/#438
**Executable rung and evidence:** narrow the **413–423** guard (not stale `:407`) for intercept-only `(1 | g)`; add `ℓ_REML = ℓ_ML − ½ logdet(XμᵀV⁻¹Xμ) + (pμ/2) log 2π` on `_fit_ranef_gaussian` `S`/`M`; invert `test_reml.jl:121-128`; standalone file for the extra cells. B-card flips only after those land. Documenter = Impl, untested until Option A include.

### Capacity ladder
| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| Arc 0 | 180 min | Mean `(1 \| g)` REML path + standalone test + DoD docs | Start now after G0. |
| Rung 1 | 30 min | `docs/src/capabilities.md` REML-scope warning matches the new cell | If Arc 0 completes early. |
| Rung 2 | — | `test/runtests.jl` include | **DEFER** until #423+#428 merge (or an explicit steal G0). |
| Integrate/close | 20 min | check-log + after-task + Rose claim-vs-evidence | Always reserve. |
| **Total capacity** | **~200 min (~3.3 h)** | | Size-mode ceiling, not a fill-the-day programme. |

### Budget
| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient | 20 | New issue; scratch worktree from `origin/main`; re-read guard + Woodbury nll |
| Core | 90 | Invert `test_reml.jl:121-128` first; `reml` kwarg on `_fit_ranef_gaussian`; narrow 413–423 hole; PT on `S`/`M`; `_withreml` |
| Verify | 40 | Standalone test + FE REML + ML `(1 \| g)` still green; do not run q4 as a claim |
| Repair reserve | 30 | FD / logdet / routing miss |
| Closeout | 20 | DoD docs; capability-status flip **only if** src+test landed |
| **Total** | **200** | Arc 0 |

**In scope:** Patterson–Thompson restricted likelihood for Gaussian mean `(1 | g)` only; ML default; model-selection guard unchanged.
**Not in this arc:** σ-RE REML; random slopes; multi-ranef; non-Gaussian REML; q4 / `src/reml_q4.jl`; AI-REML / `#291` / HSquared; AGHQ; VA remainder; `:natgrad`; `#428` steal; Option A `runtests.jl` include; TSV `supported`; “parity complete”; `#136`; `#49`; D-111 / Registrator.
**Evidence used:** Noether catchup `docs/dev-log/evidence/2026-08-17-recon-noether-mean-re-reml.md`; Rose catchup `docs/dev-log/evidence/2026-08-17-recon-rose-claim-fence.md`; Shannon/Hopper recon notes; `capability-status.md` rejected row; live guard `gaussian_core.jl:413–423` (not `:407`); Woodbury `gaussian_ranef.jl:94–158`; FE REML analogue; `test/test_reml.jl:121-128`; `gh issue list` (need new issue).
**Risk branch:** If `XμᵀV⁻¹Xμ` is not FD-self-consistent by minute 40 of core, stop and diagnose (profile-β vs joint) — do not widen the fence. If `test_reml.jl:121-128` is left as `@test_throws`, stop and invert it before claiming green.

**Done when:** `method = :REML` on Gaussian mean `(1 | g)` returns a `DrmFit` with `estim_method === :REML`; ML default unchanged; σ-RE / slopes still `ArgumentError`; standalone test green; capability-status flipped only after src+test; Rose clean-with-limitations (no default-suite include, no parity claim).

**First action:** `bash ~/shinichi-brain/tools/lane_launch.sh "/Users/z3437171/Dropbox/Github Local/DRM.jl" mean-re-reml --base origin/main` then `gh issue create` (new ticket; do not `closes #136` / `#11` / `#291` / `#327`).

### Actuals (complete at close)
**Recommended / actual:** 200 / _pending_ · **Requested / used:** N/A / _pending_ · **Rungs/cohorts completed:** _pending_
**Under-run event:** _pending_
**Calibration:** _pending_
**Metric movement:** _pending_ (`rejected` → `implemented` only after src+test)
**Result:** _pending_ · **Next arc:** Option A `runtests.jl` include after #423+#428, or stop

G0 PRE-APPROVED. Overnight conductor executes `/goal` in `docs/dev-log/after-task/2026-08-17-ultra-plan-mean-re-reml.md`. This planning chat STOPS.
