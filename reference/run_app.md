# Launch the lstparsR Shiny Application

Opens an interactive browser-based application for uploading NONMEM
`.lst` files, viewing parsed parameter tables, and downloading results
in CSV or RDS format.

## Usage

``` r
run_app(...)
```

## Arguments

- ...:

  Additional arguments passed to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html).

## Value

Called for its side effect (launches a Shiny app). Returns the value
from [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html)
invisibly.

## Examples

``` r
if (interactive()) {
  run_app()
}
```
