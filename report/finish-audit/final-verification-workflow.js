export const meta = {
  name: 'ayumi-reply-final-verify',
  description: 'Final adversarial verification that every rev5 panel blocker is resolved in the completed rev6',
  phases: [{ title: 'Verify' }],
}

const REPLY = "report/finish-audit/ayumi-reply-draft-rev6.md"
const DEMO_OUT = "/tmp/rdemo.txt"
const COV_OUT = "/tmp/profcov2.txt"

const SCHEMA = {
  type: "object",
  additionalProperties: false,
  properties: {
    lens: { type: "string" },
    unresolved: {
      type: "array",
      description: "Any remaining blocker/major issues; empty if clean",
      items: {
        type: "object",
        additionalProperties: false,
        properties: {
          severity: { type: "string", enum: ["blocker", "major", "minor"] },
          location: { type: "string" },
          problem: { type: "string" },
          fix: { type: "string" }
        },
        required: ["severity", "location", "problem", "fix"]
      }
    },
    verdict: { type: "string", enum: ["ready-to-send", "fix-then-send", "do-not-send"] },
    summary: { type: "string" }
  },
  required: ["lens", "unresolved", "verdict", "summary"]
}

const AGENTS = [
  {
    label: "resolution-audit",
    prompt: `The rev5 draft of a reply to collaborator Ayumi was reviewed by a 4-lens panel that returned these BLOCKERS/MAJORS. The reply was then REFRAMED to be honest about profile-CI calibration (it no longer claims profile is "calibrated" — only boundary-honest). Read the CURRENT reply at ${REPLY} and confirm EACH is resolved (quote the fixed text), or flag it as still-unresolved:

1. The [PROFILE-COV] placeholder and any "profile is calibrated ≈0.NN" claim were REMOVED in the reframe. Verify NO unfilled placeholder or bracketed TODO remains anywhere, AND that the reply does NOT assert a specific profile coverage number or call profile "calibrated". The honest framing should be: profile is BOUNDARY-HONEST (lower=0 at a collapse, verified) and precise interval WIDTH is approximate at small p for ANY method; the bootstrap's scale-axis undercoverage (~0.52) is the only measured coverage claim. Flag any residual overclaim of profile calibration as a blocker.
2. Inline R code: 'df' and 'newick_r' undefined; bare julia_setup(); missing rng. Must now be self-contained/runnable.
3. REML SD numbers (0.95/0.67) contradicted the demo (1.139/0.648). Must be reconciled or removed.
4. "#19" cited as a PR — it is actually an unrelated GitHub ISSUE. Must cite the branch shannon/bivariate-missing-q4 instead.
5. "works today on an uninstallable branch" — must give a concrete install path (the combined branch).
6. B=195 vs B=200 inconsistency — must be reconciled.
7. "[−1,1]" overstatement on the σ2 correlations — must be softened to approximate.

Return any that are NOT fully resolved as unresolved[] with severity. If all are resolved, empty unresolved[] and verdict ready-to-send.`
  },
  {
    label: "fisher-stats-final",
    prompt: `You are a rigorous statistician giving the FINAL stats sign-off on a reply to collaborator Ayumi (bivariate q=4 phylogenetic location-scale, pdHess=FALSE at a variance boundary). Read ${REPLY} and the bootstrap finding in report/finish-audit/bootstrap-coverage-findings.md. (A profile-coverage MC was run but was too noisy/small-p to support a calibration claim, so the reply was deliberately reframed NOT to claim profile is calibrated.)

Scrutinise the statistics for CORRECTNESS and HONESTY:
- Is the pdHess=FALSE explanation (singular observed information at the boundary -> Wald/vcov undefined) correct?
- Is the profile-CI description right (LR inversion, no Hessian, lower bound exactly 0 at a collapsed axis)?
- The reply claims profile is BOUNDARY-HONEST (trustworthy collapse/no-collapse call + lower=0) but does NOT claim its precise width is calibrated — it says precise width is approximate at small p for ANY method. Is that an honest, defensible position? Is it correct that boundary coverage is intrinsically irregular and that no method gives exact nominal coverage there at small p? Flag if the reply still over-claims profile precision ANYWHERE, OR if it now UNDER-sells something that is actually solid.
- Is the bootstrap undercoverage explanation (ML shrinkage -> bootstrap inherits bias) sound, and is "report the distribution of the point estimate across trees" defensible?
- Any remaining statistical overclaim or misstatement.

Flag issues in unresolved[]. If the stats are sound and honestly stated, verdict ready-to-send.`
  },
  {
    label: "final-adversary",
    prompt: `Final ship-gate. Read ${REPLY} (complete, no placeholders should remain) and the verified outputs ${DEMO_OUT} and ${COV_OUT}. Assume it is sent verbatim to Ayumi if you say nothing.

Hunt for ANY remaining: unfilled placeholder or bracketed TODO, number that does not match the verified outputs, R code that would error on first paste, a claim of "works"/"verified" not backed by the repo, or an internal numeric inconsistency. Check the closing recap is consistent with the body.

Return the single highest-severity remaining problem (if any) plus runners-up in unresolved[]. If you find nothing that should block sending, verdict ready-to-send.`
  }
]

phase('Verify')
const results = await parallel(AGENTS.map(a => () =>
  agent(a.prompt, { label: a.label, phase: 'Verify', schema: SCHEMA, agentType: 'general-purpose' })
))

const valid = results.filter(Boolean)
const unresolved = valid.flatMap(v => (v.unresolved || []).map(u => ({ ...u, lens: v.lens })))
return {
  reviewers: valid.map(v => ({ lens: v.lens, verdict: v.verdict, summary: v.summary })),
  blockers: unresolved.filter(u => u.severity === 'blocker'),
  majors: unresolved.filter(u => u.severity === 'major'),
  minors: unresolved.filter(u => u.severity === 'minor'),
  allClear: unresolved.filter(u => u.severity !== 'minor').length === 0 && valid.every(v => v.verdict === 'ready-to-send')
}
