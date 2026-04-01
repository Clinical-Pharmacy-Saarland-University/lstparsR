# Extract OMEGA (ETA) Estimates from a NONMEM Listing File

Parses the OMEGA covariance matrix diagonal (variance of random effects)
and, if available, standard errors, RSE, and ETA shrinkage from a NONMEM
`.lst` file.

## Usage

``` r
fetch_etas(lst, digits = NA, shk_digits = NA)
```

## Arguments

- lst:

  An object of class `"lst"` from
  [`read_lst_file()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/read_lst_file.md).

- digits:

  Integer or `NA`. Rounding for `rse`. Default `NA`.

- shk_digits:

  Integer or `NA`. Rounding for `shrinkage`. Default `NA`.

## Value

A [`tibble`](https://tibble.tidyverse.org/reference/tibble.html) with
columns:

- parameter:

  Character. Parameter label (e.g. `"ETA1"`).

- estimate:

  Numeric. Diagonal variance estimate.

- se:

  Numeric. Standard error. `NA` if no covariance step.

- rse:

  Numeric. Relative standard error (%). `NA` if no covariance step.

- shrinkage:

  Numeric. ETA shrinkage (%). `NA` if not reported.

## Examples

``` r
path <- system.file("testdata", "full_cov.lst", package = "lstparsR")
lst  <- read_lst_file(path)
fetch_etas(lst)
#> # A tibble: 7 × 5
#>   parameter estimate      se         rse shrinkage
#>   <chr>        <dbl>   <dbl>       <dbl>     <dbl>
#> 1 ETA1       0.2      0.0389        19.4        NA
#> 2 ETA2       0.255    0.0463        18.2        NA
#> 3 ETA3       0.1     73          73000          NA
#> 4 ETA4       0.1     73          73000          NA
#> 5 ETA5       0.00001 68      680000000          NA
#> 6 ETA6       0.00001 NA             NA          NA
#> 7 ETA7       0.00001 NA             NA          NA
```
