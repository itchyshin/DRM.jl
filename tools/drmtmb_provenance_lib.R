# drmtmb_provenance_lib.R — the drmTMB build fingerprint, as a sourceable function.
#
# Extracted from tools/drmtmb_provenance.R so the parity harnesses can STAMP the
# comparator build into the evidence they write, without duplicating the hashing
# logic. Two copies of that logic would be worse than none: they could drift, and
# a stamp that no longer matches what `--check` computes is a false reassurance.
#
# `drmtmb_provenance.R` sources this file, so there is exactly one definition of
# what "the installed drmTMB build" means.
#
# Usage:
#   source("tools/drmtmb_provenance_lib.R")
#   p <- drmtmb_provenance()          # list(version, built, code_hash, n_objects, libpath)
#   p$code_hash
#
# Returns NULL (with a warning) if drmTMB is not installed, so a harness can
# record "<drmTMB-not-installed>" rather than aborting a measurement run.

drmtmb_provenance <- function() {
  ok <- suppressWarnings(suppressMessages(requireNamespace("drmTMB", quietly = TRUE)))
  if (!ok) {
    warning("drmTMB is not installed in this R library; provenance unavailable.")
    return(NULL)
  }

  desc <- utils::packageDescription("drmTMB")
  version <- as.character(utils::packageVersion("drmTMB"))
  built <- if (is.null(desc$Built)) "<none>" else desc$Built

  # Hash the installed CODE, not the files: deparse every object in the namespace
  # in name order. This is stable across reinstalls of identical source and
  # changes the moment any function body does.
  ns <- asNamespace("drmTMB")
  nms <- sort(ls(ns, all.names = TRUE))
  src <- vapply(
    nms,
    function(n) {
      obj <- tryCatch(get(n, envir = ns), error = function(e) NULL)
      if (is.function(obj)) {
        paste(deparse(obj), collapse = "\n")
      } else {
        # non-functions: record name + class only; data payloads are not the contract
        paste0("<", paste(class(obj), collapse = ","), ">")
      }
    },
    character(1)
  )
  blob <- paste0(nms, "\036", src, collapse = "\035")

  code_hash <- if (requireNamespace("digest", quietly = TRUE)) {
    digest::digest(blob, algo = "sha256", serialize = FALSE)
  } else {
    # no hard dependency on digest: fall back to the system tool
    tf <- tempfile()
    on.exit(unlink(tf), add = TRUE)
    writeLines(blob, tf, useBytes = TRUE)
    out <- tryCatch(system2("shasum", c("-a", "256", tf), stdout = TRUE),
                    error = function(e) NA_character_)
    if (length(out) && !is.na(out[1])) sub("\\s.*$", "", out[1]) else "<unavailable>"
  }

  list(version = version, built = built, code_hash = code_hash,
       n_objects = length(nms), libpath = find.package("drmTMB"))
}

# Convenience for the harnesses: a single stamp string, safe when drmTMB is absent.
drmtmb_code_hash <- function() {
  p <- drmtmb_provenance()
  if (is.null(p)) "<drmTMB-not-installed>" else p$code_hash
}
