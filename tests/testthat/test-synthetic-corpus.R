# Synthetic NONMEM listing corpus
#
# inst/extdata/lst/ holds invented listings written by
# data-raw/make_synthetic_lst.R. Each case exercises one estimation method,
# run outcome or layout feature. manifest.csv and expected_parameters.csv
# record the values the generator wrote into the listings, so the parsers are
# compared with known inputs rather than with their own earlier output.

corpus_dir <- system.file("extdata", "lst", package = "lstparsR")

read_corpus_csv <- function(file) {
  utils::read.csv(file.path(corpus_dir, file), stringsAsFactors = FALSE,
                  na.strings = "NA")
}
manifest <- read_corpus_csv("manifest.csv")
expected <- read_corpus_csv("expected_parameters.csv")

read_case <- function(id) {
  read_lst_file(file.path(corpus_dir, manifest$file[manifest$case_id == id]))
}

# Evaluate `expr`, returning its value (or the error) and all warnings.
capture <- function(expr) {
  warnings <- character()
  value <- withCallingHandlers(
    tryCatch(expr, error = function(e) {
      structure(list(message = conditionMessage(e)), class = "captured_error")
    }),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(value = value, warnings = warnings)
}

expect_warnings <- function(warnings, pattern) {
  if (is.na(pattern) || !nzchar(pattern)) {
    expect_identical(warnings, character())
  } else {
    expect_length(warnings, 1L)
    expect_match(warnings, pattern)
  }
}

test_that("the corpus is complete, labelled synthetic and small", {
  files <- list.files(corpus_dir, pattern = "\\.lst$")
  expect_setequal(files, manifest$file)
  expect_false(anyDuplicated(manifest$case_id) > 0)
  expect_setequal(unique(expected$case_id),
                  manifest$case_id[manifest$thetas == "ok" |
                                     manifest$etas == "ok" |
                                     manifest$sigmas == "ok"])
  for (i in seq_len(nrow(manifest))) {
    lines <- readLines(file.path(corpus_dir, manifest$file[i]), warn = FALSE)
    expect_match(lines[1], paste0("^\\$PROBLEM +SYNTHETIC lstparsR test case ",
                                  manifest$case_id[i], ": "))
    # Guard against real run output: no drive paths, no calendar dates.
    expect_false(any(grepl("[A-Za-z]:[\\\\/]", lines)))
    expect_false(any(grepl("[0-9]{1,2}[./][0-9]{1,2}[./][0-9]{4}", lines)))
  }
  expect_lt(sum(file.size(file.path(corpus_dir, files))), 500 * 1024)
})

for (i in seq_len(nrow(manifest))) {
  m <- manifest[i, ]

  test_that(sprintf("synthetic case %s: %s", m$case_id, m$title), {
    lst <- read_case(m$case_id)

    for (block in c("thetas", "etas", "sigmas")) {
      res <- capture(get(paste0("fetch_", block))(lst))
      if (m[[block]] == "error") {
        expect_s3_class(res$value, "captured_error")
        expect_match(res$value$message, m[[paste0(block, "_error")]])
        next
      }
      expect_identical(res$warnings, character())
      want <- expected[expected$case_id == m$case_id & expected$block == block, ]
      got  <- res$value
      expect_s3_class(got, "tbl_df")
      expect_identical(got$parameter, want$parameter)
      expect_equal(got$estimate, want$estimate)
      expect_equal(got$se, want$se)
      expect_equal(got$rse, want$se * 100 / abs(want$estimate))
      if (block == "etas") expect_equal(got$shrinkage, want$shrinkage)
    }
    n <- c(thetas = m$n_theta, etas = m$n_eta, sigmas = m$n_eps)
    for (block in names(n)[c(m$thetas, m$etas, m$sigmas) == "ok"]) {
      expect_equal(sum(expected$case_id == m$case_id & expected$block == block),
                   n[[block]])
    }

    ofv <- capture(fetch_ofv(lst))
    expect_warnings(ofv$warnings, m$ofv_warning)
    expect_equal(ofv$value, m$ofv)

    condn <- capture(fetch_condn(lst))
    expect_warnings(condn$warnings, m$condn_warning)
    expect_equal(condn$value, m$condn)

    s <- summary(lst)
    expect_identical(s$method, m$summary_method)
    expect_identical(s$covariance_step, m$covariance_step)

    all <- capture(fetch_all(lst))
    expect_false(inherits(all$value, "captured_error"))
    failed <- c(m$thetas, m$etas, m$sigmas) == "error"
    expect_identical(vapply(all$value[c("thetas", "etas", "sigmas")], is.null, TRUE),
                     stats::setNames(failed, c("thetas", "etas", "sigmas")))
    expect_equal(all$value$ofv, m$ofv)
    expect_equal(all$value$condn, m$condn)
    expect_length(grep("^fetch_all: ", all$warnings), sum(failed))
  })
}

test_that("Windows line endings parse like the LF listing they mirror", {
  path <- file.path(corpus_dir, manifest$file[manifest$case_id == "s34"])
  bytes <- readBin(path, "raw", file.size(path))
  expect_gt(sum(bytes == as.raw(13L)), 100L)  # CR bytes survived checkout
  crlf <- fetch_all(read_case("s34"))
  lf   <- fetch_all(read_case("s01"))
  expect_identical(crlf, lf)
})

test_that("fixed and non-finite placeholders keep standard errors aligned", {
  # "........." (fixed THETA 3, 5, 6) and "+Infinity" (THETA 2) occupy a
  # field each; the following THETAs keep their own standard errors.
  fixed <- fetch_thetas(read_case("s21"))
  expect_equal(fixed$se, c(0.381, 2.94, NA, 0.0962, NA, NA))
  expect_true(is.na(fixed$rse[6]))     # THETA fixed at exactly zero
  inf <- fetch_thetas(read_case("s26"))
  expect_equal(inf$se, c(0.338, Inf, 0.127, 0.148))
  expect_equal(inf$rse[2], Inf)
  expect_true(is.na(fetch_etas(read_case("s26"))$se[2]))   # NaN prints as NA
})

test_that("ten or more random effects keep their four-character labels", {
  etas <- fetch_etas(read_case("s24"))
  expect_identical(tail(etas$parameter, 4), c("ET10", "ET11", "ET12", "ET13"))
  expect_equal(etas$estimate[13], 0.411)   # 13th value on a continuation record
  expect_equal(etas$se[13], 0.111)
  expect_equal(etas$shrinkage[11:13], c(60.06, 65.63, 71.2))  # wrapped record
  sigmas <- fetch_sigmas(read_case("s25"))
  expect_identical(tail(sigmas$parameter, 2), c("EP10", "EP11"))
})

test_that("the final estimation step and problem are selected", {
  # SAEM then IMP: IMP estimates, standard errors and OFV.
  imp <- fetch_all(read_case("s07"))
  expect_equal(imp$thetas$estimate, c(4.36, 31.3, 1.14, 0.679))
  expect_equal(imp$ofv, 1875.893)
  # FOCE-I then IMP EONLY=1: same estimates, OFV of the IMP evaluation.
  expect_equal(fetch_ofv(read_case("s36")), 3151.84)
  # Estimation then simulation problem: the estimation results remain.
  expect_equal(fetch_thetas(read_case("s28"))$se, c(0.219, 1.88))
  # FO with $COV, then FOCE-I without: no standard errors are borrowed.
  second <- fetch_thetas(read_case("s29"))
  expect_equal(second$estimate, c(3.13, 22.3))
  expect_true(all(is.na(second$se)))
  expect_true(is.na(fetch_condn(read_case("s29"))))
})

test_that("legitimately missing quantities are NA without warnings", {
  # Former false positives of the external test harness: simulation-only
  # runs (no OFV) and covariance steps run with EIGENVLS. PRINTED: NO.
  expect_no_warning(expect_true(is.na(fetch_ofv(read_case("s30")))))
  expect_no_warning(expect_true(is.na(fetch_ofv(read_case("s31")))))
  expect_no_warning(expect_true(is.na(fetch_condn(read_case("s18")))))
  expect_no_warning(expect_true(is.na(fetch_condn(read_case("s15")))))
  expect_true(all(is.na(fetch_etas(read_case("s03"))$shrinkage)))
})

test_that("rounding arguments apply to synthetic results", {
  lst <- read_case("s24")
  want <- expected[expected$case_id == "s24" & expected$block == "etas", ]
  etas <- fetch_etas(lst, digits = 1, shk_digits = 0)
  expect_equal(etas$rse, round(want$se * 100 / want$estimate, 1))
  expect_equal(etas$shrinkage, round(want$shrinkage, 0))
  expect_equal(fetch_ofv(read_case("s32"), digits = 2), 1874.11)
  expect_equal(fetch_condn(lst, digits = 3),
               round(as.numeric(manifest$condn[manifest$case_id == "s24"]), 3))
})

test_that("listings cut at any line give results or the documented errors", {
  known_errors <- paste(c("FINAL PARAMETER ESTIMATE section not found",
                          "Could not parse (THETA|OMEGA|SIGMA) estimates",
                          "Could not detect a known estimation method"),
                        collapse = "|")
  known_warnings <- paste(c("OFV not found", "Eigenvalue section not found",
                            "Could not extract eigenvalues", "Fewer than 2 eigenvalues",
                            "row count does not match", "IDs but", "ETASHRINKSD has"),
                          collapse = "|")
  for (id in c("s01", "s24")) {
    full <- read_case(id)
    for (n in unique(c(seq(1L, length(full), by = 7L), length(full)))) {
      cut <- lstparsR:::.lst_new(unclass(full)[seq_len(n)])
      for (fn in list(fetch_thetas, fetch_etas, fetch_sigmas, fetch_ofv, fetch_condn)) {
        res <- capture(fn(cut))
        if (inherits(res$value, "captured_error")) {
          expect_match(res$value$message, known_errors)
        }
        for (w in res$warnings) expect_match(w, known_warnings)
      }
    }
  }
})
