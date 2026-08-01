# Registry checklist — 2026-08-01 (LOOP S0 RECON)

**Role:** Scout (read-only). Shannon speaking; no spawned subagents.
**SHAs:** `origin/main` = `edd9965`; `origin/shannon/ayumi-integration` tip = `7cb868d` (includes merged #339).
**Method:** tip-vs-tip path compare; branch uniqueness; load-print grep; `gh` issue probe (partial).
**Uncertain items** marked **UNVERIFIED**.

---

## 1. Checklist — must-green before Registrator

| # | Gate | Evidence at recon | State |
|---|---|---|---|
| 1 | Integration base = agreed ayumi↔main tip (Q1 = integrate before Registrator) | ayumi **25 ahead / 51 behind** `origin/main`; S2 in progress elsewhere | **BLOCKED (S2)** |
| 2 | No load-time `println` on `using DRM` | Pre-S3: script-gated `println` at `fit_q4_sparse_tmb.jl:576` and `fisherz_q4.jl:301` (already silent under `include`/`using`); S3 branch `shannon/s3-scoped-hygiene` removes both blocks. Live `using DRM` between markers: empty. | **FIXED on S3 branch** (pending merge after #340) |
| 3 | `Project.toml`: name/uuid/version/`[compat]` for every dep + `julia` | Identical on main & ayumi; version `0.1.0`; stdlib + pkg compat present (post–a1-registry) | **GREEN** (metadata) |
| 4 | Aqua hygiene wired (`test/test_aqua.jl`, `deps_compat=true`, in `runtests.jl`) | Same file both tips; Aqua in `test/Project.toml` only | **WIRED** — live pass **UNVERIFIED** this recon |
| 5 | Local `Pkg.test()` green on register tip | Not run (read-only recon) | **UNVERIFIED** |
| 6 | Linux CI green on register tip | Workflows identical both tips; CI conclusion not re-checked | **UNVERIFIED** |
| 7 | TagBot + Documenter workflows present | `.github/workflows/{TagBot,Documenter,CI}.yml` same on both tips | **GREEN** |
| 8 | LICENSE MIT; no vendored drmTMB GPL | MIT LICENSE on main | **GREEN** (spot-check) |
| 9 | README/HANDOVER honesty (no oversell of bridge / experimental wire) | HANDOVER still lists General-registry as **Next**; bridge present but #5 open | **NEEDS Rose pass (S3)** |
| 10 | Version / tag policy chosen (reuse `v0.1.1` vs bump) | Tags `v0.1.0`/`v0.1.1` exist; `Project.toml` + `CITATION.cff` still `0.1.0` | **OPEN (S3/S4)** |
| 11 | Not already in Julia General (or deliberate re-register) | Local brain: no “already registered” decision; GitHub API to General **Forbidden** this session | **UNVERIFIED** |
| 12 | Explicit Shinichi OK to submit Registrator | Ultra-plan: do not submit without say-so | **S4 gate** (not S3) |

---

## 2. Already-on-main (do not re-land)

Compared register-relevant paths `origin/main` (`edd9965`) vs ayumi `7cb868d`:

| Path | main vs ayumi |
|---|---|
| `Project.toml` | **SAME** |
| `README.md` | **SAME** |
| `HANDOVER.md` | **SAME** |
| `NEWS.md` | **SAME** |
| `.github/workflows/{CI,TagBot,Documenter}.yml` | **SAME** |
| `test/test_aqua.jl` | **SAME** |

**Branch uniqueness:**

| Branch | vs `origin/main` | Note |
|---|---|---|
| `shannon/a1-registry` tip `175e259` | **0 ahead** (ancestor) | Aqua + stdlib-compat hygiene already on main — **do not re-PR** |
| `claude/julia-package-register-ready-SuLOC` tip `46f7b44` | **3 ahead / 178 behind** | Old: silence `sparse_aug_plsm` load print (already on main), thinner `[compat]`, older README. **Not a ship base**; cherry-pick only after rebase check — likely **noop / regressive** |
| `shannon/ayumi-integration` @ `7cb868d` | **25 ahead / 51 behind** | Register metadata same; differs in engine/docs/tests (`src/DRM.jl`, `sparse_aug_plsm.jl`, many tests). S2 integration owns this |

**Load-print status (both tips):**

- `src/sparse_aug_plsm.jl` — silent (SuLOC `c60019c` already absorbed).
- `src/DRM.jl` — no load `println`.
- Residual include-time prints remain (see gaps).

---

## 3. Residual hygiene inventory (scoped #3 / #8 — S3)

1. **Silence remaining load prints** — **DONE on `shannon/s3-scoped-hygiene`**: removed script-gated banners at former `fit_q4_sparse_tmb.jl:575–578` and `fisherz_q4.jl:300–303`. Pre-fix: already silent under `using DRM` (PROGRAM_FILE gate). Residual `src/experimental/fit_q4_tmbgrad.jl` left alone (not included by `src/DRM.jl`).
2. **Re-verify Aqua + `Pkg.test`** on the post-S2 tip — **IN PROGRESS** on this branch (log under `/tmp/drm-pkg-test-logs/`); claim only from LOG.
3. **Version / CITATION drift:** tags `v0.1.0`/`v0.1.1` exist; tree still `0.1.0` in `Project.toml` + `CITATION.cff` — **not bumped** in this hygiene PR (Rose-honest: decide bump vs register-as-is at S4 with Shinichi).
4. **HANDOVER / README “Next” + claim fence:** refresh after registry; do not claim Phase 1.5 / R-bridge “done” (#5 still open).
5. **General membership check:** confirm package absent (or present) in JuliaRegistries/General before Registrator — **UNVERIFIED** here.
6. **Issue trackers (status from earlier `gh` this session; REST later Forbidden → treat as snapshot):**
   - **#8** Roadmap v0.1.0 — **OPEN** (registry + R-bridge still called out as outstanding).
   - **#3** Phase 1.0 Hygiene + wire experimental — **OPEN**; Q2 = **SCOPED** registry hygiene only.
   - **#5** Phase 1.5 R-side `engine=julia` — **OPEN** (S5, not S3).
   - **#339** — **MERGED** into ayumi (`7cb868d`, closed 2026-08-01).

---

## 4. Do-not-touch fences

| Fence | Rule |
|---|---|
| **AGENTS commits** | Do not dump the 4 unrelated local AGENTS/Ranganathan commits from REML tip into registry/bridge PRs |
| **#136** VA/ELBO | DEFER — no promotion / public claim |
| **#291** REML speed / AI-REML | DEFER |
| **#13** `fit_em_natgrad` public wire | Out of scoped #3 unless Shinichi expands |
| **Full experimental/ wire** | Out of default hygiene scope |
| **Verified q=4 engine baseline** | Noether — do not touch logLik −256.51 / 2.18× for registry cosmetics |
| **GPL boundary** | Never vendor drmTMB source (Rose) |
| **Registrator submit** | S4 only; needs explicit Shinichi OK after S3 green |

---

## 5. S3 blockers (from this recon)

1. **S2 incomplete** — ayumi↔main not yet a single register tip (25/51 divergence).
2. **Two remaining load-time prints** (`fit_q4_sparse_tmb.jl`, `fisherz_q4.jl`).
3. **Live Aqua / `Pkg.test` / CI green** on the integrated tip — **UNVERIFIED**.
4. **Version/tag/CITATION policy** undecided (`0.1.0` tree vs `v0.1.1` tags).
5. **General presence** — **UNVERIFIED** (API forbidden this session).

S3 itself does **not** wait on #5 bridge finish, #136, #291, or #13.
