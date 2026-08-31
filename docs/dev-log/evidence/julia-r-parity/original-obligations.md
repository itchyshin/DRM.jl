# Recovered LSS obligations — status at the 2026-08-30 checkpoint

These are remaining obligations recovered from repository handovers and the local
Claude plan `~/.claude/plans/partitioned-wishing-shell.md`. Historical statements
are leads; the current source and retained run outputs determine completion.

| Obligation | Current evidence | What remains |
|---|---|---|
| Dense Gaussian LSS REML (#558) | Implementation commit `5e9a2ecd` is in the frozen Julia main; `test/test_lss_reml.jl` exists. Current article run exercises group and single-phylo REML and records estimator labels. | Exact cross-engine restricted-objective, SE, profile/bootstrap and multi-component evidence on the final source; an implemented source path alone does not close inference parity. |
| Missing responses (#559) | Implementation commit `140460a0` is in the frozen main; current article executes the missing-response phylogenetic LSS example. | Cross-engine values, row restoration, missing-pattern/refusal neighbours and uncertainty semantics across the admitted routes. |
| Sparse LSS (#551) | Implementation commit `57aa8fe4` is in the frozen main. Two hidden dense conversions now have a reproduced allocation defect. | Apply approved correction after the source-write gate clears; retain p=10,000 measurements and independent oracle/inference checks. No p=10,000 LSS result was located in the inspected evidence. |
| Stamped SE and row12 promotion | `test/fixtures/lsss/README.md` records generated R outputs, seeds1/3 and seed20260828 for the M2 sparse SE pin. R `inst/extdata/julia-capabilities.tsv` marks the LSS claim covered. | Required stamped LSS row was not found in `docs/dev-log/evidence/parity-se.tsv`; build provenance, refreshed comparison tables and a fresh closure receipt remain unproven. Do not infer them from the covered label. |
| Final-source verification | Cursor handover requires a full suite on final head, after an earlier stale-fixture failure. | No fresh final-programme suite receipt exists; run it after integration. |

Primary recovery anchors: `docs/dev-log/handover/2026-08-28-cursor-handover.md`
(REML requirements98–103, large-tree149–152, SE154–159, final checks185–187),
`docs/dev-log/handover/2026-08-28-claude-handover-lss-arc.md`, and the Claude plan
(REML52–88, missing90–114, scaling149–170 and final checks165–173).

The acceptance matrix `docs/dev-log/evidence/2026-08-28-lss-acceptance-matrix.md`
explicitly describes the final PR#547 head. It gives finite SE/Wald/profile/bootstrap
results for the M2–M6q ladder, retaining183/199 M2 and198/199 M6q bootstrap successes.
It does **not** identify REML or missing-response runs, so it cannot prove the later
#558/#559 obligations. An initial scout incorrectly treated it as such; direct reading
corrected that classification. Its timings are historical, not this programme's benchmark.

Recovery of dirty Rose-nit/stash work remains separate. Nothing has been discarded.
The Aug24 handover retains owner-held #420/#406 residue; compare actual content and
restore a preservation copy before proposing any disposition. This note does NOT
constitute a complete Claude/Cursor history or unregistered-clone audit.

## Ayumi-san follow-up reported by Shinichi (2026-08-30)

User-reported lead, not yet a reproduced verdict: point estimates appear good
through `engine = "julia"`; profile intervals and bootstrap require investigation.
Ayumi-san also reports native R accepts polytomous trees while the Julia route
refuses them. Her issue is forthcoming; do not invent an issue number or wait
for it to begin a minimal reproduction. Track direct Julia and the R bridge
separately to locate tree conversion versus kernel restrictions. Preserve branch
length/covariance meaning rather than silently resolving a polytomy with arbitrary
positive-length branches. These obligations join the existing inference/valid-case
manifest; neither point-estimate agreement nor this report proves parity.

## Polytomy follow-up (2026-08-30)

Positive-length rooted multifurcations are now admitted by both constructors and
the Rserializer. Retainedstar/mixed GaussianML cases pass native/direct/bridge
checks; see polytomy/public-003.json. This repairs that admission restriction, not
all tree/inference scope. Zeroedges,unary/singletip/general-label cases,all-family
qualification and Ayumi's unspecified profile/bootstrap report remain required.
Previousmissing-predictor losses and all24native obligations are unchanged.
