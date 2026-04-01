#' Read a NONMEM Listing File
#'
#' Reads a NONMEM `.lst` output file into memory as a character vector
#' with class `"lst"` for use by the `fetch_*` family of functions.
#'
#' @param path Character string. Path to the `.lst` file.
#'
#' @return A character vector of class `"lst"`, where each element is one
#'   line of the file.
#'
#' @export
#'
#' @examples
#' path <- system.file("testdata", "full_cov.lst", package = "lstparsR")
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

  .lst_new(lines)
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
  method <- tryCatch(.get_estimation_method(object), error = function(e) "unknown")
  cat(sprintf("<lst> NONMEM listing file\n"))
  cat(sprintf("  Lines            : %d\n", length(object)))
  cat(sprintf("  Estimation method: %s\n", method))
  cat(sprintf("  Covariance step  : %s\n", .has_covariance_step(object)))
  invisible(object)
}
