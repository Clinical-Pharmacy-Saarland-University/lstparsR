# Getting Started with lstparsR

## Overview

**lstparsR** reads NONMEM `.lst` listing files and extracts parameter
estimates into tidy tibbles. It is designed for population
pharmacokinetic and pharmacodynamic (PK/PD) workflows where many model
runs need to be parsed programmatically.

Key design choices:

- All output is returned as tibbles with consistent column names.
- Missing quantities (e.g., standard errors when the covariance step is
  absent) are `NA`, never errors.
- Both VECTOR blocks (THETA) and lower-triangular MATRIX blocks (OMEGA,
  SIGMA) are handled, including multi-line parameter sets.

## Reading a Listing File

Use
[`read_lst_file()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/read_lst_file.md)
to load a `.lst` file into an S3 object of class `"lst"`:

``` r

path <- system.file("testdata", "full_cov.lst", package = "lstparsR")
lst  <- read_lst_file(path)
lst
#> <lst> NONMEM listing file: 1321 lines
summary(lst)
#> <lst> NONMEM listing file
#>   Lines            : 1321
#>   Estimation method: FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION
#>   Covariance step  : TRUE
```

The `lst` object is simply a character vector (one element per line)
with class `"lst"` attached. All `fetch_*` functions require this class.

## Extracting THETA (Fixed Effects)

``` r

fetch_thetas(lst)
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
```

Each row corresponds to one THETA parameter. The `se` and `rse` columns
contain the standard error and relative standard error (as a
percentage), respectively.

Use the `digits` argument to round RSE values:

``` r

fetch_thetas(lst, digits = 1)
#> # A tibble: 12 × 4
#>    parameter     estimate       se     rse
#>    <chr>            <dbl>    <dbl>   <dbl>
#>  1 TH_1          34.1     3.37e+ 0 9.9 e 0
#>  2 TH_2      387000       5.41e+ 7 1.40e 4
#>  3 TH_3           8.05    5.2 e- 1 6.5 e 0
#>  4 TH_4           1.78    1.49e- 1 8.4 e 0
#>  5 TH_5           0.498   2.78e- 2 5.6 e 0
#>  6 TH_6           0.362   4.81e- 1 1.33e 2
#>  7 TH_7          -0.171   1.35e- 1 7.89e 1
#>  8 TH_8          -0.0314  2.69e- 1 8.57e 2
#>  9 TH_9          -0.163   2.78e- 1 1.71e 2
#> 10 TH10          -0.23    1.88e- 1 8.17e 1
#> 11 TH11           0.00539 1.98e- 2 3.67e 2
#> 12 TH12           0.2     1.90e+74 9.50e76
```

## Extracting OMEGA (Random Effects)

[`fetch_etas()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/fetch_etas.md)
extracts the diagonal of the OMEGA covariance matrix, plus ETA shrinkage
when reported:

``` r

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

Shrinkage values can be rounded separately:

``` r

fetch_etas(lst, digits = 1, shk_digits = 1)
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

## Extracting SIGMA (Residual Error)

``` r

fetch_sigmas(lst)
#> # A tibble: 2 × 4
#>   parameter estimate      se    rse
#>   <chr>        <dbl>   <dbl>  <dbl>
#> 1 EPS1        0.0769 0.00434   5.64
#> 2 EPS2        0.123  0.199   162.
```

## Objective Function Value

``` r

fetch_ofv(lst)
#> [1] 8986.318
```

For failed runs,
[`fetch_ofv()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/fetch_ofv.md)
falls back to the workflow footer (`OFV = ...`) if the standard `#OBJV:`
line is absent.

## Condition Number

The condition number is computed as the ratio of the largest to smallest
eigenvalue of the correlation matrix of parameter estimates. Values
above 1000 suggest numerical instability:

``` r

fetch_condn(lst)
#> [1] 23.30882
```

## All at Once

[`fetch_all()`](https://clinical-pharmacy-saarland-university.github.io/lstparsR/reference/fetch_all.md)
runs every parser in a single call. Individual parser failures are
caught and returned as `NULL` with a warning, so a single problematic
section does not abort the entire extraction:

``` r

result <- fetch_all(lst)
names(result)
#> [1] "thetas" "etas"   "sigmas" "ofv"    "condn"
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
result$condn
#> [1] 23.30882
```

## Runs Without a Covariance Step

When NONMEM did not run or complete a covariance step, SE, RSE,
shrinkage, and condition number are returned as `NA`:

``` r

path2 <- system.file("testdata", "theta_no_cov.lst", package = "lstparsR")
lst2  <- read_lst_file(path2)
fetch_thetas(lst2)
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
fetch_condn(lst2)
#> [1] 23.30882
```

## Batch Processing

A common pattern is to parse many `.lst` files at once:

``` r

library(purrr)

lst_files <- list.files("models/", pattern = "\\.lst$", full.names = TRUE)

results <- map(lst_files, \(f) {
  lst <- read_lst_file(f)
  fetch_all(lst)
})

# Combine all THETA tables
all_thetas <- map_dfr(results, "thetas", .id = "run")
```

## Supported Estimation Methods

lstparsR detects and supports the following NONMEM estimation methods:

- First Order (FO)
- First Order Conditional Estimation (FOCE)
- First Order Conditional Estimation with Interaction (FOCE-I)
- Stochastic Approximation Expectation-Maximization (SAEM)
- Importance Sampling (IMP)
- Importance Sampling Assisted by Mode A Posteriori (IMPMAP)
- Markov Chain Monte Carlo Bayesian Analysis

## Interactive Exploration

For interactive use, launch the built-in Shiny application:

``` r

lstparsR::run_app()
```

This opens a browser-based interface where you can upload `.lst` files,
view parsed results in tables, and download them as CSV or RDS.
