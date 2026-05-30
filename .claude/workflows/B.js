export const meta = {
  name: 'bf-formula-frontend',
  description: 'B — the bf() multi-formula front end with drmTMB-exact parity',
  whenToUse: 'Phase 1.1. Boole-led; gated by Hopper round-trip parity (Workflow G).',
  phases: [
    { title: 'Grammar', detail: 'bf(mu,sigma,rho12) + structured markers on StatsModels.jl' },
    { title: 'Reject', detail: 'reject the same reserved syntax drmTMB rejects, parallel messages' },
    { title: 'Parity', detail: 'round-trip R<->Julia formula equivalence' },
  ],
}

// Workflow B — SCAFFOLD (runs in Phase 1.1). drmTMB-exact parity is BOTH the
// accepted grammar AND the rejections: a reader who hits "not supported yet" in
// drmTMB must hit the same in DRM.jl. Resolves the public-verb and tree-I/O
// design issues opened in Phase 0.

const PARAMS = ['mu', 'sigma', 'nu', 'phi', 'zi', 'hu', 'zoi', 'coi', 'rho12', 'sd', 'sd1', 'sd2', 'sd_phylo']
const MARKERS = ['phylo', 'spatial', 'animal', 'relmat', 'corpair', 'meta_V', 'mvbind']

log(`Workflow B — ${PARAMS.length} parameter names, ${MARKERS.length} markers (Phase 1.1).`)

// --- Phase 1.1 body (enable when the phase opens) -------------------------
// const grammar = await agent(`Boole: build bf()/drm_formula() on StatsModels.jl ...`, {phase:'Grammar'});
// const rejects = await agent(`Boole: implement the reserved-syntax rejections from
//   docs/src/developer-notes/formula-grammar.md with parallel messages.`, {phase:'Reject'});
// const parity  = await agent(`Hopper: round-trip every bf() example R<->Julia against
//   drmTMB v0.1.3.`, {phase:'Parity'});
// --------------------------------------------------------------------------

return { workflow: 'B', status: 'scaffold', phase: '1.1', params: PARAMS, markers: MARKERS }
