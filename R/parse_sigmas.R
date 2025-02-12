#' Fetches the sigmas from an lst object
#'
#' @param lst A list object containing the output from a NONMEM run
#' @param rse_digits The number of digits to round the RSEs to
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

  epsilons <- lst |>
    .fetch_matrix(par_name = "SIGMA") |>
    lapply(\(x) {
      x <- x |>
        as.matrix() |>
        diag() |>
        as.data.frame()
      return(x)
    })

  eps_vals <- epsilons[[1]] |>
    tibble::rownames_to_column()

  if (length(epsilons) == 2) {
    if (!is.na(rse_digits)) {
      eps_rses <- round(epsilons[[2]][[1]] * 100 / eps_vals[[2]], rse_digits)
    } else {
      eps_rses <- epsilons[[2]][[1]] * 100 / eps_vals[[2]]
    }
  } else {
    eps_rses <- NA_real_
  }
  epsilons_out <- epsilons |>
    mutate(RSE = eps_rses) |>
    setNames(c("Parameter", "Value", "RSE"))
}
