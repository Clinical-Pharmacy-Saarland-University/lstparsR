#' Fetch Thetas from List
#'
#' This function extracts theta values from a lst-file object.
#'
#' @param lst A lst-file object.
#' @param rse_digits An optional parameter specifying the number of digits for rounding standard errors. Default is NA.
#'
#' @return A data frame containing the extracted theta values and standard errors.
#' @export
#'
fetch_thetas <- function(lst, rse_digits = NA) {
  checkmate::assert_class(lst, "lst")
  checkmate::assert_number(rse_digits, lower = 0, na.ok = TRUE)

  # just the theta values
  header1 <- "FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION"
  header2 <- "FINAL PARAMETER ESTIMATE"
  subheader <- "THETA - VECTOR OF FIXED EFFECTS PARAMETERS"
  df <- .f_get_block_values(lst, header1, header2, subheader)$df
  colnames(df) <- c("Parameter", "Value")

  header1 <- "FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION"
  header2 <- "STANDARD ERROR OF ESTIMATE"
  subheader <- "THETA - VECTOR OF FIXED EFFECTS PARAMETERS"
  se_block <- .safe_f_get_block_values(lst, header1, header2, subheader)
  if (is.null(se_block$result)) {
    df$RSE <- NA_real_
  } else {
    se_block <- se_block$result
    df$RSE <- se_block$value * 100 / df$Value
    if (!is.na(rse_digits)) {
      df$RSE <- round(df$RSE, rse_digits)
    }
  }
  return(df)
}
