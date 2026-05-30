export const meta = {
  name: 'pre-publish-audit',
  description: 'F — Rose-led pre-tag audit: drift, scope honesty, missing cells, Confidence Eye, license',
  whenToUse: 'Before every tag / release.',
  phases: [{ title: 'Audit', detail: '5 parallel audit lenses; any failure blocks the tag' }],
}

// Workflow F — the pre-publish gate (Rose). Five independent lenses run
// concurrently; any non-ok lens blocks the tag. Runnable today.

const LENSES = [
  { key: 'drift',          prompt: 'README / HANDOVER / CLAUDE / AGENTS / ROADMAP drift: do they agree with the code and with each other?' },
  { key: 'scope',          prompt: 'Scope honesty: every Documenter page carries an accurate status tag (Stable / First slice / Opt-in control / Planned / Blocked); nothing oversold.' },
  { key: 'missing-cell',   prompt: 'Missing-cell audit: univariate x bivariate x location x scale/shape/inflation x ordinary x structured x fitted x planned — any claimed-but-uncovered cell?' },
  { key: 'confidence-eye', prompt: 'Confidence Eye contract: uncertainty figures use a pale compatibility region + darker outline + hollow point estimate; render-proof (fresh PNG inspected).' },
  { key: 'license',        prompt: 'License boundary: no drmTMB GPL source vendored into MIT DRM.jl; R-parity uses generated outputs only.' },
]

phase('Audit')

const FIND = {
  type: 'object',
  required: ['lens', 'ok', 'findings'],
  properties: {
    lens: { type: 'string' },
    ok: { type: 'boolean' },
    findings: { type: 'array', items: { type: 'string' } },
  },
}

const results = (await parallel(LENSES.map(l => () =>
  agent(`Rose pre-publish audit — ${l.key}: ${l.prompt} Working dir is the repo root; read-only. Return {lens, ok, findings[]}.`,
    { label: `F:${l.key}`, schema: FIND })
))).filter(Boolean)

const blocking = results.filter(r => !r.ok).map(r => r.lens)
log(`F — ${results.length - blocking.length}/${results.length} lenses clean.` + (blocking.length ? ` BLOCKING: ${blocking.join(', ')}.` : ' Clear to tag.'))
return { audit: results, blocking }
