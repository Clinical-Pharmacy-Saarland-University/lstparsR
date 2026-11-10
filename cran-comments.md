## Submission

This is a new submission: lstparsR 1.0.0.

The package extracts parameter estimates and diagnostics from existing
'NONMEM' listing files. A 'NONMEM' installation is not required. The optional
'shiny' application is launched only on request; examples and tests run without
interactive input and without network access.

## Test environments

- Local: macOS 27 on Apple silicon, R 4.6.1 (aarch64-apple-darwin),
  `R CMD check --as-cran --no-manual` on the built tarball with `NOT_CRAN`
  unset. The PDF manual was built locally with TinyTeX (TeX Live 2026) via
  `R CMD Rd2pdf` without errors; the check run itself used `--no-manual`.
- GitHub Actions (r-lib/actions v2, `--as-cran`): macOS-latest (R release),
  windows-latest (R release), ubuntu-latest (R devel, R release,
  R oldrel-1).
- An earlier version (0.1.2) of the package passed win-builder (R-devel,
  Windows) including the PDF manual, with only the new-submission NOTE.

## R CMD check results

0 errors | 0 warnings | 1 note

- New submission.

The incoming feasibility check may flag "pharmacokinetic" and
"pharmacodynamic" in DESCRIPTION as possibly misspelled words. Both are
correctly spelled scientific terms.

## Scope

The package reads fixed-format result sections illustrated by the bundled
examples. Method-header recognition is documented separately from numerical
output-layout validation. Missing optional quantities return NA; unavailable
required sections produce errors that fetch_all() contains with warnings and
NULL elements.

## Downstream dependencies

This is a new CRAN package.
