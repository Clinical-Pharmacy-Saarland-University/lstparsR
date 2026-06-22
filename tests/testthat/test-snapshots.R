# Regression locks: freeze the parsed output of the real reference
# fixtures. Any future change to parsing behaviour will fail these
# snapshots, which is exactly the "functionality stays the same"
# guarantee baked permanently into the suite. Values are serialized so
# the lock is on the data, not on print formatting.

test_that("parsing the full covariance reference plate is stable", {
  expect_snapshot_value(fetch_thetas(lst_full_cov), style = "serialize")
  expect_snapshot_value(fetch_etas(lst_full_cov),   style = "serialize")
  expect_snapshot_value(fetch_sigmas(lst_full_cov), style = "serialize")
  expect_snapshot_value(fetch_ofv(lst_full_cov),    style = "serialize")
  expect_snapshot_value(fetch_condn(lst_full_cov),  style = "serialize")
})

test_that("fetch_all output for the reference plate is stable", {
  expect_snapshot_value(fetch_all(lst_full_cov), style = "serialize")
})

test_that("THETA parsing without a covariance step is stable", {
  expect_snapshot_value(fetch_thetas(lst_theta_no_cov), style = "serialize")
})
