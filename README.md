# lstparseR

<p align="center">
  <img src="logo.png" alt="pyDarwinXploR hex sticker" width="200" />
</p>


`lstparseR` is an R package designed to simplify and standardize the parsing of NONMEM “.lst” (listing) files. It provides functions to extract model run metadata, parameter estimates, variance–covariance components, residual diagnostics, and other rich output directly into tidy R data frames for downstream analysis, reporting, or visualization.


## Installation

```r
# From CRAN (when available)
install.packages("lstparseR")

# Latest development version from GitHub
if (!requireNamespace("remotes", quietly = TRUE))
  install.packages("remotes")

remotes::install_github(
  "Clinical-Pharmacy-Saarland-University/lstparseR",
  build_vignettes = TRUE
)
````


## Quick Start

```r
library(lstparseR)

# Point to a NONMEM run directory
run_dir <- "/path/to/nonmem/run0"

# 1) Read the main .lst file
lst  <- read_lst_file(file.path(run_dir, "run0.lst"))

# 2) Extract parameter tables
thetas  <- fetch_thetas(lst)
sigmas  <- fetch_sigmas(lst)
omegas  <- fetch_omegas(lst)       # alias: fetch_condn()
ofv      <- fetch_ofv(lst)
etas     <- fetch_etas(lst)

# 3) Extract raw result table (.tab)
df_tab <- read.table(
  paste0(run_dir, "/results.tab"),
  skip   = 1,
  header = TRUE
)

# 4) Inspect
head(thetas)
head(omegas)
head(ofv)
head(etas)

# 5) Simple plot of OFV history
plot(ofv$STEP, ofv$OBJECTIVE, type = "b",
     xlab = "Iteration", ylab = "OFV",
     main = "NONMEM OFV Trace")
```

## Functions

| Function          | Description                                                                       |
| :---------------- | :-------------------------------------------------------------------------------- |
| `read_lst_file()` | Reads a NONMEM `.lst` file into R and returns a structured list object.           |
| `fetch_thetas()`  | Pulls summary of fixed effect estimates (`THETA`) from the `lst` object.          |
| `fetch_sigmas()`  | Pulls residual error model variances (`SIGMA`).                                   |
| `fetch_omegas()`  | Pulls inter‐individual variability variances (`OMEGA`).                           |
| `fetch_ofv()`     | Extracts the objective function value history over the minimization.              |
| `fetch_etas()`    | Extracts post‐hoc ETA estimates for each individual (conditional mode estimates). |
| `fetch_condn()`   | Alias for `fetch_omegas()` (pulls IIV components).                                |

---

## Examples

### 1. Extract and compare parameter tables

```r
# Read and extract
lst   <- read_lst_file("run0.lst")
th    <- fetch_thetas(lst)
om    <- fetch_omegas(lst)
sg    <- fetch_sigmas(lst)

# Combine and view
library(dplyr)
bind_rows(
  th   %>% mutate(source = "theta"),
  om   %>% mutate(source = "omega"),
  sg   %>% mutate(source = "sigma")
) %>%
  glimpse()
```

### 2. Plot ETA distribution

```r
eta_df <- fetch_etas(lst)

library(ggplot2)
ggplot(eta_df, aes(x = ETA_ID, y = ETA)) +
  geom_boxplot() +
  facet_wrap(~PARAMETER, scales = "free_y") +
  labs(title = "ETA Distributions", x = "Individual ID", y = "ETA")
```

### 3. Trace of objective function

```r
ofv <- fetch_ofv(lst)
ggplot(ofv, aes(step, ofv)) +
  geom_line() +
  geom_point() +
  labs(title = "OFV Trace", x = "Iteration", y = "OFV")
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Open a Pull Request

Please run `devtools::check()` and ensure all examples and tests pass before submitting.


## License

This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.

<p align="center">
  <em>Developed by the Clinical Pharmacy group at Saarland University</em>
</p>

**What’s in this README?**

* **Title & description**: concisely explains the package purpose.
* **Installation**: from CRAN (future) and GitHub.
* **Quick Start**: minimal code snippet showing core workflow.
* **Function reference**: table of primary exports.
* **Worked examples**: three typical use cases.
* **Contributing**: standard open‐source workflow.
* **License**: pointer to MIT license.


