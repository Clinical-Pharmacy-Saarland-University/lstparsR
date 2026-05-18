devtools::load_all(".")

# Suspect files from initial baseline report.csv
suspects <- c(
  "long_lst.lst", "test.lst", "test_115.lst", "test_116.lst",
  "vpc_original.lst", "vpc_original_107.lst", "vpc_original_110.lst",
  "vpc_original_112.lst", "vpc_original_117.lst",
  "vpc_simulation.1.lst", "vpc_simulation.1_108.lst",
  "vpc_simulation.1_111.lst", "vpc_simulation.1_113.lst",
  "vpc_simulation.1_118.lst"
)

cat("File | ofv_value | ofv_warn | condn_value | condn_warn\n")
cat(strrep("-", 100), "\n")
for (f in suspects) {
  p <- file.path(".exttest/_collected_lst", f)
  if (!file.exists(p)) { cat(f, "MISSING\n"); next }
  lst <- read_lst_file(p)
  ofv_w <- character(0); cn_w <- character(0)
  ofv <- withCallingHandlers(
    tryCatch(fetch_ofv(lst), error = function(e) NA_real_),
    warning = function(w) { ofv_w <<- c(ofv_w, conditionMessage(w)); invokeRestart("muffleWarning") }
  )
  cn <- withCallingHandlers(
    tryCatch(fetch_condn(lst), error = function(e) NA_real_),
    warning = function(w) { cn_w <<- c(cn_w, conditionMessage(w)); invokeRestart("muffleWarning") }
  )
  cat(sprintf("%-30s | %s | %s | %s | %s\n",
    f, format(ofv), paste(ofv_w, collapse="|"),
    format(cn), paste(cn_w, collapse="|")))
}
