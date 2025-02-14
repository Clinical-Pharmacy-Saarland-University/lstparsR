#' Fetches the etas from an lst object
#'
#' @param lst A list object containing the output from a NONMEM run
#' @param rse_digits The number of digits to round the RSEs to
#' @param shk_digits The number of digits to round the SHKs to
#' @return A tibble containing the etas and their RSEs
#' @export
#' @importFrom checkmate assert_class assert_number
#' @importFrom dplyr mutate
#' @importFrom tibble rownames_to_column
#' @examples
#' fetch_etas(lst = lst)
fetch_etas <- function(lst, rse_digits = NA, shk_digits = NA) {
  checkmate::assert_class(lst, "lst")
  checkmate::assert_number(rse_digits, lower = 0, na.ok = TRUE)

  omegas <- lst |>
    .fetch_matrix(par_name = "OMEGA") |>
    lapply(\(x) {
      x <- x |>
        as.matrix() |>
        diag() |>
        as.data.frame()
      return(x)
    })

  ome_vals <- omegas[[1]] |>
    tibble::rownames_to_column()

  if (length(omegas) == 2) {
    if (!is.na(rse_digits)) {
      omerses <- round(omegas[[2]][[1]] * 100 / ome_vals[[2]], rse_digits)
    } else {
      omerses <- omegas[[2]][[1]] * 100 / ome_vals[[2]]
    }
  } else {
    omerses <- NA_real_
  }

  omegas_out <- ome_vals |>
    dplyr::mutate(RSE = omerses) |>
    setNames(c("Parameter", "Value", "RSE"))
  
  # add shrinkage
  shrinkage_line <- grep("ETASHRINKSD", lst, value = TRUE)
  shrinkage_values <- NA  # Default to NA if not found
  if (length(shrinkage_line) > 0) {
    # Extract all numeric values from the line
    shrinkage_values <- as.numeric(unlist(regmatches(shrinkage_line, gregexpr("[0-9]+\\.[0-9]+E[+-][0-9]+", shrinkage_line)))) |>
      suppressWarnings()
  }
  if (!is.na(shk_digits)) {
    shrinkage_values <- round(shrinkage_values, shk_digits)
  }
  
  omegas_out$SHK <- shrinkage_values

  return(omegas_out)
}

.fetch_matrix <- function(lst,
                          name_tables = c("COV MATRIX", "COV MATRIX (SE)"),
                          par_name = c("OMEGA", "SIGMA")) {
  checkmate::assert_class(lst, "lst")
  par_name <- match.arg(par_name, c("OMEGA", "SIGMA"))

  upper_delim <- "OMEGA - COV MATRIX FOR RANDOM EFFECTS - ETAS"
  lower_delim <- "SIGMA - COV MATRIX FOR RANDOM EFFECTS - EPSILONS"
  if (par_name == "SIGMA") {
    upper_delim <- "SIGMA - COV MATRIX FOR RANDOM EFFECTS - EPSILONS"
    lower_delim <- "OMEGA - CORR MATRIX FOR RANDOM EFFECTS - ETAS"
  }

  upper_delims <- grep(pattern = upper_delim, lst)
  lower_delims <- grep(pattern = lower_delim, lst)

  if (length(upper_delims) == 0 || length(lower_delims) == 0) {
    stop("Delimiters not found.")
  } else if (length(upper_delims) != length(lower_delims)) {
    stop("Delimiters in incorrect order or malformatted lst file.")
  }

  dfs_out <- list()
  for (j in seq_len(length(upper_delims))) {
    rng <- seq(upper_delims[j] + 1, lower_delims[j] - 1)
    block <- lst[rng] |>
      trimws() |>
      stringi::stri_remove_empty()

    col_names <- block[1] |>
      strsplit("  ") |>
      unlist() |>
      trimws() |>
      stringi::stri_remove_empty()

    rws <- list()
    for (b in block[-1]) {
      if (!grepl(pattern = "ETA|EPS", b)) {
        inner <- stringr::str_split(b, pattern = " ") |>
          unlist() |>
          trimws() |>
          stringr::str_replace_all(pattern = ".........", replacement = NA_character_) |>
          stringi::stri_remove_empty()
        rws[[length(rws) + 1]] <- inner
      }
    }

    max_len <- max(sapply(rws, length))
    rws <- lapply(rws, function(x) {
      if (length(x) < max_len) {
        x <- c(x, rep(NA, max_len - length(x)))
      }
      return(x)
    })

    df_out <- do.call(rbind, rws) |>
      as.data.frame() |>
      dplyr::select(-1) |>
      dplyr::slice(seq_len(length(col_names))) |>
      dplyr::mutate_all(as.numeric) |>
      setNames(col_names)
    row.names(df_out) <- col_names
    dfs_out[[j]] <- df_out
  }

  names(dfs_out) <- paste0(par_name, " ", name_tables[[length(dfs_out)]])
  return(dfs_out)
}



# fetch_etas <- function(lst, rse_digits = NA, shk_digits = NA) {
#   checkmate::assert_class(lst, "lst")
#   checkmate::assert_number(rse_digits, lower = 0, na.ok = TRUE)
#   
#   omegas <- lst |>
#     .fetch_matrix(par_name = "OMEGA") |>
#     lapply(\(x) {
#       x <- x |>
#         as.matrix() |>
#         diag() |>
#         as.data.frame()
#       return(x)
#     })
#   
#   ome_vals <- omegas[[1]] |>
#     tibble::rownames_to_column()
#   
#   if (length(omegas) == 2) {
#     if (!is.na(rse_digits)) {
#       omerses <- round(omegas[[2]][[1]] * 100 / ome_vals[[2]], rse_digits)
#     } else {
#       omerses <- omegas[[2]][[1]] * 100 / ome_vals[[2]]
#     }
#   } else {
#     omerses <- NA_real_
#   }
#   
#   omegas_out <- ome_vals |>
#     dplyr::mutate(RSE = omerses) |>
#     setNames(c("Parameter", "Value", "RSE"))
#   
#   # add shrinkage
#   shrinkage_line <- grep("ETASHRINKSD", lst, value = TRUE)
#   shrinkage_values <- NA  # Default to NA if not found
#   if (length(shrinkage_line) > 0) {
#     # Extract all numeric values from the line
#     shrinkage_values <- as.numeric(unlist(regmatches(shrinkage_line, gregexpr("[0-9]+\\.[0-9]+E[+-][0-9]+", shrinkage_line)))) |>
#       suppressWarnings()
#   }
#   if (!is.na(shk_digits)) {
#     shrinkage_values <- round(shrinkage_values, shk_digits)
#   }
#   
#   omegas_out$SHK <- shrinkage_values
#   
#   return(omegas_out)
# }
# 
# .fetch_matrix <- function(lst,
#                           name_tables = c("COV MATRIX", "COV MATRIX (SE)"),
#                           par_name = c("OMEGA", "SIGMA")) {
#   checkmate::assert_class(lst, "lst")
#   par_name <- match.arg(par_name, c("OMEGA", "SIGMA"))
#   
#   upper_delim <- "OMEGA - COV MATRIX FOR RANDOM EFFECTS - ETAS"
#   lower_delim <- "SIGMA - COV MATRIX FOR RANDOM EFFECTS - EPSILONS"
#   if (par_name == "SIGMA") {
#     upper_delim <- "SIGMA - COV MATRIX FOR RANDOM EFFECTS - EPSILONS"
#     lower_delim <- "OMEGA - CORR MATRIX FOR RANDOM EFFECTS - ETAS"
#   }
#   
#   upper_delims <- grep(pattern = upper_delim, lst)
#   lower_delims <- grep(pattern = lower_delim, lst)
#   
#   if (length(upper_delims) == 0 || length(lower_delims) == 0) {
#     stop("Delimiters not found.")
#   } else if (length(upper_delims) != length(lower_delims)) {
#     stop("Delimiters in incorrect order or malformatted lst file.")
#   }
#   
#   dfs_out <- list()
#   for (j in seq_len(length(upper_delims))) {
#     rng <- seq(upper_delims[j] + 1, lower_delims[j] - 1)
#     block <- lst[rng] |>
#       trimws() |>
#       stringi::stri_remove_empty()
#     
#     col_names <- block[1] |>
#       strsplit("  ") |>
#       unlist() |>
#       trimws() |>
#       stringi::stri_remove_empty()
#     
#     rws <- list()
#     for (b in block[-1]) {
#       if (!grepl(pattern = "ETA|EPS", b)) {
#         inner <- stringr::str_split(b, pattern = " ") |>
#           unlist() |>
#           trimws() |>
#           stringr::str_replace_all(pattern = ".........", replacement = NA_character_) |>
#           stringi::stri_remove_empty()
#         rws[[length(rws) + 1]] <- inner
#       }
#     }
#     
#     max_len <- max(sapply(rws, length))
#     rws <- lapply(rws, function(x) {
#       if (length(x) < max_len) {
#         x <- c(x, rep(NA, max_len - length(x)))
#       }
#       return(x)
#     })
#     
#     df_out <- do.call(rbind, rws) |>
#       as.data.frame() |>
#       dplyr::select(-1) |>
#       dplyr::slice(seq_len(length(col_names))) |>
#       dplyr::mutate_all(as.numeric) |>
#       setNames(col_names)
#     row.names(df_out) <- col_names
#     dfs_out[[j]] <- df_out
#   }
#   
#   names(dfs_out) <- paste0(par_name, " ", name_tables[[length(dfs_out)]])
#   return(dfs_out)
# }
