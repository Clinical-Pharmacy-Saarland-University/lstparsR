#' Extract the Condition Number from a NONMEM Listing File
#'
#' Computes the condition number of the correlation matrix of parameter estimates
#' as the ratio of the largest to smallest eigenvalue. A condition number above
#' 1000 typically indicates numerical difficulties in parameter estimation.
#'
#' Returns `NA` gracefully when no covariance step was run.
#'
#' @param lst    An object of class `"lst"` from [read_lst_file()].
#' @param digits Integer or `NA`. Rounding for the condition number. Default `NA`.
#'
#' @return A single numeric value (the condition number), or `NA_real_` if the
#'   eigenvalue section is absent.
#'
#' @export
#'
#' @examples
#' path <- system.file("testdata", "full_cov.lst", package = "lstparsR")
#' lst  <- read_lst_file(path)
#' fetch_condn(lst)
fetch_condn <- function(lst, digits = NA) {
  .assert_lst(lst)
  checkmate::assert_number(digits, lower = 0, na.ok = TRUE)

  if (!.has_covariance_step(lst)) {
    return(NA_real_)
  }

  # Find the eigenvalue section header
  eigen_header <- which(stringr::str_detect(
    lst, stringr::fixed("EIGENVALUES OF COR MATRIX OF ESTIMATE")
  ))
  if (length(eigen_header) == 0) {
    warning("Eigenvalue section not found. Returning NA.", call. = FALSE)
    return(NA_real_)
  }

  start <- eigen_header[1]
  n     <- length(lst)

  # Scan forward past the header block (skip asterisk lines) to find eigenvalues
  eigen_lines <- character(0)
  found_values <- FALSE
  for (i in seq.int(start + 4, min(start + 30, n))) {
    line <- lst[i]
    if (stringr::str_detect(line, "[0-9]\\.?[0-9]*E[+-][0-9]+")) {
      eigen_lines <- c(eigen_lines, line)
      found_values <- TRUE
    } else if (found_values) {
      # Stop once we've found values and hit a non-value line
      break
    }
  }

  if (length(eigen_lines) == 0) {
    warning("Could not extract eigenvalues. Returning NA.", call. = FALSE)
    return(NA_real_)
  }

  # Extract all eigenvalues
  eigenvalues <- suppressWarnings(as.numeric(unlist(stringr::str_extract_all(
    paste(eigen_lines, collapse = " "),
    "-?[0-9]+\\.?[0-9]*E[+-][0-9]+"
  ))))
  eigenvalues <- eigenvalues[!is.na(eigenvalues) & eigenvalues > 0]

  if (length(eigenvalues) < 2) {
    warning("Fewer than 2 positive eigenvalues found. Returning NA.", call. = FALSE)
    return(NA_real_)
  }

  condn <- max(eigenvalues) / min(eigenvalues)
  if (!is.na(digits)) condn <- round(condn, digits)
  condn
}
