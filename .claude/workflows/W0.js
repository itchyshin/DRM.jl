export const meta = {
  name: 'scaffold-team',
  description: 'W0 — audit the DRM.jl Phase 0 team scaffold for presence and consistency',
  whenToUse: 'Once at Phase 0, to verify the team / workflows / ledger / docs scaffold.',
  phases: [{ title: 'Audit', detail: 'confirm scaffold files exist and are non-trivial' }],
}

// W0 — the team scaffold (AGENTS.md, CLAUDE.md, ROADMAP.md, .claude/workflows/,
// .codex/agents/, docs/dev-log/, the Documenter shell, the GitHub ledger) is
// created by hand during Phase 0. This workflow AUDITS it: one read-only agent
// confirms presence + consistency and returns a structured gap report. Cheap and
// safe to re-run any time as a scaffold-integrity check.

phase('Audit')

const SCHEMA = {
  type: 'object',
  required: ['present', 'missing', 'verdict'],
  properties: {
    present: { type: 'array', items: { type: 'string' } },
    missing: { type: 'array', items: { type: 'string' } },
    verdict: { type: 'string' },
  },
}

const report = await agent(
  `You are Rose auditing the DRM.jl Phase 0 scaffold. The working directory is the
repo root. Verify these exist and are non-trivial (not empty stubs where content
is expected):
  - AGENTS.md (12 personas), CLAUDE.md, ROADMAP.md, NEWS.md, CITATION.cff, .JuliaFormatter.toml
  - .claude/workflows/{W0,Q,A,B,D,F,G,H,S,R}.js
  - .codex/agents/*.toml (expect 12)
  - docs/dev-log/{check-log.md,coordination-board.md,after-task,decisions,recovery-checkpoints,scout}
  - docs/make.jl, docs/Project.toml, docs/src/ (expect ~36 .md)
  - .github/ISSUE_TEMPLATE/*.yml, .github/PULL_REQUEST_TEMPLATE.md, .github/labels.yml
  - .github/workflows/{CI,Documenter,TagBot}.yml
  - tools/drm-checkpoint.jl, tools/bootstrap-issues.jl, tools/propose-polya-pattern.md
Return present[], missing[], and a one-line verdict. Do not modify anything.`,
  { label: 'W0:audit', schema: SCHEMA, agentType: 'Explore' },
)

log(`W0 audit — ${report.present.length} present, ${report.missing.length} missing: ${report.verdict}`)
return report
