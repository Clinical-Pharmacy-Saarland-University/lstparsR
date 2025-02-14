# extracts block of values from a lst file
# 1. file = character vector of the lst file
# 2. header1 = first line of block header
# 3. header2 = second line of block header
# 4. subheader = subheader to find the start of the block of interest
.f_get_block_values <- function(file, header1, header2, subheader) {
  # Read the file into a character vector
  lst <- file

  # Initialize variables for upper and lower delimiters
  upper_delimiter_id <- NA
  lower_delimiter_id <- NA
  upper_delimiter_val <- NA
  lower_delimiter_val <- NA

  # Get the type of return
  if (stringr::str_detect(subheader, "MATRIX")) {
    data_type <- "MATRIX"
  } else if (stringr::str_detect(subheader, "VECTOR")) {
    data_type <- "VECTOR"
  } else {
    data_type <- "UNKNOWN"
  }

  # Return type
  if (data_type == "UNKNOWN") {
    stop("Unknown return type.")
  }

  # Loop through each line and find the first block that matches the criteria
  for (i in 1:length(lst)) {
    # Check for the specified conditions:
    # 1. First line is "1"
    # 2. Second line is a line of 120 asterisks
    # 3. Fourth line contains "FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION"
    # 4. Fifth line contains "FINAL PARAMETER ESTIMATE"
    if (lst[i] == "1" &&
      stringr::str_trim(lst[i + 1]) == stringr::str_dup("*", 120) &&
      stringr::str_detect(lst[i + 3], header1) &&
      stringr::str_detect(lst[i + 4], header2)) {
      # Find the line index of subheader of interest
      for (j in (i + 6):length(lst)) {
        if (stringr::str_detect(lst[j], subheader)) {
          delimiter_subhead <- j
          break
        }
      }

      # Set the upper delimiter as the subheading line index + 3
      upper_delimiter_id <- delimiter_subhead + 3

      # Find the lower delimiter
      for (k in (upper_delimiter_id + 1):length(lst)) {
        if (lst[k] == "" || lst[k] == " " || lst[k] == "1") {
          lower_delimiter_id <- k - 1
          break
        }
      }

      # Set the upper delimiter of ids
      upper_delimiter_val <- lower_delimiter_id + 3

      # Find the lower delimiter
      for (l in (upper_delimiter_val + 1):length(lst)) {
        if (lst[l] == "" || lst[l] == "1") {
          lower_delimiter_val <- l - 1
          break
        }
      }

      # Exit the loop after finding the first matching block
      break
    }
  }

  # Check if delimiters are valid
  if (is.na(delimiter_subhead) || is.na(upper_delimiter_id) || is.na(lower_delimiter_id) ||
    upper_delimiter_id > lower_delimiter_id || is.na(upper_delimiter_val) ||
    is.na(lower_delimiter_val) || upper_delimiter_val > lower_delimiter_val) {
    stop("Invalid delimiters provided.")
  }

  # Extract the ids
  lines_of_ids <- lst[upper_delimiter_id:lower_delimiter_id]

  # Replace single spaces between characters or numbers with underscores
  lines_of_ids_cleaned <- gsub("(?<=[A-Za-z0-9]) (?=[A-Za-z0-9])", "_", lines_of_ids, perl = TRUE)

  # Split the modified lines by remaining spaces and combine into a single vector
  ids <- unlist(strsplit(lines_of_ids_cleaned, "\\s+"))

  # remove empty strings
  ids <- ids[ids != ""]

  # Extract the values
  lines_of_val <- lst[upper_delimiter_val:lower_delimiter_val]

  if (data_type == "VECTOR") {
    # Split the modified lines by remaining spaces and combine into a single vector
    val_vector <- unlist(stringr::str_extract_all(lines_of_val, "-?\\d+\\.?\\d*(E[+-]?\\d+)?"))

    # Convert to numeric vector
    val_vector <- as.numeric(val_vector)

    # Collect reults
    val_result <- val_vector
    df_result <- data.frame(id = ids, value = val_vector)
  } else if (data_type == "MATRIX") {
    # Initialize an empty vector to store diagonal values
    val_matrix <- c()

    # Iterate through the lines of values
    for (i in seq(1, length(lines_of_val), by = 3)) { # Every third line contains values
      value_line <- lines_of_val[i] # Get the line with values after ETA

      # Extract all values including "........."
      values <- stringr::str_split(value_line, "\\s+")[[1]]

      # Get the last non-empty element
      last_value <- tail(values[values != ""], 1)

      # Check if it's a numeric value or "........."
      if (last_value == ".........") {
        val_matrix <- c(val_matrix, NA) # Add NA for "........."
      } else {
        numeric_value <- as.numeric(last_value)
        val_matrix <- c(val_matrix, numeric_value) # Add the numeric value
      }
    }

    # Collect results
    val_result <- val_matrix
    df_result <- data.frame(id = ids, value = val_matrix)
  } else {
    stop("Unknown data type.")
  }


  # collect results
  results <- list(
    block = list(title = paste0(header1, " - ", header2)),
    delims_id = list(
      upper_delimiter_id = upper_delimiter_id,
      lower_delimiter_id = lower_delimiter_id
    ),
    delims_val = list(
      upper_delimiter_val = upper_delimiter_val,
      lower_delimiter_val = lower_delimiter_val
    ),
    ids = ids,
    values = val_result,
    df = df_result
  )

  # Return the numeric vector
  return(results)
}

# safe version of .f_get_block_values
.safe_f_get_block_values <- purrr::safely(.f_get_block_values)
