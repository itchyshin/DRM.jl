## DRM.jl validation — R side: shared data generation + R baselines.
##
## Goal: produce the evidence for the Ayumi reply with honest, cross-checked
## numbers. R generates every dataset (so Julia fits the *identical* data) and
## fits the R baselines where an R baseline exists.
##
## Studies
##   S1  Homoscedastic Gaussian REML exactness  (lm analytic, gls, drmTMB-tmb)
##         -> the one REML cell where Julia and R compute the same thing.
##   S2  Mean-phylo variance parity, ML, one obs/species (Pagel-lambda model)
##         -> phylolm + gls(corPagel) + Rphylopars vs DRM.jl. 4-way parity on H.
##   S4  Missing-data analogue: Rphylopars on the shared trait + missingness masks
##         -> the canonical R missing-data phylo tool, for cross-engine support.
##
## Model (S2/S4, the phylogenetic cell):
##   response   y   (continuous trait), one value per species (S2) / m reps (S4)
##   predictors intercept only
##   RE         phylogenetic random intercept a ~ N(0, sigma_p^2 * C), C = vcv(tree)
##              on an ultrametric height-1 tree (diag C = 1) => Pagel lambda model
##   residual   e ~ N(0, sigma_e^2)
##   target     sigma_p^2, sigma_e^2, mu, and H = sigma_p^2/(sigma_p^2+sigma_e^2)
##   link       identity (Gaussian)

suppressPackageStartupMessages({
  library(ape); library(nlme); library(phylolm); library(Rphylopars); library(MASS)
})

dir  <- "/tmp/drm-validation"
ddir <- file.path(dir, "data")
dir.create(ddir, recursive = TRUE, showWarnings = FALSE)

## ----------------------------------------------------------------------------
## S1 — homoscedastic Gaussian REML exactness
## DGP: y = b0 + b1*x + e, e ~ N(0, sd_true^2). REML residual var = RSS/(n-p).
## ----------------------------------------------------------------------------
n_s1 <- 200; b0 <- 1.0; b1 <- 0.5; sd_true <- 0.7
S1 <- data.frame()
for (seed in 1:10) {
  set.seed(100 + seed)
  x <- rnorm(n_s1)
  y <- b0 + b1 * x + rnorm(n_s1, sd = sd_true)
  d <- data.frame(y = y, x = x)
  write.csv(d, file.path(ddir, sprintf("s1_%02d.csv", seed)), row.names = FALSE)

  m_lm  <- lm(y ~ x, d)
  p_lm  <- length(coef(m_lm))
  sd_reml_lm <- sqrt(sum(resid(m_lm)^2) / (n_s1 - p_lm))   # analytic REML residual SD
  m_gls <- gls(y ~ x, data = d, method = "REML")
  sd_gls <- sigma(m_gls)                                    # gls REML residual SD

  # drmTMB native TMB engine, REML, sigma ~ 1: residual SD is constant across rows.
  sd_tmb <- tryCatch(
    as.numeric(sigma(drmTMB::drmTMB(drmTMB::bf(y ~ x, sigma ~ 1),
                                    family = gaussian(), data = d,
                                    engine = "tmb", REML = TRUE)))[1],
    error = function(e) NA_real_)

  S1 <- rbind(S1, data.frame(seed = seed,
                             sd_reml_lm = sd_reml_lm, sd_gls = sd_gls, sd_tmb = sd_tmb,
                             b0 = unname(coef(m_lm)[1]), b1 = unname(coef(m_lm)[2])))
}
write.csv(S1, file.path(dir, "R_S1.csv"), row.names = FALSE)
cat("S1 done:", nrow(S1), "datasets\n")

## helper: extract (mu, sigma_p^2, sigma_e^2, H, total, logLik) from each R fit.
extract_H <- function(phylo_var, resid_var) phylo_var / (phylo_var + resid_var)

## ----------------------------------------------------------------------------
## S2 — mean-phylo variance parity (ML, one obs/species)
## ----------------------------------------------------------------------------
p_s2 <- 40; mu_s2 <- 2.0; vp <- 0.6; ve <- 0.4     # true phylo var / residual var
S2 <- data.frame()
for (seed in 1:20) {
  set.seed(200 + seed)
  tr <- rcoal(p_s2)
  tr$tip.label <- paste0("t", seq_len(p_s2))
  tr$edge.length <- tr$edge.length / max(node.depth.edgelength(tr))  # height 1 => diag(vcv)=1
  Cmat <- vcv(tr)
  a <- MASS::mvrnorm(1, rep(0, p_s2), vp * Cmat)
  y <- mu_s2 + a + rnorm(p_s2, sd = sqrt(ve))
  dat <- data.frame(species = tr$tip.label, y = as.numeric(y))
  write.tree(tr,  file.path(ddir, sprintf("s2_%02d.nwk", seed)))
  write.csv(dat, file.path(ddir, sprintf("s2_%02d.csv", seed)), row.names = FALSE)

  ## NA-safe row so rbind stays consistent even if a fit fails. Rphylopars is
  ## NOT used here: with one obs/species it cannot separate within-species
  ## (pheno) variance from phylo variance (it needs replicates -> used in S4).
  row <- data.frame(seed = seed,
                    mu_phylolm = NA_real_, H_phylolm = NA_real_,
                    total_phylolm = NA_real_, ll_phylolm = NA_real_,
                    mu_gls = NA_real_, H_gls = NA_real_,
                    total_gls = NA_real_, ll_gls = NA_real_)

  ## phylolm, Pagel lambda (ML). phylolm matches data to tips by ROWNAMES.
  ## For a height-1 tree: tip total var = sigma2, phylo fraction H = optpar.
  d2 <- dat; rownames(d2) <- d2$species
  pl <- tryCatch(phylolm(y ~ 1, data = d2, phy = tr, model = "lambda"),
                 error = function(e) NULL)
  if (!is.null(pl)) {
    row$mu_phylolm <- unname(coef(pl)[1]); row$H_phylolm <- unname(pl$optpar)
    row$total_phylolm <- unname(pl$sigma2); row$ll_phylolm <- as.numeric(logLik(pl))
  }

  ## gls corPagel (ML): lambda from corStruct, total tip var = sigma(fit)^2.
  gp <- tryCatch(gls(y ~ 1, data = dat,
                     correlation = corPagel(0.5, tr, form = ~species, fixed = FALSE),
                     method = "ML"),
                 error = function(e) NULL)
  if (!is.null(gp)) {
    lam <- unname(coef(gp$modelStruct$corStruct, unconstrained = FALSE))
    row$mu_gls <- unname(coef(gp)[1]); row$H_gls <- lam
    row$total_gls <- sigma(gp)^2; row$ll_gls <- as.numeric(logLik(gp))
  }
  S2 <- rbind(S2, row)
}
write.csv(S2, file.path(dir, "R_S2.csv"), row.names = FALSE)
cat("S2 done:", nrow(S2), "datasets\n")

## ----------------------------------------------------------------------------
## S4 — missing-data analogue (Rphylopars) on a shared sigma-phylo trait.
## DGP: BOTH-phylo location-scale (phylo on mean AND on log-sigma), m reps/species,
## so DRM.jl fits the real Ayumi cell while Rphylopars fits the homoscedastic
## mean-phylo analogue on the same values. Missingness masks: 0/30/60/90% MCAR
## plus "drop whole species" (5 fully-missing species). Same data file, NA-coded.
## ----------------------------------------------------------------------------
p_s4 <- 40; m_s4 <- 4; n_s4 <- p_s4 * m_s4
set.seed(404)
tr4 <- rcoal(p_s4); tr4$tip.label <- paste0("t", seq_len(p_s4))
tr4$edge.length <- tr4$edge.length / max(node.depth.edgelength(tr4))
C4 <- vcv(tr4)
u_mu  <- MASS::mvrnorm(1, rep(0, p_s4), 0.6 * C4)     # phylo SD on mean ~ sqrt(.6)
u_sig <- MASS::mvrnorm(1, rep(0, p_s4), 0.25 * C4)    # phylo SD on log-sigma ~ .5
sp_idx <- rep(seq_len(p_s4), each = m_s4)
species <- tr4$tip.label[sp_idx]
y_full <- 1.0 + u_mu[sp_idx] + exp(log(0.5) + u_sig[sp_idx]) * rnorm(n_s4)
write.tree(tr4, file.path(ddir, "s4_tree.nwk"))

miss_levels <- c(0, 0.30, 0.60, 0.90)
S4 <- data.frame()
for (lev in miss_levels) {
  set.seed(900 + round(lev * 100))
  y <- y_full
  if (lev > 0) y[sample.int(n_s4, floor(lev * n_s4))] <- NA
  dat <- data.frame(species = species, y = y)
  tag <- sprintf("mcar%02d", round(lev * 100))
  write.csv(dat, file.path(ddir, sprintf("s4_%s.csv", tag)), row.names = FALSE)

  ## Rphylopars handles missing (NA) natively, dropping missing obs, keeping tree.
  rp <- tryCatch(phylopars(dat, tr4, model = "BM", pheno_error = TRUE, REML = FALSE),
                 error = function(e) NULL)
  if (!is.null(rp)) {
    pcov <- as.numeric(rp$pars$phylocov); ecov <- as.numeric(rp$pars$phenocov)
    S4 <- rbind(S4, data.frame(scenario = tag, frac_missing = lev,
                               n_obs = sum(!is.na(y)),
                               H_rp = extract_H(pcov, ecov),
                               total_rp = pcov + ecov, mu_rp = as.numeric(rp$mu)))
  }
}
## fully-missing-species scenario: drop 5 species entirely.
set.seed(950)
drop_sp <- tr4$tip.label[sample.int(p_s4, 5)]
y <- y_full; y[species %in% drop_sp] <- NA
dat <- data.frame(species = species, y = y)
write.csv(dat, file.path(ddir, "s4_dropspecies.csv"), row.names = FALSE)
rp <- tryCatch(phylopars(dat, tr4, model = "BM", pheno_error = TRUE, REML = FALSE),
               error = function(e) NULL)
if (!is.null(rp)) {
  pcov <- as.numeric(rp$pars$phylocov); ecov <- as.numeric(rp$pars$phenocov)
  S4 <- rbind(S4, data.frame(scenario = "dropspecies", frac_missing = 5 / p_s4,
                             n_obs = sum(!is.na(y)),
                             H_rp = extract_H(pcov, ecov),
                             total_rp = pcov + ecov, mu_rp = as.numeric(rp$mu)))
}
write.csv(S4, file.path(dir, "R_S4.csv"), row.names = FALSE)
cat("S4 done:", nrow(S4), "scenarios\n")
cat("ALL R STUDIES COMPLETE\n")
