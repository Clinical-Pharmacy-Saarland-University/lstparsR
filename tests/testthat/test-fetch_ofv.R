test_that("fetch_ofv returns single numeric for full_cov", {
  result <- fetch_ofv(lst_full_cov)
  expect_type(result, "double")
  expect_length(result, 1)
  expect_false(is.na(result))
})

test_that("fetch_ofv digits rounds correctly", {
  result <- fetch_ofv(lst_full_cov, digits = 2)
  expect_equal(result, round(result, 2))
})

test_that("fetch_ofv returns numeric for no_cov (footer fallback)", {
  result <- fetch_ofv(lst_no_cov)
  expect_true(is.numeric(result))
  expect_length(result, 1)
})

test_that("fetch_ofv warns and returns NA for empty lst", {
  fake <- lstparseR:::.lst_new(c("line1", "line2", "no objv here"))
  expect_warning(result <- fetch_ofv(fake))
  expect_true(is.na(result))
})
