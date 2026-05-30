export const meta = {
  name: 'add-family',
  description: 'H — add one distribution family: link infra, Laplace path, ADEMP cell, article, R-parity',
  whenToUse: 'Phase 2, once per family. Pass {family} via args.',
  phases: [
    { title: 'Link', detail: 'link function + parameter names' },
    { title: 'Laplace', detail: 'marginal path for the family' },
    { title: 'ADEMP', detail: 'recovery cell (Curie)' },
    { title: 'Doc', detail: 'Documenter article stub (Workflow D)' },
    { title: 'Parity', detail: 'R-parity gate (Workflow G)' },
  ],
}

// Workflow H — SCAFFOLD (runs in Phase 2, once per family). Preserve the
// internal sigma<->phi mappings for parity (Tweedie phi = sigma^2; beta phi =
// 1/sigma^2). With args = {family} it runs that family's pipeline; otherwise it
// returns the Phase 2 queue.

const FAMILIES = ['student', 'lognormal', 'Gamma', 'tweedie', 'beta', 'poisson', 'nbinom2', 'cumulative_logit']
const fam = (args && args.family) || null

if (!fam) {
  log(`Workflow H — ${FAMILIES.length} families queued for Phase 2: ${FAMILIES.join(', ')}. Pass {family} to run one.`)
  return { workflow: 'H', status: 'scaffold', phase: '2', families: FAMILIES }
}

log(`Workflow H — adding family "${fam}" (Phase 2).`)
// Phase 2 body (enable then): Link -> Laplace -> ADEMP recovery -> Documenter
// stub (workflow('mirror-article', {...})) -> R-parity (workflow('r-parity-suite')).
return { workflow: 'H', status: 'scaffold', phase: '2', family: fam }
