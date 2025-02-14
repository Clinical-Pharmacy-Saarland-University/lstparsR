#' Fetches the etas from an lst object
#'
#' @param lst A list object containing the output from a NONMEM run
#' @param rse_digits The number of digits to round the RSEs to
#' @param shk_digits The number of digits to round the SHKs to
#' @return A tibble containing the etas and their RSEs
#' @export
#' @importFrom checkmate assert_class assert_number
#' @importFrom dplyr mutate
#' @importFrom tibble rownames_to_column
#' @examples
#' fetch_etas(lst = lst)
fetch_etas <- function(lst, rse_digits = NA, shk_digits = NA) {
  checkmate::assert_class(lst, "lst")
  checkmate::assert_number(rse_digits, lower = 0, na.ok = TRUE)

  # get the OMEGA values
  header1 <- "FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION"
  header2 <- "FINAL PARAMETER ESTIMATE"
  subheader <- "OMEGA - COV MATRIX FOR RANDOM EFFECTS - ETAS"
  df <- .f_get_block_values(lst, header1, header2, subheader)$df
  colnames(df) <- c("Parameter", "Value")

  header1 <- "FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION"
  header2 <- "STANDARD ERROR OF ESTIMATE"
  subheader <- "OMEGA - COV MATRIX FOR RANDOM EFFECTS - ETAS"
  rse_block <- .safe_f_get_block_values(lst, header1, header2, subheader)
  if (is.null(rse_block$result)) {
    df$RSE <- NA_real_
  } else {
    rse_block <- rse_block$result
    df$RSE <- rse_block$value * 100 / df$Value
    if (!is.na(rse_digits)) {
      df$RSE <- round(df$RSE, rse_digits)
    }
  }

  # add shrinkage
  shrinkage_line <- grep("ETASHRINKSD", lst, value = TRUE)
  shrinkage_values <- NA_real_ # Default to NA if not found
  if (length(shrinkage_line) > 0) {
    # Extract all numeric values from the line
    shrinkage_values <- as.numeric(unlist(regmatches(
      shrinkage_line,
      gregexpr("[0-9]+\\.[0-9]+E[+-][0-9]+", shrinkage_line)
    ))) |>
      suppressWarnings()
  }
  if (!is.na(shk_digits)) {
    shrinkage_values <- round(shrinkage_values, shk_digits) |>
      suppressWarnings()
  }

  df$SHK <- shrinkage_values
  return(df)
}