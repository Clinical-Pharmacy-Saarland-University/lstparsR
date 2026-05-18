# lstparsR 0.1.1

## Bug fixes

* `fetch_ofv()`: No longer warns "OFV not found" for `$SIMULATION`-only runs
  (e.g. VPC simulation outputs). Such runs legitimately produce no objective
  function value; the function now returns `NA_real_` silently in that case.
  The warning is still emitted when an estimation step ran but its OFV cannot
  be parsed.
* `fetch_condn()`: No longer warns "Eigenvalue section not found" when the user
  set `EIGENVLS. PRINTED: NO` in `$COV`. In that case the covariance step ran
  but the eigenvalue block is intentionally absent; the function now returns
  `NA_real_` silently. The warning is still emitted when eigenvalues are
  expected but cannot be located.
* Reported by Christiane on multiple unrelated projects.

## Internal

* New internal helpers `.has_estimation_step()` and `.eigenvalues_suppressed()`
  in `R/utils-internal.R`.

# lstparsR 0.1.0

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
