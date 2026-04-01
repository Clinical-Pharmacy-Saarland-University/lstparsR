#' Launch the lstparseR Shiny Application
#'
#' Opens an interactive browser-based application for uploading NONMEM `.lst`
#' files, viewing parsed parameter tables, and downloading results in CSV or
#' RDS format.
#'
#' @param ... Additional arguments passed to [shiny::runApp()].
#'
#' @return Called for its side effect (launches a Shiny app). Returns the
#'   value from [shiny::runApp()] invisibly.
#'
#' @export
#'
#' @examples
#' if (interactive()) {
#'   run_app()
#' }
run_app <- function(...) {
  if (!requireNamespace("shiny", quietly = TRUE)) {
    stop(
      "The 'shiny' package is required to run the lstparseR app.\n",
      "Install it with: install.packages(\"shiny\")",
      call. = FALSE
    )
  }

  app_dir <- system.file("shiny", package = "lstparseR")
  if (app_dir == "") {
    stop("Could not find the Shiny app directory. Try reinstalling lstparseR.",
         call. = FALSE)
  }

  shiny::runApp(app_dir, ...)
}
