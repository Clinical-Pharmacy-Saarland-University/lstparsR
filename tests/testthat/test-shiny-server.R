test_that("uploads preserve identities, diagnostics and download contents", {
  skip_if_not_installed("shiny")
  app <- new.env(parent = globalenv())
  sys.source(system.file("shiny", "app.R", package = "lstparsR"), envir = app)
  bad <- tempfile(fileext = ".lst")
  on.exit(unlink(bad))
  writeLines("not a listing", bad)
  good <- system.file("testdata", "full_cov.lst", package = "lstparsR")
  shiny::testServer(app$server, {
    session$setInputs(lst_files = data.frame(
      name = c("same.lst", "same.lst", "=unsafe.lst"),
      datapath = c(good, good, bad)))
    expect_equal(length(all_results_list()), 3L)
    expect_equal(names(all_results_list()), c("same.lst", "same.lst.1", "=unsafe.lst"))
    expect_match(scalars_df()$error[3], "No usable results")
    expect_equal(vapply(parsed(), function(x) x$covariance, logical(1)), c(TRUE, TRUE, FALSE))
    expect_match(output$file_summary_table, "Needs review")
    csv <- read.csv(output$dl_scalars_csv)
    expect_equal(csv$file[3], "'=unsafe.lst")
    rds <- readRDS(output$dl_all_rds)
    expect_equal(length(rds$raw), 3L)
    expect_equal(rds$scalars$file[3], "=unsafe.lst")
    zip_path <- output$dl_all_csv
    expect_setequal(utils::unzip(zip_path, list = TRUE)$Name,
                    c("thetas.csv", "etas.csv", "sigmas.csv", "scalars.csv"))
    for (id in c("dl_thetas_csv", "dl_etas_csv", "dl_sigmas_csv",
                 "dl_thetas_rds", "dl_etas_rds", "dl_sigmas_rds", "dl_scalars_rds")) {
      expect_true(file.exists(output[[id]]))
    }
  })
})
