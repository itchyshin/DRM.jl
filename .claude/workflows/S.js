export const meta = {
  name: 'scout-and-combine',
  description: 'S — Pólya scout of drmTMB / gllvmTMB / GLLVM.jl + literature, then creative combinations',
  whenToUse: 'Weekly (routine, via /schedule) and at every phase-start. Pass {mode, phase} via args.',
  phases: [
    { title: 'Scan', detail: 'fan out across sister packages + literature' },
    { title: 'Combine', detail: 'propose original combinations that open a slice' },
  ],
}

// Workflow S — Pólya's scouting + creative-combination workflow. Runnable today.
// Two modes via args.mode: 'routine' (weekly diff) and 'phase-start' (idea pass
// when a phase opens). Output: creative combinations to file as `idea` issues +
// a snapshot under docs/dev-log/scout/. Pólya proposes; Pólya does not implement.

const mode = (args && args.mode) || 'routine'

phase('Scan')
const SCAN = [
  { k: 'drmtmb',     p: 'WebFetch https://itchyshin.github.io/drmTMB/news/index.html and the articles index. Summarize what changed since the drmTMB v0.1.3 parity anchor (new families, markers, articles). Return concise bullets + the current dev version.' },
  { k: 'gllvmtmb',   p: 'Summarize the latest gllvmTMB pkgdown capabilities + NEWS relevant to distributional / phylogenetic modelling.' },
  { k: 'gllvmjl',    p: 'Read the sister GLLVM.jl repo AGENTS.md, docs/dev-log/check-log.md, and recent commits. What engine ideas or patterns transfer to DRM.jl?' },
  { k: 'literature', p: 'Use arxiv-search / academic-search for recent work on distributional regression, phylogenetic location-scale models, and boundary inference at a singular variance. Return 3-5 citations, each with a one-line relevance note.' },
]
const SUM = { type: 'object', required: ['source', 'signals'], properties: { source: { type: 'string' }, signals: { type: 'array', items: { type: 'string' } } } }
const scans = (await parallel(SCAN.map(s => () =>
  agent(`Pólya scout — ${s.k}: ${s.p}`, { label: `S:${s.k}`, schema: SUM })
))).filter(Boolean)

phase('Combine')
const COMBINE = {
  type: 'object',
  required: ['ideas'],
  properties: {
    ideas: {
      type: 'array',
      items: {
        type: 'object',
        required: ['title', 'why', 'phase'],
        properties: { title: { type: 'string' }, why: { type: 'string' }, phase: { type: 'string' } },
      },
    },
  },
}
const combos = await agent(
  `Pólya creative-combination pass (mode=${mode}). Given these scout signals, propose <=5 ORIGINAL ` +
  `combinations that could open a DRM.jl slice — e.g. the verified O(p) sparse Laplace x Bayesian boundary ` +
  `inference (Self-Liang chi-bar^2), or the bivariate q=4 PLSM x a coordinate-spatial layer drmTMB hasn't done. ` +
  `For each: title, why-now, target phase. Signals:\n${JSON.stringify(scans)}`,
  { label: 'S:combine', schema: COMBINE },
)

log(`S — ${scans.length} sources scanned; ${combos.ideas.length} combinations proposed. File each as an \`idea\` issue and snapshot to docs/dev-log/scout/.`)
return { mode, scans, ideas: combos.ideas }
