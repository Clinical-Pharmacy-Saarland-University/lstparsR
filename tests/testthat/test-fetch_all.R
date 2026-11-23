test_that("fetch_all returns named list", {
  result <- fetch_all(lst_full_cov)
  expect_type(result, "list")
  expect_named(result, c("thetas", "etas", "sigmas", "ofv", "condn"))
})

test_that("fetch_all thetas, etas, sigmas are tibbles for full_cov", {
  result <- fetch_all(lst_full_cov)
  expect_s3_class(result$thetas, "data.frame")
  expect_s3_class(result$etas,   "data.frame")
  expect_s3_class(result$sigmas, "data.frame")
})

test_that("fetch_all condn is NA for no_cov", {
  # no_cov has no covariance step, so individual fetchers may fail
  # but fetch_all should not error
  result <- suppressWarnings(fetch_all(lst_no_cov))
  expect_true(is.na(result$condn))
})

test_that("fetch_all errors on non-lst input", {
  expect_error(fetch_all("not a lst"))
})

test_that("fetch_all reports an invalid rounding argument per element", {
  # Documented contract: a warning and NULL for the affected element only
  # (the message names the parser's own argument, `digits`)
  expect_warning(res <- fetch_all(lst_full_cov, cn_digits = "a"),
                 "fetch_all: Assertion on 'digits' failed")
  expect_null(res$condn)
  expect_s3_class(res$etas, "tbl_df")
  expect_equal(res$ofv, fetch_ofv(lst_full_cov))
})
