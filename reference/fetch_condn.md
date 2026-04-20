# Extract the Condition Number from a NONMEM Listing File

Computes the condition number of the correlation matrix of parameter
estimates as the ratio of the largest to smallest eigenvalue. A
condition number above 1000 typically indicates numerical difficulties
in parameter estimation.

## Usage

``` r
fetch_condn(lst, digits = NA)
```

## Arguments

- lst:

  An object of class `"lst"` from
  [`read_lst_file()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/read_lst_file.md).

- digits:

  Integer or `NA`. Rounding for the condition number. Default `NA`.

## Value

A single numeric value (the condition number), or `NA_real_` if the
eigenvalue section is absent.

## Details

Returns `NA` gracefully when no covariance step was run or when
eigenvalues were not printed (`EIGENVLS. PRINTED: NO`).

## Examples

``` r
path <- system.file("testdata", "full_cov.lst", package = "lstparsR")
lst  <- read_lst_file(path)
fetch_condn(lst)
#> [1] 23.30882
```
