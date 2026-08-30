# Inspect the runner without executing any fits or loading JuliaCall.
tree <- parse("tools/parity_fixture.R")
nodes <- unlist(lapply(as.list(tree), function(x) all.names(x, functions = TRUE)))
stopifnot(sum(nodes == "parity_numeric") == 3L)
stopifnot(!"intersect" %in% nodes, !"min" %in% nodes)
stopifnot("quit" %in% nodes)
cat("FIXTURE_CONTRACT_PASS\n")
