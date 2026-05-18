# Fetch All Parameters from a NONMEM Listing File

Convenience wrapper that runs all `fetch_*` functions in a single call
and returns a named list. Failed individual parsers produce a warning
and return `NULL` for that element rather than stopping the entire call.

## Usage

``` r
fetch_all(lst, digits = NA, shk_digits = NA, ofv_digits = NA, cn_digits = NA)
```

## Arguments

- lst:

  An object of class `"lst"` from
  [`read_lst_file()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/read_lst_file.md).

- digits:

  Integer or `NA`. Rounding for RSE values. Default `NA`.

- shk_digits:

  Integer or `NA`. Rounding for ETA shrinkage. Default `NA`.

- ofv_digits:

  Integer or `NA`. Rounding for OFV. Default `NA`.

- cn_digits:

  Integer or `NA`. Rounding for condition number. Default `NA`.

## Value

A named list with elements:

- thetas:

  [tibble](https://tibble.tidyverse.org/reference/tibble.html) from
  [`fetch_thetas()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/fetch_thetas.md),
  or `NULL` on failure.

- etas:

  [tibble](https://tibble.tidyverse.org/reference/tibble.html) from
  [`fetch_etas()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/fetch_etas.md),
  or `NULL` on failure.

- sigmas:

  [tibble](https://tibble.tidyverse.org/reference/tibble.html) from
  [`fetch_sigmas()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/fetch_sigmas.md),
  or `NULL` on failure.

- ofv:

  Numeric from
  [`fetch_ofv()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/fetch_ofv.md).

- condn:

  Numeric from
  [`fetch_condn()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/fetch_condn.md),
  or `NA` if no covariance step.

## Examples

``` r
path   <- system.file("testdata", "full_cov.lst", package = "lstparsR")
lst    <- read_lst_file(path)
result <- fetch_all(lst)
result$thetas
#> # A tibble: 12 × 4
#>    parameter     estimate       se     rse
#>    <chr>            <dbl>    <dbl>   <dbl>
#>  1 TH_1          34.1     3.37e+ 0 9.88e 0
#>  2 TH_2      387000       5.41e+ 7 1.40e 4
#>  3 TH_3           8.05    5.2 e- 1 6.46e 0
#>  4 TH_4           1.78    1.49e- 1 8.37e 0
#>  5 TH_5           0.498   2.78e- 2 5.58e 0
#>  6 TH_6           0.362   4.81e- 1 1.33e 2
#>  7 TH_7          -0.171   1.35e- 1 7.89e 1
#>  8 TH_8          -0.0314  2.69e- 1 8.57e 2
#>  9 TH_9          -0.163   2.78e- 1 1.71e 2
#> 10 TH10          -0.23    1.88e- 1 8.17e 1
#> 11 TH11           0.00539 1.98e- 2 3.67e 2
#> 12 TH12           0.2     1.90e+74 9.50e76
result$ofv
#> [1] 8986.318
```
