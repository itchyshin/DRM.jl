export const meta = {
  name: 'engine-quality-battery',
  description: 'Q — the 7-gate engine-quality battery for the DRM.jl src/ engine',
  whenToUse: 'On every PR touching src/, and before each tag.',
  phases: [{ title: 'Gates', detail: 'FD · cross-check · R-parity · JET · Allocs · Aqua · multi-shape' }],
}

// Workflow Q — the engine-quality battery (Karpinski). Each gate is an
// independent agent so they run concurrently and a failure is isolated. Gates
// with ready:false are scaffolded now and wired in the phase noted — they return
// a "deferred" verdict instead of spawning an agent, so a smoke-run is honest
// and never falsely green. This is the "do better than drmTMB" edge: R can't
// JET-check or Allocs-profile its TMB engine.

const JULIA = 'julia --project=.' // ~/.juliaup/bin/julia locally; setup-julia in CI

const GATES = [
  { key: 'aqua',       ready: true,  phase: '0',   how: `${JULIA} -e 'using Pkg; Pkg.test()' — Aqua.jl project hygiene clean` },
  { key: 'jet',        ready: true,  phase: '0',   how: 'Pkg.test — test/test_qgate_jet.jl (JET.@test_opt on lc_to_Λ / Λ_to_lc)' },
  { key: 'fd',         ready: true,  phase: '1.0', how: 'test/test_qgate_fd_gradient.jl — exact vs FD ≤ 1e-6' },
  { key: 'crosscheck', ready: false, phase: '1.0', how: 'two independent gradient paths agree ≤ 1e-8' },
  { key: 'allocs',     ready: true,  phase: '1.0', how: 'test/test_qgate_alloc_inner.jl — zero alloc in inner Newton arithmetic' },
  { key: 'multishape', ready: true,  phase: '1.0', how: 'bench scaling — balanced + caterpillar, p ∈ {100, 1000, 10000} (Totoro for heavy)' },
  { key: 'rparity',    ready: true,  phase: '1.1', how: 'RCall.jl vs vendored drmTMB v0.1.3 outputs ≤ 1e-6 (DRM_PARITY_TESTS=1; opt-in)' },
]

phase('Gates')

const VERDICT = {
  type: 'object',
  required: ['gate', 'pass', 'detail'],
  properties: {
    gate: { type: 'string' },
    pass: { type: ['boolean', 'null'] },
    detail: { type: 'string' },
  },
}

const results = await parallel(GATES.map(g => () =>
  g.ready
    ? agent(
        `Run the DRM.jl "${g.key}" engine-quality gate from the repo root: ${g.how}. ` +
        `Report {gate, pass, detail} with the key number. Do not modify src/.`,
        { label: `Q:${g.key}`, schema: VERDICT },
      )
    : ({ gate: g.key, pass: null, detail: `scaffold — wired in Phase ${g.phase}` })
))

const ran = results.filter(r => r && r.pass !== null)
const passed = ran.filter(r => r.pass).length
log(`Q — ${passed}/${ran.length} ready gates passed; ${results.length - ran.length} deferred to later phases.`)
return { gates: results, ready: ran.length, passed }
