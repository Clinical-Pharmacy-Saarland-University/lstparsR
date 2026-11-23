test_that("fetch_etas returns tibble with correct columns", {
  result <- fetch_etas(lst_full_cov)
  expect_named(result, c("parameter", "estimate", "se", "rse", "shrinkage"))
})

test_that("fetch_etas shrinkage length matches ETA count", {
  result <- fetch_etas(lst_full_cov)
  expect_equal(length(result$shrinkage), nrow(result))
})

test_that("fetch_etas errors on no_cov (no final param section)", {
  expect_error(fetch_etas(lst_no_cov))
})

test_that("fetch_etas errors on non-lst", {
  expect_error(fetch_etas(data.frame()))
})

test_that("fetch_etas rounds rse and shrinkage with digits arguments", {
  res <- fetch_etas(lst_full_cov, digits = 1, shk_digits = 0)
  rse <- res$rse[!is.na(res$rse)]
  shk <- res$shrinkage[!is.na(res$shrinkage)]
  if (length(rse) > 0) expect_equal(rse, round(rse, 1))
  if (length(shk) > 0) expect_equal(shk, round(shk, 0))
})

test_that("fetch_etas errors when the final parameter page is absent", {
  lst <- lstparsR:::.lst_new(c(paste(" ", FOCEI), rep(" filler", 8)))
  expect_error(fetch_etas(lst), "FINAL PARAMETER ESTIMATE section not found")
})

test_that("fetch_etas errors when the OMEGA block cannot be parsed", {
  lst <- lstparsR:::.lst_new(
    make_section_page(FOCEI, "FINAL PARAMETER ESTIMATE", " no omega block")
  )
  expect_error(fetch_etas(lst), "Could not parse OMEGA")
})

test_that("fetch_etas warns and sets SE to NA on a row-count mismatch", {
  est <- make_section_page(FOCEI, "FINAL PARAMETER ESTIMATE",
                           omega_body(c("2.00E-01", "2.55E-01")))
  se  <- make_section_page(FOCEI, "STANDARD ERROR OF ESTIMATE",
                           omega_body(c("1.00E-02")))
  lst <- lstparsR:::.lst_new(c(est, se))
  expect_warning(res <- fetch_etas(lst), "OMEGA SE row count")
  expect_true(all(is.na(res$se)))
})

test_that("fetch_etas warns and NA-fills when shrinkage count mismatches ETAs", {
  est <- make_section_page(FOCEI, "FINAL PARAMETER ESTIMATE",
                           omega_body(c("2.00E-01", "2.55E-01")))
  lst <- lstparsR:::.lst_new(c(
    est, " ETASHRINKSD(%) =  1.0E+00  2.0E+00  3.0E+00"
  ))
  w <- expect_warning(res <- fetch_etas(lst), "^ETASHRINKSD has")
  expect_null(conditionCall(w))
  expect_true(all(is.na(res$shrinkage)))
})

test_that("fetch_etas attaches shrinkage when the count matches", {
  est <- make_section_page(FOCEI, "FINAL PARAMETER ESTIMATE",
                           omega_body(c("2.00E-01", "2.55E-01")))
  lst <- lstparsR:::.lst_new(c(est, " ETASHRINKSD(%) =  5.0E+00  1.6E+00"))
  res <- fetch_etas(lst)
  expect_equal(res$shrinkage, c(5.0, 1.6))
})

test_that("fetch_etas keeps shrinkage aligned when one value prints as NaN", {
  lines <- unclass(read_lst_file(synthetic_path("s01_focei_cov_success.lst")))
  i <- grep("^\\s*ETASHRINKSD", lines)
  expect_length(i, 1L)
  ref <- fetch_etas(lstparsR:::.lst_new(lines))$shrinkage
  lines[i] <- sub("[0-9.]+E[+-][0-9]+", "NaN", lines[i])
  # Previously: "ETASHRINKSD has 2 values but 3 ETAs" and NA for every ETA
  expect_no_warning(res <- fetch_etas(lstparsR:::.lst_new(lines)))
  expect_equal(res$shrinkage, c(NA, ref[-1]))
})

# OMEGA block as NONMEM prints it for many ETAs: ET10 labels from the tenth
# on, rows wrapped after 12 values onto records without "+".
wrapped_omega_body <- function(diag) {
  n   <- length(diag)
  lab <- ifelse(seq_len(n) < 10, paste0("ETA", seq_len(n)), paste0("ET", seq_len(n)))
  out <- c(" OMEGA - COV MATRIX FOR RANDOM EFFECTS - ETAS  ********", "", "",
           paste0("        ", paste(sprintf("%-10s", lab[seq_len(min(n, 12))]), collapse = "")),
           " ")
  for (i in seq_len(n)) {
    row    <- c(rep("0.00E+00", i - 1), diag[i])
    chunks <- split(row, ceiling(seq_along(row) / 12))
    recs   <- vapply(chunks, function(x) paste(sprintf("%10s", x), collapse = ""), "")
    recs   <- paste0(c("+       ", rep("         ", length(recs) - 1)), recs)
    out    <- c(out, paste0(" ", lab[i]), recs, " ")
  }
  out
}

test_that("large OMEGA blocks are read in full and SIGMA is found after them", {
  n    <- 70L
  diag <- sprintf("%.2E", seq_len(n) / 100)
  body <- c(theta_vector_body(c("TH 1", "TH 2"), c("1.00E+00", "2.00E+00")), "",
            wrapped_omega_body(diag), "", sigma_body(c("4.00E-02", "9.00E-02")))
  expect_gt(length(wrapped_omega_body(diag)), 300L)
  lst <- lstparsR:::.lst_new(make_section_page(FOCEI, "FINAL PARAMETER ESTIMATE", body))

  # Previously the scan stopped 300 lines after the subheader and returned
  # fewer ETAs without a warning; SIGMA more than 200 lines after the page
  # header gave "Could not parse SIGMA estimates."
  etas <- fetch_etas(lst)
  expect_equal(nrow(etas), n)
  expect_equal(etas$parameter[c(1, 9, 10, n)], c("ETA1", "ETA9", "ET10", "ET70"))
  expect_equal(etas$estimate, seq_len(n) / 100)
  expect_equal(fetch_sigmas(lst)$estimate, c(0.04, 0.09))
  expect_equal(fetch_thetas(lst)$estimate, c(1, 2))
})
