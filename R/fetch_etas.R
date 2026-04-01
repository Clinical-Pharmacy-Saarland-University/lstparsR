#' Extract OMEGA (ETA) Estimates from a NONMEM Listing File
#'
#' Parses the OMEGA covariance matrix diagonal (variance of random effects)
#' and, if available, standard errors, RSE, and ETA shrinkage from a NONMEM
#' `.lst` file.
#'
#' @param lst        An object of class `"lst"` from [read_lst_file()].
#' @param digits     Integer or `NA`. Rounding for `rse`. Default `NA`.
#' @param shk_digits Integer or `NA`. Rounding for `shrinkage`. Default `NA`.
#'
#' @return A [`tibble`][tibble::tibble] with columns:
#'   \describe{
#'     \item{parameter}{Character. Parameter label (e.g. `"ETA1"`).}
#'     \item{estimate}{Numeric. Diagonal variance estimate.}
#'     \item{se}{Numeric. Standard error. `NA` if no covariance step.}
#'     \item{rse}{Numeric. Relative standard error (%). `NA` if no covariance step.}
#'     \item{shrinkage}{Numeric. ETA shrinkage (%). `NA` if not reported.}
#'   }
#'
#' @export
#'
#' @examples
#' path <- system.file("testdata", "full_cov.lst", package = "lstparsR")
#' lst  <- read_lst_file(path)
#' fetch_etas(lst)
fetch_etas <- function(lst, digits = NA, shk_digits = NA) {
  .assert_lst(lst)
  checkmate::assert_number(digits,     lower = 0, na.ok = TRUE)
  checkmate::assert_number(shk_digits, lower = 0, na.ok = TRUE)

  method  <- .get_estimation_method(lst)
  sub_str <- "OMEGA - COV MATRIX FOR RANDOM EFFECTS - ETAS"

  # --- Estimates ---
  page_est <- .find_section_page(lst, method, "FINAL PARAMETER ESTIMATE")
  if (is.na(page_est)) {
    stop("FINAL PARAMETER ESTIMATE section not found.", call. = FALSE)
  }
  df_est <- .parse_matrix_block(lst, page_est, sub_str)
  if (is.null(df_est)) {
    stop("Could not parse OMEGA estimates.", call. = FALSE)
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
        warning("OMEGA SE row count does not match estimates. Setting SE to NA.")
      }
    }
  }

  # --- RSE ---
  rse_vec <- se_vec * 100 / abs(df_est$value)
  if (!is.na(digits)) rse_vec <- round(rse_vec, digits)

  # --- ETA shrinkage ---
  shk_vec <- .parse_shrinkage(lst, "ETASHRINKSD")
  if (!is.null(shk_vec)) {
    if (length(shk_vec) != nrow(df_est)) {
      warning(sprintf(
        "ETASHRINKSD has %d values but %d ETAs were parsed. Setting shrinkage to NA.",
        length(shk_vec), nrow(df_est)
      ))
      shk_vec <- rep(NA_real_, nrow(df_est))
    }
  } else {
    shk_vec <- rep(NA_real_, nrow(df_est))
  }
  if (!is.na(shk_digits)) shk_vec <- round(shk_vec, shk_digits)

  tibble::tibble(
    parameter = df_est$id,
    estimate  = df_est$value,
    se        = se_vec,
    rse       = rse_vec,
    shrinkage = shk_vec
  )
}
