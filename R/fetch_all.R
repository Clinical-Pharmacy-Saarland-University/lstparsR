#' Fetch All Parameters from a NONMEM Listing File
#'
#' Convenience wrapper that runs all `fetch_*` functions in a single call and
#' returns a named list. Failed individual parsers produce a warning and return
#' `NULL` for that element rather than stopping the entire call.
#'
#' @param lst        An object of class `"lst"` from [read_lst_file()].
#' @param digits     Integer or `NA`. Rounding for RSE values. Default `NA`.
#' @param shk_digits Integer or `NA`. Rounding for ETA shrinkage. Default `NA`.
#' @param ofv_digits Integer or `NA`. Rounding for OFV. Default `NA`.
#' @param cn_digits  Integer or `NA`. Rounding for condition number. Default `NA`.
#'
#' @return A named list with elements:
#'   \describe{
#'     \item{thetas}{[tibble] from [fetch_thetas()], or `NULL` on failure.}
#'     \item{etas}{[tibble] from [fetch_etas()], or `NULL` on failure.}
#'     \item{sigmas}{[tibble] from [fetch_sigmas()], or `NULL` on failure.}
#'     \item{ofv}{Numeric from [fetch_ofv()].}
#'     \item{condn}{Numeric from [fetch_condn()], or `NA` if no covariance step.}
#'   }
#'
#' @export
#'
#' @examples
#' path   <- system.file("testdata", "full_cov.lst", package = "lstparsR")
#' lst    <- read_lst_file(path)
#' result <- fetch_all(lst)
#' result$thetas
#' result$ofv
fetch_all <- function(lst, digits = NA, shk_digits = NA,
                      ofv_digits = NA, cn_digits = NA) {
  .assert_lst(lst)

  .safe_fetch <- function(fn, ...) {
    res <- purrr::safely(fn)(...)
    if (!is.null(res$error)) {
      warning(sprintf("fetch_all: %s",
                      conditionMessage(res$error)),
              call. = FALSE)
    }
    res$result
  }

  list(
    thetas = .safe_fetch(fetch_thetas, lst, digits = digits),
    etas   = .safe_fetch(fetch_etas,   lst, digits = digits, shk_digits = shk_digits),
    sigmas = .safe_fetch(fetch_sigmas, lst, digits = digits),
    ofv    = fetch_ofv(lst,   digits = ofv_digits),
    condn  = fetch_condn(lst, digits = cn_digits)
  )
}
