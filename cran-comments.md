## Submission

This is the first CRAN submission of lstparsR (version 0.1.2).

The package extracts parameter estimates and diagnostics from existing
'NONMEM' listing files. A 'NONMEM' installation is not required. The optional
'shiny' application is launched only on request; examples and tests run without
interactive input.

## Test environments

The same source archive was checked with R CMD check --as-cran on:

- Linux, R 4.6.1, including the PDF manual and vignette rebuilding.
- Linux, R-devel (2026-10-05 r90641), without the PDF manual.
- Windows, R-devel (2026-10-06 r90643 ucrt), without the PDF manual.

Each check completed with 0 errors, 0 warnings, and 1 NOTE:

    New submission

The same archive also passed on Linux with R 4.1.0 and compatible dependency
versions (without the PDF manual; the legacy network clock check disabled).
It reported 0 errors, 0 warnings, and the same new-submission NOTE.

Additional source checks passed on Windows and macOS with R 4.6.1, and on
Linux with R 4.6.1, R 4.5.3, and R-devel.

## Scope

The package reads fixed-format result sections illustrated by the bundled
examples. Method-header recognition is documented separately from numerical
output-layout validation. Missing optional quantities return NA; unavailable
required sections produce errors that fetch_all() contains with warnings and
NULL elements.

## Downstream dependencies

This is a new CRAN package.
