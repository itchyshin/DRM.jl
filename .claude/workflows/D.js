export const meta = {
  name: 'mirror-article',
  description: 'D — fill one Documenter article mirroring a drmTMB pkgdown article',
  whenToUse: 'Phase 1+, once per article. Pass {slug, drmtmbUrl, status} via args.',
  phases: [
    { title: 'Ingest', detail: 'draft the page from drmTMB source + local material' },
    { title: 'Figure', detail: 'Florence: CairoMakie + Confidence Eye where relevant' },
    { title: 'Reader', detail: 'Pat: reader-first voice, runnable example' },
    { title: 'Audit', detail: 'Rose: claim-vs-evidence, correct status tag' },
  ],
}

// Workflow D — fill ONE article and promote its checklist item to a real `article`
// issue. Pipeline per article so the four passes flow without barriers. Without
// args it returns the plan (scaffold). With args = {slug, drmtmbUrl, status} it
// runs the real pipeline (Phase 1+).

const a = args || {}
if (!a.slug) {
  log('Workflow D — pass {slug, drmtmbUrl, status} via args to fill an article. Scaffold otherwise.')
  return { workflow: 'D', status: 'scaffold', phase: '1+' }
}

log(`Workflow D — filling article "${a.slug}" (mirrors ${a.drmtmbUrl || 'drmTMB'}; status ${a.status || 'planned'}).`)

const draft = await agent(
  `Draft docs/src/.../${a.slug}.md for DRM.jl, mirroring the drmTMB article at ` +
  `${a.drmtmbUrl}. Reader-first voice (like drmTMB). Keep the YAML status tag = ` +
  `"${a.status}". Use a runnable Julia example only for surfaces DRM.jl actually ` +
  `fits today; otherwise mark Planned and point to the drmTMB page. Return the markdown.`,
  { label: `D:ingest:${a.slug}`, phase: 'Ingest' },
)
const withFig = await agent(
  `Florence: add/curate figures for this article (CairoMakie; Confidence Eye contract ` +
  `for uncertainty displays). Render-proof: fresh PNG filename, inspect the actual render.\n\n${draft}`,
  { label: `D:figure:${a.slug}`, phase: 'Figure' },
)
const withVoice = await agent(
  `Pat: tighten for a biologist new to Julia — clear first paragraph, no jargon dumps, ` +
  `working example, "see also" links.\n\n${withFig}`,
  { label: `D:reader:${a.slug}`, phase: 'Reader' },
)
const audit = await agent(
  `Rose: claim-vs-evidence audit of this article. Does every capability claim match ` +
  `what DRM.jl actually fits? Is the status tag honest? Return {ok, issues[], finalMarkdown}.`,
  { label: `D:audit:${a.slug}`, phase: 'Audit',
    schema: { type:'object', required:['ok','finalMarkdown'], properties:{ ok:{type:'boolean'}, issues:{type:'array',items:{type:'string'}}, finalMarkdown:{type:'string'} } } },
)
return { workflow: 'D', slug: a.slug, ok: audit.ok, issues: audit.issues || [] }
