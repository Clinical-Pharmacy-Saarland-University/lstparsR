# lstparseR

A simple R package to parse `.lst` NONMEM output files.

````markdown
# lstparseR

`lstparseR` is an R package designed to simplify and standardize the parsing of NONMEM “.lst” (listing) files. It provides functions to extract model run metadata, parameter estimates, variance–covariance components, residual diagnostics, and other rich output directly into tidy R data frames for downstream analysis, reporting, or visualization.

---

## Features

- **Robust parsing** of NONMEM `.lst` files, handling different NONMEM versions and table styles.
- **Extraction of key sections** such as `$THETA`, `$OMEGA`, `$SIGMA`, `$TABLE` output, objective function values, and convergence diagnostics.
- **Tidy data frames** for easy integration with the tidyverse suite (e.g., `dplyr`, `ggplot2`).
- **Batch processing**: parse many `.lst` files at once and combine results.
- **Lightweight dependency** footprint.

---

## Installation

You can install the latest development version of `lstparseR` directly from GitHub:

```r
# install.packages("remotes")  # if you haven’t already
remotes::install_github("Clinical-Pharmacy-Saarland-University/lstparseR")
````

---

## Quick Start

```r
library(lstparseR)

# 1. Point to your NONMEM .lst file
lst_file <- "path/to/model_run.lst"

# 2. Parse the file
parsed <- parse_lst(lst_file)

# 3. Inspect the results
# parsed is a named list of tibbles:
names(parsed)
#> [1] "metadata"     "theta"        "omega"        "sigma"
#> [5] "objfun"       "covres"       "table_output"

# 4. Work with THETA estimates
parsed$theta
#> # A tibble: … 
#>   parameter estimate se  lower upper
#>   <chr>       <dbl>  <dbl> <dbl> <dbl>
#> 1 THETA1       5.12   0.34  4.46  5.78
#> …

# 5. Batch‐parse a directory of runs
all_results <- parse_lst_dir("path/to/lst_files/")
```

---

## Functions

| Function           | Description                                                 |
| ------------------ | ----------------------------------------------------------- |
| `parse_lst()`      | Parse a single `.lst` file into structured components.      |
| `parse_lst_dir()`  | Recursively parse all `.lst` files in a directory.          |
| `read_lst_lines()` | Read raw lines from a `.lst` for custom downstream parsing. |
| `summarize_runs()` | Combine metadata across multiple parsed runs.               |
| `export_to_csv()`  | Write parsed tables to CSV files for reporting.             |

---

## Examples

### Extracting variance–covariance components

```r
res <- parse_lst("run001.lst")

# View IIV covariance (OMEGA)
res$omega
```

### Plotting observed vs. individual predictions

```r
library(ggplot2)

tbl <- res$table_output

ggplot(tbl, aes(x = IPRED, y = DV)) +
  geom_point(alpha = 0.5) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  labs(
    x = "Individual Predictions",
    y = "Observations",
    title = "Observed vs. Individual Predictions"
  ) +
  theme_minimal()
```

---

## Contributing

We welcome contributions! Please:

1. Fork the repository.
2. Create a feature branch (`git checkout -b feature/awesome-feature`).
3. Commit your changes (`git commit -m "Add awesome-feature"`).
4. Push to your branch (`git push origin feature/awesome-feature`).
5. Open a Pull Request.

Please adhere to the existing code style and include unit tests where appropriate.

---

## License

`lstparseR` is released under the MIT License. See [LICENSE](LICENSE) for details.

```
```
