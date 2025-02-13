devtools::load_all()

# fetch_objfun()
# OBJV:********************************************     8986.318       **************************************************



lst <- read_lst_file("./tests/lsts/full_cov.lst")


lst <- read_lst_file("../tests/lsts/theta_no_cov.lst")


summary(lst)

fetch_thetas(lst)
fetch_etas(lst)
fetch_condn(lst)

fetch_ofv(lst, 3)




f_get_block_values <- function(file, string1, string2) {
  # Read the file into a character vector
  lst <- file
  
  # Initialize variables for upper and lower delimiters
  upper_delimiter <- NA
  lower_delimiter <- NA
  
  # Loop through each line and find the first block that matches the criteria
  for (i in 1:(length(lst) - 16)) {
    # Check for the specified conditions:
    # 1. First line is "1"
    # 2. Second line is a line of 120 asterisks
    # 3. Fourth line contains "FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION"
    # 4. Fifth line contains "FINAL PARAMETER ESTIMATE"
    if (lst[i] == "1" &&
        str_trim(lst[i + 1]) == str_dup("*", 120) &&
        str_detect(lst[i + 3], string1) &&
        str_detect(lst[i + 4], string2)) {
      
      # Set the upper delimiter (17th line after the start of the block)
      upper_delimiter <- i + 16
      
      # Find the lower delimiter
      for (j in (upper_delimiter + 1):length(lst)) {
        if (lst[j] == "" || lst[j] == "1") {
          lower_delimiter <- j - 1
          break
        }
      }
      
      # Exit the loop after finding the first matching block
      break
    }
  }
  
  # Check if delimiters are valid
  if (is.na(upper_delimiter) || is.na(lower_delimiter) || upper_delimiter > lower_delimiter) {
    stop("Invalid delimiters provided.")
  }
  
  # Extract the lines of interest
  lines_of_interest <- lst[upper_delimiter:lower_delimiter]
  
  # Extract all numeric values from the lines using regular expressions
  numeric_values <- unlist(str_extract_all(lines_of_interest, "-?\\d+\\.?\\d*(E[+-]?\\d+)?"))
  
  # Convert to numeric vector
  numeric_vector <- as.numeric(numeric_values)
  
  # collect results
  results <- list(block= list(title = paste0(string1, " - ", string2))
                  , delims= list(upper_delimiter = upper_delimiter
                               , lower_delimiter = lower_delimiter)
                  , values = numeric_vector
                  )
  
  # Return the numeric vector
  return(results)
}



# Get delims
results1 <- f_get_block_values(lst, "FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION", "FINAL PARAMETER ESTIMATE")

results2 <- f_get_block_values(lst, "FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION", "STANDARD ERROR OF ESTIMATE")


