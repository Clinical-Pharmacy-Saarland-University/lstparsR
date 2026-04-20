# Extract the Objective Function Value (OFV) from a NONMEM Listing File

Extracts the OFV from a NONMEM `.lst` file, trying several output
formats produced by different NONMEM versions and estimation methods:

## Usage

``` r
fetch_ofv(lst, digits = NA)
```

## Arguments

- lst:

  An object of class `"lst"` from
  [`read_lst_file()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/read_lst_file.md).

- digits:

  Integer or `NA`. Rounding for the OFV. Default `NA`.

## Value

A single numeric value (the OFV), or `NA_real_` if not found.

## Details

1.  `#OBJV:***...*** <value> ***...***` — standard NONMEM 7.x banner
    line

2.  `MINIMUM VALUE OF OBJECTIVE FUNCTION = <value>` — same-line format

3.  `OBJECTIVE FUNCTION VALUE WITHOUT CONSTANT: <value>` — multi-line
    FOCE-I

4.  `FINAL VALUE OF OBJECTIVE FUNCTION <value>` — alternative wording

5.  `OFV = <value>` — pyDARWIN / workflow tool footer

When multiple `#OBJV:` lines are present (multiple estimation steps),
the **last** occurrence is returned (final step result).

Returns `NA_real_` with a
[`warning()`](https://rdrr.io/r/base/warning.html) if no OFV can be
found — never stops.

## Examples

``` r
path <- system.file("testdata", "full_cov.lst", package = "lstparsR")
lst  <- read_lst_file(path)
fetch_ofv(lst)
#> [1] 8986.318
```
