test_that("read_lst_file returns lst object", {
  expect_s3_class(lst_full_cov, "lst")
  expect_type(lst_full_cov, "character")
  expect_gt(length(lst_full_cov), 100)
})

test_that("read_lst_file errors on missing file", {
  expect_error(read_lst_file("does_not_exist.lst"))
})

test_that("read_lst_file errors on wrong extension", {
  f <- withr::local_tempfile(fileext = ".txt")
  writeLines("hello", f)
  expect_error(read_lst_file(f))
})

test_that("print.lst produces output", {
  expect_output(print(lst_full_cov), "lst")
})

test_that("summary.lst returns a summary that prints", {
  s <- summary(lst_full_cov)
  expect_s3_class(s, "summary.lst")
  expect_equal(s$lines, length(lst_full_cov))
  expect_type(s$covariance_step, "logical")
  expect_output(print(s), "Estimation method")
  expect_invisible(print(s))
})

test_that(".lst_new rejects non-character input", {
  expect_error(lstparsR:::.lst_new(1:5))
})

test_that("read_lst_file wraps a readLines failure with a clear message", {
  f <- withr::local_tempfile(fileext = ".lst")
  writeLines("dummy", f)
  testthat::local_mocked_bindings(
    readLines = function(...) stop("disk on fire"), .package = "base"
  )
  expect_error(read_lst_file(f), "Failed to read file")
})

test_that("summary.lst falls back to 'unknown' method and print returns invisibly", {
  lst <- lstparsR:::.lst_new(c("no recognisable estimation method here"))
  expect_equal(summary(lst)$method, "unknown")
  expect_output(print(summary(lst)), "unknown")
  expect_invisible(print(lstparsR:::.lst_new("x")))
})
