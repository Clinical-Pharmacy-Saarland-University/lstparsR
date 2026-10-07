## Submission

This is the first CRAN submission of lstparsR (version 0.1.2).

The package extracts parameter estimates and diagnostics from existing
'NONMEM' listing files. A 'NONMEM' installation is not required. The optional
Shiny application is launched only on request; examples and tests run without
interactive input.

## Checks

Release-candidate checks and exact source-archive verification are recorded by
the CRAN-preflight workflow. The submission handoff includes the final check
logs and source-archive checksum.

The incoming feasibility check may report "New submission" for this package.

## Scope

The package reads fixed-format result sections illustrated by the bundled
examples. Method-header recognition is documented separately from numerical
output-layout validation. Missing optional quantities return NA; unavailable
required sections produce errors that fetch_all() contains with warnings and
NULL elements.

## Downstream dependencies

This is a new CRAN package.
