# lstparsR: Tidy Parsing of NONMEM Listing Files for Population PK/PD Workflows

Provides functions to read, clean, and reshape NONMEM listing (.lst)
files into tidy data frames for downstream population pharmacokinetic
and pharmacodynamic (PK/PD) analyses. Parsers extract THETA, OMEGA,
SIGMA, objective function value (OFV), condition number, and shrinkage
values from NONMEM output files. Both runs with and without a covariance
step are handled gracefully, returning NA for unavailable quantities
rather than raising errors.

## See also

Useful links:

- <https://github.com/Clinical-Pharmacy-Saarland-University/lstparsR>

- Report bugs at
  <https://github.com/Clinical-Pharmacy-Saarland-University/lstparsR/issues>

## Author

**Maintainer**: Raban Heller <raban.heller@uni-ulm.de>

Authors:

- Simeon Rüdesheim <simeon.ruedesheim@uni-saarland.de>

- Dominik Selzer <dominik.selzer@uni-saarland.de>
