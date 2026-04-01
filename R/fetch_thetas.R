#' Extract THETA Estimates from a NONMEM Listing File
#'
#' Parses the THETA (fixed effects) parameter estimates and, if available,
#' their standard errors and relative standard errors (RSE) from a NONMEM
#' `.lst` file.
#'
#' @param lst   An object of class `"lst"` from [read_lst_file()].
#' @param digits Integer or `NA`. Number of decimal places to round `RSE`.
#'   Default `NA` (no rounding).
#'
#' @return A [`tibble`][tibble::tibble] with columns:
#'   \describe{
#'     \item{parameter}{Character. Parameter label (e.g. `"TH_1"`).}
#'     \item{estimate}{Numeric. Point estimate.}
#'     \item{se}{Numeric. Standard error. `NA` if no covariance step.}
#'     \item{rse}{Numeric. Relative standard error (%). `NA` if no covariance step.}
#'   }
#'
#' @export
#'
#' @examples
#' path <- system.file("testdata", "full_cov.lst", package = "lstparsR")
#' lst  <- read_lst_file(path)
#' fetch_thetas(lst)
fetch_thetas <- function(lst, digits = NA) {
  .assert_lst(lst)
  checkmate::assert_number(digits, lower = 0, na.ok = TRUE)

  method  <- .get_estimation_method(lst)
  sub_str <- "THETA - VECTOR OF FIXED EFFECTS PARAMETERS"

  # --- Estimates ---
  page_est <- .find_section_page(lst, method, "FINAL PARAMETER ESTIMATE")
  if (is.na(page_est)) {
    stop("FINAL PARAMETER ESTIMATE section not found. Did the NONMEM run complete?",
         call. = FALSE)
  }
  df_est <- .parse_vector_block(lst, page_est, sub_str)
  if (is.null(df_est)) {
    stop("Could not parse THETA estimates.", call. = FALSE)
  }

  # --- Standard errors (optional) ---
  se_vec <- rep(NA_real_, nrow(df_est))
  if (.has_covariance_step(lst)) {
    page_se <- .find_section_page(lst, method, "STANDARD ERROR OF ESTIMATE")
    if (!is.na(page_se)) {
      df_se <- .parse_vector_block(lst, page_se, sub_str)
      if (!is.null(df_se) && nrow(df_se) == nrow(df_est)) {
        se_vec <- df_se$value
      } else {
        warning("THETA SE row count does not match estimates. Setting SE to NA.")
      }
    }
  }

  # --- RSE ---
  rse_vec <- se_vec * 100 / abs(df_est$value)
  if (!is.na(digits)) rse_vec <- round(rse_vec, digits)

  tibble::tibble(
    parameter = df_est$id,
    estimate  = df_est$value,
    se        = se_vec,
    rse       = rse_vec
  )
}
