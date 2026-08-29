# Handover — location–scale–scale arc complete, Ayumi handoff sent (2026-08-28)

**Author:** Claude (Shannon; no subagents running). **Lane closed** with this document.
Supplements the v0.7.0 handover (`2026-08-28-claude-handover-v070-tagged.md`).

## Landed (all merged, both repos)

- **DRM.jl #547** (carried #554): `sd(group)` / `sd(species, phylogenetic)` grammar (canonical;
  `sd_phylo` soft-deprecated), exact Woodbury + dense phylo + multi-component lsss engines
  (#544/#545/#555), fixes #548 (Woodbury cancellation, was shipped in v0.7.0), #549 (shared-box
  closure race), #550 (BLAS pin — threaded bootstrap 15× serial), #556 (sparse-route variance
  SEs, match drmTMB to 5 digits); tutorials: Part 1 ↔ Part 2 variance sequence paired,
  bivariate-nongaussian page; #553: ν logm2 docs fix.
- **drmTMB #1100**: bridge routing for sd() parts, `sigma ~ 1` phylo fence lifted, block-aware
  coefficient-name splitting, capability ledger row 12 `location_scale_scale = partial`,
  setup-UX polish (actionable errors, boot notice, one-time threads hint).
- **Owner acceptance gate MET**: all five Mizuno models green on estimates + SE + Wald +
  profile + bootstrap via `engine = "julia"`, ΔlogLik = 0 vs TMB
  (`docs/dev-log/evidence/2026-08-28-lss-acceptance-matrix.md`).
- **Outbound**: Ayumi-495/LS_ecogeographical-rules#28 posted on the owner's go (install + usage
  + multicore inference + thanks).

## OWED next — the TRUE-PARITY arc (owner-adopted 2026-08-28, in order)

1. **#558 — lss REML on the dense routes** (quick win): Ayumi's mass/tarsus/beak fits are REML;
   Patterson–Thompson on the dense marginal, reduction + cross-engine gates. Do FIRST.
2. **#559 — lss missing responses** (the lightness models): extend the #517 observed-rows +
   full-tree convention to the lss engines.
3. **#551 — sparse O(p) lss engine**: lifts the 5000-species cap for the whole-tree scope; the
   `D_a T` row-scaling preserves the sparse tree factor; #164 is the gradient-pattern precedent.
   Gates: FD-vs-exact ≤ 1e-6, dense-route logLik identity on the committed lsss fixtures,
   scaling run to p = 10,000 before any whole-tree claim.
4. Ledger row 12 promotion price: one stamped SE cell in drmTMB's `parity-se.tsv` (docs page is
   live at /dev/).
5. v0.7.1 + Julia General registration (owner-gated, D-181) — also gives Ayumi `Pkg.add`
   instead of a clone.

## Known residue (deliberate)

- Local branch `feat/555-lsss-multi` points at a commit contained in main; the destructive-command
  guard blocks its force-deletion — remove at leisure (`git branch -D`), nothing is lost.
- A spawned-task chip for the bivariate tutorial was started in another session AFTER the tutorial
  merged; that session should find the page on main and stand down.
- Scratch checkouts under `/tmp` (`fresh-DRM.jl`, `drm-lsss`) are disposable.

## Resume prompt

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-28-claude-handover-lss-arc.md. Run lane preflight, reconcile with git state, then start OWED item 1 (#558 lss REML) unless the owner redirects.
```
