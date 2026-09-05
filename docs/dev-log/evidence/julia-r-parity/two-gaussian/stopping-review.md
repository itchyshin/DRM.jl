# Rose independent stopping review — 2026-08-30

Verdict: no native default-solver repair is warranted by the retained evidence.
Native source HEAD80f168acb5dec1dd5fcf9088cccad0a6e1cae0f0. R/drmTMB.R834–861
accepts finite objective and convergence0 as documented by R/control.R18–26.
Presets careful/robust only increase budgets (294–299). R/check.R195 default
raw gradient tolerance1e-3 exceeds the observed~2.87e-4/~6.70e-4 residuals.

Diagnostic quadratic remaining NLL improvements4.1964e-10Gaussian and
4.2044e-9Bern match retained gaps4.1831e-10/4.2031e-9. This supports ordinary
stopping resolution, not a defective likelihood or default acceptance bug.
The curvature in that diagnostic was Julia-derived: it is not an independent
native optimizer certificate and must never replace the native baseline.

Keep all4e-6 default workflow failures. Any future precision policy must be
explicit, independently justified across models, honor user controls and retain
original results. Proceed with other required capabilities while this gate stays
open. Requested/actual reviewer dispatch: Rose gpt-5.6-sol/high, existing agent;
read-only review, no fit/source edits. No timing or programme completion claim.

Reviewed hashes:
- R/drmTMB.R 1fb01724a4d6060f22f2d4062f09cb0f9ecd5d17f4626d0cbb919fe0a0796b59
- R/control.R 066b5bb4662677340f99a5ebbd7d51396379b8c85d0aee9f6526e263711fbcb3
- R/check.R a63e0551c7a6b494fef73d86b0b0f1752ae1f222893b547214d63e6dd4e6f979
- prior diagnostic2f3845afe9f22db44780a9779495c9390d35411e01793264b3697fdaab624b96
- public0049f0600a195c2a9a9c83a80cc835508a42847df447b06b071593b8354ae7132b9
