#' Extract the Objective Function Value (OFV) from a NONMEM Listing File
#'
#' Extracts the OFV reported on the `#OBJV:` line of a NONMEM `.lst` file.
#' For failed or early-terminated runs where `#OBJV:` is absent, the function
#' falls back to the workflow footer (`OFV = ...`) and returns `NA` with a
#' warning if neither is found.
#'
#' @param lst    An object of class `"lst"` from [read_lst_file()].
#' @param digits Integer or `NA`. Rounding for the OFV. Default `NA`.
#'
#' @return A single numeric value (the OFV), or `NA_real_` if not found.
#'
#' @export
#'
#' @examples
#' path <- system.file("testdata", "full_cov.lst", package = "lstparsR")
#' lst  <- read_lst_file(path)
#' fetch_ofv(lst)
fetch_ofv <- function(lst, digits = NA) {
  .assert_lst(lst)
  checkmate::assert_number(digits, lower = 0, na.ok = TRUE)

  # Try #OBJV: line first (standard NONMEM output)
  objv_lines <- lst[stringr::str_detect(lst, "#OBJV:")]
  if (length(objv_lines) > 0) {
    objv_line <- objv_lines[1]
    ofv <- suppressWarnings(
      as.numeric(stringr::str_extract(
        objv_line, "-?[0-9]+\\.?[0-9]*(?:E[+-]?[0-9]+)?$"
      ))
    )
    if (!is.na(ofv)) {
      if (!is.na(digits)) ofv <- round(ofv, digits)
      return(ofv)
    }
  }

  # Fallback: pyDARWIN / workflow tool footer line "OFV = <value>"
  footer_lines <- lst[stringr::str_detect(lst, "^OFV\\s*=\\s*")]
  if (length(footer_lines) > 0) {
    ofv <- suppressWarnings(
      as.numeric(stringr::str_extract(footer_lines[1], "-?[0-9]+\\.?[0-9]*"))
    )
    if (!is.na(ofv)) {
      if (!is.na(digits)) ofv <- round(ofv, digits)
      return(ofv)
    }
  }

  warning("OFV not found in lst file. Returning NA.", call. = FALSE)
  NA_real_
}
