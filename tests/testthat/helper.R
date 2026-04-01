# Shared fixtures for all tests
lst_full_cov <- read_lst_file(
  system.file("testdata", "full_cov.lst", package = "lstparseR")
)
lst_no_cov <- read_lst_file(
  system.file("testdata", "no_cov.lst", package = "lstparseR")
)
lst_theta_no_cov <- read_lst_file(
  system.file("testdata", "theta_no_cov.lst", package = "lstparseR")
)
