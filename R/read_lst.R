#' Read .lst File Contents
#'
#' Reads the contents of a .lst file, ensuring the file exists and has the correct extension before proceeding.
#' The function reads the file line by line and assigns a specific class to the resulting object for further processing.
#'
#' @param lst_file_path The file path to the .lst file that needs to be read. The function checks that this file exists
#' and that it has a .lst extension before attempting to read it.
#'
#' @return Returns a character vector, where each element represents a line from the .lst file.
#' The returned object is assigned the class "lst" for identification and further use in processing.
#'
#' @examples
#' # Assuming you have a .mod file at the specified path:
#' lst_file_path <- "path/to/your/file.lst"
#' lst_contents <- read_lst_file(lst_file_path)
#' print(lst_contents)
#'
#' @export
#' @import checkmate
#'
#' @keywords file-io
read_lst_file <- function(lst_file_path) {
  checkmate::assert_file_exists(lst_file_path)
  checkmate::assert_file(lst_file_path, extension = ".lst")

  chars_parsed <- tryCatch(
    {
      base::readLines(lst_file_path) |>
        suppressWarnings()
    },
    error = function(e) {
      stop(base::paste0("Error while reading file: ", lst_file_path, "\\n", e))
    }
  )

  lst <- chars_parsed |>
    .lst_from_char_vec()

  return(lst)
}

.lst_from_char_vec <- function(char_vec) {
  checkmate::assert_character(char_vec, min.len = 1)

  lst <- char_vec
  class(lst) <- "lst"

  return(lst)
}
