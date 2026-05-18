# ============================================================
# Internal utilities for lstparsR
# Not exported. Prefix all names with a dot.
# ============================================================

# ------------------------------------------------------------------
# Input validation
# ------------------------------------------------------------------

#' @noRd
.assert_lst <- function(x, arg_name = "lst") {
  if (!inherits(x, "lst")) {
    stop(
      sprintf(
        "`%s` must be an object of class 'lst'. Use read_lst_file() to create one.",
        arg_name
      ),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

# ------------------------------------------------------------------
# Estimation method detection
# ------------------------------------------------------------------

# Known NONMEM estimation method strings as they appear in .lst headers.
# Order matters: check more specific strings first.
.ESTIMATION_METHODS <- c(
  "FIRST ORDER CONDITIONAL ESTIMATION WITH INTERACTION",
  "FIRST ORDER CONDITIONAL ESTIMATION",
  "FIRST ORDER",
  "STOCHASTIC APPROXIMATION EXPECTATION-MAXIMIZATION",
  "IMPORTANCE SAMPLING ASSISTED BY MODE A POSTERIORI",
  "IMPORTANCE SAMPLING",
  "MARKOV CHAIN MONTE CARLO BAYESIAN ANALYSIS"
)

#' @noRd
.get_estimation_method <- function(lst) {
  for (method in .ESTIMATION_METHODS) {
    if (any(stringr::str_detect(lst, stringr::fixed(method)))) {
      return(method)
    }
  }
  stop(
    "Could not detect a known estimation method in this lst file.\n",
    "Supported: FOCE-I, FOCE, FO, SAEM, IMP, IMPMAP, Bayesian.",
    call. = FALSE
  )
}

# ------------------------------------------------------------------
# Covariance step detection
# ------------------------------------------------------------------

#' @noRd
.has_covariance_step <- function(lst) {
  any(stringr::str_detect(lst, stringr::fixed("STANDARD ERROR OF ESTIMATE")))
}

# ------------------------------------------------------------------
# Estimation-step detection
# ------------------------------------------------------------------
#
# Returns TRUE if any marker indicates that NONMEM performed an
# estimation step ($EST). Used to suppress the "OFV not found"
# warning for $SIMULATION-only runs, where no OFV is ever produced.
#
#' @noRd
.has_estimation_step <- function(lst) {
  markers <- c(
    "#OBJT:", "#OBJV:", "#METH:",
    "MINIMIZATION SUCCESSFUL", "MINIMIZATION TERMINATED",
    "MINIMUM VALUE OF OBJECTIVE FUNCTION",
    "OBJECTIVE FUNCTION EVALUATIONS",
    "BURN-IN ITERATIONS"
  )
  for (m in markers) {
    if (any(stringr::str_detect(lst, stringr::fixed(m)))) return(TRUE)
  }
  FALSE
}

# ------------------------------------------------------------------
# Eigenvalue-printing detection
# ------------------------------------------------------------------
#
# Returns TRUE if the lst explicitly states "EIGENVLS. PRINTED: NO",
# meaning the user opted out of printing eigenvalues even though the
# covariance step ran. Used to suppress the "Eigenvalue section not
# found" warning in that legitimate case.
#
#' @noRd
.eigenvalues_suppressed <- function(lst) {
  any(stringr::str_detect(
    lst,
    stringr::regex("EIGENVLS\\.\\s*PRINTED\\s*:\\s*NO", ignore_case = TRUE)
  ))
}

# ------------------------------------------------------------------
# Block header locator
# ------------------------------------------------------------------
#
# Finds the line index of a section page header in the lst file.
# A section page starts with a line containing only "1", followed by
# a line of >= 80 asterisks, then two content lines, then the title lines.
#
# Returns the line index i of the "1" line for the FIRST page that
# matches both `method_str` (estimation method) and `section_str`
# (e.g. "FINAL PARAMETER ESTIMATE" or "STANDARD ERROR OF ESTIMATE").
# Returns NA_integer_ if not found.
#
#' @noRd
.find_section_page <- function(lst, method_str, section_str) {
  n <- length(lst)
  for (i in seq_len(n - 5)) {
    if (
      lst[i] == "1" &&
      stringr::str_detect(stringr::str_trim(lst[i + 1]), "^\\*{80,}$") &&
      stringr::str_detect(lst[i + 3], stringr::fixed(method_str)) &&
      stringr::str_detect(lst[i + 4], stringr::fixed(section_str))
    ) {
      return(i)
    }
  }
  NA_integer_
}

# ------------------------------------------------------------------
# VECTOR block parser
# ------------------------------------------------------------------
#
# Parses a VECTOR-type block (used for THETA).
# Starting from `page_start` (the "1" line), finds `subheader_str`
# (e.g. "THETA - VECTOR OF FIXED EFFECTS PARAMETERS"), then extracts:
#   - The ID row (column labels like TH 1, TH 2, ...)
#   - The value row(s) that follow
#
# Returns a data.frame with columns `id` (character) and `value` (numeric),
# or NULL on failure.
#
#' @noRd
.parse_vector_block <- function(lst, page_start, subheader_str) {
  n <- length(lst)

  # Find subheader line after the page start
  subheader_line <- NA_integer_
  for (j in seq.int(page_start + 5, min(page_start + 200, n))) {
    if (stringr::str_detect(lst[j], stringr::fixed(subheader_str))) {
      subheader_line <- j
      break
    }
  }
  if (is.na(subheader_line)) return(NULL)

  # Collect all ID lines (may span multiple lines, e.g. TH 1..TH12 on line 1,

  # TH13..TH20 on line 2). ID lines are non-blank, contain alpha+digit tokens,
  # and appear before the blank line that separates IDs from values.
  id_lines <- character(0)
  id_start <- NA_integer_
  for (j in seq.int(subheader_line + 1, min(subheader_line + 10, n))) {
    trimmed <- stringr::str_trim(lst[j])
    if (nchar(trimmed) > 0) {
      id_start <- j
      break
    }
  }
  if (is.na(id_start)) return(NULL)

  # Gather contiguous non-blank ID lines (stop at blank, value line, or

  # duplicate — if a line starts with the same first token as the first line,
  # it's a duplicate row, not a continuation).
  first_token <- NULL
  for (j in seq.int(id_start, min(id_start + 10, n))) {
    trimmed <- stringr::str_trim(lst[j])
    if (nchar(trimmed) == 0) break
    # If a line has scientific notation, it's a value line, not an ID line
    if (stringr::str_detect(trimmed, "[0-9]E[+-]")) break
    # Check for duplicate: does this line start with the same token as the first?
    line_clean <- gsub("(?<=[A-Za-z0-9]) (?=[A-Za-z0-9])", "_", trimmed, perl = TRUE)
    line_tokens <- unlist(stringr::str_split(line_clean, "\\s+"))
    line_tokens <- line_tokens[nchar(line_tokens) > 0]
    if (is.null(first_token)) {
      first_token <- line_tokens[1]
    } else if (line_tokens[1] == first_token) {
      # Duplicate line — stop collecting
      break
    }
    id_lines <- c(id_lines, lst[j])
  }
  if (length(id_lines) == 0) return(NULL)

  # Parse IDs: multi-word tokens like "TH 1" become "TH_1"
  raw_ids <- paste(id_lines, collapse = " ")
  raw_ids <- stringr::str_trim(raw_ids)
  # Replace single space between word chars with underscore
  clean_ids <- gsub("(?<=[A-Za-z0-9]) (?=[A-Za-z0-9])", "_", raw_ids, perl = TRUE)
  ids <- unlist(stringr::str_split(clean_ids, "\\s+"))
  ids <- ids[nchar(ids) > 0]

  # Scan forward to find the first line containing scientific-notation values
  val_start <- NA_integer_
  for (j in seq.int(id_start, min(id_start + 20, n))) {
    trimmed <- stringr::str_trim(lst[j])
    if (nchar(trimmed) > 0 &&
        stringr::str_detect(trimmed, "[0-9]E[+-]")) {
      val_start <- j
      break
    }
  }
  if (is.na(val_start)) return(NULL)

  # Collect value lines: all contiguous lines with scientific notation numbers
  val_lines <- character(0)
  for (j in seq.int(val_start, min(val_start + 20, n))) {
    line <- lst[j]
    trimmed <- stringr::str_trim(line)
    if (trimmed == "" || trimmed == "1") break
    # Only include lines that contain scientific notation
    if (stringr::str_detect(trimmed, "[0-9]E[+-]")) {
      val_lines <- c(val_lines, line)
    } else {
      break
    }
  }

  # Extract all numbers (scientific notation)
  nums_str <- unlist(stringr::str_extract_all(
    paste(val_lines, collapse = " "),
    "-?[0-9]+\\.?[0-9]*E[+-][0-9]+"
  ))
  values <- suppressWarnings(as.numeric(nums_str))
  values <- values[!is.na(values)]

  if (length(ids) == 0 || length(values) == 0) return(NULL)

  # Handle duplicate rows: if values is a multiple of ids, take first set
  if (length(values) > length(ids) && length(values) %% length(ids) == 0) {
    values <- values[seq_len(length(ids))]
  }

  if (length(ids) != length(values)) {
    # Length mismatch: pad with NA
    warning(sprintf(
      ".parse_vector_block: %d IDs but %d values for '%s'. Padding with NA.",
      length(ids), length(values), subheader_str
    ))
    len <- max(length(ids), length(values))
    length(ids)    <- len
    length(values) <- len
  }

  data.frame(id = ids, value = values, stringsAsFactors = FALSE)
}

# ------------------------------------------------------------------
# MATRIX block parser (diagonal only)
# ------------------------------------------------------------------
#
# Parses a MATRIX-type block (used for OMEGA/SIGMA).
# Finds `subheader_str` after `page_start`, then for each named parameter
# (lines like " ETA1" followed by "+  value  ...") extracts the diagonal
# value (last non-"........." value on the + line(s) for that parameter).
#
# Returns a data.frame with columns `id` (character) and `value` (numeric),
# or NULL on failure. ".........." entries become NA_real_.
#
#' @noRd
.parse_matrix_block <- function(lst, page_start, subheader_str) {
  n <- length(lst)

  # Find subheader
  subheader_line <- NA_integer_
  for (j in seq.int(page_start + 5, min(page_start + 200, n))) {
    if (stringr::str_detect(lst[j], stringr::fixed(subheader_str))) {
      subheader_line <- j
      break
    }
  }
  if (is.na(subheader_line)) return(NULL)

  # Parse the matrix: scan for lines like " ETA1" (name) followed by "+" line(s)
  ids    <- character(0)
  values <- numeric(0)

  # Determine the end of this block: next page separator or new section
  end_search <- min(subheader_line + 300, n)

  j <- subheader_line + 1
  while (j <= end_search) {
    line <- lst[j]
    trimmed <- stringr::str_trim(line)

    # A parameter name line: starts with optional space, then an ID like ETA1 or EPS1
    if (stringr::str_detect(trimmed, "^(ETA|EPS)[0-9]+$")) {
      param_name <- trimmed
      # Collect all immediately following "+" lines
      plus_lines <- character(0)
      k <- j + 1
      while (k <= end_search && stringr::str_detect(lst[k], "^\\+")) {
        plus_lines <- c(plus_lines, lst[k])
        k <- k + 1
      }

      if (length(plus_lines) > 0) {
        # Combine all + lines and extract the last non-"........." token
        combined <- paste(plus_lines, collapse = " ")
        # Remove the leading "+" characters
        combined <- gsub("\\+", " ", combined)
        # Split into tokens
        tokens <- unlist(stringr::str_split(stringr::str_trim(combined), "\\s+"))
        tokens <- tokens[nchar(tokens) > 0]

        # Find last token that is not dots (.........)
        last_val <- NA_real_
        for (tok in rev(tokens)) {
          if (!stringr::str_detect(tok, "^\\.+$")) {
            numeric_tok <- suppressWarnings(as.numeric(tok))
            if (!is.na(numeric_tok)) {
              last_val <- numeric_tok
              break
            }
          }
        }

        ids    <- c(ids, param_name)
        values <- c(values, last_val)
        j <- k  # skip past the + lines
        next
      }
    }

    # Stop if we hit a new page header
    if (trimmed == "1" && j + 1 <= n &&
        stringr::str_detect(stringr::str_trim(lst[j + 1]), "^\\*{80,}$")) {
      break
    }

    # Stop if we hit a new section (different subheader)
    if (stringr::str_detect(trimmed, "^(OMEGA|SIGMA|THETA).*\\*+$") &&
        !stringr::str_detect(trimmed, stringr::fixed(subheader_str))) {
      break
    }

    j <- j + 1
  }

  if (length(ids) == 0) return(NULL)
  data.frame(id = ids, value = values, stringsAsFactors = FALSE)
}

# ------------------------------------------------------------------
# Shrinkage parser
# ------------------------------------------------------------------
#
# Internal: parse shrinkage lines from lst
# type: "ETASHRINKSD" or "EPSSHRINKSD"
# Returns numeric vector or NULL
#
#' @noRd
.parse_shrinkage <- function(lst, type = "ETASHRINKSD") {
  pattern <- paste0(type, ".*?=")
  lines   <- lst[stringr::str_detect(lst, pattern)]
  if (length(lines) == 0) return(NULL)

  # Take the last occurrence (final estimation step)
  line <- lines[length(lines)]

  # Extract all numbers in scientific notation
  nums <- suppressWarnings(as.numeric(unlist(stringr::str_extract_all(
    line, "-?[0-9]+\\.?[0-9]*E[+-][0-9]+"
  ))))
  nums <- nums[!is.na(nums)]
  if (length(nums) == 0) return(NULL)
  nums
}
