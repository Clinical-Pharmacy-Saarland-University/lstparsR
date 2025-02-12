#' Extract Objective Function Value (OFV) from a NONMEM lst file
#'
#' This function extracts the Objective Function Value (OFV) from a NONMEM `.lst` file.
#' It looks for the line containing `#OBJV:`
#' and returns the numeric value found on that line.
#' The value can be optionally rounded to a specified number of digits.
#'
#' @param lst A character vector representing the lines of a NONMEM `.lst` file.
#' @param ofv_digits An optional integer specifying the number of digits to round the OFV.
#' Use `NA` for no rounding.
#' @return A numeric value representing the extracted OFV. If the `#OBJV:` line is not found, an error is raised.
#' If the OFV could not be extracted, NA is returned.
#' @details The function uses regular expressions to locate and extract the OFV.
#' If multiple `#OBJV:` lines are present,
#' only the first one is processed.
#' @export
#' @examples
#' # Example 1: Extract OFV with no rounding
#' lst <- read_lst_file("path/to/full_cov.lst")
#' fetch_ofv(lst)
#'
#' # Example 2: Extract OFV and round to 2 digits
#' fetch_ofv(lst, ofv_digits = 2)
fetch_condn <- function(lst, condn_digits = NA) {
  checkmate::assert_class(lst, "lst")
  checkmate::assert_number(condn_digits, lower = 0, na.ok = TRUE)


  start_line <- grep("EIGENVALUES OF COR MATRIX OF ESTIMATE", lst)
  
  if (length(start_line) == 0) {
    stop("Eigenvalue section not found.")
  }
  
  # Extract the lines following the matched line until the next block of asterisks (end of eigenvalue section)
  eigen_lines <- lst[(start_line + 7):(start_line + 9)]
  
  # Combine lines and extract numbers in exponential format
  eigenvalues <- as.numeric(unlist(regmatches(eigen_lines, gregexpr("[0-9.]+E[+-][0-9]+", eigen_lines))))
  
  # Calculate condition number
  condn <- max(eigenvalues) / min(eigenvalues[eigenvalues > 0])
  
  # round the condn value to the specified number of digits
  if (!is.na(condn_digits) && !is.na(condn)) {
    condn <- round(condn, condn_digits)
  }
  
  return(condn)
}
