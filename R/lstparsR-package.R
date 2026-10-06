#' @details
#' Parsers use the final problem and estimation step. Explicit `#PROB:` and
#' `#METH:` markers delimit results; legacy listings use final result pages.
#' A failed final step does not reuse earlier estimates or covariance output.
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom checkmate assert_number assert_string assert_file_exists
#' @importFrom purrr safely
#' @importFrom stringr str_detect str_extract str_extract_all str_split
#'   str_trim fixed
#' @importFrom tibble tibble
## usethis namespace: end
NULL
