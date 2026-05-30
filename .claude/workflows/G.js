export const meta = {
  name: 'r-parity-suite',
  description: 'G — RCall.jl round-trip + fit parity vs vendored drmTMB v0.1.3 outputs',
  whenToUse: 'Phase 1.1+. Gated by DRM_PARITY_TESTS=1.',
  phases: [
    { title: 'Roundtrip', detail: 'every bf() example parses identically R <-> Julia' },
    { title: 'Fit', detail: 'fit numbers match vendored drmTMB v0.1.3 outputs' },
    { title: 'Shape', detail: 'result objects are drmTMB-shaped' },
  ],
}

// Workflow G — SCAFFOLD (runs in Phase 1.1+, once Workflow B lands bf()).
// HERMETIC by design: compares against *vendored* drmTMB v0.1.3 reference
// outputs in test/parity/fixtures/ (generated outputs only, never GPL source —
// see AGENTS.md), so the gate runs on CI with no live R+drmTMB install. Hopper.

log('Workflow G — R-parity suite scaffold (Phase 1.1+). Anchor: drmTMB v0.1.3; fixtures: test/parity/fixtures/.')
return { workflow: 'G', status: 'scaffold', phase: '1.1', anchor: 'drmTMB v0.1.3', fixtures: 'test/parity/fixtures/' }
