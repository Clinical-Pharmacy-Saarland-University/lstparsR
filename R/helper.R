# extracts block of values from a lst file
# 1. file = character vector of the lst file
# 2. string1 = first line of block header
# 3. string2 = second line of block header
.f_get_block_values <- function(file, string1, string2) {
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
      stringr::str_trim(lst[i + 1]) == stringr::str_dup("*", 120) &&
      stringr::str_detect(lst[i + 3], string1) &&
      stringr::str_detect(lst[i + 4], string2)) {
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
  val_vector <- unlist(stringr::str_extract_all(lines_of_val, "-?\\d+\\.?\\d*(E[+-]?\\d+)?"))


  # Convert to numeric vector
  val_vector <- as.numeric(val_vector)

  # collect results
  results <- list(
    block = list(title = paste0(string1, " - ", string2)),
    delims_id = list(
      upper_delimiter_id = upper_delimiter_id,
      lower_delimiter_id = lower_delimiter_id
    ),
    delims_val = list(
      upper_delimiter_val = upper_delimiter_val,
      lower_delimiter_val = lower_delimiter_val
    ),
    ids = ids_vector,
    values = val_vector,
    df = data.frame(id = ids_vector, value = val_vector)
  )

  # Return the numeric vector
  return(results)
}

# safe version of .f_get_block_values
.safe_f_get_block_values <- purrr::safely(.f_get_block_values)
