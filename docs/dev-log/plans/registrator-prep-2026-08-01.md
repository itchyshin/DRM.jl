# S4 Registrator prep — 2026-08-01 (DRM.jl only)

**Role:** Grace + Rose (prep only). Shannon speaking; no spawned subagents.
**Branch tip:** `origin/main` @ `e7261d9` (post #340/#341/#342/#343).
**This document does NOT submit** Registrator.jl, open a
`JuliaRegistries/General` PR, or create a release tag.

Companion recon: [`registry-checklist-2026-08-01.md`](registry-checklist-2026-08-01.md).
Ultra-plan: [`2026-08-01-ultra-plan-registry-bridge.md`](2026-08-01-ultra-plan-registry-bridge.md)
(S4 blocked on explicit Shinichi OK).

---

## 1. Evidence snapshot (measured 2026-08-01)

| Item | Value | Source |
|---|---|---|
| `Project.toml` `version` | **`0.1.0`** | tip `e7261d9` |
| `CITATION.cff` `version` | **`0.1.0`** | tip (no `date-released`) |
| Git tag `v0.1.0` | exists → `782e53d` (2026-05-31) | local + `origin` |
| Git tag `v0.1.1` | exists → `91a5078`; `Project.toml` was **`0.1.1`** at that commit | local + `origin` |
| Tip vs `v0.1.1` | **345 commits ahead**; tag is ancestor of main | `git rev-list` |
| Version regression | tip was set back `0.1.1` → `0.1.0` in `f65beee` (“registry-ready metadata”, #239) | `git log -S` |
| Julia General `D/DRM` | **absent** (GitHub contents **404**; no local registry entry) | `gh api` + filesystem |
| LICENSE | MIT | tip |
| UUID | `6c755ef2-eed4-4cdd-aafe-b639090bd215` | `Project.toml` |
| `[compat]` | every dep + `julia = "1.10"` | tip (a1-registry ancestry) |
| TagBot / Documenter / CI workflows | present | `.github/workflows/` |
| Issue #8 | OPEN — “Then register in the Julia General registry” | `gh issue view 8` |
| S2 / S3 | **merged** (#340 integrate, #341 hygiene, #342 docs honesty, #343 checkpoint) | `gh pr` |
| Local `Pkg.test` / Aqua on tip | **not re-run in this prep slice** — treat as pre-submit gate | — |
| Linux CI on `main` tip | no completed `CI.yml` run listed for `e7261d9` yet; recent CI runs were on PR branches (some cancelled / in progress) | `gh run list` |

---

## 2. Rose-honest version bump recommendation

### Verdict: **YES — bump before first General registration**

**Recommended register version: `0.1.2`**

Do **not** register tip as `0.1.0` or `0.1.1`.

| Option | Rose verdict | Why |
|---|---|---|
| A. Register tip as **`0.1.0`** | **Reject** | Git tag `v0.1.0` already points at May tip `782e53d`. TagBot after AutoMerge expects to create `v0.1.0` on the registered SHA → collision / wrong-SHA tag. Also understates 345+ commits since the May family release. |
| B. Bump tip to **`0.1.1`** and register | **Reject** | Same TagBot collision with existing `v0.1.1` @ `91a5078`. Tip ≠ that release SHA. |
| C. Register the **old** annotated tag `v0.1.1` SHA first, then tip later | **Allowed but awkward** | First General version would be a May snapshot; tip still needs a new version (`0.1.2+`) immediately after. Extra AutoMerge cycle; easy to mis-claim “current main is 0.1.1”. |
| D. Bump tip to **`0.1.2`**, sync CITATION/NEWS, then Registrator | **Recommend** | Fresh General version; TagBot can create a clean `v0.1.2`; May git tags remain historical GitHub tags without being General entries. |

### Pre-register bump checklist (when Shinichi OKs)

1. On register tip (today: `main` @ post-S3): set `Project.toml` `version = "0.1.2"`.
2. Set `CITATION.cff` `version: 0.1.2` and add `date-released: YYYY-MM-DD`.
3. Move `NEWS.md` **Unreleased** bullets into `## v0.1.2 (YYYY-MM-DD)` (honest scope — no “bridge done”, no “in General” until AutoMerge lands).
4. Refresh README/HANDOVER “Status / Next” after submit (not before AutoMerge claims membership).
5. Commit the bump on `main` (or a tiny bump PR) **before** the Registrator comment.

Historical May tags `v0.1.0` / `v0.1.1` may stay as git tags; they are **not** General versions until/unless someone deliberately registers those SHAs (not recommended for tip).

---

## 3. Exact steps for Julia General (after Shinichi OK)

Do these **in order**. Stop if any gate fails.

### Gate 0 — human OK

- [ ] Shinichi explicitly says to submit Registrator (ultra-plan S4).
- [ ] Agree version = **`0.1.2`** (or document a deliberate override of §2).

### Gate 1 — tip hygiene (scoped #8 / S3 residual)

- [ ] Working tree = agreed register tip (`main` after #340+#341+#342).
- [ ] No load-time `println` on `using DRM` (S3 #341 claimed silence — re-smoke once).
- [ ] Local: `julia --project=. -e 'using Pkg; Pkg.test()'` green (incl. Aqua).
- [ ] Linux CI green on the commit that will be registered (wait for `CI.yml` on that SHA).
- [ ] Rose claim fence: README/HANDOVER do **not** say Phase 1.5 / R-bridge “done”; do **not** claim General membership before merge.
- [ ] Reconfirm General still lacks `D/DRM` (`gh api repos/JuliaRegistries/General/contents/D/DRM` → 404).

### Gate 2 — version bump commit

- [ ] Land `0.1.2` metadata (§2 checklist) on the tip to register.
- [ ] `git show HEAD:Project.toml | head -5` shows `version = "0.1.2"`.

### Gate 3 — Registrator trigger (human or session with OK)

Preferred (comment on the **GitHub commit or PR** that contains the `0.1.2` tip):

```text
@JuliaRegistrator register
```

Notes:

- First registration creates `JuliaRegistries/General` PR for package `DRM`.
- Do **not** pass `branch=…` unless registering a non-default branch tip on purpose.
- Alternative: JuliaHub / Registrator web UI against `itchyshin/DRM.jl` @ that commit — same effect.
- **Do not** open a hand-rolled General PR if Registrator can file it.

### Gate 4 — watch AutoMerge

- [ ] General PR opened by Registrator / JuliaRegistrator.
- [ ] CI on that General PR: RegistryCI / AutoMerge checks.
- [ ] Fix follow-ups they request (compat, name, license, UUID) on the **DRM.jl** side if needed, then re-trigger.
- [ ] After merge: confirm `D/DRM` exists in General; `] add DRM` resolves from General.

### Gate 5 — TagBot + docs after merge

- [ ] TagBot should open/create tag **`v0.1.2`** on the registered SHA (workflow already present; needs `DOCUMENTER_KEY` / secrets as configured).
- [ ] If TagBot skips because of pre-existing tags only for `v0.1.0`/`v0.1.1`, that is expected — new `v0.1.2` should still appear.
- [ ] Update HANDOVER/README “Next” and close/check off #8 registry bullet **only after** General membership is real.
- [ ] Optional: `date-released` already set; bump CITATION if TagBot’s tag date differs.

### Explicit non-steps (this prep)

- ✗ Do not run Registrator from this prep PR.
- ✗ Do not open `JuliaRegistries/General` PRs manually here.
- ✗ Do not retarget or delete historical `v0.1.0` / `v0.1.1` tags without a separate Rose/Ada decision.
- ✗ Do not touch drmTMB or claim R-bridge Phase 1.5 closed (#5 is S5).

---

## 4. What Shinichi must OK

| # | Decision | Default if “use your judgment” |
|---|---|---|
| 1 | **Submit Registrator now** (after gates), or wait | Wait until local `Pkg.test`+Aqua+CI green on tip |
| 2 | **Register version = `0.1.2`** (bump tip) vs register old May `v0.1.1` SHA | **`0.1.2` on tip** |
| 3 | Whether historical git tags `v0.1.0`/`v0.1.1` stay untouched | **Stay** (git history only; not General) |
| 4 | Whether #8 closes on first AutoMerge or waits for Phase 1.5 (#5) | Close **registry** checklist item on AutoMerge; keep #8 / roadmap honest if R-bridge still open |
| 5 | Who posts `@JuliaRegistrator register` (Shinichi vs delegated session) | Shinichi posts, or session only after spoken OK |

Ultra-plan lock (already decided): *“Do not submit without explicit Shinichi say-so even after green.”*

---

## 5. AutoMerge expectations (first package)

Typical first-registration AutoMerge path for a MIT Julia package with complete `[compat]`:

| Check | Expectation for DRM.jl |
|---|---|
| Package name `DRM` | Short; AutoMerge may flag similarity to other names — answer if asked. Local General has `libdrm_jll` only (unrelated JLL). |
| UUID uniqueness | Should pass (`6c755ef2-…` already published in repo). |
| SemVer / new version | First version in General → usually allowed; use **`0.1.2`** so it does not fight existing git tags. |
| `[compat]` bounds | Present for deps + `julia` — should satisfy modern RegistryCI. |
| License | MIT file present — OK. |
| Repo / docs URL | `repository-code` + docs site in CITATION — helpful, not always blocking. |
| Tests | AutoMerge does **not** replace local `Pkg.test`; still required before you trigger. |
| Wait time | Often hours; can be longer on first package or if a maintainer must dismiss a name note. |
| After merge | Users need an updated General registry (`] up` / registry fetch) before `add DRM` works everywhere. |

If AutoMerge **fails**: paste the General PR check log into #8; fix on DRM.jl tip; re-comment `@JuliaRegistrator register` on the fixed commit (do not force-push General).

---

## 6. Claim fence (Rose)

Allowed **after** AutoMerge merges:

- “DRM.jl is registered in the Julia General registry at version 0.1.2.”

Not allowed in the Registrator comment, bump PR, or README until then:

- “Already in General” / “install via `] add DRM` from General” (false today — 404).
- “v0.1.1 is the registered release” while `Project.toml` still says `0.1.0`.
- “R `engine = \"julia\"` / Phase 1.5 shipped” (#5 open).
- “REML / experimental fully wired” (still scoped out).

---

## 7. One-line return for the parent lane

| Question | Answer |
|---|---|
| Prep path | `docs/dev-log/plans/registrator-prep-2026-08-01.md` |
| Version bump needed before register? | **Yes — bump tip to `0.1.2`** (do not register as `0.1.0` / `0.1.1`) |
| Submit now? | **No** — awaiting Shinichi OK + green local/CI gates |
