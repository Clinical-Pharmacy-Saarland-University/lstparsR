#' Extract the Condition Number from a NONMEM Listing File
#'
#' Computes the condition number of the correlation matrix of parameter estimates
#' as the ratio of the largest to smallest eigenvalue. A condition number above
#' 1000 typically indicates numerical difficulties in parameter estimation.
#'
#' Returns `NA` gracefully when no covariance step was run or when eigenvalues
#' were not printed (`EIGENVLS. PRINTED: NO`).
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

  # User opted out of printing eigenvalues (EIGENVLS. PRINTED: NO).
  # Covariance step ran, but eigenvalues are legitimately absent.
  if (.eigenvalues_suppressed(lst)) {
    return(NA_real_)
  }

  # Eigenvalue number pattern (scientific notation, possibly with leading sign)
  eigen_num_pat <- "-?[0-9]+\\.?[0-9]*[Ee][+-][0-9]+"

  # ------------------------------------------------------------------ #
  # Find the eigenvalue section header.
  # Strip leading Fortran CC character (0 or 1) before matching.
  # Accept multiple phrasings:
  #   "EIGENVALUES OF COR MATRIX OF ESTIMATE"
  #   "EIGENVALUES OF THE CORRELATION MATRIX OF ESTIMATES"
  # ------------------------------------------------------------------ #
  stripped <- sub("^[01]", " ", lst)
  eigen_header <- which(stringr::str_detect(
    stripped,
    stringr::regex("EIGENVALUE", ignore_case = TRUE)
  ) & stringr::str_detect(
    stripped,
    stringr::regex("MATRIX.*ESTIMATE", ignore_case = TRUE)
  ))

  if (length(eigen_header) == 0) {
    warning("Eigenvalue section not found. Returning NA.", call. = FALSE)
    return(NA_real_)
  }

  start <- eigen_header[1]
  n     <- length(lst)

  # ------------------------------------------------------------------ #
  # Scan forward from the line AFTER the header.
  # Skip:
  #   - asterisk lines (page borders)
  #   - blank / whitespace-only lines
  #   - integer-only index lines (e.g. "  1  2  3  4 ...")
  # Collect all lines that contain at least one scientific-notation number.
  # Stop when we hit a non-blank line with no numbers (section boundary).
  # ------------------------------------------------------------------ #
  eigen_lines  <- character(0)
  found_values <- FALSE

  for (i in seq.int(start + 1, min(start + 40, n))) {
    line    <- lst[i]
    trimmed <- stringr::str_trim(line)

    # Skip blank lines (before or between value blocks)
    if (nchar(trimmed) == 0) {
      if (found_values) break   # blank line after values = end of block
      next
    }

    # Skip asterisk-only lines (section borders)
    if (stringr::str_detect(trimmed, "^\\*+$")) next

    # Skip lines that are entirely within the section header box
    # (contain asterisks as padding around text)
    if (stringr::str_detect(trimmed, "^\\*{5,}")) next

    # Check for scientific notation numbers
    if (stringr::str_detect(line, eigen_num_pat)) {
      eigen_lines  <- c(eigen_lines, line)
      found_values <- TRUE
    } else if (found_values) {
      # Non-blank, non-number line after we already collected values → stop
      break
    }
    # Non-blank, non-number line before values: could be integer index line —
    # just skip and keep looking (found_values remains FALSE)
  }

  if (length(eigen_lines) == 0) {
    warning("Could not extract eigenvalues. Returning NA.", call. = FALSE)
    return(NA_real_)
  }

  # Extract all eigenvalues
  eigenvalues <- suppressWarnings(as.numeric(unlist(stringr::str_extract_all(
    paste(eigen_lines, collapse = " "),
    eigen_num_pat
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
