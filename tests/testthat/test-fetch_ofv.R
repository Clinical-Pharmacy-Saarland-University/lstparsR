test_that("fetch_ofv returns single numeric for full_cov", {
  result <- fetch_ofv(lst_full_cov)
  expect_type(result, "double")
  expect_length(result, 1)
  expect_false(is.na(result))
})

test_that("fetch_ofv digits rounds correctly", {
  result <- fetch_ofv(lst_full_cov, digits = 2)
  expect_equal(result, round(result, 2))
})

test_that("fetch_ofv returns numeric for no_cov (without-constant fallback)", {
  result <- fetch_ofv(lst_no_cov)
  expect_true(is.numeric(result))
  expect_length(result, 1)
  expect_false(is.na(result))
})

test_that("fetch_ofv warns and returns NA for empty lst", {
  fake <- lstparsR:::.lst_new(c(
    "line1", "line2", "no objv here",
    " MINIMIZATION SUCCESSFUL"
  ))
  expect_warning(result <- fetch_ofv(fake))
  expect_true(is.na(result))
})

test_that("fetch_ofv returns NA silently for $SIMULATION-only runs", {
  path <- system.file("testdata", "sim_only_no_ofv.lst", package = "lstparsR")
  lst  <- read_lst_file(path)
  expect_no_warning(result <- fetch_ofv(lst))
  expect_true(is.na(result))
})

# --- #OBJV: banner line format (number flanked by asterisks) ---
test_that("fetch_ofv extracts value from #OBJV: line (positive)", {
  lst <- lstparsR:::.lst_new(c(
    " #OBJV:********************************************     8986.318       **************************************************"
  ))
  result <- suppressWarnings(fetch_ofv(lst))
  expect_equal(result, 8986.318)
})

test_that("fetch_ofv extracts value from #OBJV: line (negative)", {
  lst <- lstparsR:::.lst_new(c(
    " #OBJV:********************************************     -1234.567       **************************************************"
  ))
  result <- suppressWarnings(fetch_ofv(lst))
  expect_equal(result, -1234.567)
})

test_that("fetch_ofv returns LAST #OBJV: value for multiple estimation steps", {
  lst <- lstparsR:::.lst_new(c(
    " #OBJV:*** -1111.111 ***",
    " some middle content",
    " #OBJV:*** -2222.222 ***"
  ))
  result <- suppressWarnings(fetch_ofv(lst))
  expect_equal(result, -2222.222)
})

# --- MINIMUM VALUE OF OBJECTIVE FUNCTION with = on same line ---
test_that("fetch_ofv extracts from MINIMUM VALUE OF OBJECTIVE FUNCTION = line", {
  lst <- lstparsR:::.lst_new(c(
    " MINIMUM VALUE OF OBJECTIVE FUNCTION  =   1234.567"
  ))
  result <- suppressWarnings(fetch_ofv(lst))
  expect_equal(result, 1234.567)
})

# --- OBJECTIVE FUNCTION VALUE WITHOUT CONSTANT multi-line format ---
test_that("fetch_ofv extracts WITHOUT CONSTANT value from multi-line format", {
  lst <- lstparsR:::.lst_new(c(
    "0MINIMUM VALUE OF OBJECTIVE FUNCTION",
    "",
    " OBJECTIVE FUNCTION VALUE WITHOUT CONSTANT:     -1234.567",
    " OBJECTIVE FUNCTION VALUE WITH CONSTANT:        5678.901"
  ))
  result <- suppressWarnings(fetch_ofv(lst))
  expect_equal(result, -1234.567)
})

test_that("fetch_ofv extracts WITHOUT CONSTANT when no MINIMUM VALUE header", {
  lst <- lstparsR:::.lst_new(c(
    " N*LOG(2PI) CONSTANT TO OBJECTIVE FUNCTION:    183.79",
    " OBJECTIVE FUNCTION VALUE WITHOUT CONSTANT:    -567.891",
    " OBJECTIVE FUNCTION VALUE WITH CONSTANT:       -384.10",
    " REPORTED OBJECTIVE FUNCTION DOES NOT CONTAIN CONSTANT"
  ))
  result <- suppressWarnings(fetch_ofv(lst))
  expect_equal(result, -567.891)
})

# --- FINAL VALUE OF OBJECTIVE FUNCTION format ---
test_that("fetch_ofv extracts from FINAL VALUE OF OBJECTIVE FUNCTION = line", {
  lst <- lstparsR:::.lst_new(c(
    " FINAL VALUE OF OBJECTIVE FUNCTION  =   9999.123"
  ))
  result <- suppressWarnings(fetch_ofv(lst))
  expect_equal(result, 9999.123)
})

# --- Fixture file: #OBJV: format ---
test_that("fetch_ofv correctly parses ofv_objv_format.lst fixture", {
  path <- system.file("testdata", "ofv_objv_format.lst", package = "lstparsR")
  lst  <- read_lst_file(path)
  result <- suppressWarnings(fetch_ofv(lst))
  expect_equal(result, -1234.567)
})

# --- Fixture file: WITHOUT CONSTANT format ---
test_that("fetch_ofv correctly parses ofv_without_constant.lst fixture", {
  path <- system.file("testdata", "ofv_without_constant.lst", package = "lstparsR")
  lst  <- read_lst_file(path)
  result <- suppressWarnings(fetch_ofv(lst))
  expect_equal(result, -567.891234567890)
})

# --- digits rounding on each strategy ---
test_that("fetch_ofv rounds the MINIMUM VALUE = format with digits", {
  lst <- lstparsR:::.lst_new(" MINIMUM VALUE OF OBJECTIVE FUNCTION  =   1234.567")
  expect_equal(suppressWarnings(fetch_ofv(lst, digits = 1)), 1234.6)
})

test_that("fetch_ofv rounds the multi-line WITHOUT CONSTANT format with digits", {
  lst <- lstparsR:::.lst_new(c(
    "0MINIMUM VALUE OF OBJECTIVE FUNCTION", "",
    " OBJECTIVE FUNCTION VALUE WITHOUT CONSTANT:     -1234.567"
  ))
  expect_equal(suppressWarnings(fetch_ofv(lst, digits = 1)), -1234.6)
})

test_that("fetch_ofv falls back to a generic OBJECTIVE FUNCTION VALUE line", {
  lst <- lstparsR:::.lst_new(c(
    "0MINIMUM VALUE OF OBJECTIVE FUNCTION", "",
    " OBJECTIVE FUNCTION VALUE:    500.567"
  ))
  expect_equal(suppressWarnings(fetch_ofv(lst, digits = 1)), 500.6)
})

test_that("fetch_ofv rounds the standalone WITHOUT CONSTANT format with digits", {
  lst <- lstparsR:::.lst_new(" OBJECTIVE FUNCTION VALUE WITHOUT CONSTANT:  -567.891")
  expect_equal(suppressWarnings(fetch_ofv(lst, digits = 2)), -567.89)
})

test_that("fetch_ofv extracts and rounds the pyDARWIN 'OFV =' footer", {
  lst <- lstparsR:::.lst_new("OFV = 1234.567")
  expect_equal(suppressWarnings(fetch_ofv(lst, digits = 1)), 1234.6)
})
