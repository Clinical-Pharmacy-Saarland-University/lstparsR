# Regression locks: freeze the parsed output of the synthetic reference
# listings (inst/extdata/lst/, see manifest.csv). Any future change to
# parsing behaviour will fail these snapshots. Values are deparsed, so the
# lock is on the data rather than on print formatting, and the recorded
# snapshots can be reviewed as text.

test_that("parsing the long synthetic reference listing is stable", {
  expect_snapshot_value(fetch_thetas(lst_full_cov), style = "deparse")
  expect_snapshot_value(fetch_etas(lst_full_cov),   style = "deparse")
  expect_snapshot_value(fetch_sigmas(lst_full_cov), style = "deparse")
  expect_snapshot_value(fetch_ofv(lst_full_cov),    style = "deparse")
  expect_snapshot_value(fetch_condn(lst_full_cov),  style = "deparse")
})

test_that("fetch_all output for the long synthetic reference listing is stable", {
  expect_snapshot_value(fetch_all(lst_full_cov), style = "deparse")
})

test_that("THETA parsing of a listing with damaged OMEGA/SIGMA blocks is stable", {
  expect_snapshot_value(fetch_thetas(lst_theta_no_cov), style = "deparse")
})

test_that("THETA parsing without a covariance step is stable", {
  lst <- read_lst_file(synthetic_path("s39_focei_no_cov.lst"))
  expect_snapshot_value(fetch_thetas(lst), style = "deparse")
})
