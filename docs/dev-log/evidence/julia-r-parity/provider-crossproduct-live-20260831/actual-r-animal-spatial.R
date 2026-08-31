root <- normalizePath("/private/tmp/drm-parity-20260830/integration/drmTMB")
jl <- normalizePath("/private/tmp/drm-parity-20260830/integration/DRM.jl")
thread_count <- as.integer(Sys.getenv("JULIA_NUM_THREADS", "1"))
threaded <- identical(thread_count, 4L)
stopifnot(thread_count %in% c(1L, 4L), identical(Sys.getenv("OPENBLAS_NUM_THREADS"), "1"))

options(drmTMB.DRM.jl.path = jl)
pkgload::load_all(root, quiet = TRUE, compile = FALSE)
stopifnot(identical(normalizePath(getNamespaceInfo("drmTMB", "path")), root))

JuliaCall::julia_command(paste(
  "drmTMB_direct_provider_inference(formula, family, data, K, A, coords, options, method, B, seed, threads) =",
  "DRM.drm_bridge_inference(formula = formula, family = family, data = data, K = K, A = A, coords = coords,",
  "options = options, method = method, level = 0.95, B = B, seed = seed, threads = threads, parm = \"fixef:mu:x\")"
))
actual_julia_threads <- as.integer(JuliaCall::julia_eval("Threads.nthreads()"))
stopifnot(identical(actual_julia_threads, thread_count))

make_case <- function(provider) {
  set.seed(if (identical(provider, "animal")) 20260911L else 20260912L)
  groups <- 8L
  per_group <- 4L
  id <- rep(sprintf("g%02d", seq_len(groups)), each = per_group)
  x <- rnorm(groups * per_group)
  coords <- data.frame(
    east = runif(groups, 0, 3),
    north = runif(groups, 0, 3),
    row.names = unique(id)
  )
  A <- 0.55 ^ abs(outer(seq_len(groups), seq_len(groups), "-"))
  K <- exp(-as.matrix(dist(coords)) / 0.8) + diag(1e-8, groups)
  covariance <- if (identical(provider, "animal")) A else K
  group_effect <- 0.45 * drop(t(chol(covariance)) %*% rnorm(groups))
  y <- 0.2 + 0.35 * x + group_effect[match(id, unique(id))] + 0.3 * rnorm(groups * per_group)
  data <- data.frame(y = y, x = x, id = id)
  formula <- if (identical(provider, "animal")) {
    drmTMB::bf(y ~ x + animal(1 | id, A = A), sigma ~ 1)
  } else {
    drmTMB::bf(y ~ x + spatial(1 | id, coords = coords), sigma ~ 1)
  }
  list(data = data, formula = formula, A = A, coords = coords)
}

run_case <- function(provider) {
  case <- make_case(provider)
  fit <- drmTMB::drmTMB(
    case$formula,
    family = stats::gaussian(),
    data = case$data,
    engine = "julia"
  )
  payload <- fit$bridge_payload
  expected_kwarg <- if (identical(provider, "animal")) "A" else "K"
  stopifnot(
    identical(payload$kwarg, expected_kwarg),
    is.null(payload$tree),
    is.matrix(payload$matrix),
    isTRUE(all(is.finite(payload$matrix)))
  )
  if (identical(provider, "spatial")) {
    native_spatial <- drmTMB:::drm_spatial_coords_precision(
      case$coords,
      site = case$data$id,
      group = "id"
    )
    stopifnot(
      grepl("relmat(1 | id)", payload$formula$mu, fixed = TRUE),
      isTRUE(all.equal(
        unname(payload$matrix),
        unname(solve(as.matrix(native_spatial$precision))),
        tolerance = 0
      ))
    )
  } else {
    stopifnot(isTRUE(all.equal(unname(payload$matrix), unname(case$A), tolerance = 0)))
  }

  K <- if (identical(payload$kwarg, "K")) payload$matrix else NULL
  A <- if (identical(payload$kwarg, "A")) payload$matrix else NULL
  coords <- if (identical(payload$kwarg, "coords")) payload$matrix else NULL
  options <- if (length(payload$options)) payload$options else NULL

  public_bootstrap <- stats::confint(
    fit,
    parm = "fixef:mu:x",
    method = "bootstrap",
    level = 0.95,
    R = 2L,
    seed = 7001L,
    threads = threaded
  )
  public_profile <- stats::confint(
    fit,
    parm = "fixef:mu:x",
    method = "profile",
    level = 0.95,
    threads = threaded
  )
  direct_bootstrap <- JuliaCall::julia_call(
    "drmTMB_direct_provider_inference",
    payload$formula,
    fit$model$model_type,
    as.list(payload$data),
    K,
    A,
    coords,
    options,
    "bootstrap",
    2L,
    7001L,
    threaded
  )
  direct_profile <- JuliaCall::julia_call(
    "drmTMB_direct_provider_inference",
    payload$formula,
    fit$model$model_type,
    as.list(payload$data),
    K,
    A,
    coords,
    options,
    "profile",
    1L,
    NULL,
    threaded
  )

  observed_bootstrap <- c(
    unname(stats::coef(fit, dpar = "mu")["x"]),
    public_bootstrap$lower[[1L]],
    public_bootstrap$upper[[1L]]
  )
  expected_bootstrap <- c(
    direct_bootstrap$estimate,
    direct_bootstrap$lower,
    direct_bootstrap$upper
  )
  observed_profile <- c(public_profile$lower[[1L]], public_profile$upper[[1L]])
  expected_profile <- c(direct_profile$lower, direct_profile$upper)
  stopifnot(
    all(is.finite(observed_bootstrap)),
    all(is.finite(observed_profile)),
    isTRUE(all.equal(observed_bootstrap, expected_bootstrap, tolerance = 1e-12)),
    isTRUE(all.equal(observed_profile, expected_profile, tolerance = 1e-12)),
    identical(public_bootstrap$bootstrap.n[[1L]], 2L),
    identical(public_bootstrap$bootstrap.failed[[1L]], 0L),
    identical(public_bootstrap$conf.status[[1L]], "bootstrap"),
    identical(public_profile$conf.status[[1L]], "profile"),
    identical(public_bootstrap$julia.threaded[[1L]], threaded),
    identical(public_bootstrap$julia.threads[[1L]], actual_julia_threads),
    identical(public_profile$julia.threaded[[1L]], threaded),
    identical(public_profile$julia.threads[[1L]], actual_julia_threads),
    identical(as.integer(JuliaCall::julia_eval("DRM.LinearAlgebra.BLAS.get_num_threads()")), 1L)
  )
  list(
    provider = provider,
    julia_threads = actual_julia_threads,
    payload_kwarg = payload$kwarg,
    payload_formula = payload$formula$mu,
    bootstrap_difference = observed_bootstrap - expected_bootstrap,
    profile_difference = observed_profile - expected_profile,
    bootstrap_n = public_bootstrap$bootstrap.n[[1L]],
    bootstrap_failed = public_bootstrap$bootstrap.failed[[1L]],
    bootstrap_status = public_bootstrap$conf.status[[1L]],
    profile_status = public_profile$conf.status[[1L]],
    bootstrap_threaded = public_bootstrap$julia.threaded[[1L]],
    bootstrap_workers = public_bootstrap$julia.workers[[1L]],
    bootstrap_julia_threads = public_bootstrap$julia.threads[[1L]],
    profile_threaded = public_profile$julia.threaded[[1L]],
    profile_workers = public_profile$julia.workers[[1L]],
    profile_julia_threads = public_profile$julia.threads[[1L]],
    blas_threads = as.integer(JuliaCall::julia_eval("DRM.LinearAlgebra.BLAS.get_num_threads()"))
  )
}

results <- lapply(c("animal", "spatial"), run_case)
print(list(
  source = getNamespaceInfo("drmTMB", "path"),
  drm_path = JuliaCall::julia_eval("pathof(DRM)"),
  results = results
))
cat("ACTUAL_R_ANIMAL_SPATIAL_BOOTSTRAP_PROFILE_PASS\n")
