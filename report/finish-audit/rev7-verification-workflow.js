export const meta = {
  name: 'ayumi-rev7-verify',
  description: 'Verify the comprehensive rev7 Ayumi reply: completeness, technical accuracy, honesty',
  phases: [{ title: 'Verify' }],
}

const REPLY = "report/finish-audit/ayumi-reply-draft-rev7.md"
const DEMO = "/tmp/rdemo.txt"

const SCHEMA = {
  type: "object", additionalProperties: false,
  properties: {
    lens: { type: "string" },
    issues: { type: "array", items: { type: "object", additionalProperties: false,
      properties: {
        severity: { type: "string", enum: ["blocker", "major", "minor"] },
        location: { type: "string" }, problem: { type: "string" }, fix: { type: "string" }
      }, required: ["severity","location","problem","fix"] } },
    verdict: { type: "string", enum: ["ready-to-send","fix-then-send","do-not-send"] },
    summary: { type: "string" }
  }, required: ["lens","issues","verdict","summary"]
}

const AGENTS = [
  { label: "completeness", prompt: `Read the reply at ${REPLY}. Ayumi (collaborator) asked these OPEN questions in her latest comments; confirm EACH is answered clearly, or flag it as unaddressed:
(Q-A) "What is the correct branch/ref to install for the sigma-phylo Julia features?" — she hit a 404 on shannon/RELEASE-drmtmb.
(Q-B) "Is scale-phylo reachable through the R engine='julia' bridge yet, or only inside DRM.jl directly?"
(Q-C) "50 vs 100 posterior trees — is 50 sufficient for median + 2.5-97.5% interval summaries?"
She also reported results to engage with: mass+* bimodal D/E sign-flip; sigma~mass dispersion-allometry +0.7..+0.83; scale-phylo SD identifiable only for tarsus+beakCulmen, collapsing 1e-3..1e-6 elsewhere; robust mean effects (Gloger -0.245 etc.); convergence cost (D 66/300, E 17/300, a 176-min boundary fit); and her REML question.
For each: is it addressed accurately and helpfully? Flag anything missing or buried as major/minor. Also flag if the reply re-explains things she obviously already knows at tedious length.` },

  { label: "technical", prompt: `Read the reply at ${REPLY} and verify its TECHNICAL/RUNNABILITY claims against the repo (cwd is the DRM.jl checkout):
- Install: it cites DRM.jl branch "shannon/sigma-phylo-tools" via Pkg.add(url=..., rev=...). Confirm that branch EXISTS locally (git branch --list) and loads (it was validated to export profile_sigma_a + bootstrap_sigma_a). Flag if the cited ref is wrong or the URL/repo (itchyshin/DRM.jl) is wrong. NOTE: it must be PUSHED before Ayumi can install — flag that as a dependency, not an error.
- The "how to run" Julia code: bf() formula with sigma1 = @formula(sigma1 ~ temp + prec + temp&prec + mass + phylo(1|species)) — covariate-dependent sigma WITH phylo on sigma WITH an interaction. This was just tested and FITS (converged, all sigma coefs estimated). Confirm the code in the reply matches a runnable call (function names drm/bf/profile_sigma_a/bootstrap_sigma_a/augmented_phy, the @formula & operator for interactions, the named-tuple data, julia_assign/julia_eval usage). Flag any call that would error.
- The Q-B claim that the bivariate-phylo bridge is gated (routes to engine=tmb) and bivariate uses DRM.jl-direct — is that consistent with the repo's bridge? Flag if overstated.
Flag concrete errors as blocker/major.` },

  { label: "honesty", prompt: `Final ship-gate on the reply at ${REPLY}. Cross-check every user-facing NUMBER against the verified demo output ${DEMO} (the profile CIs sd_mu1 1.139 [0.885,1.510], sd_sigma2 [0.000,0.234], cor_mu1_mu2 0.69 [0.35,0.92], cor_sigma1_sigma2 -0.64 [-0.98,0.96], etc.). Flag any number that does not match.
Then hunt for honesty problems: does it anywhere claim profile is "calibrated" or attach a profile coverage number? (It must NOT — profile small-p coverage is irreducibly uncertain; only the bootstrap's ~0.52 scale undercoverage is a measured claim.) Does it overclaim what's "verified" or "works"? Any [VERIFY]/placeholder that would ship to Ayumi if the internal header (lines 1-14, marked DO NOT SEND) were stripped? Confirm the sendable body (from "Hi Ayumi") has no bracketed TODO. Flag the single worst issue + runners-up.` }
]

phase('Verify')
const res = (await parallel(AGENTS.map(a => () =>
  agent(a.prompt, { label: a.label, phase: 'Verify', schema: SCHEMA, agentType: 'general-purpose' })
))).filter(Boolean)

const all = res.flatMap(r => (r.issues||[]).map(i => ({...i, lens: r.lens})))
return {
  reviewers: res.map(r => ({ lens: r.lens, verdict: r.verdict, summary: r.summary })),
  blockers: all.filter(i => i.severity === 'blocker'),
  majors: all.filter(i => i.severity === 'major'),
  minors: all.filter(i => i.severity === 'minor'),
  allClear: all.filter(i => i.severity !== 'minor').length === 0 && res.every(r => r.verdict === 'ready-to-send')
}
