.result_page <- function(value = "1.00E+00", method = FOCEI,
                         section = "FINAL PARAMETER ESTIMATE") {
  c("1", strrep("*", 100), "x", method, section,
    "THETA - VECTOR OF FIXED EFFECTS PARAMETERS ********",
    " TH 1", "", paste("", value))
}

test_that("matrix exponents and missing diagonal positions are preserved", {
  x <- lstparsR:::.lst_new(c(
    "1", strrep("*", 100), "x", FOCEI, "FINAL PARAMETER ESTIMATE",
    "OMEGA - COV MATRIX FOR RANDOM EFFECTS - ETAS ********",
    " ETA1", "+ 2.50E+01", " ETA2", "+ 2.00E-02 ..........",
    " ETA3", "+ 0.00E+00 0.00E+00", "+ 2.50E+00"))
  expect_equal(fetch_etas(x)$estimate, c(25, NA, 2.5))
  expect_equal(fetch_etas(lst_full_cov)$se,
               c(0.0389, 0.0463, 2e73, 1.99e73, 6.85e68, NA, NA))
  expect_equal(fetch_etas(lst_full_cov)$shrinkage,
               c(5.0757, 1.6156, 100, 100, 97.599, 98.964, 97.007))
})

test_that("all outputs belong to the final marked step", {
  first <- c("#METH: First Order Conditional Estimation with Interaction",
             "#OBJV:**** 100 ****", .result_page(),
             .result_page("1.00E-01", section = "STANDARD ERROR OF ESTIMATE"),
             "EIGENVALUES OF COR MATRIX OF ESTIMATE", "1.00E+00 2.00E+00")
  last <- c("#METH: FIRST ORDER", "#OBJV:**** 200 ****",
            .result_page("2.00E+00", "FIRST ORDER"))
  x <- lstparsR:::.lst_new(c(first, last))
  expect_equal(fetch_thetas(x)$estimate, 2)
  expect_true(is.na(fetch_thetas(x)$se))
  expect_equal(fetch_ofv(x), 200)
  expect_true(is.na(fetch_condn(x)))
  failed <- lstparsR:::.lst_new(c(first, "#METH: FIRST ORDER", "MINIMIZATION TERMINATED"))
  expect_error(fetch_thetas(failed), "FINAL PARAMETER")
  expect_warning(expect_true(is.na(fetch_ofv(failed))), "OFV not found")
  problem <- lstparsR:::.lst_new(c(first, "#PROB: 2", "ESTIMATION STEP OMITTED"))
  expect_true(is.na(fetch_ofv(problem)))
  expect_error(fetch_thetas(problem), "estimation method")
})

test_that("legacy multi-step result pages select consistent values", {
  x <- lstparsR:::.lst_new(c(.result_page(), "#OBJV:**** 100 ****",
                           .result_page("2.00E+00"), "#OBJV:**** 200 ****"))
  expect_equal(fetch_thetas(x)$estimate, 2)
  expect_equal(fetch_ofv(x), 200)
  x <- lstparsR:::.lst_new(c("MINIMUM VALUE OF OBJECTIVE FUNCTION = 100",
                           .result_page(),
                           "MINIMUM VALUE OF OBJECTIVE FUNCTION = 200",
                           .result_page("2.00E+00")))
  expect_equal(fetch_thetas(x)$estimate, 2)
  expect_equal(fetch_ofv(x), 200)
})

test_that("condition numbers include all groups and expose invalid matrices", {
  header <- c("STANDARD ERROR OF ESTIMATE", "EIGENVALUES OF COR MATRIX OF ESTIMATE")
  expect_equal(fetch_condn(lstparsR:::.lst_new(c(header, "0.00E+00 1.00E+00 2.00E+00"))), Inf)
  expect_warning(expect_true(is.na(fetch_condn(lstparsR:::.lst_new(
    c(header, "-1.00E+00 1.00E+00 2.00E+00"))))), "negative eigenvalues")
  x <- lstparsR:::.lst_new(c(header, "1 2", "1.00E+00 2.00E+00", "", "3 4",
                           "1.00E-03 1.00E+02", "NEXT SECTION 9.00E+09"))
  expect_equal(fetch_condn(x), 1e5)
  expect_warning(expect_true(is.na(fetch_condn(lstparsR:::.lst_new(header)))),
                 "Could not extract")
})

test_that("truncated and alternate objective headers are safe", {
  expect_warning(expect_true(is.na(fetch_ofv(lstparsR:::.lst_new(
    "MINIMUM VALUE OF OBJECTIVE FUNCTION")))), "OFV not found")
  expect_equal(fetch_ofv(lstparsR:::.lst_new("FINAL VALUE OF OBJECTIVE FUNCTION  1234.5")), 1234.5)
  for (n in 0:5) {
    x <- lstparsR:::.lst_new(rep("x", n))
    expect_error(fetch_thetas(x), "estimation method")
    expect_true(is.na(fetch_ofv(x)))
  }
  expect_warning(res <- fetch_all(lst_full_cov, ofv_digits = -1), "fetch_all")
  expect_null(res$ofv)
  expect_s3_class(res$thetas, "tbl_df")
})

test_that("the no-covariance vignette fixture retains estimates only", {
  x <- read_lst_file(system.file("testdata", "theta_without_cov.lst", package = "lstparsR"))
  expect_equal(nrow(fetch_thetas(x)), 12L)
  expect_true(all(is.na(fetch_thetas(x)$se)))
  expect_true(is.na(fetch_condn(x)))
})

test_that("missing parameter blocks cannot borrow standard error values", {
  x <- lstparsR:::.lst_new(c(.result_page(),
    make_section_page(FOCEI, "STANDARD ERROR OF ESTIMATE", omega_body("1.00E-01"))))
  expect_error(fetch_etas(x), "Could not parse OMEGA estimates")
  x <- read_lst_file(system.file("testdata", "theta_no_cov.lst", package = "lstparsR"))
  expect_error(fetch_etas(x), "Could not parse OMEGA estimates")
  expect_error(fetch_sigmas(x), "Could not parse SIGMA estimates")
})

test_that("missing THETA values cannot borrow another parameter block", {
  x <- lstparsR:::.lst_new(c(
    "1", strrep("*", 100), "x", FOCEI, "FINAL PARAMETER ESTIMATE",
    "THETA - VECTOR OF FIXED EFFECTS PARAMETERS ********", " TH 1", "",
    "OMEGA - COV MATRIX FOR RANDOM EFFECTS - ETAS ********", " ETA1", "+ 1.00E+00"))
  expect_error(fetch_thetas(x), "Could not parse THETA")
})
