# The lstparsR logo: a CTTIR v5 hex drawn entirely in R with the shared
# CTTIR renderer in R/ (primitives, palette, tokens). Clinical family.
# Motif: a NONMEM listing page whose THETA, OMEGA and SIGMA rows are parsed
# into a tidy table, over a concentration-time curve.
#
#   Rscript tools/branding/render.R /path/to/review   # review copy
#   Rscript tools/branding/render.R --apply           # update the package
#
# Requires the installed JetBrains Mono ExtraBold for the name: the supplied
# v5 names are heavier than the bundled SemiBold cut, and ExtraBold is the
# closest measured match.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L || !nzchar(args)) stop("Supply an output directory or --apply.")
script <- sub("^--file=", "", grep("^--file=", commandArgs(FALSE), value = TRUE))
branding <- dirname(normalizePath(script, mustWork = TRUE))
repository <- dirname(dirname(branding))
Sys.setenv(CTTIR_FONTCONFIG = "off")
source(file.path(branding, "R", "cttir_hex.R"))
if (!capabilities("cairo")) stop("Cairo graphics are required.")

installed <- systemfonts::system_fonts()
if (!any(installed$family == "JetBrains Mono" & installed$style == "ExtraBold")) {
  stop("Install JetBrains Mono ExtraBold.")
}
name_font <- "JetBrains Mono ExtraBold"
cttir_name <- function(name, y = .049, max_width = .90, size = 34, colour = "#212121",
                       font = name_font) {
  repeat {
    g <- grid::textGrob(name, gp = grid::gpar(fontfamily = name_font, fontsize = size))
    if (grid::convertWidth(grid::grobWidth(g), "npc", valueOnly = TRUE) <= max_width ||
        size <= 12) break
    size <- size - .25
  }
  grid::grid.text(name, .5, y, gp = grid::gpar(fontfamily = name_font, fontsize = size,
                                               col = colour))
  invisible(size)
}

lstparsR_motif <- function(s, small = FALSE) {
  g <- cttir_primitives(s, small)
  a <- s$mid; p <- s$paper; l <- s$light; d <- s$deep
  # The .lst listing: a page of output with three estimate rows in colour.
  g$B(.29, .56, .36, .64, p, r = .03, shadow = TRUE)
  g$B(.23, .81, .20, .04, d, r = .015)
  rows <- c(.62, .52, .42)
  for (y in rows) g$B(.21, y, .14, .055, a, r = .015)
  if (!small) {
    for (y in c(.72, .32, .26)) g$L(c(.16, .42), rep(y, 2), cttir_alpha(d, .55), 2)
    for (y in rows) g$L(c(.31, .42), rep(y, 2), cttir_alpha(d, .55), 2)
  }
  # Parsed: each row lands in its own row of a tidy table. Free-standing
  # strokes use the light role, which turns dark on light faces.
  for (y in rows) g$L(c(.49, .58), c(y, y), l, if (small) 4 else 3)
  g$B(.76, .52, .30, .38, l, r = .025, shadow = TRUE)
  g$B(.76, .67, .30, .08, d, r = .02)
  for (i in seq_along(rows)) g$B(.68, rows[i], .10, .07, a, r = .012)
  if (!small) {
    for (x in c(.79, .85)) g$L(c(x, x), c(.35, .63), cttir_alpha(d, .45), 1.5)
    for (y in c(.47, .37)) g$L(c(.62, .90), c(y, y), cttir_alpha(d, .45), 1.5)
  }
  # Population PK: concentration rising and declining over time.
  g$L(c(.58, .94), c(.15, .15), l, 2.5)
  g$Q(c(.60, .64, .70, .93), c(.16, .34, .20, .17), a, if (small) 5 else 4)
}
v5_motif <- cttir_motif
cttir_motif <- function(name, s, small = FALSE) {
  if (name == "lstparsR") lstparsR_motif(s, small) else v5_motif(name, s, small)
}

output <- if (identical(args, "--apply")) tempfile("lstparsR-logo-") else args
dir.create(output, recursive = TRUE, showWarnings = FALSE)
font <- cttir_token("type", "brand_font")
for (mode in c("light", "dark", "mono")) for (layout in c("hex", "lockup")) {
  stem <- paste0(layout, if (mode == "light") "" else paste0("-", mode))
  d <- cttir_dimensions(layout)
  draw <- function() cttir_draw("lstparsR", "clinical", mode, layout)
  cttir_device(function() grDevices::svg(file.path(output, paste0(stem, ".svg")),
    width = d$width, height = d$height, bg = "transparent", family = font), draw)
  cttir_device(function() grDevices::png(file.path(output, paste0(stem, ".png")),
    width = 1600L, height = 1848L, res = 1600 / d$width, bg = "transparent",
    type = "cairo", antialias = "gray"), draw)
}
# Icons use the dark artwork-only hex; the touch and manifest icons are
# opaque because their hosts fill transparent corners.
icon <- function(file, px, bg = "transparent", scale = 1) cttir_device(function()
  grDevices::png(file.path(output, file), width = px, height = px, res = px / 6, bg = bg,
    type = "cairo", antialias = "gray"), function() {
  grid::grid.newpage()
  grid::pushViewport(grid::viewport(width = scale * sqrt(3) / 2, height = scale))
  cttir_draw("lstparsR", "clinical", mode = "dark", small = px <= 64, newpage = FALSE)
  grid::popViewport()
})
for (px in c(16L, 32L, 48L, 96L)) icon(sprintf("icon-%d.png", px), px)
page <- cttir_token("dark", "page")
icon("apple-touch-icon.png", 180L, page, .86)
for (px in c(192L, 512L)) icon(sprintf("maskable-%d.png", px), px, page, .72)
cttir_device(function() grDevices::png(file.path(output, "app-logo.png"), width = 414L,
  height = 480L, res = 414 / 6, bg = "transparent", type = "cairo", antialias = "gray"),
  function() cttir_draw("lstparsR", "clinical", "light", "lockup"))

write_ico <- function(path, files) {
  images <- lapply(files, function(f) readBin(f, "raw", n = file.info(f)$size))
  sizes <- as.integer(sub(".*icon-([0-9]+)[.]png$", "\\1", files))
  con <- file(path, "wb"); on.exit(close(con))
  writeBin(as.integer(c(0, 1, length(images))), con, size = 2L, endian = "little")
  offset <- 6L + 16L * length(images)
  for (i in seq_along(images)) {
    writeBin(as.raw(c(sizes[i], sizes[i], 0, 0)), con)
    writeBin(as.integer(c(1, 32)), con, size = 2L, endian = "little")
    writeBin(as.integer(c(length(images[[i]]), offset)), con, size = 4L, endian = "little")
    offset <- offset + length(images[[i]])
  }
  for (raw in images) writeBin(raw, con)
}
write_ico(file.path(output, "favicon.ico"),
          file.path(output, sprintf("icon-%d.png", c(16L, 32L, 48L))))

if (identical(args, "--apply")) {
  targets <- c(
    "lockup.svg" = "man/figures/logo.svg",
    "lockup.png" = "man/figures/logo.png",
    "hex-dark.svg" = "pkgdown/favicon/favicon.svg",
    "icon-96.png" = "pkgdown/favicon/favicon-96x96.png",
    "favicon.ico" = "pkgdown/favicon/favicon.ico",
    "apple-touch-icon.png" = "pkgdown/favicon/apple-touch-icon.png",
    "maskable-192.png" = "pkgdown/favicon/web-app-manifest-192x192.png",
    "maskable-512.png" = "pkgdown/favicon/web-app-manifest-512x512.png",
    "app-logo.png" = "inst/shiny/www/logo.png",
    "hex.svg" = "lstparsR_icon.svg")
  for (from in names(targets)) {
    if (!file.copy(file.path(output, from), file.path(repository, targets[[from]]),
                   overwrite = TRUE)) stop("Could not update ", targets[[from]])
  }
  unlink(output, recursive = TRUE)
  message("Updated the lstparsR logo, favicons and app logo.")
} else message("lstparsR logo rendered into ", normalizePath(output))
