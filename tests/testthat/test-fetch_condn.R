test_that("fetch_condn returns numeric >= 1 for full_cov", {
  result <- fetch_condn(lst_full_cov)
  expect_type(result, "double")
  expect_length(result, 1)
  expect_gte(result, 1)
})

test_that("fetch_condn returns NA for no_cov (no covariance step)", {
  result <- fetch_condn(lst_no_cov)
  expect_true(is.na(result))
})

test_that("fetch_condn digits rounds result", {
  result <- fetch_condn(lst_full_cov, digits = 0)
  if (!is.na(result)) {
    expect_equal(result, round(result, 0))
  }
})

# --- Inline inline: standard single-line eigenvalues ---
test_that("fetch_condn extracts condition number from single-line eigenvalues", {
  lst <- lstparsR:::.lst_new(c(
    " STANDARD ERROR OF ESTIMATE",
    " EIGENVALUES OF COR MATRIX OF ESTIMATE",
    "  1.00E-02  1.00E+02"
  ))
  result <- fetch_condn(lst)
  expect_equal(result, 1e4)
})

# --- Inline: eigenvalues on separate lines ---
test_that("fetch_condn handles eigenvalues on separate lines", {
  lst <- lstparsR:::.lst_new(c(
    " STANDARD ERROR OF ESTIMATE",
    " EIGENVALUES OF COR MATRIX OF ESTIMATE",
    "  1.00E-02",
    "  5.00E+00",
    "  1.00E+02"
  ))
  result <- fetch_condn(lst)
  expect_equal(result, 1e4)
})

# --- Inline: Fortran CC prefix (leading 0) on header ---
test_that("fetch_condn handles Fortran carriage control prefix on header", {
  lst <- lstparsR:::.lst_new(c(
    " STANDARD ERROR OF ESTIMATE",
    "0EIGENVALUES OF COR MATRIX OF ESTIMATE",
    "  1.00E-02  1.00E+02"
  ))
  result <- fetch_condn(lst)
  expect_equal(result, 1e4)
})

# --- Inline: blank line between header and values ---
test_that("fetch_condn handles blank line between header and values", {
  lst <- lstparsR:::.lst_new(c(
    " STANDARD ERROR OF ESTIMATE",
    " EIGENVALUES OF COR MATRIX OF ESTIMATE",
    "",
    "  1.00E-02  1.00E+02"
  ))
  result <- fetch_condn(lst)
  expect_equal(result, 1e4)
})

# --- Inline: header within asterisk box (realistic NONMEM format) ---
test_that("fetch_condn skips asterisk box lines around the header", {
  lst <- lstparsR:::.lst_new(c(
    " STANDARD ERROR OF ESTIMATE",
    " ************************************************************************************************************************",
    " ********************               FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION              ********************",
    " ********************                      EIGENVALUES OF COR MATRIX OF ESTIMATE                     ********************",
    " ********************                                                                                ********************",
    " ************************************************************************************************************************",
    " ",
    "",
    "             1         2",
    "  1.00E-02  1.00E+02"
  ))
  result <- fetch_condn(lst)
  expect_equal(result, 1e4)
})

# --- No covariance step ---
test_that("fetch_condn returns NA without warning when no covariance step", {
  lst <- lstparsR:::.lst_new(c(
    " ESTIMATION STEP OMITTED",
    " FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION"
  ))
  expect_silent(result <- fetch_condn(lst))
  expect_true(is.na(result))
})

# --- Warning when eigenvalue section absent despite covariance step ---
test_that("fetch_condn warns when no eigenvalue section found", {
  lst <- lstparsR:::.lst_new(c(
    " STANDARD ERROR OF ESTIMATE",
    " SOME OTHER CONTENT",
    " NO EIGENVALUE SECTION HERE"
  ))
  expect_warning(result <- fetch_condn(lst), "Eigenvalue section not found")
  expect_true(is.na(result))
})

# --- EIGENVLS. PRINTED: NO  (legitimate-NA, no warning) ---
test_that("fetch_condn returns NA silently when EIGENVLS. PRINTED: NO", {
  path <- system.file("testdata", "eigen_printed_no.lst", package = "lstparsR")
  lst  <- read_lst_file(path)
  expect_no_warning(result <- fetch_condn(lst))
  expect_true(is.na(result))
})

# --- Fixture file: multiline eigenvalues ---
test_that("fetch_condn correctly parses eigen_multiline.lst fixture", {
  path <- system.file("testdata", "eigen_multiline.lst", package = "lstparsR")
  lst  <- read_lst_file(path)
  result <- fetch_condn(lst)
  # eigenvalues: 1e-2, 5e-1, 1e+2 => max/min = 1e2/1e-2 = 1e4
  expect_equal(result, 1e4)
})

# --- Stop at trailing non-numeric text after the eigenvalue block ---
test_that("fetch_condn stops collecting at trailing text after values", {
  lst <- lstparsR:::.lst_new(c(
    " STANDARD ERROR OF ESTIMATE",
    " EIGENVALUES OF COR MATRIX OF ESTIMATE",
    "  1.00E-02  1.00E+02",
    "  SOME TRAILING TEXT"
  ))
  expect_equal(fetch_condn(lst), 1e4)
})

# --- Header present but no numeric eigenvalues follow ---
test_that("fetch_condn warns when the eigenvalue block has no numbers", {
  lst <- lstparsR:::.lst_new(c(
    " STANDARD ERROR OF ESTIMATE",
    " EIGENVALUES OF COR MATRIX OF ESTIMATE",
    " NO NUMBERS HERE"
  ))
  expect_warning(res <- fetch_condn(lst), "Could not extract eigenvalues")
  expect_true(is.na(res))
})

# --- Fewer than two positive eigenvalues ---
test_that("fetch_condn warns when fewer than two eigenvalues are found", {
  lst <- lstparsR:::.lst_new(c(
    " STANDARD ERROR OF ESTIMATE",
    " EIGENVALUES OF COR MATRIX OF ESTIMATE",
    "  1.00E+02"
  ))
  expect_warning(res <- fetch_condn(lst), "Fewer than 2")
  expect_true(is.na(res))
})
