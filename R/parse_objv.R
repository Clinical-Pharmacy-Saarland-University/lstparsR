fetch_objv <- function(lst) {
  checkmate::assert_class(lst, "lst")

  objv <- lst |>
    grep(pattern = "OBJV", value = TRUE) |>
    stringr::str_replace_all(pattern = "[^0-9.]", replacement = "") |>
    as.numeric()

  return(objv)
}
