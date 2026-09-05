# Lossless tip-label review and source binding

Programme DRM.jl#563 remains active; this is a bounded leaf, not final parity.

Julia parser source SHA256: `569ee4fc0c41f7fa8cf5d9704288aa4eef7436782967604264070ba19f2dd8c4`.
Julia test SHA256: `adf9a31a6184503fe61152d04496be860be641d550a3d580b3581ea254ac1377`.
R development bridge SHA256: `72fcb02a5fecb9c30d6c7e5901f65fce6fedfadddc5ea767de2f710351e885c8`.
R test SHA256: `135cdb694077737936c6668761cc5e0a76e46b70dc8475d68cd3b3c43e97276b`.

Rose independently approved the parser and owned serializer hunks. The first
review exposed a NUL/EOF-sentinel collision; the dedicated regression failed
before repair and now passes. Final focused tests are Julia30/R14. Exact
reversed-edge Newick and tip order are asserted. Julia topology/height69 and R
polytomy33 neighbours pass. All earlier failed/historical logs remain retained.

Public002 in the R twin evidence directory binds all136 source hashes to current
development files; source before/after and runner hashes agree. Twelve tree tips
include collision-prone names, punctuation, quotes, Unicode and literal control
whitespace. The72 observations are shuffled. Native/direct coefficient differences
are below4e-6; bridge/direct values agree exactly. Rose independently recomputed
the Gaussian likelihood using scalar Cholesky from retained data/covariance and
found absolute errors at most5.7e-14. Row restoration is exact. Direct data was
explicitly ordered to tree tips: this does not qualify arbitrary-row direct LSS.

The changed Documenter page executed two examples in6.225seconds. This proves
example execution and Markdown generation only, not visual quality or deployment.

The evidence checker is separately reviewed and damage-tested; its first failure
(raw covariance incorrectly compared to correlation at tree height2) is retained.
Final checker SHA256 `512a61bbede2c5c05509940875d895d94d6c842e2ce35d1ad57ace376211f16c` passes public002 and rejects11damaged receipts. Rose independently ran it (exit0,0.62seconds) and approved the bounded leaf. Melissa found no material scope drop against the original obligations. All four executable leaf gates are reverified; programme gates remain open.

## Preservation and remaining work

Undoing only label hunks reconstructs the prior foreign R working file exactly:
SHA256 `a57b7aa7d912d46f21e68c9ce9f0f0610bbe822030f56ff65eb93af493cd6ccc`.
The staged label-only R bridge SHA256 is
`c9b8f907037e95f79669b81e46ba550e13f54cb9613ade364c50dafeae530467`.
Foreign ZOB96insertions/10deletions and Julia S5 include/test stay unstaged.
Receipts use development bytes including foreign R work, not clean-head builds.

Separate required work: direct-LSS tree-tip mapping at both frontend call sites;
profile nuisance convergence/status and analytic gradient retention; bootstrap,
all-native capability/output coverage, strict tolerance losses, complete LSS
SE/REML/mask/large-tree/final-head evidence, all registered warm performance wins,
safe recovery/cleanup, and whole Documenter qualification. Neither previously
denied numerical engine file was edited or bypassed. No release, registration,
remote campaign, deployment or collaborator message.
