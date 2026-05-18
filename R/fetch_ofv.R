#' Extract the Objective Function Value (OFV) from a NONMEM Listing File
#'
#' Extracts the OFV from a NONMEM `.lst` file, trying several output formats
#' produced by different NONMEM versions and estimation methods:
#'
#' 1. `#OBJV:***...***  <value>  ***...***` — standard NONMEM 7.x banner line
#' 2. `MINIMUM VALUE OF OBJECTIVE FUNCTION  =  <value>` — same-line format
#' 3. `OBJECTIVE FUNCTION VALUE WITHOUT CONSTANT:  <value>` — multi-line FOCE-I
#' 4. `FINAL VALUE OF OBJECTIVE FUNCTION  <value>` — alternative wording
#' 5. `OFV = <value>` — pyDARWIN / workflow tool footer
#'
#' When multiple `#OBJV:` lines are present (multiple estimation steps), the
#' **last** occurrence is returned (final step result).
#'
#' Returns `NA_real_` with a `warning()` if no OFV can be found — never stops.
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

  # Number pattern: handles integer, decimal, and scientific notation
  num_pat <- "-?[0-9]+\\.?[0-9]*(?:[Ee][+-]?[0-9]+)?"

  # ------------------------------------------------------------------ #
  # Strategy 1: #OBJV: banner line
  #
  # Format: " #OBJV:***...***     <value>     ***...***"
  # The number is NOT at the end — it is flanked by asterisk blocks.
  # We must look for the number that appears between the two asterisk groups.
  # Use a lookahead for whitespace followed by asterisks to anchor right side.
  # Take the LAST occurrence for multi-step runs.
  # ------------------------------------------------------------------ #
  objv_idx <- which(stringr::str_detect(lst, "#OBJV:"))
  if (length(objv_idx) > 0) {
    # Take last occurrence
    objv_line <- lst[objv_idx[length(objv_idx)]]
    ofv <- suppressWarnings(as.numeric(trimws(stringr::str_extract(
      objv_line,
      paste0(num_pat, "(?=\\s*\\*)")
    ))))
    if (!is.na(ofv)) {
      if (!is.na(digits)) ofv <- round(ofv, digits)
      return(ofv)
    }
  }

  # ------------------------------------------------------------------ #
  # Strategy 2: "MINIMUM VALUE OF OBJECTIVE FUNCTION" or
  #             "FINAL VALUE OF OBJECTIVE FUNCTION"
  #
  # Sub-case A: number on the same line after "="
  #   e.g. " MINIMUM VALUE OF OBJECTIVE FUNCTION  =   1234.567"
  #
  # Sub-case B: number not on the header line — scan next 10 lines for
  #   "OBJECTIVE FUNCTION VALUE WITHOUT CONSTANT: <value>"
  #   or "OBJECTIVE FUNCTION VALUE: <value>"
  # ------------------------------------------------------------------ #
  min_idx <- which(stringr::str_detect(
    lst,
    "(?:MINIMUM|FINAL) VALUE OF OBJECTIVE FUNCTION"
  ))

  if (length(min_idx) > 0) {
    # Take last occurrence
    header_i <- min_idx[length(min_idx)]
    header_line <- lst[header_i]

    # Sub-case A: "=" present on the same line
    if (stringr::str_detect(header_line, "=")) {
      after_eq <- stringr::str_extract(header_line, paste0("=\\s*(", num_pat, ")"))
      if (!is.na(after_eq)) {
        ofv <- suppressWarnings(as.numeric(trimws(
          stringr::str_extract(after_eq, num_pat)
        )))
        if (!is.na(ofv)) {
          if (!is.na(digits)) ofv <- round(ofv, digits)
          return(ofv)
        }
      }
    }

    # Sub-case B: check the next 10 lines for WITHOUT CONSTANT line
    n <- length(lst)
    for (i in seq.int(header_i + 1, min(header_i + 10, n))) {
      line <- lst[i]
      if (stringr::str_detect(line, "OBJECTIVE FUNCTION VALUE WITHOUT CONSTANT")) {
        ofv <- suppressWarnings(as.numeric(trimws(stringr::str_extract(
          line, paste0(":\\s*(", num_pat, ")")
        ) |> stringr::str_extract(num_pat))))
        if (!is.na(ofv)) {
          if (!is.na(digits)) ofv <- round(ofv, digits)
          return(ofv)
        }
      }
      # Generic "OBJECTIVE FUNCTION VALUE:" fallback
      if (stringr::str_detect(line, "OBJECTIVE FUNCTION VALUE(?! WITH)")) {
        ofv <- suppressWarnings(as.numeric(trimws(stringr::str_extract(
          line, paste0(":\\s*(", num_pat, ")")
        ) |> stringr::str_extract(num_pat))))
        if (!is.na(ofv)) {
          if (!is.na(digits)) ofv <- round(ofv, digits)
          return(ofv)
        }
      }
    }
  }

  # ------------------------------------------------------------------ #
  # Strategy 3: Standalone "OBJECTIVE FUNCTION VALUE WITHOUT CONSTANT:"
  # (appears without a preceding MINIMUM VALUE header in some formats)
  # ------------------------------------------------------------------ #
  woc_idx <- which(stringr::str_detect(
    lst, "OBJECTIVE FUNCTION VALUE WITHOUT CONSTANT"
  ))
  if (length(woc_idx) > 0) {
    woc_line <- lst[woc_idx[length(woc_idx)]]
    ofv <- suppressWarnings(as.numeric(trimws(stringr::str_extract(
      woc_line, paste0("(?<=:)\\s*(", num_pat, ")")
    ) |> stringr::str_extract(num_pat))))
    if (!is.na(ofv)) {
      if (!is.na(digits)) ofv <- round(ofv, digits)
      return(ofv)
    }
  }

  # ------------------------------------------------------------------ #
  # Strategy 4: pyDARWIN / workflow tool footer "OFV = <value>"
  # ------------------------------------------------------------------ #
  footer_lines <- lst[stringr::str_detect(lst, "^OFV\\s*=\\s*")]
  if (length(footer_lines) > 0) {
    ofv <- suppressWarnings(
      as.numeric(trimws(stringr::str_extract(footer_lines[1], num_pat)))
    )
    if (!is.na(ofv)) {
      if (!is.na(digits)) ofv <- round(ofv, digits)
      return(ofv)
    }
  }

  # Distinguish "missing because no $EST was performed" (legitimate NA, no
  # warning) from "expected but unparseable" (genuine bug, warn).
  if (!.has_estimation_step(lst)) {
    return(NA_real_)
  }

  warning("OFV not found in lst file. Returning NA.", call. = FALSE)
  NA_real_
}
