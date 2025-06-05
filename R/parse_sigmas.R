#' Fetches the sigmas from an lst object
#'
#' @param lst A list object containing the output from a NONMEM run
#' @param rse_digits The number of digits to round the RSEs to
#' @param shk_digits The number of digits to round the SHKs to
#' @return A tibble containing the sigmas and their RSEs
#' @export
#' @importFrom checkmate assert_class assert_number
#' @importFrom dplyr mutate
#' @importFrom tibble rownames_to_column
#' @examples
#' fetch_sigmas(lst = lst)
fetch_sigmas <- function(lst, rse_digits = NA) {
  checkmate::assert_class(lst, "lst")
  checkmate::assert_number(rse_digits, lower = 0, na.ok = TRUE)

  # get the SIGMA values
  header1 <- "FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION"
  header2 <- "FINAL PARAMETER ESTIMATE"
  subheader <- "SIGMA - COV MATRIX FOR RANDOM EFFECTS - EPSILONS"
  df <- .f_get_block_values(lst, header1, header2, subheader)$df
  colnames(df) <- c("Parameter", "Value")
  header1 <- "FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION"
  header2 <- "STANDARD ERROR OF ESTIMATE"
  subheader <- "SIGMA - COV MATRIX FOR RANDOM EFFECTS - EPSILONS"
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

  return(df)
}
