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
