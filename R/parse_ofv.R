#' Extract Objective Function Value (OFV) from a NONMEM lst file
#'
#' This function extracts the Objective Function Value (OFV) from a NONMEM `.lst` file. It looks for the line containing `#OBJV:` 
#' and returns the numeric value found on that line. The value can be optionally rounded to a specified number of digits.
#'
#' @param lst A character vector representing the lines of a NONMEM `.lst` file.
#' @param ofv_digits An optional integer specifying the number of digits to round the OFV. Use `NA` for no rounding.
#' @return A numeric value representing the extracted OFV. If the `#OBJV:` line is not found, returns `NA`.
#' @details The function uses regular expressions to locate and extract the OFV. If multiple `#OBJV:` lines are present, 
#' only the first one is processed.
#' @seealso \code{\link[checkmate]{assert_class}}, \code{\link[base]{round}}
#' @export
#' @examples
#' # Example 1: Extract OFV with no rounding
#' lst_lines <- readLines("path/to/full_cov.lst")
#' fetch_ofv(lst_lines)
#'
#' # Example 2: Extract OFV and round to 2 digits
#' fetch_ofv(lst_lines, ofv_digits = 2)
fetch_ofv <- function(lst, ofv_digits = NA) {
  checkmate::assert_class(lst, "lst")
  checkmate::assert_number(ofv_digits, lower = 0, na.ok = TRUE)
  
  
  # find the line containing "#OBJV:"
  ofv_line <- c(NA)
  ofv_line <- grep("#OBJV:", lst, value = TRUE)
  
  # if (is.na(ofv_line)) {
  #   print("OFV line not found")
  #   break
  # }
  
  # Extract the numeric value after "#OBJV:" using a regular expression
  ofv <- as.numeric(sub(".*#OBJV:.*?([0-9]+\\.[0-9]+).*", "\\1", ofv_line))
  
  # round the OFV value to the specified number of digits
  if (!is.na(ofv_digits)) {
    ofv <- round(ofv, ofv_digits)
  }
  
  return(ofv)
}


