# Direct tests for the internal parsing helpers. These exercise the
# edge/error branches that the public fetch_* functions only reach for
# unusual NONMEM output shapes.

SUB_T <- "THETA - VECTOR OF FIXED EFFECTS PARAMETERS"
SUB_O <- "OMEGA - COV MATRIX FOR RANDOM EFFECTS - ETAS"

# A bare page whose "1"/asterisk header sits at index 1, so callers can
# pass page_start = 1. The subheader (when present) lives in the body.
.page <- function(body) {
  lstparsR:::.lst_new(c("1", strrep("*", 100), "x", "m", "s", body))
}

# ---- .assert_lst ----------------------------------------------------

test_that(".assert_lst accepts lst and rejects everything else", {
  expect_true(lstparsR:::.assert_lst(lst_full_cov))
  expect_error(lstparsR:::.assert_lst(1:3), "class 'lst'")
  expect_error(lstparsR:::.assert_lst(list(), arg_name = "obj"), "`obj`")
})

# ---- .get_estimation_method ----------------------------------------

test_that(".get_estimation_method detects known methods and errors otherwise", {
  expect_equal(
    lstparsR:::.get_estimation_method(lstparsR:::.lst_new(" FIRST ORDER")),
    "FIRST ORDER"
  )
  expect_error(
    lstparsR:::.get_estimation_method(lstparsR:::.lst_new("no method here")),
    "estimation method"
  )
})

# ---- .find_section_page --------------------------------------------

test_that(".find_section_page returns NA when no matching page exists", {
  lst <- lstparsR:::.lst_new(c("a", "b", "c", "d", "e", "f"))
  expect_true(is.na(lstparsR:::.find_section_page(lst, FOCEI, "FINAL PARAMETER ESTIMATE")))
})

test_that(".find_section_page locates a matching page", {
  lst <- .page("body line")  # >= 6 lines so the search loop runs
  # header at index 1, method at index 4 ("m"), section at index 5 ("s")
  expect_equal(lstparsR:::.find_section_page(lst, "m", "s"), 1L)
})

# ---- .parse_vector_block -------------------------------------------

test_that(".parse_vector_block returns NULL when the subheader is absent", {
  expect_null(lstparsR:::.parse_vector_block(.page("nothing"), 1, SUB_T))
})

test_that(".parse_vector_block returns NULL when no ID lines follow", {
  body <- c(paste(" ", SUB_T), rep("", 12))
  expect_null(lstparsR:::.parse_vector_block(.page(body), 1, SUB_T))
})

test_that(".parse_vector_block returns NULL when the first line is a value line", {
  body <- c(paste(" ", SUB_T), "", "  1.0E+00  2.0E+00")
  expect_null(lstparsR:::.parse_vector_block(.page(body), 1, SUB_T))
})

test_that(".parse_vector_block returns NULL when no value lines are present", {
  body <- c(paste(" ", SUB_T), "  A   B", "", "  no numbers here")
  expect_null(lstparsR:::.parse_vector_block(.page(body), 1, SUB_T))
})

test_that(".parse_vector_block returns NULL when values are unparseable", {
  # tokens match the loose scan but not the strict numeric extractor
  body <- c(paste(" ", SUB_T), "  A   B", "", "  1E+  2E+")
  expect_null(lstparsR:::.parse_vector_block(.page(body), 1, SUB_T))
})

test_that(".parse_vector_block stops collecting IDs at a value line", {
  body <- c(paste(" ", SUB_T), "  TH 1  TH 2", "  1.0E+00  2.0E+00")
  res  <- lstparsR:::.parse_vector_block(.page(body), 1, SUB_T)
  expect_equal(res$id, c("TH_1", "TH_2"))
  expect_equal(res$value, c(1, 2))
})

test_that(".parse_vector_block stops at trailing non-value text", {
  body <- c(paste(" ", SUB_T), "  A   B", "", "  1.0E+00  2.0E+00", "  TRAILING")
  res  <- lstparsR:::.parse_vector_block(.page(body), 1, SUB_T)
  expect_equal(nrow(res), 2L)
  expect_equal(res$value, c(1, 2))
})

test_that(".parse_vector_block warns and pads on an ID/value count mismatch", {
  body <- c(paste(" ", SUB_T), "  A   B   C", "", "  1.0E+00  2.0E+00")
  expect_warning(
    res <- lstparsR:::.parse_vector_block(.page(body), 1, SUB_T),
    "IDs but"
  )
  expect_equal(nrow(res), 3L)
  expect_true(is.na(res$value[3]))
})

# ---- .parse_matrix_block -------------------------------------------

test_that(".parse_matrix_block returns NULL when the subheader is absent", {
  expect_null(lstparsR:::.parse_matrix_block(.page("nothing"), 1, SUB_O))
})

test_that(".parse_matrix_block returns NULL when no parameter rows exist", {
  body <- c(paste(" ", SUB_O), "  header", "  no params")
  expect_null(lstparsR:::.parse_matrix_block(.page(body), 1, SUB_O))
})

test_that(".parse_matrix_block stops at a new page header", {
  lst <- lstparsR:::.lst_new(c(
    "1", strrep("*", 100), "x", "m", "s",
    paste(" ", SUB_O), "", "", "        ETA1", " ",
    " ETA1", "+        2.00E-01", " ",
    "1", strrep("*", 100)
  ))
  res <- lstparsR:::.parse_matrix_block(lst, 1, SUB_O)
  expect_equal(res$id, "ETA1")
  expect_equal(res$value, 0.2)
})

# ---- .parse_shrinkage ----------------------------------------------

test_that(".parse_shrinkage extracts the last matching line's values", {
  lst <- lstparsR:::.lst_new(c(
    " ETASHRINKSD(%) =  9.9E+00",
    " ETASHRINKSD(%) =  5.0E+00  1.6E+00"
  ))
  expect_equal(lstparsR:::.parse_shrinkage(lst, "ETASHRINKSD"), c(5.0, 1.6))
})

test_that(".parse_shrinkage returns NULL when no line matches", {
  expect_null(lstparsR:::.parse_shrinkage(lstparsR:::.lst_new("nothing"), "ETASHRINKSD"))
})

test_that(".parse_shrinkage returns NULL when the line has no numbers", {
  expect_null(
    lstparsR:::.parse_shrinkage(lstparsR:::.lst_new(" ETASHRINKSD = none"), "ETASHRINKSD")
  )
})

# ---- estimation/covariance detection helpers -----------------------

test_that(".has_covariance_step and .has_estimation_step detect markers", {
  expect_true(lstparsR:::.has_covariance_step(
    lstparsR:::.lst_new(" STANDARD ERROR OF ESTIMATE")))
  expect_false(lstparsR:::.has_covariance_step(lstparsR:::.lst_new("none")))
  expect_true(lstparsR:::.has_estimation_step(lstparsR:::.lst_new(" #METH: FOCE")))
  expect_false(lstparsR:::.has_estimation_step(lstparsR:::.lst_new("none")))
})

test_that(".eigenvalues_suppressed detects the EIGENVLS. PRINTED: NO flag", {
  expect_true(lstparsR:::.eigenvalues_suppressed(
    lstparsR:::.lst_new(" EIGENVLS. PRINTED:  NO")))
  expect_false(lstparsR:::.eigenvalues_suppressed(lstparsR:::.lst_new("none")))
})
