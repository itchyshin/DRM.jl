# Arcs — feat-biv-q4-phylo-reml-fixture

From approved ultra-plan. Status: todo / doing / done / blocked.
Gate = needs a human before it can proceed.

| ID | Status | Gate | What |
|---|---|---|---|
| SCAFFOLD | doing | — | New LOOP kit on `claude/lane-biv-q4-phylo-reml`; open GitHub issue |
| S1 | todo | — | Hopper recon: drmTMB outputs + exact Julia `drm(..., method=:REML, tree=)` call |
| S2 | todo | — | Boole+Hopper schema: `test/parity/q4-reml/biv-q4-phylo-reml/{data,tree,expected,meta}` |
| S3 | todo | HANDS TO Codex if R/Julia toolchain stalls | Generator + generate numbers + standalone Julia test |
| S4 | todo | — | Curie smoke: both sides converge; coef+logLik within [tol]; status finite |
| S5 | todo | — | Rose claim-vs-evidence (no parity complete / TSV / coverage / AI-REML) |
| S6 | todo | — | DoD: check-log + after-task + worked-example snippet |
| S7 | todo | — | Mechanical verify: fixtures, meta 0.7.0, no src/, no runtests, no TSV |
| S8 | todo | — | Melissa plan-vs-actual |
| PR | todo | **OPEN GATE** | Open PR `closes #NN`. Auto-merge last or leave unarmed. TSV flip is NOT this PR. |

**PARALLEL:** S1 first; S2 after S1. S3–S8 sequential.
**FENCE:** no `src/`; no TSV `supported`; no `runtests.jl`; no Workflow G glob.
