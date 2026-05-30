export const meta = {
  name: 'autoresearch',
  description: 'R — estimator-optimisation loop with verify-and-revert against the verified baseline',
  whenToUse: 'Phase 1.0+. Pass {metric} via args. Hill-climbs without regressing logLik -256.51 / 2.18x.',
  phases: [
    { title: 'Propose', detail: 'one estimator change (mode-finder / line search / EM<->LBFGS crossover)' },
    { title: 'Measure', detail: 'run the verified bench gate on a worktree' },
    { title: 'Keep-or-revert', detail: 'keep only if it beats baseline AND holds the logLik guard' },
  ],
}

// Workflow R — SCAFFOLD (first real run in Phase 1.0). Wraps the `autoresearch`
// skill as an autonomous loop: propose -> measure -> keep-or-revert, where the
// gate is the verified bench (bench/run_sparse_tmb_nd.jl). KEEP only if the
// metric beats baseline AND logLik stays -256.51 (2.18x vs drmTMB); else REVERT.
// This automates the verify-and-revert discipline and turns HANDOVER section 5's
// hand-run 4-strategy mode-finder search into a formal loop. Never auto-edit
// src/ unless the gate passes; surviving wins become `enhancement` issues with
// the measured delta. Runs each trial in an isolated worktree.

const metric = (args && args.metric) || 'wall-clock per fit (bench/run_sparse_tmb_nd.jl)'
const BASELINE = { logLik: -256.51, speed: '2.18x vs drmTMB', source: 'HANDOVER.md' }

log(`Workflow R — autoresearch scaffold (Phase 1.0). Metric: ${metric}. Baseline guard: logLik ${BASELINE.logLik}, ${BASELINE.speed}.`)

// --- Phase 1.0 body (enable when the phase opens) -------------------------
// const CHANGE = { type:'object', required:['summary','patch'], properties:{ summary:{type:'string'}, patch:{type:'string'} } };
// const MEAS   = { type:'object', required:['metric','logLik','beatsBaseline','logLikOK'], properties:{ ... } };
// const wins = [];
// while (budget.total && budget.remaining() > 50_000) {
//   const change = await agent('Propose ONE estimator change to speed up the q=4 fit without changing the model.', {phase:'Propose', schema: CHANGE});
//   const meas   = await agent(`Apply on a worktree, run bench/run_sparse_tmb_nd.jl, report ${metric} + logLik vs baseline.`, {phase:'Measure', isolation:'worktree', schema: MEAS});
//   if (meas.beatsBaseline && meas.logLikOK) { wins.push({change, meas}); log(`kept: ${change.summary}`); }
//   else { log(`reverted: ${change.summary}`); }
// }
// return { workflow:'R', wins };
// --------------------------------------------------------------------------

return { workflow: 'R', status: 'scaffold', phase: '1.0', metric, baseline: BASELINE }
