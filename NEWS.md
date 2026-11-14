# lstparsR 1.0.0

- First CRAN submission. The version moves to 1.0.0 to mark a stable
  interface for `read_lst_file()`, the `fetch_*()` parsers and `run_app()`.
- `summary()` on an `"lst"` object now returns a `"summary.lst"` object
  (number of lines, estimation method, covariance step) with its own
  `print()` method, instead of printing with `cat()` and returning the
  input invisibly. Printed at the console, the output is unchanged.
- The Shiny app's ZIP download no longer prints the names of the files it
  adds to the console.
- DESCRIPTION declares `Language: en-US`, and an `inst/WORDLIST` records
  the technical terms used in the documentation.
- A synthetic test corpus replaces the external corpus of study listings,
  which is no longer part of the repository. `inst/extdata/lst/` holds 39
  small, invented listings written by `data-raw/make_synthetic_lst.R`, with a
  manifest and the expected values of every case. The cases cover FO, FOCE,
  FOCE-I, LAPLACE (with the M3 likelihood), ITS, SAEM, IMP (including
  evaluation-only steps), IMPMAP and BAYES; chained estimation steps and
  multiple problems; successful, terminated and evaluation-only runs;
  completed, aborted and singular covariance steps; eigenvalues that are
  not printed, negative or zero; fixed, block and SAME parameters;
  non-finite standard errors; extreme magnitudes; wrapped records; Windows
  line endings; and truncated, damaged or failed runs. The tests compare
  every parser with these known values, and the "Getting Started" vignette
  parses some of the cases.
- Examples, vignettes, README, snapshot tests and the Shiny app test use
  the synthetic listings. The listings from study runs that were bundled in
  `inst/testdata/` and `tests/` have been removed, and the snapshots are
  recorded as readable deparsed values.
- `fetch_thetas()` keeps standard errors aligned with their parameters when a
  field prints `.........` (a fixed THETA) or `+Infinity`. Previously the
  following values moved one column to the left and a padding warning was
  issued. `.........` and `NaN` now give `NA`, `+Infinity` gives `Inf`, in
  every parameter table.
- `fetch_etas()` and `fetch_sigmas()` return all random effects when there
  are ten or more. From the tenth on, NONMEM labels them `ET10`, `EP10` and
  so on, and these rows were dropped. Matrix rows longer than 12 values,
  which continue on a record without `+`, are read in full.
- `fetch_etas()` reads ETA shrinkage records that NONMEM wraps after ten
  values, instead of returning `NA` shrinkage with a warning.
- `fetch_condn()` again returns `NA` without a warning when the covariance
  step ran with `EIGENVLS. PRINTED: NO`. Since 0.1.2 this flag was looked
  for only in the final estimation step, but NONMEM prints it in the problem
  header.
- Method headers for LAPLACE (`LAPLACIAN CONDITIONAL ESTIMATION`, with or
  without interaction), ITS (`ITERATIVE TWO STAGE`) and BAYES as NONMEM prints
  it (`MCMC BAYESIAN ANALYSIS`) are recognized.

# lstparsR 0.1.2

- Preserve scientific exponents and missing matrix diagonals, and read printed
  ETA shrinkage with or without an equals sign.
- Select a consistent final estimation step across parameter and scalar results.
- Handle truncated objective output, grouped eigenvalues and singular matrices.
- Preserve duplicate uploads, expose incomplete results, and improve table layout
  and download isolation.
- Clarify supported output layouts and first-submission metadata.

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

* Initial development release.
* `read_lst_file()`: reads NONMEM `.lst` files; returns S3 class `"lst"`.
* `fetch_thetas()`: THETA estimates with SE and RSE.
* `fetch_etas()`: OMEGA diagonal with SE, RSE, and ETA shrinkage.
* `fetch_sigmas()`: SIGMA diagonal with SE and RSE.
* `fetch_ofv()`: objective function value with fallback to workflow footer.
* `fetch_condn()`: condition number from eigenvalues.
* `fetch_all()`: convenience wrapper returning all of the above.
* `run_app()`: interactive Shiny application for uploading, viewing, and
  downloading parsed results.
* Recognizes FOCE-I, FOCE, FO, SAEM, IMP, IMPMAP, and Bayesian method headers.
* Handles multi-line parameter blocks (>12 THETAs spanning multiple rows).
* Missing optional covariance quantities are returned as NA.
* Exercised against more than 7,600 listing files, predominantly FOCE-I.
