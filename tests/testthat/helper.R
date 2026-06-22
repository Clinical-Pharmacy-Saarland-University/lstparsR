# Shared fixtures for all tests
lst_full_cov <- read_lst_file(
  system.file("testdata", "full_cov.lst", package = "lstparsR")
)
lst_no_cov <- read_lst_file(
  system.file("testdata", "no_cov.lst", package = "lstparsR")
)
lst_theta_no_cov <- read_lst_file(
  system.file("testdata", "theta_no_cov.lst", package = "lstparsR")
)

# ------------------------------------------------------------------
# Synthetic-page builders
#
# Construct minimal NONMEM-style section pages that satisfy the
# internal locator/parser contract, so that error and mismatch
# branches can be triggered deterministically without shipping a
# bespoke fixture file for every edge case.
# ------------------------------------------------------------------

FOCEI <- "FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION"

# A page header recognised by .find_section_page():
#   line 1   : "1"
#   line 2   : >= 80 asterisks
#   line 4   : estimation method
#   line 5   : section title
make_section_page <- function(method, section, body = character(0)) {
  stars <- strrep("*", 100)
  c(
    "1",
    stars,
    paste0(" ****", strrep(" ", 20), "****"),
    paste0(" ****   ", method, "   ****"),
    paste0(" ****   ", section, "   ****"),
    paste0(" ****", strrep(" ", 20), "****"),
    stars,
    "",
    "",
    body
  )
}

# THETA vector block. `ids` and `values` are character vectors of
# equal length (values in scientific notation, e.g. "3.41E+01").
theta_vector_body <- function(ids, values) {
  pad      <- function(x) paste(sprintf("%-10s", x), collapse = "")
  c(
    " THETA - VECTOR OF FIXED EFFECTS PARAMETERS   *********",
    "", "",
    paste0("        ", pad(ids)),
    "", " ",
    paste0("        ", pad(values))
  )
}

# OMEGA (ETA) or SIGMA (EPS) lower-triangular matrix block.
# `diag` is a character vector of diagonal values; `prefix` is
# "ETA" or "EPS"; `subheader` is the matching section subheader.
matrix_body <- function(diag, prefix, subheader) {
  n      <- length(diag)
  header <- paste0("        ",
                   paste(sprintf("%-10s", paste0(prefix, seq_len(n))),
                         collapse = ""))
  out <- c(subheader, "", "", header, " ")
  for (i in seq_len(n)) {
    row <- c(rep("0.00E+00", i - 1), diag[i])
    out <- c(out, paste0(" ", prefix, i),
             paste0("+        ", paste(row, collapse = "  ")), " ")
  }
  out
}

omega_body <- function(diag) {
  matrix_body(diag, "ETA", " OMEGA - COV MATRIX FOR RANDOM EFFECTS - ETAS  ********")
}

sigma_body <- function(diag) {
  matrix_body(diag, "EPS", " SIGMA - COV MATRIX FOR RANDOM EFFECTS - EPSILONS  ****")
}
