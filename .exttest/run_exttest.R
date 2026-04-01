# =============================================================================
# lstparsR Extended Test Harness
# =============================================================================
#
# Reads every .lst file in .exttest/_collected_lst/, runs all fetch_* parsers,
# and produces a detailed report of successes, failures, warnings, and
# extracted values.
#
# Usage:
#   cd lstparsR2
#   Rscript .exttest/run_exttest.R
#
# Outputs:
#   .exttest/report.csv        — one row per file x parser combination
#   .exttest/summary.txt       — human-readable summary
#   .exttest/errors.txt        — full error/warning messages grouped by file
#   .exttest/values_thetas.csv — all extracted theta values across files
#   .exttest/values_etas.csv   — all extracted eta values across files
#   .exttest/values_sigmas.csv — all extracted sigma values across files
#   .exttest/values_scalar.csv — OFV and condition number per file
# =============================================================================

# --- Setup -------------------------------------------------------------------

devtools::load_all(".")

lst_dir    <- ".exttest/_collected_lst"
out_dir    <- ".exttest"
lst_files  <- sort(list.files(lst_dir, pattern = "\\.lst$", full.names = TRUE,
                              recursive = TRUE))

if (length(lst_files) == 0) {
  stop("No .lst files found in ", lst_dir,
       "\nPlace your NONMEM listing files there and re-run.")
}

cat(sprintf("Found %d .lst files in %s\n\n", length(lst_files), lst_dir))

# --- Helpers -----------------------------------------------------------------

# Run a single parser safely, capturing result + error + warnings
run_parser <- function(fn, ...) {
  warns <- character(0)
  result <- withCallingHandlers(
    tryCatch(
      fn(...),
      error = function(e) {
        structure(list(error = conditionMessage(e)), class = "parse_error")
      }
    ),
    warning = function(w) {
      warns <<- c(warns, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  is_err <- inherits(result, "parse_error")
  list(
    ok       = !is_err,
    result   = if (is_err) NULL else result,
    error    = if (is_err) result$error else NA_character_,
    warnings = if (length(warns) > 0) paste(warns, collapse = "; ") else NA_character_
  )
}

# --- Helper for n_rows (handles vectors vs data.frames) ----------------------
nrow_or_len <- function(x) {
  if (is.data.frame(x)) nrow(x)
  else if (is.atomic(x)) length(x)
  else NA_integer_
}

# --- Main loop ---------------------------------------------------------------

parsers <- c("read_lst", "thetas", "etas", "sigmas", "ofv", "condn")

report_rows   <- list()
error_lines   <- character(0)
all_thetas    <- list()
all_etas      <- list()
all_sigmas    <- list()
scalar_rows   <- list()

for (i in seq_along(lst_files)) {
  fpath <- lst_files[i]
  fname <- basename(fpath)
  cat(sprintf("[%d/%d] %s ... ", i, length(lst_files), fname))

  # --- Step 1: read_lst_file -------------------------------------------------
  r_read <- run_parser(read_lst_file, fpath)

  report_rows[[length(report_rows) + 1]] <- data.frame(
    file    = fname,
    parser  = "read_lst_file",
    ok      = r_read$ok,
    error   = r_read$error,
    warnings = r_read$warnings,
    n_rows  = if (r_read$ok) nrow_or_len(r_read$result) else NA_integer_,
    stringsAsFactors = FALSE
  )

  if (!r_read$ok) {
    cat("FAIL (read)\n")
    error_lines <- c(error_lines,
      sprintf("=== %s ===", fname),
      sprintf("  read_lst_file: ERROR: %s", r_read$error), "")
    # Add NA rows for remaining parsers
    for (p in parsers[-1]) {
      report_rows[[length(report_rows) + 1]] <- data.frame(
        file = fname, parser = p, ok = NA,
        error = "skipped (read failed)", warnings = NA_character_,
        n_rows = NA_integer_, stringsAsFactors = FALSE
      )
    }
    next
  }

  lst <- r_read$result
  file_errors <- character(0)

  # --- Step 2: estimation method detection -----------------------------------
  est_method <- tryCatch(
    lstparsR:::.get_estimation_method(lst),
    error = function(e) NA_character_
  )
  has_cov <- lstparsR:::.has_covariance_step(lst)

  # --- Step 3: fetch_thetas --------------------------------------------------
  r_th <- run_parser(fetch_thetas, lst)
  report_rows[[length(report_rows) + 1]] <- data.frame(
    file = fname, parser = "thetas", ok = r_th$ok,
    error = r_th$error, warnings = r_th$warnings,
    n_rows = if (r_th$ok) nrow(r_th$result) else NA_integer_,
    stringsAsFactors = FALSE
  )
  if (r_th$ok) {
    df <- r_th$result
    df$file <- fname
    all_thetas[[length(all_thetas) + 1]] <- df
  } else {
    file_errors <- c(file_errors, sprintf("  thetas: %s", r_th$error))
  }

  # --- Step 4: fetch_etas ----------------------------------------------------
  r_et <- run_parser(fetch_etas, lst)
  report_rows[[length(report_rows) + 1]] <- data.frame(
    file = fname, parser = "etas", ok = r_et$ok,
    error = r_et$error, warnings = r_et$warnings,
    n_rows = if (r_et$ok) nrow(r_et$result) else NA_integer_,
    stringsAsFactors = FALSE
  )
  if (r_et$ok) {
    df <- r_et$result
    df$file <- fname
    all_etas[[length(all_etas) + 1]] <- df
  } else {
    file_errors <- c(file_errors, sprintf("  etas: %s", r_et$error))
  }

  # --- Step 5: fetch_sigmas --------------------------------------------------
  r_sg <- run_parser(fetch_sigmas, lst)
  report_rows[[length(report_rows) + 1]] <- data.frame(
    file = fname, parser = "sigmas", ok = r_sg$ok,
    error = r_sg$error, warnings = r_sg$warnings,
    n_rows = if (r_sg$ok) nrow(r_sg$result) else NA_integer_,
    stringsAsFactors = FALSE
  )
  if (r_sg$ok) {
    df <- r_sg$result
    df$file <- fname
    all_sigmas[[length(all_sigmas) + 1]] <- df
  } else {
    file_errors <- c(file_errors, sprintf("  sigmas: %s", r_sg$error))
  }

  # --- Step 6: fetch_ofv -----------------------------------------------------
  r_ofv <- run_parser(fetch_ofv, lst)
  report_rows[[length(report_rows) + 1]] <- data.frame(
    file = fname, parser = "ofv", ok = r_ofv$ok,
    error = r_ofv$error, warnings = r_ofv$warnings,
    n_rows = NA_integer_,
    stringsAsFactors = FALSE
  )
  if (!r_ofv$ok) {
    file_errors <- c(file_errors, sprintf("  ofv: %s", r_ofv$error))
  }

  # --- Step 7: fetch_condn ---------------------------------------------------
  r_cn <- run_parser(fetch_condn, lst)
  report_rows[[length(report_rows) + 1]] <- data.frame(
    file = fname, parser = "condn", ok = r_cn$ok,
    error = r_cn$error, warnings = r_cn$warnings,
    n_rows = NA_integer_,
    stringsAsFactors = FALSE
  )
  if (!r_cn$ok) {
    file_errors <- c(file_errors, sprintf("  condn: %s", r_cn$error))
  }

  # --- Scalars row -----------------------------------------------------------
  scalar_rows[[length(scalar_rows) + 1]] <- data.frame(
    file       = fname,
    est_method = if (is.na(est_method)) NA_character_ else est_method,
    has_cov    = has_cov,
    n_lines    = length(lst),
    n_thetas   = if (r_th$ok) nrow(r_th$result) else NA_integer_,
    n_etas     = if (r_et$ok) nrow(r_et$result) else NA_integer_,
    n_sigmas   = if (r_sg$ok) nrow(r_sg$result) else NA_integer_,
    ofv        = if (r_ofv$ok) r_ofv$result else NA_real_,
    ofv_warn   = r_ofv$warnings,
    condn      = if (r_cn$ok && !is.na(r_cn$result)) r_cn$result else NA_real_,
    condn_warn = r_cn$warnings,
    stringsAsFactors = FALSE
  )

  # --- Error log for this file -----------------------------------------------
  if (length(file_errors) > 0) {
    error_lines <- c(error_lines, sprintf("=== %s ===", fname), file_errors, "")
  }

  # Progress indicator
  all_ok <- r_th$ok && r_et$ok && r_sg$ok && r_ofv$ok && r_cn$ok
  cat(if (all_ok) "OK" else "PARTIAL", "\n")
}

# --- Assemble outputs --------------------------------------------------------

report <- do.call(rbind, report_rows)

# --- Write report.csv --------------------------------------------------------
write.csv(report, file.path(out_dir, "report.csv"), row.names = FALSE)

# --- Write values_*.csv ------------------------------------------------------
if (length(all_thetas) > 0) {
  write.csv(do.call(rbind, all_thetas),
            file.path(out_dir, "values_thetas.csv"), row.names = FALSE)
}
if (length(all_etas) > 0) {
  write.csv(do.call(rbind, all_etas),
            file.path(out_dir, "values_etas.csv"), row.names = FALSE)
}
if (length(all_sigmas) > 0) {
  write.csv(do.call(rbind, all_sigmas),
            file.path(out_dir, "values_sigmas.csv"), row.names = FALSE)
}
if (length(scalar_rows) > 0) {
  write.csv(do.call(rbind, scalar_rows),
            file.path(out_dir, "values_scalar.csv"), row.names = FALSE)
}

# --- Write errors.txt --------------------------------------------------------
if (length(error_lines) > 0) {
  writeLines(error_lines, file.path(out_dir, "errors.txt"))
} else {
  writeLines("No errors encountered.", file.path(out_dir, "errors.txt"))
}

# --- Write summary.txt -------------------------------------------------------
n_files      <- length(lst_files)
n_read_ok    <- sum(report$ok[report$parser == "read_lst_file"], na.rm = TRUE)
n_read_fail  <- sum(!report$ok[report$parser == "read_lst_file"], na.rm = TRUE)

parser_summary <- function(pname) {
  sub <- report[report$parser == pname, ]
  n_ok   <- sum(sub$ok == TRUE, na.rm = TRUE)
  n_fail <- sum(sub$ok == FALSE, na.rm = TRUE)
  n_skip <- sum(is.na(sub$ok))
  n_warn <- sum(!is.na(sub$warnings))
  sprintf("  %-15s  OK: %3d  FAIL: %3d  SKIP: %3d  WARN: %3d",
          pname, n_ok, n_fail, n_skip, n_warn)
}

# Unique errors per parser
unique_errors <- function(pname) {
  sub <- report[report$parser == pname & report$ok == FALSE, ]
  if (nrow(sub) == 0) return(character(0))
  errs <- unique(sub$error)
  files_per_err <- vapply(errs, function(e) {
    fnames <- sub$file[sub$error == e]
    n <- length(fnames)
    examples <- paste(head(fnames, 3), collapse = ", ")
    if (n > 3) examples <- paste0(examples, sprintf(", ... (+%d more)", n - 3))
    sprintf("    \"%s\" [%d files: %s]", e, n, examples)
  }, character(1))
  c(sprintf("  %s failures:", pname), files_per_err)
}

summary_lines <- c(
  "lstparsR Extended Test Report",
  sprintf("Generated: %s", Sys.time()),
  sprintf("R version: %s", R.version.string),
  "",
  sprintf("Files scanned: %d", n_files),
  sprintf("  read OK  : %d", n_read_ok),
  sprintf("  read FAIL: %d", n_read_fail),
  "",
  "Parser results:",
  vapply(parsers, parser_summary, character(1)),
  "",
  "Unique error messages:",
  unlist(lapply(parsers, unique_errors)),
  "",
  "Warnings summary:",
  {
    warn_rows <- report[!is.na(report$warnings), ]
    if (nrow(warn_rows) > 0) {
      unique_warns <- unique(warn_rows$warnings)
      vapply(unique_warns, function(w) {
        n <- sum(warn_rows$warnings == w, na.rm = TRUE)
        sprintf("  [%d occurrences] %s", n, w)
      }, character(1))
    } else {
      "  (none)"
    }
  },
  "",
  "Estimation methods detected:",
  {
    scalars <- do.call(rbind, scalar_rows)
    methods <- table(scalars$est_method, useNA = "ifany")
    sprintf("  %-55s %d files", names(methods), as.integer(methods))
  },
  "",
  sprintf("Files with covariance step: %d / %d",
          sum(do.call(rbind, scalar_rows)$has_cov), n_files),
  "",
  "Output files:",
  sprintf("  %s/report.csv", out_dir),
  sprintf("  %s/errors.txt", out_dir),
  sprintf("  %s/summary.txt", out_dir),
  sprintf("  %s/values_thetas.csv", out_dir),
  sprintf("  %s/values_etas.csv", out_dir),
  sprintf("  %s/values_sigmas.csv", out_dir),
  sprintf("  %s/values_scalar.csv", out_dir)
)

writeLines(summary_lines, file.path(out_dir, "summary.txt"))
cat("\n")
cat(paste(summary_lines, collapse = "\n"))
cat("\n\nDone. Reports written to .exttest/\n")
