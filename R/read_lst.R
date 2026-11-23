#' Read a NONMEM Listing File
#'
#' Reads a NONMEM `.lst` output file into memory as a character vector
#' with class `"lst"` for use by the `fetch_*` family of functions.
#'
#' Listings are plain text. Lines that are not valid UTF-8, as written by
#' NONMEM on Windows when a problem title, path or data set name holds
#' accented characters, are read as Latin-1 and converted to UTF-8.
#'
#' @param path Character string. Path to the `.lst` file.
#'
#' @return A character vector of class `"lst"`, where each element is one
#'   line of the file. `print()` shows the number of lines; `summary()`
#'   reports the estimation method of the final step and whether a
#'   covariance step is present.
#'
#' @export
#'
#' @examples
#' path <- system.file("extdata", "lst", "s01_focei_cov_success.lst",
#'                     package = "lstparsR")
#' lst  <- read_lst_file(path)
#' print(lst)
read_lst_file <- function(path) {
  checkmate::assert_string(path)
  checkmate::assert_file_exists(path, extension = "lst")

  lines <- tryCatch(
    readLines(path, warn = FALSE),
    error = function(e) {
      stop(sprintf("Failed to read file '%s': %s", path, conditionMessage(e)),
           call. = FALSE)
    }
  )

  .lst_new(.as_utf8(lines))
}

# Lines that are not valid UTF-8 are taken as Latin-1 (every byte maps to a
# character, so the conversion cannot fail). Valid UTF-8 and ASCII lines are
# left untouched. Without this, the parsers raise an encoding warning for every
# pattern search on such a listing.
#' @noRd
.as_utf8 <- function(lines) {
  bad <- !validUTF8(lines)
  if (any(bad)) {
    lines[bad] <- iconv(lines[bad], from = "latin1", to = "UTF-8")
  }
  lines
}

# Constructor -- also used in tests to build lst objects from character vectors
#' @noRd
.lst_new <- function(lines) {
  checkmate::assert_character(lines)
  structure(lines, class = "lst")
}

#' @export
print.lst <- function(x, ...) {
  cat(sprintf("<lst> NONMEM listing file: %d lines\n", length(x)))
  invisible(x)
}

#' @export
summary.lst <- function(object, ...) {
  selected <- .final_step(object)
  method <- tryCatch(.get_estimation_method(selected), error = function(e) "unknown")
  structure(
    list(
      lines = length(object),
      method = method,
      covariance_step = .has_covariance_step(selected)
    ),
    class = "summary.lst"
  )
}

#' @export
print.summary.lst <- function(x, ...) {
  cat("<lst> NONMEM listing file\n")
  cat(sprintf("  Lines            : %d\n", x$lines))
  cat(sprintf("  Estimation method: %s\n", x$method))
  cat(sprintf("  Covariance step  : %s\n", x$covariance_step))
  invisible(x)
}
