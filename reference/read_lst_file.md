# Read a NONMEM Listing File

Reads a NONMEM `.lst` output file into memory as a character vector with
class `"lst"` for use by the `fetch_*` family of functions.

## Usage

``` r
read_lst_file(path)
```

## Arguments

- path:

  Character string. Path to the `.lst` file.

## Value

A character vector of class `"lst"`, where each element is one line of
the file.

## Examples

``` r
path <- system.file("testdata", "full_cov.lst", package = "lstparseR")
lst  <- read_lst_file(path)
print(lst)
#> <lst> NONMEM listing file: 1321 lines
```
