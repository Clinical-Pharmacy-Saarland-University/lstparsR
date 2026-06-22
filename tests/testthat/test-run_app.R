# run_app() launches an interactive Shiny app, so the happy path is
# exercised by mocking shiny::runApp rather than starting a server.

test_that("run_app errors when shiny is not installed", {
  testthat::local_mocked_bindings(
    requireNamespace = function(...) FALSE, .package = "base"
  )
  expect_error(run_app(), "required to run the lstparsR app")
})

test_that("run_app delegates to shiny::runApp with the app directory", {
  skip_if_not_installed("shiny")
  called <- NULL
  testthat::local_mocked_bindings(
    runApp = function(appDir, ...) {
      called <<- appDir
      invisible("launched")
    },
    .package = "shiny"
  )
  res <- run_app()
  expect_match(called, "shiny$")
  expect_equal(res, "launched")
})
