test_that("fetch_sigmas returns tibble with correct columns", {
  result <- fetch_sigmas(lst_full_cov)
  expect_named(result, c("parameter", "estimate", "se", "rse"))
})

test_that("fetch_sigmas estimates are positive (diagonal variances)", {
  result <- fetch_sigmas(lst_full_cov)
  valid  <- result$estimate[!is.na(result$estimate)]
  expect_true(all(valid > 0))
})

test_that("fetch_sigmas errors on no_cov (no final param section)", {
  expect_error(fetch_sigmas(lst_no_cov))
})

test_that("fetch_sigmas rounds rse with the digits argument", {
  est <- make_section_page(FOCEI, "FINAL PARAMETER ESTIMATE",
                           sigma_body(c("7.69E-02", "1.23E-01")))
  se  <- make_section_page(FOCEI, "STANDARD ERROR OF ESTIMATE",
                           sigma_body(c("1.00E-02", "2.00E-02")))
  lst <- lstparsR:::.lst_new(c(est, se))
  res <- fetch_sigmas(lst, digits = 1)
  rse <- res$rse[!is.na(res$rse)]
  expect_true(length(rse) > 0)
  expect_equal(rse, round(rse, 1))
})

test_that("fetch_sigmas errors when the final parameter page is absent", {
  lst <- lstparsR:::.lst_new(c(paste(" ", FOCEI), rep(" filler", 8)))
  expect_error(fetch_sigmas(lst), "FINAL PARAMETER ESTIMATE section not found")
})

test_that("fetch_sigmas errors when the SIGMA block cannot be parsed", {
  lst <- lstparsR:::.lst_new(
    make_section_page(FOCEI, "FINAL PARAMETER ESTIMATE", " no sigma block")
  )
  expect_error(fetch_sigmas(lst), "Could not parse SIGMA")
})

test_that("fetch_sigmas warns and sets SE to NA on a row-count mismatch", {
  est <- make_section_page(FOCEI, "FINAL PARAMETER ESTIMATE",
                           sigma_body(c("7.69E-02", "1.23E-01")))
  se  <- make_section_page(FOCEI, "STANDARD ERROR OF ESTIMATE",
                           sigma_body(c("1.00E-02")))
  lst <- lstparsR:::.lst_new(c(est, se))
  expect_warning(res <- fetch_sigmas(lst), "SIGMA SE row count")
  expect_true(all(is.na(res$se)))
})
