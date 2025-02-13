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
  upper_delimiter_id <- NA
  lower_delimiter_id <- NA
  upper_delimiter_val <- NA
  lower_delimiter_val <- NA
  
  # Loop through each line and find the first block that matches the criteria
  for (i in 1:length(lst)) {
    # Check for the specified conditions:
    # 1. First line is "1"
    # 2. Second line is a line of 120 asterisks
    # 3. Fourth line contains "FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION"
    # 4. Fifth line contains "FINAL PARAMETER ESTIMATE"
    if (lst[i] == "1" &&
        str_trim(lst[i + 1]) == str_dup("*", 120) &&
        str_detect(lst[i + 3], string1) &&
        str_detect(lst[i + 4], string2)) {
      
      # Set the upper delimiter of ids (13th line after the start of the block)
      upper_delimiter_id <- i + 13
      
      # Find the lower delimiter
      for (j in (upper_delimiter_id + 1):length(lst)) {
        if (lst[j] == "" || lst[j] == "1") {
          lower_delimiter_id <- j - 1
          break
        }
      }
      
      # Set the upper delimiter of ids (13th line after the start of the block)
      upper_delimiter_val <- lower_delimiter_id + 3
      
      # Find the lower delimiter
      for (j in (upper_delimiter_val + 1):length(lst)) {
        if (lst[j] == "" || lst[j] == "1") {
          lower_delimiter_val <- j - 1
          break
        }
      }
      
      # Exit the loop after finding the first matching block
      break
    }
  }
  
  # Check if delimiters are valid
  if (is.na(upper_delimiter_id) || is.na(lower_delimiter_id) || upper_delimiter_id > lower_delimiter_id || is.na(upper_delimiter_val) || is.na(lower_delimiter_val) || upper_delimiter_val > lower_delimiter_val) {
    stop("Invalid delimiters provided.")
  }
  
  # Extract the ids
  lines_of_ids <- lst[upper_delimiter_id:lower_delimiter_id]
  
  # Replace single spaces between characters or numbers with underscores
  lines_of_ids_cleaned <- gsub("(?<=[A-Za-z0-9]) (?=[A-Za-z0-9])", "_", lines_of_ids, perl = TRUE)
  
  # Split the modified lines by remaining spaces and combine into a single vector
  ids_vector <- unlist(strsplit(lines_of_ids_cleaned, "\\s+"))
  
  # remove empty strings
  ids_vector <- ids_vector[ids_vector != ""]
  
  
  # Extract the values
  lines_of_val <- lst[upper_delimiter_val:lower_delimiter_val]
  
  # Split the modified lines by remaining spaces and combine into a single vector
  val_vector <- unlist(str_extract_all(lines_of_val, "-?\\d+\\.?\\d*(E[+-]?\\d+)?"))
  
  
  # Convert to numeric vector
  val_vector <- as.numeric(val_vector)
  
  # collect results
  results <- list(block = list(title = paste0(string1, " - ", string2))
                  , delims_id = list(upper_delimiter_id = upper_delimiter_id
                               , lower_delimiter_id = lower_delimiter_id)
                  , delims_val = list(upper_delimiter_val = upper_delimiter_val
                                     , lower_delimiter_val = lower_delimiter_val)
                  , ids = ids_vector
                  , values = val_vector
                  , df = data.frame(id = ids_vector, value = val_vector)
                  )
  
  # Return the numeric vector
  return(results)
}

string1 <- "FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION"
string2 <- "FINAL PARAMETER ESTIMATE"

# Get delims
results1 <- f_get_block_values(lst, "FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION", "FINAL PARAMETER ESTIMATE")

results2 <- f_get_block_values(lst, "FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION", "STANDARD ERROR OF ESTIMATE")


