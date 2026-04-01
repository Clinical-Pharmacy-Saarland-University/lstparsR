#' Extract SIGMA (EPS) Estimates from a NONMEM Listing File
#'
#' Parses the SIGMA covariance matrix diagonal (variance of residual errors)
#' and, if available, standard errors and RSE from a NONMEM `.lst` file.
#'
#' @param lst    An object of class `"lst"` from [read_lst_file()].
#' @param digits Integer or `NA`. Rounding for `rse`. Default `NA`.
#'
#' @return A [`tibble`][tibble::tibble] with columns:
#'   \describe{
#'     \item{parameter}{Character. Parameter label (e.g. `"EPS1"`).}
#'     \item{estimate}{Numeric. Diagonal variance estimate.}
#'     \item{se}{Numeric. Standard error. `NA` if no covariance step.}
#'     \item{rse}{Numeric. Relative standard error (%). `NA` if no covariance step.}
#'   }
#'
#' @export
#'
#' @examples
#' path <- system.file("testdata", "full_cov.lst", package = "lstparseR")
#' lst  <- read_lst_file(path)
#' fetch_sigmas(lst)
fetch_sigmas <- function(lst, digits = NA) {
  .assert_lst(lst)
  checkmate::assert_number(digits, lower = 0, na.ok = TRUE)

  method  <- .get_estimation_method(lst)
  sub_str <- "SIGMA - COV MATRIX FOR RANDOM EFFECTS - EPSILONS"

  # --- Estimates ---
  page_est <- .find_section_page(lst, method, "FINAL PARAMETER ESTIMATE")
  if (is.na(page_est)) {
    stop("FINAL PARAMETER ESTIMATE section not found.", call. = FALSE)
  }
  df_est <- .parse_matrix_block(lst, page_est, sub_str)
  if (is.null(df_est)) {
    stop("Could not parse SIGMA estimates.", call. = FALSE)
  }

  # --- Standard errors ---
  se_vec <- rep(NA_real_, nrow(df_est))
  if (.has_covariance_step(lst)) {
    page_se <- .find_section_page(lst, method, "STANDARD ERROR OF ESTIMATE")
    if (!is.na(page_se)) {
      df_se <- .parse_matrix_block(lst, page_se, sub_str)
      if (!is.null(df_se) && nrow(df_se) == nrow(df_est)) {
        se_vec <- df_se$value
      } else {
        warning("SIGMA SE row count does not match estimates. Setting SE to NA.")
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
