fetch_thetas <- function(lst, rse_digits = NA) {
  checkmate::assert_class(lst, "lst")
  checkmate::assert_number(rse_digits, lower = 0, na.ok = TRUE)

  upper_delims <- grep(pattern = "THETA - VECTOR OF FIXED EFFECTS PARAMETERS", lst)
  lower_delims <- grep(pattern = "OMEGA - COV MATRIX FOR RANDOM EFFECTS - ETAS", lst)

  if (length(upper_delims) == 0 || length(lower_delims) == 0) {
    stop("Delimiters not found.")
  } else if (length(upper_delims) != length(lower_delims)) {
    stop("Delimiters in incorrect order or malformatted lst file.")
  }

  dfs_out <- list()
  for (j in seq_len(length(upper_delims))) {
    rng <- seq(upper_delims[j] + 1, lower_delims[j] - 1)
    block <- lst[rng] |>
      trimws()
    block_non_empty <- block[block != ""]

    col_names <- block_non_empty[1] |>
      strsplit("  ") |>
      unlist() |>
      trimws()

    values <- block_non_empty[2] |>
      strsplit(" ") |>
      unlist() |>
      trimws()

    values_df <- values[values != ""] |>
      as.numeric() |>
      suppressWarnings()
    colnames_df <- col_names[col_names != ""]

    df_out <- colnames_df |>
      as.data.frame() |>
      dplyr::mutate(
        Value = values_df
      ) |>
      setNames(c("Parameter", "Value"))

    dfs_out[[j]] <- df_out
  }

  param_table <- dfs_out[[1]]
  if (length(dfs_out) == 2) {
    RSEs <- round(dfs_out[[2]]$Value * 100 / dfs_out[[1]]$Value, 0)
  } else {
    RSEs <- NA_real_
  }
  param_table <- param_table |>
    dplyr::mutate(RSE = RSEs)

  return(param_table)
}
