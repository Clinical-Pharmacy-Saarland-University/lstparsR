# Changelog

## lstparsR 0.1.0

- Initial CRAN release.
- [`read_lst_file()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/read_lst_file.md):
  reads NONMEM `.lst` files; returns S3 class `"lst"`.
- [`fetch_thetas()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/fetch_thetas.md):
  THETA estimates with SE and RSE.
- [`fetch_etas()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/fetch_etas.md):
  OMEGA diagonal with SE, RSE, and ETA shrinkage.
- [`fetch_sigmas()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/fetch_sigmas.md):
  SIGMA diagonal with SE and RSE.
- [`fetch_ofv()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/fetch_ofv.md):
  objective function value with fallback to workflow footer.
- [`fetch_condn()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/fetch_condn.md):
  condition number from eigenvalues.
- [`fetch_all()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/fetch_all.md):
  convenience wrapper returning all of the above.
- [`run_app()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/run_app.md):
  interactive Shiny application for uploading, viewing, and downloading
  parsed results.
- Supports FOCE-I, FOCE, FO, SAEM, IMP, IMPMAP, and Bayesian estimation
  methods.
- Handles multi-line parameter blocks (\>12 THETAs spanning multiple
  rows).
- Graceful NA returns for all quantities when the covariance step is
  absent.
- Validated against 7,600+ real NONMEM listing files.
