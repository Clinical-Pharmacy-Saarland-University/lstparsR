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
  expect_warning(res <- fetch_etas(lst), "ETASHRINKSD")
  expect_true(all(is.na(res$shrinkage)))
})

test_that("fetch_etas attaches shrinkage when the count matches", {
  est <- make_section_page(FOCEI, "FINAL PARAMETER ESTIMATE",
                           omega_body(c("2.00E-01", "2.55E-01")))
  lst <- lstparsR:::.lst_new(c(est, " ETASHRINKSD(%) =  5.0E+00  1.6E+00"))
  res <- fetch_etas(lst)
  expect_equal(res$shrinkage, c(5.0, 1.6))
})
