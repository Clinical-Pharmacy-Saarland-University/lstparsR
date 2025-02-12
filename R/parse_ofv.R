fetch_ofv <- function(lst, ofv_digits = NA) {
  checkmate::assert_class(lst, "lst")
  checkmate::assert_number(ofv_digits, lower = 0, na.ok = TRUE)
  
  
  # find the line containing "#OBJV:"
  ofv_line <- c(NA)
  ofv_line <- grep("#OBJV:", lst, value = TRUE)
  
  # if (is.na(ofv_line)) {
  #   print("OFV line not found")
  # }
  
  # Extract the numeric value after "#OBJV:" using a regular expression
  ofv <- as.numeric(sub(".*#OBJV:.*?([0-9]+\\.[0-9]+).*", "\\1", ofv_line))
  
  # round the OFV value to the specified number of digits
  if (!is.na(ofv_digits)) {
    ofv <- round(ofv, ofv_digits)
  }
  
  return(ofv)
}


