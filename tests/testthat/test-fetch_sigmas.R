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
