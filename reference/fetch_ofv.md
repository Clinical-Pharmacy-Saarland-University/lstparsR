# Extract the Objective Function Value (OFV) from a NONMEM Listing File

Extracts the OFV reported on the `#OBJV:` line of a NONMEM `.lst` file.
For failed or early-terminated runs where `#OBJV:` is absent, the
function falls back to the workflow footer (`OFV = ...`) and returns
`NA` with a warning if neither is found.

## Usage

``` r
fetch_ofv(lst, digits = NA)
```

## Arguments

- lst:

  An object of class `"lst"` from
  [`read_lst_file()`](https://clinical-pharmacy-saarland-university.github.io/lstparseR/reference/read_lst_file.md).

- digits:

  Integer or `NA`. Rounding for the OFV. Default `NA`.

## Value

A single numeric value (the OFV), or `NA_real_` if not found.

## Examples

``` r
path <- system.file("testdata", "full_cov.lst", package = "lstparseR")
lst  <- read_lst_file(path)
fetch_ofv(lst)
#> [1] 8986.318
```
