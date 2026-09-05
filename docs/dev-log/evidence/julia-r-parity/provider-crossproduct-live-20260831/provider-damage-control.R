root <- normalizePath('/private/tmp/drm-parity-20260830/integration/drmTMB')
jl <- normalizePath('/private/tmp/drm-parity-20260830/integration/DRM.jl')
options(drmTMB.DRM.jl.path = jl)
pkgload::load_all(root, quiet = TRUE, compile = FALSE)

JuliaCall::julia_command(paste(
  'drmTMB_provider_profile(formula,family,data,K,A,options)=',
  'DRM.drm_bridge_inference(formula=formula,family=family,data=data,',
  'K=K,A=A,options=options,method="profile",level=.95,threads=false,',
  'parm="fixef:mu:x")'
))

make_gaussian_case <- function(provider) {
  set.seed(if (identical(provider, 'animal')) 20260911L else 20260912L)
  groups <- 8L
  per_group <- 4L
  id <- rep(sprintf('g%02d', seq_len(groups)), each = per_group)
  x <- rnorm(groups * per_group)
  coords <- data.frame(
    east = runif(groups, 0, 3),
    north = runif(groups, 0, 3),
    row.names = unique(id)
  )
  A <- 0.55 ^ abs(outer(seq_len(groups), seq_len(groups), '-'))
  K <- exp(-as.matrix(dist(coords)) / 0.8) + diag(1e-8, groups)
  covariance <- if (identical(provider, 'animal')) A else K
  group_effect <- 0.45 * drop(t(chol(covariance)) %*% rnorm(groups))
  y <- 0.2 + 0.35 * x + group_effect[match(id, unique(id))] +
    0.3 * rnorm(groups * per_group)
  data <- data.frame(y = y, x = x, id = id)
  formula <- if (identical(provider, 'animal')) {
    drmTMB::bf(y ~ x + animal(1 | id, A = A), sigma ~ 1)
  } else {
    drmTMB::bf(y ~ x + spatial(1 | id, coords = coords), sigma ~ 1)
  }
  list(data = data, formula = formula)
}

make_poisson_case <- function() {
  set.seed(20260831)
  groups <- 8L
  per_group <- 5L
  pos <- matrix(runif(groups * 2L, 0, 3), groups, 2L)
  K <- exp(-as.matrix(dist(pos)) / 0.8) + diag(1e-8, groups)
  id <- rep(sprintf('g%02d', seq_len(groups)), each = per_group)
  x <- rnorm(groups * per_group)
  u <- 0.35 * drop(t(chol(K)) %*% rnorm(groups))
  lambda <- exp(0.25 + 0.30 * x + u[match(id, unique(id))])
  y <- stats::rpois(groups * per_group, lambda)
  data <- data.frame(y = y, x = x, id = id)
  list(data = data, formula = drmTMB::bf(y ~ x + relmat(1 | id, K = K)))
}

run_damage <- function(name, case, family) {
  fit <- drmTMB::drmTMB(case$formula, family = family, data = case$data,
                        engine = 'julia')
  payload <- fit$bridge_payload
  provider <- payload$matrix
  damaged <- diag(nrow(provider))
  options <- if (length(payload$options)) payload$options else NULL
  correct <- JuliaCall::julia_call(
    'drmTMB_provider_profile', payload$formula, fit$model$model_type,
    as.list(payload$data),
    if (identical(payload$kwarg, 'K')) provider else NULL,
    if (identical(payload$kwarg, 'A')) provider else NULL,
    options
  )
  wrong <- JuliaCall::julia_call(
    'drmTMB_provider_profile', payload$formula, fit$model$model_type,
    as.list(payload$data),
    if (identical(payload$kwarg, 'K')) damaged else NULL,
    if (identical(payload$kwarg, 'A')) damaged else NULL,
    options
  )
  correct_values <- c(correct$estimate, correct$lower, correct$upper)
  wrong_values <- c(wrong$estimate, wrong$lower, wrong$upper)
  delta <- wrong_values - correct_values
  stopifnot(all(is.finite(correct_values)), all(is.finite(wrong_values)))
  list(name = name, kwarg = payload$kwarg, correct = correct_values,
       damaged = wrong_values, delta = delta, max_abs_delta = max(abs(delta)))
}

results <- list(
  run_damage('animal', make_gaussian_case('animal'), stats::gaussian()),
  run_damage('spatial-converted-K', make_gaussian_case('spatial'), stats::gaussian()),
  run_damage('poisson-relmat', make_poisson_case(), stats::poisson())
)
print(results)
stopifnot(all(vapply(results, function(x) x$max_abs_delta > 1e-6, logical(1))))
cat('PROVIDER_DAMAGE_CONTROL_PASS\n')
