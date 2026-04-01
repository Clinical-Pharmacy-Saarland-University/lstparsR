test_that("fetch_thetas returns tibble with correct columns", {
  result <- fetch_thetas(lst_full_cov)
  expect_s3_class(result, "data.frame")
  expect_named(result, c("parameter", "estimate", "se", "rse"))
})

test_that("fetch_thetas estimates are numeric", {
  result <- fetch_thetas(lst_full_cov)
  expect_type(result$estimate, "double")
  expect_false(any(is.na(result$estimate)))
})

test_that("fetch_thetas SE and RSE are non-NA for full_cov", {
  result <- fetch_thetas(lst_full_cov)
  expect_true(any(!is.na(result$se)))
})

test_that("fetch_thetas works for theta_no_cov fixture", {
  result <- fetch_thetas(lst_theta_no_cov)
  expect_s3_class(result, "data.frame")
  expect_gt(nrow(result), 0)
})

test_that("fetch_thetas digits argument rounds RSE", {
  result <- fetch_thetas(lst_full_cov, digits = 1)
  non_na <- result$rse[!is.na(result$rse)]
  if (length(non_na) > 0) {
    expect_equal(non_na, round(non_na, 1))
  }
})

test_that("fetch_thetas errors on non-lst input", {
  expect_error(fetch_thetas("a string"))
  expect_error(fetch_thetas(42))
  expect_error(fetch_thetas(list()))
})

test_that("fetch_thetas errors on no_cov (no final param section)", {
  expect_error(fetch_thetas(lst_no_cov))
})
