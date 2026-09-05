# Decision: GitHub PR auto-merge (DRM.jl only)

- **Date:** 2026-08-13
- **Status:** Accepted — repo settings + this note. No `src/` change.
- **Voice:** Shannon. No subagents.
- **Owner choice:** option A (native GitHub `allow_auto_merge` + required checks).
  Not Mergify, not an automerge Action.

This is a **DRM.jl-only** policy. It does not rewrite the hub
`handover-skill.md`. Hub handover stays owner-click unless a later hub
decision says otherwise.

---

## Settings (verified 2026-08-13)

| Knob | Value |
|---|---|
| `allow_auto_merge` | **true** |
| `allow_merge_commit` | true (unchanged; repo style is `--merge`) |
| `delete_branch_on_merge` | **false** (unchanged) |
| Protection | classic branch protection on `main` |
| Required checks | `test (1.10)`, `test (1)`, `docs` |
| Not required | `scaling-sweep` (skipped on PRs), `documenter/deploy` (commit status, not an Actions job) |
| `strict` | true (branch must be up to date with `main`) |
| Required reviews | **none** (sole-author self-review would block) |
| Push restrictions | **none** |
| `enforce_admins` | **false** — Shinichi can still emergency-bypass |
| Linear history | false — merge commits stay allowed |

Required-check names were read from `.github/workflows/CI.yml` +
`Documenter.yml` and confirmed on green PR #405
(`test (1.10)`, `test (1)`, `docs` pass; `scaling-sweep` skipped).

---

## Agent command

After opening a PR, agents **may**:

```sh
gh pr merge N --auto --merge
```

Use `--merge` (merge commit), not squash, to match #403 / #404 / #405.

---

## Still pause — do not `--auto`

Owner-click (or an explicit owner “merge it”) is still required when the
PR touches:

- `src/` engine
- formula grammar
- a version bump
- `AGENTS.md` / `CLAUDE.md`
- anything that would close an epic the slice does not finish
- a foreign lane (Claude / Codex / another Cursor checkout) that is active

---

## Issue-closer trap

Never put `close` / `fix` / `resolve` next to `#NN` unless the slice is
meant to close that issue. GitHub parses those tokens in commit messages
and PR bodies.

---

## Unrelated, still true

**D-111** — DRM.jl stays off Julia General until the twin is ready.
This settings change does not touch that.
