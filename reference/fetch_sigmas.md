# Extract SIGMA (EPS) Estimates from a NONMEM Listing File

Parses the SIGMA covariance matrix diagonal (variance of residual
errors) and, if available, standard errors and RSE from a NONMEM `.lst`
file.

## Usage

``` r
fetch_sigmas(lst, digits = NA)
```

## Arguments

- lst:

  An object of class `"lst"` from
  [`read_lst_file()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/read_lst_file.md).

- digits:

  Integer or `NA`. Rounding for `rse`. Default `NA`.

## Value

A [`tibble`](https://tibble.tidyverse.org/reference/tibble.html) with
columns:

- parameter:

  Character. Parameter label (e.g. `"EPS1"`).

- estimate:

  Numeric. Diagonal variance estimate.

- se:

  Numeric. Standard error. `NA` if no covariance step.

- rse:

  Numeric. Relative standard error (%). `NA` if no covariance step.

## Examples

``` r
path <- system.file("testdata", "full_cov.lst", package = "lstparsR")
lst  <- read_lst_file(path)
fetch_sigmas(lst)
#> # A tibble: 2 × 4
#>   parameter estimate      se    rse
#>   <chr>        <dbl>   <dbl>  <dbl>
#> 1 EPS1        0.0769 0.00434   5.64
#> 2 EPS2        0.123  0.199   162.  
```
