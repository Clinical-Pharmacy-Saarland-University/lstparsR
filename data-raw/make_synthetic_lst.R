#!/usr/bin/env Rscript
# =============================================================================
# Synthetic NONMEM listing corpus for lstparsR
# =============================================================================
#
# Writes compact, fully invented NONMEM 7 listing files (.lst) to
# inst/extdata/lst/ together with
#
#   manifest.csv             one row per case: what the case exercises, the
#                            expected parser status and the expected scalar
#                            results (OFV, condition number, summary());
#   expected_parameters.csv  the expected THETA, OMEGA and SIGMA rows
#                            (estimate, standard error, ETA shrinkage).
#
# Every model, data set name, parameter value and message in these files is
# invented. The page layout imitates NONMEM 7.3-7.6 output (fixed-width
# Fortran records, 120-column page banners, "#METH:"/"#OBJV:" tags, rows
# wrapped after 12 columns, shrinkage records wrapped after 10 values) so
# that the parsers meet the same layout features as in real listings.
# Layouts for methods that were not available as real reference output
# (LAPLACE, ITS, SAEM, IMP, IMPMAP, BAYES) follow the NONMEM 7 user guides.
#
# The expectations are derived from the values written here, never from the
# parser. Re-running the script reproduces the corpus byte for byte.
#
# Usage, from the package root:
#   Rscript data-raw/make_synthetic_lst.R
# =============================================================================

stopifnot(file.exists("DESCRIPTION"))
out_dir <- file.path("inst", "extdata", "lst")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
unlink(list.files(out_dir, full.names = TRUE))

# -----------------------------------------------------------------------------
# Number and record formatting
# -----------------------------------------------------------------------------

# Fortran 1PE10.2-style token as printed in the result pages. NA prints as
# the NONMEM placeholder for parameters without a value (fixed parameters in
# the standard-error pages); NaN and Inf print as the compiler spells them.
fmt_e <- function(x, digits = 2) {
  vapply(x, function(v) {
    if (is.nan(v)) return("NaN")
    if (is.na(v)) return(".........")
    if (is.infinite(v)) return(if (v > 0) "+Infinity" else "-Infinity")
    sprintf(paste0("%.", digits, "E"), v)
  }, character(1), USE.NAMES = FALSE)
}

# Fortran 0PE11.4 ("0.4000E+01"), used for initial estimates.
fmt_e0 <- function(x) {
  vapply(x, function(v) {
    if (v == 0) return("0.0000E+00")
    e <- floor(log10(abs(v))) + 1
    m <- round(v / 10^e, 4)
    if (abs(m) >= 1) {
      e <- e + 1
      m <- m / 10
    }
    sprintf("%.4fE%+03d", m, e)
  }, character(1), USE.NAMES = FALSE)
}

rjust <- function(x, width) formatC(x, width = width)
ljust <- function(x, width) formatC(x, width = -width)
chunk <- function(x, size) unname(split(x, ceiling(seq_along(x) / size)))

# Right-justified fields wrapped after `per_line` values. `prefix(k)` gives
# the leading blanks of record k (NONMEM indents the second record by one
# extra blank).
wrap_fields <- function(tokens, width, per_line, prefix) {
  ch <- chunk(tokens, per_line)
  vapply(seq_along(ch), function(k) {
    paste0(prefix(k), paste(rjust(ch[[k]], width), collapse = ""))
  }, character(1))
}

wrap_labels <- function(labels, prefix) {
  ch <- chunk(labels, 12)
  vapply(seq_along(ch), function(k) {
    paste0(prefix(k), paste(ljust(ch[[k]], 10), collapse = ""))
  }, character(1))
}

th_lab  <- function(i) ifelse(i < 10, sprintf("TH %d", i), sprintf("TH%d", i))
eta_lab <- function(i) ifelse(i < 10, sprintf("ETA%d", i), sprintf("ET%d", i))
eps_lab <- function(i) ifelse(i < 10, sprintf("EPS%d", i), sprintf("EP%d", i))

# Labelled statistics records (ETABAR, shrinkage): 1PE11.4 in 12-column
# fields after a 15-column label, wrapped after 10 values.
stat_record <- function(label, values, fmt = function(v) sprintf("%.4E", v)) {
  wrap_fields(fmt(values), 12, 10, function(k) {
    if (k == 1) paste0(" ", ljust(label, 14)) else strrep(" ", 15)
  })
}

# -----------------------------------------------------------------------------
# Page elements
# -----------------------------------------------------------------------------

STARS <- paste0(" ", strrep("*", 120))

band <- function(text = "", tag = "") {
  pad  <- 80 - nchar(text)
  left <- ceiling(pad / 2)
  paste0(" ", tag, strrep("*", 20 - nchar(tag)), strrep(" ", left), text,
         strrep(" ", pad - left), strrep("*", 20))
}

title_box <- function(method, title, tag = "") {
  c(STARS, band(), band(method), band(title, tag), band(), STARS)
}

SUB <- c(
  theta     = " THETA - VECTOR OF FIXED EFFECTS PARAMETERS   *********",
  omega_cov = " OMEGA - COV MATRIX FOR RANDOM EFFECTS - ETAS  ********",
  sigma_cov = " SIGMA - COV MATRIX FOR RANDOM EFFECTS - EPSILONS  ****",
  omega_cor = " OMEGA - CORR MATRIX FOR RANDOM EFFECTS - ETAS  *******",
  sigma_cor = " SIGMA - CORR MATRIX FOR RANDOM EFFECTS - EPSILONS  ***"
)

vector_block <- function(values) {
  ids  <- wrap_labels(th_lab(seq_along(values)),
                      function(k) strrep(" ", if (k == 2) 10 else 9))
  vals <- wrap_fields(fmt_e(values), 10, 12,
                      function(k) strrep(" ", if (k == 2) 8 else 7))
  c(SUB[["theta"]], "", "", ids, " ", vals, " ", "", "")
}

# Lower-triangular matrix block. Rows longer than 12 values continue on
# records without the "+" carriage-control character. `break_after` inserts
# a page break (with the repeated column header) after that row.
matrix_block <- function(subheader, labels, m, break_after = NULL) {
  header <- wrap_labels(labels, function(k) strrep(" ", if (k == 1) 9 else 10))
  out <- c(subheader, "", "", header, " ")
  for (i in seq_along(labels)) {
    row <- wrap_fields(fmt_e(m[i, seq_len(i)]), 10, 12, function(k) {
      if (k == 1) "+      " else strrep(" ", 8)
    })
    out <- c(out, paste0(" ", labels[i]), row, " ")
    if (identical(break_after, i)) out <- c(out, "1", "", header, "", " ")
  }
  out
}

# Correlation form printed on the second page of each result section:
# standard deviations on the diagonal, correlations below it.
cor_form <- function(m) {
  s <- sqrt(diag(m))
  r <- m / outer(s, s)
  r[!is.finite(r)] <- 0
  diag(r) <- s
  r
}

se_cor_form <- function(se, est) {
  r <- matrix(NA_real_, nrow(se), ncol(se))
  diag(r) <- signif(diag(se) / (2 * sqrt(diag(est))), 3)
  r
}

parameter_pages <- function(header, title, theta, omega, sigma, se_page,
                            est_omega, est_sigma, break_after = NULL) {
  ne <- nrow(omega)
  ns <- nrow(sigma)
  cor_omega <- if (se_page) se_cor_form(omega, est_omega) else cor_form(omega)
  cor_sigma <- if (se_page) se_cor_form(sigma, est_sigma) else cor_form(sigma)
  c("1", title_box(header, title), " ", "", "",
    vector_block(theta),
    matrix_block(SUB[["omega_cov"]], eta_lab(seq_len(ne)), omega, break_after),
    "", "",
    matrix_block(SUB[["sigma_cov"]], eps_lab(seq_len(ns)), sigma),
    "1", "", "",
    matrix_block(SUB[["omega_cor"]], eta_lab(seq_len(ne)), cor_omega, break_after),
    "", "",
    matrix_block(SUB[["sigma_cor"]], eps_lab(seq_len(ns)), cor_sigma))
}

objv_record <- function(ofv) {
  sprintf(" #OBJV:%s%13.3f       %s", strrep("*", 44), ofv, strrep("*", 50))
}

ofv_page <- function(m, ofv) {
  c("1", rep(" ", 20), title_box(m$header, m$objt, "#OBJT:"), " ",
    rep("", 5), objv_record(ofv))
}

eigen_page <- function(m, ev) {
  idx  <- wrap_fields(as.character(seq_along(ev)), 10, 12,
                      function(k) strrep(" ", if (k == 2) 5 else 4))
  vals <- wrap_fields(fmt_e(ev), 10, 12,
                      function(k) strrep(" ", if (k == 2) 8 else 7))
  c("1", rep(" ", 20),
    title_box(m$header, paste0("EIGENVALUES OF COR MATRIX OF ESTIMATE", m$se_suffix)),
    " ", "", idx, " ", vals, " ")
}

# Covariance, correlation and inverse covariance pages of the estimated
# parameters (printed only for a few cases to keep the corpus small).
full_matrix_page <- function(m, title, labels, mat) {
  header <- wrap_labels(labels, function(k) strrep(" ", if (k == 1) 12 else 13))
  out <- c("1", title_box(m$header, paste0(title, m$se_suffix)), " ", "", header, " ")
  for (i in seq_along(labels)) {
    out <- c(out, paste0(" ", labels[i]),
             wrap_fields(fmt_e(mat[i, seq_len(i)]), 10, 12, function(k) {
               if (k == 1) "+      " else strrep(" ", 8)
             }), " ")
  }
  out
}

# -----------------------------------------------------------------------------
# Estimation methods
# -----------------------------------------------------------------------------

method <- function(meth, header, detected = header, objt, family,
                   cond = "YES", inter = "YES", lapl = "NO",
                   em = "NONE", se_suffix = "") {
  list(meth = meth, header = header, detected = detected, objt = objt,
       family = family, cond = cond, inter = inter, lapl = lapl, em = em,
       se_suffix = se_suffix)
}

OBJ_MIN <- "MINIMUM VALUE OF OBJECTIVE FUNCTION"
OBJ_LIK <- "FINAL VALUE OF LIKELIHOOD FUNCTION"

METHODS <- list(
  fo = method("First Order", "FIRST ORDER", objt = OBJ_MIN,
              family = "classic", cond = "NO", inter = "NO"),
  foce = method("First Order Conditional Estimation",
                "FIRST ORDER CONDITIONAL ESTIMATION", objt = OBJ_MIN,
                family = "classic", inter = "NO"),
  focei = method("First Order Conditional Estimation with Interaction",
                 "FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION",
                 objt = OBJ_MIN, family = "classic"),
  focei_eval = method(
    "First Order Conditional Estimation with Interaction (Evaluation)",
    "FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION (EVALUATION)",
    detected = "FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION",
    objt = OBJ_MIN, family = "evaluation"),
  laplace_i = method("Laplacian Conditional Estimation with Interaction",
                     "LAPLACIAN CONDITIONAL ESTIMATION WITH INTERACTION",
                     objt = OBJ_MIN, family = "classic", lapl = "YES"),
  its = method("Iterative Two Stage", "ITERATIVE TWO STAGE", objt = OBJ_LIK,
               family = "its", em = "ITERATIVE TWO STAGE (ITS)"),
  saem = method("Stochastic Approximation Expectation-Maximization",
                "STOCHASTIC APPROXIMATION EXPECTATION-MAXIMIZATION",
                objt = OBJ_LIK, family = "saem",
                em = "STOCHASTIC APPROXIMATION EXPECTATION MAXIMIZATION (SAEM)"),
  imp = method("Importance Sampling", "IMPORTANCE SAMPLING", objt = OBJ_LIK,
               family = "imp", em = "IMPORTANCE SAMPLING (IMP)"),
  imp_eonly = method("Objective Function Evaluation by Importance Sampling",
                     "OBJECTIVE FUNCTION EVALUATION BY IMPORTANCE SAMPLING",
                     detected = "IMPORTANCE SAMPLING", objt = OBJ_LIK,
                     family = "imp_eonly", em = "IMPORTANCE SAMPLING (IMP)"),
  impmap = method("Importance Sampling assisted by Mode a Posteriori",
                  "IMPORTANCE SAMPLING ASSISTED BY MODE A POSTERIORI",
                  objt = OBJ_LIK, family = "imp",
                  em = "IMPORTANCE SAMPLING ASSISTED BY MAP (IMPMAP)"),
  bayes = method("MCMC Bayesian Analysis", "MCMC BAYESIAN ANALYSIS",
                 objt = "AVERAGE VALUE OF LIKELIHOOD FUNCTION",
                 family = "bayes", em = "MCMC BAYESIAN (BAYES)",
                 se_suffix = " (From Sample Variance)")
)

# -----------------------------------------------------------------------------
# Random-effect structures
# -----------------------------------------------------------------------------

# One $OMEGA/$SIGMA block: lower-triangular values by row.
blk <- function(values, fixed = FALSE, same = FALSE) {
  n <- (sqrt(8 * length(values) + 1) - 1) / 2
  stopifnot(n == round(n))
  list(values = values, size = as.integer(n), fixed = fixed, same = same)
}
diag_blocks <- function(values, fixed = rep(FALSE, length(values))) {
  Map(blk, values, fixed)
}

block_size_total <- function(blocks) sum(vapply(blocks, `[[`, 0L, "size"))

# Full symmetric matrix from per-block lower-triangular values. `fill` is
# used between blocks (0 for estimates, NA for standard errors). SAME blocks
# repeat the previous block's values; fixed and SAME blocks have no SE.
assemble <- function(blocks, values, fill = 0, se = FALSE) {
  n <- block_size_total(blocks)
  out <- matrix(fill, n, n)
  pos <- 0L
  prev <- NULL
  k <- 0L
  for (b in blocks) {
    if (b$same) {
      v <- if (se) rep(NA_real_, length(prev)) else prev
    } else {
      k <- k + 1L
      v <- values[[k]]
      prev <- v
      if (se && b$fixed) v <- rep(NA_real_, length(b$values))
    }
    # Row-wise lower-triangular values fill the upper triangle column-wise.
    sub <- matrix(0, b$size, b$size)
    sub[upper.tri(sub, diag = TRUE)] <- v
    sub[lower.tri(sub)] <- t(sub)[lower.tri(sub)]
    idx <- pos + seq_len(b$size)
    out[idx, idx] <- sub
    pos <- pos + b$size
  }
  out
}

# Values of non-SAME blocks of a structure, in order.
block_values <- function(blocks) {
  lapply(Filter(function(b) !b$same, blocks), `[[`, "values")
}

# -----------------------------------------------------------------------------
# Listing sections
# -----------------------------------------------------------------------------

control_stream <- function(case, p) {
  c(sprintf("$PROBLEM    %s", p$title),
    p$control)
}

nmtran_messages <- function(p) {
  c("  ", "NM-TRAN MESSAGES ", "  ",
    sprintf(" WARNINGS AND ERRORS (IF ANY) FOR PROBLEM    %d", p$no),
    "             ",
    p$nmtran %||% " (WARNING  2) NM-TRAN INFERS THAT THE DATA ARE POPULATION.",
    "  ")
}

`%||%` <- function(a, b) if (is.null(a)) b else a

is_simple <- function(blocks) {
  all(vapply(blocks, function(b) b$size == 1L && !b$same, TRUE)) &&
    (all(vapply(blocks, `[[`, TRUE, "fixed")) || !any(vapply(blocks, `[[`, TRUE, "fixed")))
}

re_header <- function(name, blocks) {
  if (is_simple(blocks)) {
    return(sprintf("0%s HAS SIMPLE DIAGONAL FORM WITH DIMENSION: %3d",
                   name, length(blocks)))
  }
  # Block-set number of every element of the lower triangle.
  n <- block_size_total(blocks)
  set <- integer(n)
  pos <- 0L
  k <- 0L
  for (b in blocks) {
    if (!b$same) k <- k + 1L
    set[pos + seq_len(b$size)] <- k
    pos <- pos + b$size
  }
  rows <- vapply(seq_len(n), function(i) {
    v <- ifelse(set[seq_len(i)] == set[i], set[i], 0L)
    paste0(" ", paste(rjust(v, 2), collapse = " "))
  }, character(1))
  c(sprintf("0%s HAS BLOCK FORM:", name), rows)
}

re_initial <- function(name, blocks) {
  out <- sprintf("0INITIAL ESTIMATE OF %s:", name)
  if (is_simple(blocks)) {
    m <- assemble(blocks, block_values(blocks))
    for (i in seq_len(nrow(m))) {
      out <- c(out, paste0(" ", paste(fmt_e0(m[i, seq_len(i)]), collapse = "   ")))
    }
    if (blocks[[1]]$fixed) out <- c(out, sprintf("0%s CONSTRAINED TO BE THIS INITIAL ESTIMATE", name))
    return(out)
  }
  out <- c(out, paste0(" BLOCK SET NO.   BLOCK", strrep(" ", 68), "FIXED"))
  k <- 0L
  for (b in blocks) {
    if (b$same) next
    k <- k + 1L
    out <- c(out, sprintf("%9d%s%s", k, strrep(" ", 82), rjust(if (b$fixed) "YES" else "NO", 4)))
    lt <- b$values
    start <- 1L
    for (i in seq_len(b$size)) {
      out <- c(out, paste0(strrep(" ", 18), paste(fmt_e0(lt[start:(start + i - 1L)]), collapse = "   ")))
      start <- start + i
    }
  }
  out
}

problem_header <- function(case, p) {
  th <- p$theta
  bounds <- vapply(seq_along(th$init), function(i) {
    if (th$fixed[i]) {
      v <- fmt_e0(rep(th$init[i], 3))
    } else {
      v <- fmt_e0(c(th$lower[i], th$init[i], th$upper[i]))
    }
    paste0(rjust(v[1], 12), rjust(v[2], 15), rjust(v[3], 15))
  }, character(1))
  cov <- p$cov_requested
  c(sprintf("1NONLINEAR MIXED EFFECTS MODEL PROGRAM (NONMEM) VERSION %s", case$version),
    "",
    sprintf(" PROBLEM NO.:%10d", p$no),
    paste0(" ", p$title),
    "0DATA CHECKOUT RUN:              NO",
    " DATA SET LOCATED ON UNIT NO.:    2",
    " THIS UNIT TO BE REWOUND:        NO",
    sprintf(" NO. OF DATA RECS IN DATA SET: %8d", p$nrec),
    sprintf(" NO. OF DATA ITEMS IN DATA SET: %3d", length(p$items)),
    " ID DATA ITEM IS DATA ITEM NO.:   1",
    sprintf(" DEP VARIABLE IS DATA ITEM NO.: %3d", match("DV", p$items)),
    sprintf(" MDV DATA ITEM IS DATA ITEM NO.: %2d", match("MDV", p$items)),
    "0LABELS FOR DATA ITEMS:",
    paste0(" ", paste(p$items, collapse = " ")),
    "0FORMAT FOR DATA:",
    sprintf(" (%dE9.0)", length(p$items)),
    "",
    sprintf(" TOT. NO. OF OBS RECS: %8d", p$nobs),
    sprintf(" TOT. NO. OF INDIVIDUALS: %7d", p$nind),
    sprintf("0LENGTH OF THETA: %3d", length(th$init)),
    "0DEFAULT THETA BOUNDARY TEST OMITTED:    NO",
    re_header("OMEGA", p$omega),
    "0DEFAULT OMEGA BOUNDARY TEST OMITTED:    NO",
    re_header("SIGMA", p$sigma),
    "0DEFAULT SIGMA BOUNDARY TEST OMITTED:    NO",
    "0INITIAL ESTIMATE OF THETA:",
    " LOWER BOUND    INITIAL EST    UPPER BOUND",
    bounds,
    re_initial("OMEGA", p$omega),
    re_initial("SIGMA", p$sigma),
    sprintf("0COVARIANCE STEP OMITTED:        %s", if (cov) "NO" else "YES"),
    if (cov) c(sprintf(" EIGENVLS. PRINTED:             %s", if (p$eigen_printed) "YES" else "NO"),
               " SPECIAL COMPUTATION:            NO",
               " COMPRESSED FORMAT:              NO"),
    "0TABLES STEP OMITTED:    NO",
    " NO. OF TABLES:           1",
    sprintf("1DOUBLE PRECISION PREDPP VERSION %s", case$version),
    "",
    paste0(" ", p$advan),
    "0PK SUBROUTINE CALLED WITH EVERY EVENT RECORD.",
    "0ERROR SUBROUTINE CALLED WITH EVERY EVENT RECORD.")
}

# Invented but deterministic monitoring values.
pseudo <- function(n, scale, phase) signif(scale * sin(seq_len(n) * 1.7 + phase), 5)

monitoring <- function(p, s, m, npar) {
  if (m$family == "evaluation") return(character(0))
  if (m$family == "classic") {
    rec <- function(label, v) {
      wrap_fields(sprintf("%.4E", v), 12, 10, function(k) {
        if (k == 1) paste0(" ", ljust(label, 10)) else strrep(" ", 11)
      })
    }
    g0 <- pseudo(npar, 850, 0.3)
    g1 <- pseudo(npar, 0.04, 1.1)
    if (!is.null(s$zero_gradient)) {
      g0[s$zero_gradient] <- 0
      g1[s$zero_gradient] <- 0
    }
    p0 <- s$ofv + 412.5 + 0.0731
    return(c(" MONITORING OF SEARCH:", "", "",
             sprintf("0ITERATION NO.: %4d    OBJECTIVE VALUE: %19.11f        NO. OF FUNC. EVALS.: %3d",
                     0L, p0, 7L),
             sprintf(" CUMULATIVE NO. OF FUNC. EVALS.: %8d", 7L),
             rec("NPARAMETR:", abs(pseudo(npar, 3, 0.9)) + 0.1),
             rec("PARAMETER:", rep(0.1, npar)),
             rec("GRADIENT:", g0),
             "",
             sprintf("0ITERATION NO.: %4d    OBJECTIVE VALUE: %19.11f        NO. OF FUNC. EVALS.: %3d",
                     s$iterations, s$ofv + s$ofv_tail, 11L),
             sprintf(" CUMULATIVE NO. OF FUNC. EVALS.: %8d", s$evals),
             rec("NPARAMETR:", abs(pseudo(npar, 3, 1.4)) + 0.1),
             rec("PARAMETER:", pseudo(npar, 0.6, 2.2)),
             rec("GRADIENT:", g1),
             ""))
  }
  tag <- switch(m$family, saem = "SAEMOBJ=", bayes = "MCMCOBJ=", "OBJ=")
  its <- switch(m$family,
                saem = c(-2000L, -1000L, 0L, 500L),
                bayes = c(-1000L, 0L, 1000L, 2000L),
                imp_eonly = c(0L, 5L),
                c(0L, 10L, 30L, 50L))
  obj <- s$ofv + rev(seq_along(its)) * 3.25 - 3.25
  lines <- sprintf(" iteration %12d %s %16.8f", its, tag, obj + s$ofv_tail)
  if (m$family %in% c("imp", "imp_eonly")) {
    lines <- paste0(lines, " eff.=     300. Smpl.=     300. Fit.= 0.78125")
  }
  c(" EM/BAYES SETUP:", " THETAS THAT ARE MU MODELED:", "", lines, "")
}

termination <- function(s, m, p) {
  if (m$family == "evaluation") return(character(0))
  evals <- sprintf(" NO. OF FUNCTION EVALUATIONS USED: %8d", s$evals)
  digits <- sprintf(" NO. OF SIG. DIGITS IN FINAL EST.: %4.1f", s$sigdig)
  body <- switch(
    s$term,
    successful = c("0MINIMIZATION SUCCESSFUL", evals, digits),
    problems = c("0MINIMIZATION SUCCESSFUL",
                 " HOWEVER, PROBLEMS OCCURRED WITH THE MINIMIZATION.",
                 " REGARD THE RESULTS OF THE ESTIMATION STEP CAREFULLY, AND ACCEPT THEM ONLY",
                 " AFTER CHECKING THAT THE COVARIANCE STEP PRODUCES REASONABLE OUTPUT.",
                 evals, digits),
    boundary = c("0MINIMIZATION SUCCESSFUL", evals, digits,
                 "0PARAMETER ESTIMATE IS NEAR ITS BOUNDARY"),
    rounding = c("0MINIMIZATION TERMINATED",
                 " DUE TO ROUNDING ERRORS (ERROR=134)", evals, digits),
    maxevals = c("0MINIMIZATION TERMINATED",
                 " DUE TO MAX. NO. OF FUNCTION EVALUATIONS EXCEEDED (ERROR=131)",
                 evals, digits),
    infinite = c("0MINIMIZATION TERMINATED",
                 " DUE TO PROXIMITY OF LAST ITERATION EST. TO A VALUE",
                 " AT WHICH THE OBJ. FUNC. IS INFINITE (ERROR=136)",
                 "0AT THE LAST COMPUTED INFINITE VALUE OF THE OBJ. FUNCT.:",
                 "0PRED EXIT CODE = 1",
                 "0INDIVIDUAL NO.      17   ID= 1.70000000000000E+01   (WITHIN-INDIVIDUAL) DATA REC NO.   4",
                 " THETA=",
                 paste0(" ", paste(rjust(fmt_e(s$theta), 10), collapse = " ")),
                 " OCCURS DURING SEARCH FOR ETA AT INITIAL VALUE, ETA=0",
                 " PK PARAMETER FOR V IS NON-POSITIVE",
                 evals, digits),
    its = " OPTIMIZATION WAS COMPLETED",
    saem = c(" STOCHASTIC PORTION WAS NOT TESTED FOR CONVERGENCE",
             " REDUCED STOCHASTIC PORTION WAS COMPLETED"),
    imp = " OPTIMIZATION WAS NOT TESTED FOR CONVERGENCE",
    imp_eonly = " EXPECTATION ONLY PROCESS WAS COMPLETED",
    bayes = c(" BURN-IN WAS NOT TESTED FOR CONVERGENCE",
              " STATISTICAL PORTION WAS COMPLETED"),
    stop("unknown termination ", s$term)
  )
  c(" #TERM:", body)
}

eta_statistics <- function(s, p) {
  if (is.null(s$shrink)) return(character(0))
  ne <- length(s$shrink)
  sd <- s$shrink
  vr <- 100 * (1 - (1 - sd / 100)^2)
  etabar <- pseudo(ne, 0.004, 0.5)
  eps_sd <- s$eps_shrink
  c("",
    " ETABAR IS THE ARITHMETIC MEAN OF THE ETA-ESTIMATES,",
    " AND THE P-VALUE IS GIVEN FOR THE NULL HYPOTHESIS THAT THE TRUE MEAN IS 0.",
    "",
    stat_record("ETABAR:", etabar),
    stat_record("SE:", abs(pseudo(ne, 0.03, 0.2)) + 0.01),
    stat_record("N:", rep(p$nind, ne), function(v) sprintf("%d", as.integer(v))),
    "",
    stat_record("P VAL.:", abs(pseudo(ne, 0.9, 1.3)) + 0.05),
    "",
    stat_record("ETASHRINKSD(%)", sd),
    stat_record("ETASHRINKVR(%)", vr),
    stat_record("EBVSHRINKSD(%)", pmin(sd * 1.07, 100)),
    stat_record("EBVSHRINKVR(%)", pmin(vr * 1.05, 100)),
    stat_record("EPSSHRINKSD(%)", eps_sd),
    stat_record("EPSSHRINKVR(%)", 100 * (1 - (1 - eps_sd / 100)^2)),
    "")
}

ofv_summary <- function(s, m, p) {
  if (m$family == "evaluation") return(character(0))
  const <- p$nobs * log(2 * pi)
  full <- s$ofv + s$ofv_tail
  c("  ",
    sprintf(" TOTAL DATA POINTS NORMALLY DISTRIBUTED (N): %12d", p$nobs),
    sprintf(" N*LOG(2PI) CONSTANT TO OBJECTIVE FUNCTION:    %.13f     ", const),
    sprintf(" OBJECTIVE FUNCTION VALUE WITHOUT CONSTANT:    %.13f     ", full),
    sprintf(" OBJECTIVE FUNCTION VALUE WITH CONSTANT:       %.13f     ", full + const),
    " REPORTED OBJECTIVE FUNCTION DOES NOT CONTAIN CONSTANT",
    "  ",
    sprintf(" TOTAL EFFECTIVE ETAS (NIND*NETA): %29d", p$nind * block_size_total(p$omega)),
    "  ")
}

cov_messages <- function(s) {
  switch(
    s$cov %||% "none",
    none = character(0),
    ok = sprintf(" Elapsed covariance  time in seconds: %8.2f", 1.37),
    aborted = c("0R MATRIX ALGORITHMICALLY SINGULAR",
                " AND ALGORITHMICALLY NON-POSITIVE-SEMIDEFINITE",
                "0R MATRIX IS OUTPUT",
                "0COVARIANCE STEP ABORTED",
                sprintf(" Elapsed covariance  time in seconds: %8.2f", 0.94)),
    s_singular = c("0S MATRIX ALGORITHMICALLY SINGULAR",
                   "0S MATRIX IS OUTPUT",
                   "0INVERSE COVARIANCE MATRIX SET TO RS*R, WHERE S* IS A PSEUDO INVERSE OF S",
                   sprintf(" Elapsed covariance  time in seconds: %8.2f", 1.66)),
    r_npd = c("0R MATRIX ALGORITHMICALLY NON-POSITIVE-SEMIDEFINITE",
              " BUT NONSINGULAR",
              sprintf(" Elapsed covariance  time in seconds: %8.2f", 1.21)),
    stop("unknown covariance status ", s$cov)
  )
}

estimation_options <- function(s, m) {
  common <- c(" ESTIMATION STEP OMITTED:                 NO",
              " ANALYSIS TYPE:                           POPULATION")
  if (m$family %in% c("classic", "evaluation")) {
    return(c(common,
             " GRADIENT METHOD USED:               NOSLOW",
             sprintf(" CONDITIONAL ESTIMATES USED:              %s", m$cond),
             " CENTERED ETA:                            NO",
             sprintf(" EPS-ETA INTERACTION:                     %s", m$inter),
             sprintf(" LAPLACIAN OBJ. FUNC.:                    %s", m$lapl),
             sprintf(" NO. OF FUNCT. EVALS. ALLOWED:            %d", s$maxeval %||% 9999L),
             " NO. OF SIG. FIGURES REQUIRED:            3",
             " INTERMEDIATE PRINTOUT:                   YES",
             " EM OR BAYESIAN METHOD USED:                 NONE"))
  }
  c(common,
    sprintf(" EM OR BAYESIAN METHOD USED:                %s", m$em),
    " MU MODELING PATTERN (MUM):",
    " GRADIENT/GIBBS PATTERN (GRD):",
    switch(m$family,
           its = " CONVERGENCE TYPE (CTYPE):                  0",
           saem = c(" BURN-IN NUMBER (NBURN):                    2000",
                    " ITERATIONS (NITER):                        500"),
           bayes = c(" BURN-IN NUMBER (NBURN):                    1000",
                     " ITERATIONS (NITER):                        2000"),
           c(" EM/BAYES SAMPLES (ISAMPLE):                300",
             " ITERATIONS (NITER):                        50")))
}

estimation_step <- function(p, s) {
  m <- METHODS[[s$method]]
  npar <- sum(!p$theta$fixed) + block_size_total(p$omega) + block_size_total(p$sigma)
  c("1", "", "",
    sprintf(" #TBLN: %6d", s$tbln),
    paste0(" #METH: ", m$meth),
    "",
    estimation_options(s, m),
    "",
    monitoring(p, s, m, npar),
    termination(s, m, p),
    eta_statistics(s, p),
    ofv_summary(s, m, p),
    if (m$family != "evaluation") c(" #TERE:", sprintf(" Elapsed estimation  time in seconds: %8.2f", 4.18)),
    if (m$family == "evaluation") sprintf(" Elapsed evaluation time in seconds: %9.2f", 0.71),
    cov_messages(s),
    sprintf(" Elapsed postprocess time in seconds: %8.2f", 0.02))
}

result_pages <- function(p, s) {
  m <- METHODS[[s$method]]
  est_omega <- assemble(p$omega, s$omega)
  est_sigma <- assemble(p$sigma, s$sigma)
  out <- c(ofv_page(m, s$ofv),
           parameter_pages(m$header, "FINAL PARAMETER ESTIMATE", s$theta,
                           est_omega, est_sigma, se_page = FALSE,
                           break_after = p$page_break_after))
  if (!is.null(s$theta_se)) {
    se_theta <- ifelse(p$theta$fixed, NA_real_, s$theta_se)
    se_omega <- assemble(p$omega, s$omega_se, fill = NA_real_, se = TRUE)
    se_sigma <- assemble(p$sigma, s$sigma_se, fill = NA_real_, se = TRUE)
    out <- c(out, parameter_pages(m$header, paste0("STANDARD ERROR OF ESTIMATE", m$se_suffix),
                                  se_theta, se_omega, se_sigma, se_page = TRUE,
                                  est_omega = est_omega, est_sigma = est_sigma,
                                  break_after = p$page_break_after))
    if (isTRUE(s$cov_pages)) out <- c(out, covariance_pages(p, s, m, se_theta))
    if (p$eigen_printed && !is.null(s$eigen)) out <- c(out, eigen_page(m, s$eigen))
  }
  out
}

# Covariance, correlation and inverse covariance pages for simple diagonal
# models; the correlation matrix is an AR(1) pattern, and the printed
# eigenvalues of the case are taken from it.
ar1 <- function(n, rho = -0.3) rho^abs(outer(seq_len(n), seq_len(n), "-"))

covariance_pages <- function(p, s, m, se_theta) {
  se <- c(se_theta[!p$theta$fixed], diag(assemble(p$omega, s$omega_se, NA, TRUE)),
          diag(assemble(p$sigma, s$sigma_se, NA, TRUE)))
  labels <- c(th_lab(which(!p$theta$fixed)),
              sprintf("OM%d%d", seq_len(block_size_total(p$omega)), seq_len(block_size_total(p$omega))),
              sprintf("SG%d%d", seq_len(block_size_total(p$sigma)), seq_len(block_size_total(p$sigma))))
  r <- ar1(length(se))
  covm <- r * outer(se, se)
  corm <- r
  diag(corm) <- se
  inverse <- solve(covm)
  inverse[abs(inverse) < 1e-10 * max(abs(inverse))] <- 0   # drop rounding noise
  inverse <- signif(inverse, 3)
  c(full_matrix_page(m, "COVARIANCE MATRIX OF ESTIMATE", labels, covm),
    full_matrix_page(m, "CORRELATION MATRIX OF ESTIMATE", labels, corm),
    full_matrix_page(m, "INVERSE COVARIANCE MATRIX OF ESTIMATE", labels, inverse))
}

simulation_step <- function(p) {
  c("1", "",
    " SIMULATION STEP PERFORMED",
    " SOURCE  1:",
    "    SEED1:     20261111   SEED2:            0",
    sprintf(" Elapsed simulation  time in seconds: %8.2f", 0.35),
    " ESTIMATION STEP OMITTED:                 YES",
    sprintf(" Elapsed finaloutput time in seconds: %8.2f", 0.04))
}

simulation_header <- function(p) {
  c("0SIMULATION STEP OMITTED:    NO",
    " OBJ FUNC EVALUATED:         NO",
    sprintf(" NUMBER OF SUBPROBLEMS: %8d", p$nsub),
    "0SIMULATION RANDOM METHOD SELECTED (RANMETHOD): 4U",
    "SOURCE   1:",
    "   SEED1:      20261111   SEED2:            0   PSEUDO-NORMAL")
}

render_problem <- function(case, p) {
  if (p$kind == "nmtran_error") {
    return(c(control_stream(case, p),
             "  ", "NM-TRAN MESSAGES ", "  ",
             sprintf(" WARNINGS AND ERRORS (IF ANY) FOR PROBLEM    %d", p$no),
             "             ",
             " AN ERROR WAS FOUND IN THE CONTROL STATEMENTS.",
             " ",
             " THE CHARACTERS IN ERROR ARE: TVQ",
             "  479  THIS VARIABLE IS NOT DEFINED.",
             "  "))
  }
  head <- c(control_stream(case, p), nmtran_messages(p), problem_header(case, p))
  if (p$kind == "simulation") {
    return(c(head, simulation_header(p), simulation_step(p)))
  }
  # Each estimation step is followed by its own result pages.
  body <- character(0)
  for (s in p$steps) body <- c(body, estimation_step(p, s), result_pages(p, s))
  c(head, body, sprintf(" Elapsed finaloutput time in seconds: %8.2f", 0.11))
}

render_case <- function(case) {
  out <- character(0)
  for (p in case$problems) out <- c(out, render_problem(case, p))
  ran <- any(vapply(case$problems, function(p) p$kind != "nmtran_error", TRUE))
  if (ran) out <- c(out, sprintf(" #CPUT: Total CPU Time in Seconds, %12.3f", 7.125), "Stop Time:")
  if (!is.null(case$footer)) out <- c(out, case$footer)
  if (!is.null(case$truncate)) out <- case$truncate(out)
  out
}

# -----------------------------------------------------------------------------
# Case constructors
# -----------------------------------------------------------------------------

theta_spec <- function(init, lower = rep(0, length(init)),
                       upper = rep(1e6, length(init)),
                       fixed = rep(FALSE, length(init))) {
  list(init = init, lower = lower, upper = upper, fixed = fixed)
}

problem <- function(no = 1L, kind = "estimation", title, control, items,
                    advan, theta, omega, sigma, steps = list(),
                    nobs = 480L, nind = 40L, nrec = NULL,
                    cov_requested = FALSE, eigen_printed = TRUE,
                    page_break_after = NULL, nsub = 100L, nmtran = NULL) {
  list(no = as.integer(no), kind = kind, title = title, control = control,
       items = items, advan = advan, theta = theta, omega = omega,
       sigma = sigma, steps = steps, nobs = as.integer(nobs),
       nind = as.integer(nind), nrec = as.integer(nrec %||% (nobs + nind)),
       cov_requested = cov_requested, eigen_printed = eigen_printed,
       page_break_after = page_break_after, nsub = as.integer(nsub),
       nmtran = nmtran)
}

# One estimation step. `omega`/`sigma` hold the lower-triangular values of
# the non-SAME blocks; *_se the matching standard errors (ignored for fixed
# blocks). Without `theta_se`, no standard-error pages are printed.
step <- function(method, theta, omega, sigma, ofv, ofv_tail = 0.000173914, shrink = NULL,
                 eps_shrink = NULL, theta_se = NULL, omega_se = NULL,
                 sigma_se = NULL, eigen = NULL, term = "successful",
                 cov = NULL, cov_pages = FALSE, tbln = 1L, zero_gradient = NULL,
                 iterations = 23L, evals = 251L, sigdig = 3.4, maxeval = NULL) {
  list(method = method, theta = theta, omega = as.list(omega),
       sigma = as.list(sigma), ofv = ofv, ofv_tail = ofv_tail,
       shrink = shrink, eps_shrink = eps_shrink %||% rep(5.25, 1),
       theta_se = theta_se, omega_se = as.list(omega_se),
       sigma_se = as.list(sigma_se), eigen = eigen, term = term, cov = cov,
       cov_pages = cov_pages, tbln = as.integer(tbln),
       zero_gradient = zero_gradient, iterations = as.integer(iterations),
       evals = as.integer(evals), sigdig = sigdig, maxeval = maxeval)
}

title_of <- function(id, what) sprintf("SYNTHETIC lstparsR test case %s: %s", id, what)

# --- Invented model templates --------------------------------------------------

# A: one-compartment model with first-order absorption and a weight effect.
model_a <- function(id, what, est = "$ESTIMATION METHOD=1 INTERACTION MAXEVAL=9999 PRINT=5 NOABORT",
                    cov = "$COVARIANCE PRINT=E", extra_omega = NULL) {
  c("$INPUT      ID TIME AMT DV MDV EVID WT",
    sprintf("$DATA      synthetic_%s.csv IGNORE=@", id),
    "$SUBROUTINE ADVAN2 TRANS2",
    "$PK",
    "  TVCL = THETA(1) * (WT / 70)**THETA(4)",
    "  CL   = TVCL * EXP(ETA(1))",
    "  V    = THETA(2) * EXP(ETA(2))",
    "  KA   = THETA(3) * EXP(ETA(3))",
    "  S2   = V",
    "$ERROR",
    "  IPRED = F",
    "  Y     = IPRED * (1 + EPS(1))",
    "$THETA  (0, 4) (0, 30) (0, 1) 0.75",
    "$OMEGA  0.1 0.1 0.3",
    extra_omega,
    "$SIGMA  0.03",
    est, cov,
    sprintf("$TABLE      ID TIME IPRED CWRES NOPRINT ONEHEADER FILE=synthetic_%s.tab", id))
}
items_a <- c("ID", "TIME", "AMT", "DV", "MDV", "EVID", "WT")
advan_a <- "ONE COMPARTMENT MODEL WITH FIRST-ORDER ABSORPTION (ADVAN2)"
theta_a <- theta_spec(c(4, 30, 1, 0.75), lower = c(0, 0, 0, -1e6))
omega_a <- diag_blocks(c(0.1, 0.1, 0.3))
sigma_1 <- diag_blocks(0.03)

# B: two-compartment infusion model with combined residual error.
model_b <- function(id, est = "$ESTIMATION METHOD=1 MAXEVAL=9999 PRINT=5",
                    cov = "$COVARIANCE PRINT=E") {
  c("$INPUT      ID TIME AMT RATE DV MDV",
    sprintf("$DATA      synthetic_%s.csv IGNORE=@", id),
    "$SUBROUTINE ADVAN3 TRANS4",
    "$PK",
    "  CL = THETA(1) * EXP(ETA(1))",
    "  V1 = THETA(2) * EXP(ETA(2))",
    "  Q  = THETA(3)",
    "  V2 = THETA(4)",
    "  S1 = V1",
    "$ERROR",
    "  IPRED = F",
    "  Y     = IPRED + IPRED * EPS(1) + EPS(2)",
    "$THETA  (0, 8) (0, 20) (0, 3) (0, 40)",
    "$OMEGA  0.1 0.1",
    "$SIGMA  0.02 0.05",
    est, cov,
    sprintf("$TABLE      ID TIME IPRED CWRES NOPRINT ONEHEADER FILE=synthetic_%s.tab", id))
}
items_b <- c("ID", "TIME", "AMT", "RATE", "DV", "MDV")
advan_b <- "TWO COMPARTMENT MODEL (ADVAN3)"
theta_b <- theta_spec(c(8, 20, 3, 40))
omega_b <- diag_blocks(c(0.1, 0.1))
sigma_b <- diag_blocks(c(0.02, 0.05))

# C: one-compartment bolus model.
model_c <- function(id, est = "$ESTIMATION METHOD=1 INTERACTION MAXEVAL=9999",
                    cov = "$COVARIANCE PRINT=E", error = NULL) {
  c("$INPUT      ID TIME AMT DV MDV",
    sprintf("$DATA      synthetic_%s.csv IGNORE=@", id),
    "$SUBROUTINE ADVAN1 TRANS2",
    "$PK",
    "  CL = THETA(1) * EXP(ETA(1))",
    "  V  = THETA(2) * EXP(ETA(2))",
    "  S1 = V",
    "$ERROR",
    error %||% c("  IPRED = F", "  Y     = IPRED * (1 + EPS(1))"),
    "$THETA  (0, 3) (0, 25)",
    "$OMEGA  0.1 0.1",
    "$SIGMA  0.04",
    est, cov,
    sprintf("$TABLE      ID TIME IPRED NOPRINT ONEHEADER FILE=synthetic_%s.tab", id))
}
items_c <- c("ID", "TIME", "AMT", "DV", "MDV")
advan_c <- "ONE COMPARTMENT MODEL (ADVAN1)"
theta_c <- theta_spec(c(3, 25))
omega_c <- diag_blocks(c(0.1, 0.1))
sigma_c <- diag_blocks(0.04)

prob_a <- function(id, what, steps, ..., control = model_a(id, what)) {
  problem(title = title_of(id, what), control = control, items = items_a,
          advan = advan_a, theta = theta_a, omega = omega_a, sigma = sigma_1,
          steps = steps, ...)
}
prob_b <- function(id, what, steps, ..., control = model_b(id)) {
  problem(title = title_of(id, what), control = control, items = items_b,
          advan = advan_b, theta = theta_b, omega = omega_b, sigma = sigma_b,
          steps = steps, nobs = 560L, nind = 35L, ...)
}
prob_c <- function(id, what, steps, ..., control = model_c(id)) {
  problem(title = title_of(id, what), control = control, items = items_c,
          advan = advan_c, theta = theta_c, omega = omega_c, sigma = sigma_c,
          steps = steps, nobs = 300L, nind = 30L, ...)
}

case <- function(id, slug, version, exercises, problems, eol = "\n",
                 final_newline = TRUE, footer = NULL, truncate = NULL,
                 expect = list(), termination = "", covariance = "") {
  list(id = id, slug = slug, file = sprintf("%s_%s.lst", id, slug),
       version = version, exercises = exercises, problems = problems,
       eol = eol, final_newline = final_newline, footer = footer,
       truncate = truncate, expect = expect, termination = termination,
       covariance = covariance)
}

# Truncation helpers: keep everything up to (and including) the first line
# matching `pattern` (optionally after the n-th match), plus `extra` lines.
cut_after <- function(pattern, extra = 0L, occurrence = 1L) {
  function(lines) {
    i <- grep(pattern, lines)[occurrence]
    stopifnot(!is.na(i))
    lines[seq_len(i + extra)]
  }
}

# -----------------------------------------------------------------------------
# The cases
# -----------------------------------------------------------------------------

cases <- list()
add <- function(x) cases[[length(cases) + 1L]] <<- x

base_a <- list(theta = c(4.37, 31.2, 1.15, 0.682),
               theta_se = c(0.312, 2.05, 0.143, 0.121),
               omega = c(0.0841, 0.0529, 0.312), omega_se = c(0.0213, 0.0187, 0.0954),
               sigma = 0.0277, sigma_se = 0.00341,
               shrink = c(8.42, 21.3, 37.9), eps_shrink = 6.15)

ev_s01 <- signif(sort(eigen(ar1(8))$values), 3)

add(case(
  "s01", "focei_cov_success", "7.4.3",
  "FOCE-I reference run: minimization successful, covariance step with covariance, correlation, inverse covariance and eigenvalue pages",
  termination = "successful", covariance = "completed",
  problems = list(prob_a("s01", "FOCE-I, covariance step successful", list(
    step("focei", base_a$theta, base_a$omega, base_a$sigma, 1873.406,
         ofv_tail = 0.000137492519, shrink = base_a$shrink, eps_shrink = 6.15,
         theta_se = base_a$theta_se, omega_se = base_a$omega_se,
         sigma_se = base_a$sigma_se, eigen = ev_s01, cov = "ok", cov_pages = TRUE)),
    cov_requested = TRUE))))

add(case(
  "s02", "foce_two_sigmas", "7.3.0",
  "FOCE without interaction, two-compartment model, two residual-error variances",
  termination = "successful", covariance = "completed",
  problems = list(prob_b("s02", "FOCE without interaction, two SIGMAs", list(
    step("foce", c(7.82, 18.6, 2.94, 44.1), c(0.0961, 0.142), c(0.0219, 0.0484), 3150.792,
         shrink = c(4.71, 18.6), eps_shrink = c(7.02, 7.02),
         theta_se = c(0.514, 1.73, 0.402, 5.27), omega_se = c(0.0242, 0.0451),
         sigma_se = c(0.00287, 0.0123),
         eigen = c(0.0973, 0.264, 0.581, 0.877, 1.12, 1.46, 1.71, 1.89), cov = "ok")),
    cov_requested = TRUE))))

add(case(
  "s03", "fo_no_shrinkage", "7.5.1",
  "First-order method: no ETABAR or shrinkage records, so shrinkage is NA",
  termination = "successful", covariance = "completed",
  problems = list(prob_a("s03", "FO, covariance step successful", list(
    step("fo", c(4.12, 29.4, 0.973, 0.751), c(0.103, 0.0617, 0.284), 0.0312, 1902.555,
         theta_se = c(0.287, 2.31, 0.118, 0.164), omega_se = c(0.0298, 0.0221, 0.112),
         sigma_se = 0.00417,
         eigen = c(0.0615, 0.223, 0.418, 0.702, 0.951, 1.27, 1.63, 2.72), cov = "ok")),
    cov_requested = TRUE,
    control = model_a("s03", "", est = "$ESTIMATION METHOD=0 MAXEVAL=9999 PRINT=5")))))

add(case(
  "s04", "laplace_m3_blq", "7.5.0",
  "LAPLACE with interaction and the M3 likelihood for values below the quantification limit",
  termination = "successful", covariance = "completed",
  problems = list(prob_c("s04", "LAPLACE, M3 likelihood for BLQ data", list(
    step("laplace_i", c(3.08, 22.7), c(0.118, 0.0745), 0.0391, 1214.337,
         shrink = c(12.6, 29.8), eps_shrink = 9.84,
         theta_se = c(0.226, 1.94), omega_se = c(0.0335, 0.0263), sigma_se = 0.00562,
         eigen = c(0.288, 0.614, 0.893, 1.36, 1.85), cov = "ok")),
    cov_requested = TRUE,
    control = model_c("s04",
      est = "$ESTIMATION METHOD=COND LAPLACIAN INTERACTION NUMERICAL SLOW MAXEVAL=9999",
      error = c("  IPRED = F",
                "  W     = SQRT(THETA(3)**2 + (THETA(4) * IPRED)**2)",
                "  LLOQ  = 0.05",
                "  IF (BLQ.EQ.0) THEN",
                "    F_FLAG = 0",
                "    Y      = IPRED * (1 + EPS(1))",
                "  ELSE",
                "    F_FLAG = 1",
                "    Y      = PHI((LLOQ - IPRED) / W)",
                "  ENDIF"))))))

add(case(
  "s05", "its_no_cov", "7.4.4",
  "Iterative two-stage (EM) estimation without a covariance step",
  termination = "optimization completed", covariance = "not requested",
  problems = list(prob_a("s05", "ITS, no covariance step", list(
    step("its", c(4.41, 30.8, 1.21, 0.659), c(0.0873, 0.0502, 0.327), 0.0281, 1880.214,
         shrink = c(7.95, 22.6, 39.1), eps_shrink = 6.42, term = "its")),
    control = model_a("s05", "", est = "$ESTIMATION METHOD=ITS INTERACTION NITER=50",
                      cov = NULL)))))

add(case(
  "s06", "saem_cov", "7.5.1",
  "SAEM estimation followed by a covariance step",
  termination = "stochastic portion completed", covariance = "completed",
  problems = list(prob_b("s06", "SAEM, covariance step successful", list(
    step("saem", c(7.64, 19.1, 3.02, 42.8), c(0.0918, 0.151), c(0.0224, 0.0451), 3125.448,
         shrink = c(5.02, 17.9), eps_shrink = c(6.88, 6.88), term = "saem",
         theta_se = c(0.498, 1.81, 0.437, 5.66), omega_se = c(0.0233, 0.0467),
         sigma_se = c(0.00301, 0.0119),
         eigen = c(0.104, 0.257, 0.566, 0.861, 1.13, 1.48, 1.72, 1.88), cov = "ok")),
    cov_requested = TRUE,
    control = model_b("s06", est = "$ESTIMATION METHOD=SAEM INTERACTION NBURN=2000 NITER=500")))))

add(case(
  "s07", "saem_then_imp", "7.4.3",
  "Two $ESTIMATION steps (SAEM, then IMP) with different estimates; results come from the final IMP step",
  termination = "optimization not tested", covariance = "completed",
  problems = list(prob_a("s07", "SAEM followed by IMP, covariance step after IMP", list(
    step("saem", c(4.33, 31.6, 1.12, 0.671), c(0.0857, 0.0538, 0.305), 0.0274, 1870.026,
         shrink = c(8.61, 21.9, 38.4), eps_shrink = 6.31, term = "saem", tbln = 1L),
    step("imp", c(4.36, 31.3, 1.14, 0.679), c(0.0846, 0.0533, 0.309), 0.0276, 1875.893,
         shrink = c(8.47, 21.5, 38.1), eps_shrink = 6.22, term = "imp", tbln = 2L,
         theta_se = c(0.318, 2.11, 0.149, 0.126), omega_se = c(0.0219, 0.0191, 0.0978),
         sigma_se = 0.00352,
         eigen = c(0.0438, 0.192, 0.401, 0.627, 0.912, 1.23, 1.72, 2.87), cov = "ok")),
    cov_requested = TRUE,
    control = model_a("s07", "", est = c("$ESTIMATION METHOD=SAEM INTERACTION NBURN=2000 NITER=500",
                                         "$ESTIMATION METHOD=IMP INTERACTION ISAMPLE=300 NITER=50"))))))

add(case(
  "s08", "impmap_cov", "7.5.0",
  "IMPMAP estimation (importance sampling assisted by mode a posteriori) with a covariance step",
  termination = "optimization not tested", covariance = "completed",
  problems = list(prob_c("s08", "IMPMAP, covariance step successful", list(
    step("impmap", c(3.11, 22.4), c(0.121, 0.0731), 0.0387, 1216.902,
         shrink = c(12.2, 30.4), eps_shrink = 9.51, term = "imp",
         theta_se = c(0.231, 1.98), omega_se = c(0.0342, 0.0259), sigma_se = 0.00571,
         eigen = c(0.301, 0.597, 0.912, 1.33, 1.86), cov = "ok")),
    cov_requested = TRUE,
    control = model_c("s08", est = "$ESTIMATION METHOD=IMPMAP INTERACTION ISAMPLE=300 NITER=50")))))

add(case(
  "s09", "its_then_bayes", "7.4.4",
  "ITS followed by MCMC Bayesian analysis; posterior standard deviations printed as standard errors 'From Sample Variance'; negative OFV",
  termination = "statistical portion completed", covariance = "from posterior sample",
  problems = list(prob_c("s09", "ITS followed by BAYES", list(
    step("its", c(3.05, 22.9), c(0.115, 0.0762), 0.0394, 1220.418,
         shrink = c(12.9, 29.1), eps_shrink = 9.92, term = "its", tbln = 1L),
    step("bayes", c(3.09, 22.6), c(0.124, 0.0768), 0.0395, -2187.645,
         shrink = c(13.1, 30.2), eps_shrink = 9.87, term = "bayes", tbln = 2L,
         theta_se = c(0.238, 2.04), omega_se = c(0.0377, 0.0281), sigma_se = 0.00604,
         eigen = c(0.276, 0.633, 0.905, 1.31, 1.88), cov = "ok")),
    cov_requested = TRUE,
    control = model_c("s09", est = c("$ESTIMATION METHOD=ITS INTERACTION NITER=50",
                                     "$ESTIMATION METHOD=BAYES INTERACTION NBURN=1000 NITER=2000"))))))

add(case(
  "s10", "focei_evaluation", "7.4.3",
  "MAXEVAL=0 evaluation: '(Evaluation)' method header, no termination block, estimates equal initial values",
  termination = "evaluation only", covariance = "not requested",
  problems = list(prob_a("s10", "FOCE-I evaluation at the initial estimates", list(
    step("focei_eval", c(4, 30, 1, 0.75), c(0.1, 0.1, 0.3), 0.03, 2011.583)),
    control = model_a("s10", "", est = "$ESTIMATION METHOD=1 INTERACTION MAXEVAL=0",
                      cov = NULL)))))

add(case(
  "s11", "rounding_errors_cov", "7.4.3",
  "Minimization terminated due to rounding errors (ERROR=134); covariance step still completed",
  termination = "terminated (rounding errors, 134)", covariance = "completed",
  problems = list(prob_b("s11", "rounding errors, covariance step completed", list(
    step("foce", c(7.71, 18.2, 3.17, 47.3), c(0.0884, 0.163), c(0.0228, 0.0503), 3148.117,
         shrink = c(4.93, 19.4), eps_shrink = c(7.15, 7.15), term = "rounding", sigdig = 2.1,
         theta_se = c(0.689, 2.37, 0.811, 9.84), omega_se = c(0.0301, 0.0612),
         sigma_se = c(0.00344, 0.0161),
         eigen = c(0.00872, 0.0915, 0.372, 0.764, 1.06, 1.39, 1.98, 2.33), cov = "ok")),
    cov_requested = TRUE))))

add(case(
  "s12", "rounding_errors_no_cov", "7.5.1",
  "Minimization terminated due to rounding errors without a covariance step: estimates only",
  termination = "terminated (rounding errors, 134)", covariance = "not requested",
  problems = list(prob_a("s12", "rounding errors, no covariance step", list(
    step("focei", c(4.29, 32.1, 1.08, 0.705), c(0.0899, 0.0611, 0.297), 0.0283, 1879.554,
         shrink = c(9.12, 23.4, 40.2), eps_shrink = 6.57, term = "rounding", sigdig = 1.8)),
    control = model_a("s12", "", cov = NULL)))))

add(case(
  "s13", "max_evals_zero_gradient", "7.3.0",
  "Maximum number of function evaluations exceeded (ERROR=131) with zero gradient elements in the search monitor",
  termination = "terminated (max. evaluations, 131)", covariance = "not requested",
  problems = list(prob_b("s13", "max. evaluations exceeded, zero gradients", list(
    step("foce", c(8.13, 17.9, 2.71, 49.6), c(0.104, 0.137), c(0.0231, 0.0467), 3162.904,
         shrink = c(6.33, 21.7), eps_shrink = c(7.4, 7.4), term = "maxevals",
         zero_gradient = c(3L, 4L), iterations = 40L, evals = 600L, sigdig = 0.9,
         maxeval = 600L)),
    control = model_b("s13", est = "$ESTIMATION METHOD=1 MAXEVAL=600 PRINT=5", cov = NULL)))))

add(case(
  "s14", "infinite_objective_136", "7.4.3",
  "Termination near an infinite objective function (ERROR=136) with a PRED exit message; final pages still printed",
  termination = "terminated (infinite objective, 136)", covariance = "not requested",
  problems = list(prob_c("s14", "terminated near an infinite objective function", list(
    step("focei", c(2.87, 25.3), c(0.142, 0.0581), 0.0412, 1251.776,
         shrink = c(15.8, 33.6), eps_shrink = 10.4, term = "infinite", sigdig = 1.2)),
    control = model_c("s14", cov = NULL)))))

add(case(
  "s15", "boundary_cov_aborted", "7.4.3",
  "Successful minimization with a parameter near its boundary; covariance step aborted (R matrix singular), so no standard errors",
  termination = "successful (near boundary)", covariance = "aborted",
  problems = list(prob_a("s15", "near boundary, covariance step aborted", list(
    step("focei", c(4.52, 30.3, 1.31, 0.618), c(0.0798, 0.0512, 1.04e-05), 0.0279, 1885.071,
         shrink = c(7.66, 20.8, 99.2), eps_shrink = 6.08, term = "boundary", cov = "aborted")),
    cov_requested = TRUE))))

add(case(
  "s16", "s_matrix_singular", "7.5.1",
  "S matrix algorithmically singular (pseudo-inverse used); standard errors printed and a near-zero eigenvalue gives a large condition number",
  termination = "successful", covariance = "S matrix singular",
  problems = list(prob_b("s16", "S matrix singular", list(
    step("foce", c(7.95, 18.8, 2.88, 45.2), c(0.0937, 0.147), c(0.0217, 0.0493), 3149.663,
         shrink = c(4.42, 18.1), eps_shrink = c(6.97, 6.97),
         theta_se = c(0.552, 1.66, 0.395, 6.11), omega_se = c(0.0251, 0.0478),
         sigma_se = c(0.00292, 0.0137),
         eigen = c(2.17e-08, 0.0486, 0.392, 0.811, 1.17, 1.52, 1.86, 2.2), cov = "s_singular")),
    cov_requested = TRUE))))

add(case(
  "s17", "success_with_problems", "7.6.0",
  "'MINIMIZATION SUCCESSFUL / HOWEVER, PROBLEMS OCCURRED' message with a completed covariance step",
  termination = "successful (problems occurred)", covariance = "completed",
  problems = list(prob_c("s17", "successful with problems, NONMEM 7.6", list(
    step("focei", c(3.14, 22.1), c(0.126, 0.0712), 0.0381, 1211.468,
         shrink = c(11.7, 31.2), eps_shrink = 9.33, term = "problems",
         theta_se = c(0.244, 2.03), omega_se = c(0.0361, 0.0277), sigma_se = 0.00589,
         eigen = c(0.253, 0.598, 0.947, 1.35, 1.85), cov = "ok")),
    cov_requested = TRUE))))

add(case(
  "s18", "eigenvalues_not_printed", "7.4.4",
  "Covariance step with 'EIGENVLS. PRINTED: NO' in the problem header: standard errors present, condition number NA without a warning",
  termination = "successful", covariance = "completed (no eigenvalues)",
  problems = list(prob_a("s18", "eigenvalues not printed", list(
    step("focei", c(4.48, 30.9, 1.19, 0.664), c(0.0866, 0.0548, 0.318), 0.0272, 1871.952,
         shrink = c(8.09, 20.7, 38.3), eps_shrink = 6.11,
         theta_se = c(0.329, 2.17, 0.151, 0.133), omega_se = c(0.0225, 0.0194, 0.0991),
         sigma_se = 0.00336, cov = "ok")),
    cov_requested = TRUE, eigen_printed = FALSE,
    control = model_a("s18", "", cov = "$COVARIANCE PRINT=R")))))

add(case(
  "s19", "negative_eigenvalue", "7.5.0",
  "R matrix non-positive-semidefinite but nonsingular: a negative eigenvalue makes the condition number NA with a warning",
  termination = "successful", covariance = "R matrix non-positive-semidefinite",
  expect = list(condn_warning = "negative eigenvalues"),
  problems = list(prob_c("s19", "negative eigenvalue", list(
    step("focei", c(3.21, 21.6), c(0.131, 0.0697), 0.0378, 1209.883,
         shrink = c(13.4, 32.7), eps_shrink = 9.12,
         theta_se = c(0.412, 3.37), omega_se = c(0.0583, 0.0412), sigma_se = 0.00811,
         eigen = c(-3.15e-03, 0.412, 0.958, 1.47, 2.16), cov = "r_npd")),
    cov_requested = TRUE))))

add(case(
  "s20", "zero_eigenvalue", "7.4.3",
  "Singular correlation matrix: an eigenvalue of exactly zero gives an infinite condition number",
  termination = "successful", covariance = "completed (singular)",
  problems = list(prob_c("s20", "zero eigenvalue", list(
    step("focei", c(3.18, 21.9), c(0.129, 0.0721), 0.0383, 1210.257,
         shrink = c(13, 31.9), eps_shrink = 9.2,
         theta_se = c(0.355, 2.88), omega_se = c(0.0497, 0.0366), sigma_se = 0.00744,
         eigen = c(0, 0.447, 0.932, 1.49, 2.13), cov = "ok")),
    cov_requested = TRUE))))

# s21: block OMEGA and SIGMA with fixed parameters in the middle of the
# THETA vector (their standard errors print as "........."), a fixed THETA of
# exactly zero and a fixed OMEGA block.
theta_s21 <- theta_spec(c(5, 40, 0.25, 0.9, 0.75, 0),
                        lower = c(0, 0, 0, 0, -1e6, -1e6),
                        fixed = c(FALSE, FALSE, TRUE, FALSE, TRUE, TRUE))
omega_s21 <- list(blk(c(0.1, 0.01, 0.1)), blk(0.25, fixed = TRUE))
sigma_s21 <- list(blk(c(0.02, 0.001, 0.05)))
add(case(
  "s21", "block_omega_fixed", "7.4.3",
  "OMEGA BLOCK(2) plus a fixed OMEGA, SIGMA BLOCK(2), fixed THETAs (one of them exactly zero) between estimated ones",
  termination = "successful", covariance = "completed",
  problems = list(problem(
    title = title_of("s21", "block OMEGA/SIGMA and fixed parameters"),
    control = c("$INPUT      ID TIME AMT DV MDV EVID WT SEX",
                "$DATA      synthetic_s21.csv IGNORE=@",
                "$SUBROUTINE ADVAN2 TRANS2",
                "$PK",
                "  CL   = THETA(1) * (WT / 70)**THETA(5) * EXP(ETA(1))",
                "  V    = THETA(2) * (1 + THETA(6) * SEX) * EXP(ETA(2))",
                "  ALAG1 = THETA(3)",
                "  KA   = THETA(4) * EXP(ETA(3))",
                "  S2   = V",
                "$ERROR",
                "  IPRED = F",
                "  Y     = IPRED + IPRED * EPS(1) + EPS(2)",
                "$THETA  (0, 5) (0, 40) 0.25 FIX (0, 0.9) 0.75 FIX 0 FIX",
                "$OMEGA  BLOCK(2) 0.1 0.01 0.1",
                "$OMEGA  0.25 FIX",
                "$SIGMA  BLOCK(2) 0.02 0.001 0.05",
                "$ESTIMATION METHOD=1 INTERACTION MAXEVAL=9999 PRINT=5",
                "$COVARIANCE PRINT=E",
                "$TABLE      ID TIME IPRED CWRES NOPRINT ONEHEADER FILE=synthetic_s21.tab"),
    items = c("ID", "TIME", "AMT", "DV", "MDV", "EVID", "WT", "SEX"),
    advan = advan_a, theta = theta_s21, omega = omega_s21, sigma = sigma_s21,
    nobs = 520L, nind = 52L, cov_requested = TRUE,
    steps = list(step(
      "focei", c(5.06, 38.7, 0.25, 0.874, 0.75, 0),
      list(c(0.0937, 0.0412, 0.0718), 0.25), list(c(0.0246, 0.00213, 0.0611)), 2467.319,
      shrink = c(6.87, 14.2, 51.6), eps_shrink = c(5.5, 5.5),
      theta_se = c(0.381, 2.94, NA, 0.0962, NA, NA),
      omega_se = list(c(0.0258, 0.0164, 0.0211), NA),
      sigma_se = list(c(0.00318, 0.00104, 0.0157)),
      eigen = c(0.0717, 0.236, 0.481, 0.726, 0.988, 1.19, 1.43, 1.77, 2.11),
      cov = "ok"))))))

# s22: inter-occasion variability with BLOCK(1) SAME.
omega_s22 <- list(blk(0.1), blk(0.1), blk(0.03), blk(0.03, same = TRUE), blk(0.03, same = TRUE))
add(case(
  "s22", "omega_same_iov", "7.5.1",
  "Inter-occasion variability coded with $OMEGA BLOCK(1) SAME: SAME ETAs repeat the estimate and have no standard error",
  termination = "successful", covariance = "completed",
  problems = list(problem(
    title = title_of("s22", "inter-occasion variability with BLOCK(1) SAME"),
    control = c("$INPUT      ID TIME AMT DV MDV EVID WT OCC",
                "$DATA      synthetic_s22.csv IGNORE=@",
                "$SUBROUTINE ADVAN2 TRANS2",
                "$PK",
                "  IOV  = ETA(3)",
                "  IF (OCC.EQ.2) IOV = ETA(4)",
                "  IF (OCC.EQ.3) IOV = ETA(5)",
                "  CL   = THETA(1) * (WT / 70)**THETA(4) * EXP(ETA(1) + IOV)",
                "  V    = THETA(2) * EXP(ETA(2))",
                "  KA   = THETA(3)",
                "  S2   = V",
                "$ERROR",
                "  IPRED = F",
                "  Y     = IPRED * (1 + EPS(1))",
                "$THETA  (0, 4) (0, 30) (0, 1) 0.75",
                "$OMEGA  0.1 0.1",
                "$OMEGA  BLOCK(1) 0.03",
                "$OMEGA  BLOCK(1) SAME",
                "$OMEGA  BLOCK(1) SAME",
                "$SIGMA  0.03",
                "$ESTIMATION METHOD=1 INTERACTION MAXEVAL=9999 PRINT=5",
                "$COVARIANCE PRINT=E",
                "$TABLE      ID TIME OCC IPRED CWRES NOPRINT ONEHEADER FILE=synthetic_s22.tab"),
    items = c("ID", "TIME", "AMT", "DV", "MDV", "EVID", "WT", "OCC"),
    advan = advan_a, theta = theta_a, omega = omega_s22, sigma = sigma_1,
    nobs = 720L, nind = 40L, cov_requested = TRUE,
    steps = list(step(
      "focei", c(4.35, 31.4, 1.17, 0.69), c(0.0812, 0.0496, 0.0213), 0.0261, 1846.271,
      shrink = c(9.44, 22.1, 41.3, 43, 44.8), eps_shrink = 5.93,
      theta_se = c(0.301, 2.02, 0.139, 0.118), omega_se = c(0.0219, 0.0177, 0.00611),
      sigma_se = 0.00322,
      eigen = c(0.0521, 0.208, 0.433, 0.659, 0.927, 1.22, 1.69, 2.8), cov = "ok"))))))

# s23: 26 THETAs (three wrapped label/value records) and 30 eigenvalues.
k23 <- seq_len(26)
theta_s23 <- signif((k23 %% 5 + 1.37) * 10^((k23 %% 7) - 3) * ifelse(k23 %% 4 == 0, -1, 1), 3)
se_s23 <- signif(abs(theta_s23) * (0.05 + 0.011 * (k23 %% 9)), 3)
ev_s23 <- signif(exp(seq(log(0.0057), log(4.4), length.out = 30)), 3)
add(case(
  "s23", "many_thetas_wrapped", "7.4.4",
  "26 THETAs: label and value records wrap after 12 columns (second record indented one extra blank); 30 eigenvalues on three records",
  termination = "successful", covariance = "completed",
  problems = list(problem(
    title = title_of("s23", "26 THETAs, wrapped records"),
    control = c("$INPUT      ID TIME AMT DV MDV EVID WT AGE SEX CRCL",
                "$DATA      synthetic_s23.csv IGNORE=@",
                "$PRED",
                "  ; 26 fixed-effect parameters of an invented covariate model",
                "  BASE = THETA(1) + THETA(2) * WT + THETA(3) * AGE",
                "  IPRED = BASE * EXP(ETA(1))",
                "  Y     = IPRED + EPS(1)",
                "$THETA  26*0.5",
                "$OMEGA  0.1 0.1 0.3",
                "$SIGMA  0.03",
                "$ESTIMATION METHOD=1 INTERACTION MAXEVAL=9999 PRINT=5",
                "$COVARIANCE PRINT=E"),
    items = c("ID", "TIME", "AMT", "DV", "MDV", "EVID", "WT", "AGE", "SEX", "CRCL"),
    advan = "PRED SUBROUTINE (NO PREDPP)",
    theta = theta_spec(rep(0.5, 26), lower = rep(-1e6, 26)),
    omega = omega_a, sigma = sigma_1, nobs = 900L, nind = 90L, cov_requested = TRUE,
    steps = list(step(
      "focei", theta_s23, c(0.0911, 0.0583, 0.276), 0.0299, 4021.86,
      shrink = c(7.21, 19.8, 35.5), eps_shrink = 4.4,
      theta_se = se_s23, omega_se = c(0.0247, 0.0201, 0.0899), sigma_se = 0.00377,
      eigen = ev_s23, cov = "ok"))))))

# s24: 13 ETAs (labels ET10-ET13, matrix rows wrap past 12 columns, a page
# break inside the matrix, ETASHRINKSD wraps after 10 values).
omega_s24 <- signif(seq(0.0312, 0.411, length.out = 13), 3)
omega_se_s24 <- signif(omega_s24 * 0.27, 3)
shrink_s24 <- signif(seq(4.37, 71.2, length.out = 13), 4)
ev_s24 <- signif(exp(seq(log(0.0133), log(3.87), length.out = 20)), 3)
add(case(
  "s24", "many_etas_wrapped", "7.5.1",
  "13 ETAs: ET10-ET13 labels, matrix rows continuing past 12 columns without '+', a page break inside the OMEGA matrix and ETASHRINKSD wrapped after 10 values",
  termination = "successful", covariance = "completed",
  problems = list(problem(
    title = title_of("s24", "13 ETAs, wrapped matrix and shrinkage records"),
    control = c("$INPUT      ID TIME AMT DV MDV EVID",
                "$DATA      synthetic_s24.csv IGNORE=@",
                "$PRED",
                "  ; 13 random effects on an invented response surface",
                "  IPRED = THETA(1) * EXP(ETA(1)) + THETA(2) * EXP(ETA(2))",
                "  Y     = IPRED * (1 + EPS(1)) + EPS(2)",
                "$THETA  (0, 6) (0, 50) (0, 1) (0, 10) (0, 0.5)",
                "$OMEGA  13*0.1",
                "$SIGMA  0.02 0.04",
                "$ESTIMATION METHOD=1 INTERACTION MAXEVAL=9999 PRINT=5",
                "$COVARIANCE PRINT=E"),
    items = c("ID", "TIME", "AMT", "DV", "MDV", "EVID"),
    advan = "PRED SUBROUTINE (NO PREDPP)",
    theta = theta_spec(c(6, 50, 1, 10, 0.5)),
    omega = diag_blocks(rep(0.1, 13)), sigma = diag_blocks(c(0.02, 0.04)),
    nobs = 1300L, nind = 100L, cov_requested = TRUE, page_break_after = 9L,
    steps = list(step(
      "focei", c(6.21, 47.3, 1.36, 12.8, 0.427), omega_s24, c(0.0187, 0.0362), 5532.418,
      shrink = shrink_s24, eps_shrink = c(3.9, 3.9),
      theta_se = c(0.418, 3.66, 0.157, 1.94, 0.0613), omega_se = omega_se_s24,
      sigma_se = c(0.00243, 0.00811), eigen = ev_s24, cov = "ok"))))))

# s25: 11 EPSILONs (labels EP10, EP11; EPSSHRINKSD wraps).
sigma_s25 <- signif(seq(0.0119, 0.0874, length.out = 11), 3)
add(case(
  "s25", "many_eps_wrapped", "7.4.3",
  "11 EPSILONs: EP10/EP11 labels and wrapped EPSSHRINKSD records next to a short ETASHRINKSD record",
  termination = "successful", covariance = "completed",
  problems = list(problem(
    title = title_of("s25", "11 residual-error variances"),
    control = c("$INPUT      ID TIME AMT DV MDV EVID ASSAY",
                "$DATA      synthetic_s25.csv IGNORE=@",
                "$SUBROUTINE ADVAN1 TRANS2",
                "$PK",
                "  CL = THETA(1) * EXP(ETA(1))",
                "  V  = THETA(2) * EXP(ETA(2))",
                "  S1 = V",
                "$ERROR",
                "  ; one proportional error per invented assay 1-11",
                "  Y = F * (1 + EPS(ASSAY))",
                "$THETA  (0, 3) (0, 18)",
                "$OMEGA  0.1 0.1",
                "$SIGMA  11*0.03",
                "$ESTIMATION METHOD=1 INTERACTION MAXEVAL=9999 PRINT=5",
                "$COVARIANCE PRINT=E"),
    items = c("ID", "TIME", "AMT", "DV", "MDV", "EVID", "ASSAY"),
    advan = advan_c, theta = theta_spec(c(3, 18)),
    omega = omega_c, sigma = diag_blocks(rep(0.03, 11)),
    nobs = 1100L, nind = 50L, cov_requested = TRUE,
    steps = list(step(
      "focei", c(2.94, 17.6), c(0.104, 0.0668), sigma_s25, 6680.127,
      shrink = c(10.3, 26.4), eps_shrink = signif(seq(3.1, 18.6, length.out = 11), 3),
      theta_se = c(0.211, 1.32), omega_se = c(0.0279, 0.0233),
      sigma_se = signif(sigma_s25 * 0.14, 3),
      eigen = signif(exp(seq(log(0.0421), log(3.06), length.out = 15)), 3), cov = "ok"))))))

add(case(
  "s26", "infinite_nan_se", "7.4.3",
  "'+Infinity' in the THETA standard-error record and 'NaN' on an OMEGA standard-error diagonal",
  termination = "successful", covariance = "completed (non-finite SE)",
  problems = list(prob_a("s26", "non-finite standard errors", list(
    step("focei", c(4.71, 29.9, 1.03, 0.733), c(0.0889, 0.0575, 0.299), 0.0285, 1877.338,
         shrink = c(8.88, 21.1, 37.2), eps_shrink = 6.4,
         theta_se = c(0.338, Inf, 0.127, 0.148), omega_se = c(0.0231, NaN, 0.0972),
         sigma_se = 0.00359,
         eigen = c(0.0389, 0.177, 0.412, 0.645, 0.903, 1.25, 1.69, 2.88), cov = "ok")),
    cov_requested = TRUE))))

# s27: extreme magnitudes, a negative THETA, an astronomically large SE, a
# fixed SIGMA and a negative objective function value.
add(case(
  "s27", "extreme_magnitudes", "7.6.0",
  "Very large and very small estimates, a negative THETA, an SE of 2E+73, $SIGMA 1 FIX and a negative OFV",
  termination = "successful", covariance = "completed",
  problems = list(problem(
    title = title_of("s27", "extreme magnitudes and negative OFV"),
    control = c("$INPUT      ID TIME DV MDV LOGC",
                "$DATA      synthetic_s27.csv IGNORE=@",
                "$PRED",
                "  BASE  = THETA(1) * EXP(ETA(1))",
                "  SLOPE = THETA(2) + THETA(3) * LOGC + THETA(5) * TIME",
                "  IPRED = LOG(BASE) + SLOPE * EXP(ETA(2)) + THETA(4) * 0",
                "  Y     = IPRED + EPS(1)",
                "$THETA  (0, 1E5) 5E-7 -0.3 300 0.001",
                "$OMEGA  1 0.000002",
                "$SIGMA  1 FIX",
                "$ESTIMATION METHOD=1 INTERACTION MAXEVAL=9999 PRINT=5",
                "$COVARIANCE PRINT=E"),
    items = c("ID", "TIME", "DV", "MDV", "LOGC"),
    advan = "PRED SUBROUTINE (NO PREDPP)",
    theta = theta_spec(c(1e5, 5e-7, -0.3, 300, 0.001), lower = c(0, -1e6, -1e6, -1e6, -1e6)),
    omega = diag_blocks(c(1, 2e-06)), sigma = list(blk(1, fixed = TRUE)),
    nobs = 1500L, nind = 60L, cov_requested = TRUE,
    steps = list(step(
      "focei", c(1.23e+05, 4.56e-07, -0.25, 331, 7.89e-04), c(1.5, 2.11e-06), 1, -4321.987,
      shrink = c(2.34, 61.8), eps_shrink = 1.75,
      theta_se = c(8410, 9.87e-08, 0.0488, 2e+73, 1.12e-04),
      omega_se = c(0.402, 8.8e-07), sigma_se = NA,
      eigen = c(1.07e-06, 3.38e-03, 0.287, 0.512, 1.13, 1.9, 2.35), cov = "ok"))))))

add(case(
  "s28", "estimation_then_simulation", "7.4.3",
  "Two problems: estimation with covariance step, then a $SIMULATION ONLYSIMULATION problem; results come from problem 1",
  termination = "successful", covariance = "completed",
  problems = list(
    prob_c("s28", "problem 1 of 2, estimation", list(
      step("focei", c(3.02, 23.1), c(0.112, 0.0779), 0.0402, 1218.674,
           shrink = c(12.4, 28.6), eps_shrink = 9.71,
           theta_se = c(0.219, 1.88), omega_se = c(0.0318, 0.0274), sigma_se = 0.00577,
           eigen = c(0.292, 0.587, 0.921, 1.37, 1.83), cov = "ok")),
      cov_requested = TRUE),
    prob_c("s28", "problem 2 of 2, simulation", list(), no = 2L, kind = "simulation",
           control = c("$INPUT      ID TIME AMT DV MDV",
                       "$DATA      synthetic_s28.csv IGNORE=@ REWIND",
                       "$SIMULATION (20261111) ONLYSIMULATION SUBPROBLEMS=100",
                       "$TABLE      ID TIME DV NOPRINT ONEHEADER FILE=synthetic_s28_sim.tab")))))

add(case(
  "s29", "two_estimation_problems", "7.5.1",
  "Two estimation problems (FO with covariance step, then FOCE-I without): results, OFV and NA standard errors come from problem 2",
  termination = "successful", covariance = "problem 1 only",
  problems = list(
    prob_a("s29", "problem 1 of 2, FO with covariance step", list(
      step("fo", c(4.18, 30.1, 0.991, 0.737), c(0.0995, 0.0602, 0.291), 0.0306, 1899.026,
           theta_se = c(0.301, 2.24, 0.122, 0.158), omega_se = c(0.0281, 0.0214, 0.105),
           sigma_se = 0.00409,
           eigen = c(0.0601, 0.219, 0.425, 0.708, 0.944, 1.28, 1.62, 2.73), cov = "ok")),
      cov_requested = TRUE,
      control = model_a("s29", "", est = "$ESTIMATION METHOD=0 MAXEVAL=9999 PRINT=5")),
    prob_c("s29", "problem 2 of 2, FOCE-I", list(
      step("focei", c(3.13, 22.3), c(0.127, 0.0703), 0.0389, 1213.552,
           shrink = c(11.9, 30.8), eps_shrink = 9.41)),
      no = 2L, control = model_c("s29", cov = NULL)))))

add(case(
  "s30", "simulation_only", "7.4.3",
  "$SIMULATION ONLYSIMULATION run: no estimation step, so no OFV (NA without a warning) and no parameter tables",
  termination = "no estimation", covariance = "not requested",
  expect = list(error = "estimation method"),
  problems = list(prob_c("s30", "simulation only", list(), kind = "simulation",
    nmtran = " (WARNING  2) NM-TRAN INFERS THAT THE DATA ARE POPULATION.",
    control = c("$INPUT      ID TIME AMT DV MDV",
                "$DATA      synthetic_s30.csv IGNORE=@",
                "$SUBROUTINE ADVAN1 TRANS2",
                "$PK",
                "  CL = THETA(1) * EXP(ETA(1))",
                "  V  = THETA(2) * EXP(ETA(2))",
                "  S1 = V",
                "$ERROR",
                "  Y = F * (1 + EPS(1))",
                "$THETA  3 25",
                "$OMEGA  0.1 0.1",
                "$SIGMA  0.04",
                "$SIMULATION (20261111) ONLYSIMULATION SUBPROBLEMS=100",
                "$TABLE      ID TIME DV NOPRINT ONEHEADER FILE=synthetic_s30.tab")))))

add(case(
  "s31", "nmtran_error", "",
  "NM-TRAN control-stream error: NONMEM never ran, so no estimation output at all",
  termination = "not run", covariance = "not run",
  expect = list(error = "estimation method"),
  problems = list(prob_c("s31", "control-stream error", list(), kind = "nmtran_error",
    control = c("$INPUT      ID TIME AMT DV MDV",
                "$DATA      synthetic_s31.csv IGNORE=@",
                "$SUBROUTINE ADVAN3 TRANS4",
                "$PK",
                "  CL = THETA(1) * EXP(ETA(1))",
                "  V1 = THETA(2)",
                "  Q  = TVQ",
                "  V2 = THETA(3)",
                "$ERROR",
                "  Y = F * (1 + EPS(1))",
                "$THETA  (0, 3) (0, 25) (0, 50)",
                "$OMEGA  0.1",
                "$SIGMA  0.04",
                "$ESTIMATION METHOD=1 INTERACTION")))))

add(case(
  "s32", "truncated_after_estimation", "7.4.3",
  "Listing truncated during the covariance step (after #TERE): no result pages; OFV recovered from 'OBJECTIVE FUNCTION VALUE WITHOUT CONSTANT'",
  termination = "successful", covariance = "interrupted",
  expect = list(error = "FINAL PARAMETER ESTIMATE section not found", ofv_full = TRUE),
  truncate = cut_after("^ Elapsed estimation  time in seconds:"),
  problems = list(prob_a("s32", "truncated during the covariance step", list(
    step("focei", c(4.39, 31, 1.16, 0.676), c(0.0858, 0.0537, 0.314), 0.0275, 1874.109,
         ofv_tail = 0.000264181937, shrink = c(8.33, 21.6, 38.6), eps_shrink = 6.2,
         theta_se = c(0.315, 2.08, 0.146, 0.124), omega_se = c(0.0217, 0.0189, 0.0961),
         sigma_se = 0.00346, cov = "ok")),
    cov_requested = TRUE))))

add(case(
  "s33", "truncated_mid_results", "7.5.1",
  "Listing cut off inside the final-estimate page (no trailing newline): THETAs parse, OMEGA and SIGMA are missing, OFV from #OBJV",
  termination = "successful", covariance = "interrupted",
  final_newline = FALSE,
  expect = list(etas_error = "Could not parse OMEGA estimates",
                sigmas_error = "Could not parse SIGMA estimates", no_se = TRUE),
  truncate = function(lines) {
    i <- grep("OMEGA - COV MATRIX FOR RANDOM EFFECTS", lines)[1]
    c(lines[seq_len(i - 1L)], " OMEGA - COV MATR")
  },
  problems = list(prob_b("s33", "truncated inside the final-estimate page", list(
    step("foce", c(7.77, 18.9, 2.99, 43.7), c(0.0949, 0.139), c(0.0226, 0.0472), 3146.981,
         shrink = c(4.85, 19.1), eps_shrink = c(7.1, 7.1),
         theta_se = c(0.507, 1.69, 0.41, 5.42), omega_se = c(0.0244, 0.0459),
         sigma_se = c(0.0029, 0.0127),
         eigen = c(0.0992, 0.26, 0.577, 0.871, 1.12, 1.47, 1.71, 1.89), cov = "ok")),
    cov_requested = TRUE))))

add(case(
  "s34", "crlf_line_endings", "7.4.3",
  "Windows (CRLF) line endings; same model and values as s01",
  termination = "successful", covariance = "completed",
  eol = "\r\n",
  problems = list(prob_a("s34", "FOCE-I with Windows line endings", list(
    step("focei", base_a$theta, base_a$omega, base_a$sigma, 1873.406,
         ofv_tail = 0.000137492519, shrink = base_a$shrink, eps_shrink = 6.15,
         theta_se = base_a$theta_se, omega_se = base_a$omega_se,
         sigma_se = base_a$sigma_se, eigen = ev_s01, cov = "ok", cov_pages = TRUE)),
    cov_requested = TRUE))))

add(case(
  "s35", "crashed_workflow_footer", "7.4.4",
  "Run stopped during the search (no #TERM, no result pages); a workflow-tool footer 'OFV = ...' supplies the OFV",
  termination = "stopped during search", covariance = "not reached",
  expect = list(error = "FINAL PARAMETER ESTIMATE section not found", ofv = 2345.678),
  footer = c("OFV = 2345.678", "success = False"),
  truncate = function(lines) {
    i <- grep("^ #TERM:", lines)[1]
    j <- grep("^ #CPUT:", lines)[1]
    c(lines[seq_len(i - 1L)],
      "0PROGRAM TERMINATED BY OBJ",
      " ERROR IN NCONTR WITH INDIVIDUAL      12   ID= 1.20000000000000E+01",
      " NUMERICAL HESSIAN OF OBJ. FUNC. FOR COMPUTING CONDITIONAL ESTIMATE",
      " IS NON POSITIVE DEFINITE",
      " MESSAGE ISSUED FROM ESTIMATION STEP",
      " AT INITIAL OBJ. FUNCTION EVALUATION",
      lines[j:length(lines)])
  },
  problems = list(prob_c("s35", "stopped during the search, workflow footer", list(
    step("focei", c(3.04, 23.3), c(0.119, 0.0751), 0.0397, 1228.03,
         shrink = c(12.5, 29.9), eps_shrink = 9.6)),
    control = model_c("s35", cov = NULL)))))

add(case(
  "s36", "focei_then_imp_eonly", "7.5.1",
  "FOCE-I followed by an IMP evaluation (EONLY=1) with a covariance step: identical estimates, the OFV of the final IMP step",
  termination = "expectation only", covariance = "completed",
  problems = list(prob_b("s36", "FOCE-I followed by IMP EONLY=1", list(
    step("focei", c(7.88, 18.4, 2.97, 45.9), c(0.0952, 0.144), c(0.0221, 0.0488), 3146.225,
         shrink = c(4.66, 18.9), eps_shrink = c(6.9, 6.9), tbln = 1L),
    step("imp_eonly", c(7.88, 18.4, 2.97, 45.9), c(0.0952, 0.144), c(0.0221, 0.0488), 3151.84,
         shrink = c(4.81, 19.3), eps_shrink = c(6.9, 6.9), term = "imp_eonly", tbln = 2L,
         theta_se = c(0.531, 1.71, 0.418, 5.94), omega_se = c(0.0247, 0.0471),
         sigma_se = c(0.00289, 0.0131),
         eigen = c(0.0957, 0.259, 0.574, 0.869, 1.13, 1.47, 1.72, 1.9), cov = "ok")),
    cov_requested = TRUE,
    control = model_b("s36", est = c("$ESTIMATION METHOD=1 INTERACTION MAXEVAL=9999 PRINT=5",
                                     "$ESTIMATION METHOD=IMP INTERACTION EONLY=1 ISAMPLE=300 NITER=5"))))))

# -----------------------------------------------------------------------------
# Expectations (from the values above, never from the parser)
# -----------------------------------------------------------------------------

na_chr <- function(x) if (length(x) == 0 || is.null(x)) "" else x

expectations <- function(cs) {
  est_problems <- Filter(function(p) p$kind == "estimation" && length(p$steps) > 0, cs$problems)
  ex <- cs$expect
  # The final estimation step of the last estimation problem.
  p <- if (length(est_problems)) est_problems[[length(est_problems)]] else NULL
  s <- if (!is.null(p)) p$steps[[length(p$steps)]] else NULL
  m <- if (!is.null(s)) METHODS[[s$method]] else NULL

  status <- function(block) {
    err <- ex[[paste0(block, "_error")]] %||% ex[["error"]]
    if (is.null(err)) "ok" else "error"
  }
  st <- c(thetas = status("thetas"), etas = status("etas"), sigmas = status("sigmas"))
  errs <- vapply(c("thetas", "etas", "sigmas"), function(b) {
    na_chr(ex[[paste0(b, "_error")]] %||% ex[["error"]])
  }, character(1))

  has_se <- !is.null(s$theta_se) && !isTRUE(ex[["no_se"]]) && is.null(ex[["error"]])
  params <- NULL
  if (!is.null(s)) {
    est_omega <- diag(assemble(p$omega, s$omega))
    est_sigma <- diag(assemble(p$sigma, s$sigma))
    se_theta <- se_omega <- se_sigma <- NULL
    if (has_se) {
      se_theta <- ifelse(p$theta$fixed, NA_real_, s$theta_se)
      se_omega <- diag(assemble(p$omega, s$omega_se, fill = NA_real_, se = TRUE))
      se_sigma <- diag(assemble(p$sigma, s$sigma_se, fill = NA_real_, se = TRUE))
    }
    nt <- length(s$theta)
    ne <- length(est_omega)
    ns <- length(est_sigma)
    clean <- function(x, n) if (is.null(x)) rep(NA_real_, n) else ifelse(is.nan(x), NA_real_, x)
    shrink <- if (is.null(s$shrink)) rep(NA_real_, ne) else s$shrink
    rows <- list(
      if (st[["thetas"]] == "ok")
        data.frame(block = "thetas", parameter = sub(" ", "_", th_lab(seq_len(nt))),
                   estimate = s$theta, se = clean(se_theta, nt), shrinkage = NA_real_),
      if (st[["etas"]] == "ok")
        data.frame(block = "etas", parameter = eta_lab(seq_len(ne)),
                   estimate = est_omega, se = clean(se_omega, ne), shrinkage = shrink),
      if (st[["sigmas"]] == "ok")
        data.frame(block = "sigmas", parameter = eps_lab(seq_len(ns)),
                   estimate = est_sigma, se = clean(se_sigma, ns), shrinkage = NA_real_))
    params <- do.call(rbind, Filter(Negate(is.null), rows))
    if (!is.null(params)) params <- cbind(case_id = cs$id, params)
  }

  # Objective function value.
  ofv <- if (!is.null(ex[["ofv"]])) {
    ex[["ofv"]]
  } else if (is.null(s)) {
    NA_real_
  } else if (isTRUE(ex[["ofv_full"]])) {
    as.numeric(sprintf("%.13f", s$ofv + s$ofv_tail))
  } else {
    round(s$ofv, 3)
  }

  # Condition number.
  ev <- if (has_se && p$eigen_printed) s$eigen else NULL
  condn <- if (is.null(ev)) NA_real_ else if (any(ev < 0)) NA_real_ else
    if (any(ev == 0)) Inf else max(ev) / min(ev)

  # summary(): method of the final step (or "unknown"), covariance flag.
  any_method <- any(vapply(cs$problems, function(q) length(q$steps) > 0, TRUE))
  summary_method <- if (!is.null(m) && any_method) m$detected else "unknown"

  manifest <- data.frame(
    case_id = cs$id,
    file = cs$file,
    title = sub("^SYNTHETIC lstparsR test case [^:]+: ", "", cs$problems[[1]]$title),
    nonmem_version = cs$version,
    line_endings = if (cs$eol == "\r\n") "CRLF" else "LF",
    final_method = if (is.null(m)) "" else m$meth,
    termination = cs$termination,
    covariance = cs$covariance,
    exercises = cs$exercises,
    n_theta = if (is.null(s)) NA_integer_ else length(s$theta),
    n_eta = if (is.null(s)) NA_integer_ else nrow(assemble(p$omega, s$omega)),
    n_eps = if (is.null(s)) NA_integer_ else nrow(assemble(p$sigma, s$sigma)),
    thetas = st[["thetas"]], etas = st[["etas"]], sigmas = st[["sigmas"]],
    thetas_error = errs[["thetas"]], etas_error = errs[["etas"]],
    sigmas_error = errs[["sigmas"]],
    ofv = format(ofv, digits = 15),
    ofv_warning = na_chr(ex[["ofv_warning"]]),
    condn = format(condn, digits = 15),
    condn_warning = na_chr(ex[["condn_warning"]]),
    summary_method = summary_method,
    covariance_step = has_se,
    stringsAsFactors = FALSE)
  list(manifest = manifest, params = params)
}

# -----------------------------------------------------------------------------
# Write
# -----------------------------------------------------------------------------

manifest <- list()
params <- list()
for (cs in cases) {
  lines <- render_case(cs)
  stopifnot(all(grepl("^[ -~]*$", lines)))   # printable ASCII only
  text <- paste(lines, collapse = cs$eol)
  if (cs$final_newline) text <- paste0(text, cs$eol)
  con <- file(file.path(out_dir, cs$file), open = "wb")
  writeBin(charToRaw(text), con)
  close(con)
  e <- expectations(cs)
  manifest[[cs$id]] <- e$manifest
  params[[cs$id]] <- e$params
}
manifest <- do.call(rbind, manifest)
manifest$bytes <- file.size(file.path(out_dir, manifest$file))
params <- do.call(rbind, params)

write_csv <- function(x, file) {
  utils::write.csv(x, file.path(out_dir, file), row.names = FALSE, na = "NA")
}
write_csv(manifest, "manifest.csv")
write_csv(params, "expected_parameters.csv")

cat(sprintf("Wrote %d listings (%s bytes) to %s\n", nrow(manifest),
            format(sum(manifest$bytes), big.mark = ","), out_dir))
