# Arcs — feat-biv-q4-phylo-reml-fixture

From approved ultra-plan. Status: todo / doing / done / blocked.
Gate = needs a human before it can proceed.

| ID | Status | Gate | What |
|---|---|---|---|
| SCAFFOLD | done | — | LOOP kit @ `8b0aa5e3`; issue #433 |
| S1 | done | — | Hopper recon: native TMB REML + four-axis phylo; Julia `method=:REML` |
| S2 | done | — | Schema outside `fixtures/` glob; 0.7.0 meta; `[status]` reserved |
| S3 | done | — | Generator + seed 20260822 fixture + standalone test (no Codex handoff) |
| S4 | done | — | Curie: TMB conv=0; Julia 33/33 within measured [tol] |
| S5 | done | — | Rose fence in `2026-08-16-biv-q4-s5-rose-fence.md` |
| S6 | done | — | check-log + after-task + worked example |
| S7 | done | — | no src/; no runtests.jl; no TSV; meta 0.7.0 |
| S8 | done | — | plan-actual: REML restriction drift recorded |
| PR | doing | **OPEN GATE** | Open PR `closes #433`. Leave auto-merge unarmed. |

**PARALLEL:** S1 first; S2 after S1. S3–S8 sequential.
**FENCE:** no `src/`; no TSV `supported`; no `runtests.jl`; no Workflow G glob.
