# lstparseR 0.1.0

* Initial CRAN release.
* `read_lst_file()`: reads NONMEM `.lst` files; returns S3 class `"lst"`.
* `fetch_thetas()`: THETA estimates with SE and RSE.
* `fetch_etas()`: OMEGA diagonal with SE, RSE, and ETA shrinkage.
* `fetch_sigmas()`: SIGMA diagonal with SE and RSE.
* `fetch_ofv()`: objective function value with fallback to workflow footer.
* `fetch_condn()`: condition number from eigenvalues.
* `fetch_all()`: convenience wrapper returning all of the above.
* `run_app()`: interactive Shiny application for uploading, viewing, and
  downloading parsed results.
* Supports FOCE-I, FOCE, FO, SAEM, IMP, IMPMAP, and Bayesian estimation methods.
* Handles multi-line parameter blocks (>12 THETAs spanning multiple rows).
* Graceful NA returns for all quantities when the covariance step is absent.
* Validated against 7,600+ real NONMEM listing files.
