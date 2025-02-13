test_that("Read Thetas work", {
  file <- read_lst_file("full_cov.lst")
  result <- fetch_thetas(file)

  expect_equal(nrow(result), 12)
  expect_equal(ncol(result), 3)
  expect_equal(result[1, 1], "TH_1")
  expect_equal(result[1, 2], 3.41E1)
  expect_equal(result[1, 3], 9.882698e+00)
})

test_that("Read Thetas work with no covar", {
  file <- read_lst_file("theta_no_se.lst")
  result <- fetch_thetas(file)

  expect_equal(nrow(result), 12)
  expect_equal(ncol(result), 3)
  expect_equal(result[1, 1], "TH_1")
  expect_equal(result[1, 2], 3.41E1)
  expect_equal(result[1, 3], NA_real_)
})

test_that("Read Etas work", {
  file <- read_lst_file("full_cov.lst")
  result <- fetch_etas(file)

  expect_equal(nrow(result), 7)
  expect_equal(ncol(result), 4)
  expect_equal(result[1, 1], "ETA1")
  expect_equal(result[1, 2], 0.2)
  expect_equal(result[1, 3], 1.945E1)
  expect_equal(result[1, 4], 5.0757)
})
