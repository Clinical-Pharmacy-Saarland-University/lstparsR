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
