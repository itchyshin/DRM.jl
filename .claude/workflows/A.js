export const meta = {
  name: 'wire-experimental',
  description: 'A — promote src/experimental/ into the public API and fix the orphan tests',
  whenToUse: 'Phase 1.0.',
  phases: [
    { title: 'Wire', detail: 'one experimental file per slice into the DRM module' },
    { title: 'Test', detail: 'fix + wire the orphan tests' },
  ],
}

// Workflow A — SCAFFOLD (runs in Phase 1.0). The structure is real; the agent
// pipeline below is enabled when Phase 1.0 opens. Running it now logs the slice
// plan and returns it without spawning agents (cheap, no src/ changes).
// Also removes the stray load-time print in src/sparse_aug_plsm.jl
// ("=== sparse_aug_plsm.jl loaded ===") — verified to fire during load in Phase 0.

const FILES = ['infer_q4', 'reml_q4', 'location_only', 'fit_em_natgrad']

log(`Workflow A — ${FILES.length} experimental files to wire into DRM (Phase 1.0): ${FILES.join(', ')}.`)

// --- Phase 1.0 body (enable when the phase opens) -------------------------
// await pipeline(FILES,
//   f => agent(
//     `Wire src/experimental/${f}.jl into the DRM module: add the include in the ` +
//     `right place, export the public symbols, add docstrings. Keep the verified ` +
//     `src/ engine untouched and do not regress logLik -256.51 / 2.18x.`,
//     { label: `wire:${f}`, phase: 'Wire' }),
//   (_, f) => agent(
//     `Fix and wire the orphan tests for ${f} into test/runtests.jl (update paths to ` +
//     `'using DRM'); run them and report pass/fail.`,
//     { label: `test:${f}`, phase: 'Test' }));
// --------------------------------------------------------------------------

return { workflow: 'A', status: 'scaffold', phase: '1.0', files: FILES }
