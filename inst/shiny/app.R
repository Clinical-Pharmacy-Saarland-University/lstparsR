# lstparseR Shiny Application
# Launch via lstparseR::run_app()

library(shiny)
library(lstparseR)

# -- UI -----------------------------------------------------------------------

ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      :root {
        --primary: #2272B4;
        --primary-dark: #1B5E94;
        --primary-light: #E8F1F8;
        --accent: #F5A623;
        --accent-light: #FFF4E0;
        --surface: #f8fafc;
        --border: #d6e3ed;
        --text: #1e293b;
        --text-muted: #64748b;
        --success: #16a34a;
        --warning: #d97706;
        --danger: #dc2626;
      }
      body {
        font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI',
                     Roboto, sans-serif;
        background: var(--surface);
        color: var(--text);
      }
      .navbar {
        background: var(--primary) !important;
        border: none;
        margin-bottom: 0;
      }
      .navbar-brand {
        color: #fff !important;
        font-weight: 700;
        display: flex !important;
        align-items: center;
        gap: 10px;
      }
      .navbar-brand img {
        height: 32px;
        width: auto;
      }
      .navbar .nav > li > a {
        color: #fff !important;
        font-weight: 600;
      }
      .navbar .nav > li > a:hover,
      .navbar .nav > li.active > a {
        background: rgba(255,255,255,0.15) !important;
      }
      .tab-content { padding-top: 24px; }
      .card {
        background: #fff;
        border: 1px solid var(--border);
        border-radius: 12px;
        padding: 24px;
        margin-bottom: 20px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.04);
      }
      .card h4 {
        margin-top: 0;
        color: var(--primary);
        font-weight: 600;
        font-size: 16px;
        margin-bottom: 16px;
      }
      .stat-box {
        text-align: center;
        padding: 16px;
        border-radius: 10px;
        background: var(--primary-light);
        border: 1px solid var(--border);
      }
      .stat-box .value {
        font-size: 28px;
        font-weight: 700;
        color: var(--accent);
        line-height: 1.2;
      }
      .stat-box .label {
        font-size: 12px;
        color: var(--text-muted);
        text-transform: uppercase;
        letter-spacing: 0.5px;
        margin-top: 4px;
      }
      .status-badge {
        display: inline-block;
        padding: 3px 10px;
        border-radius: 999px;
        font-size: 12px;
        font-weight: 600;
      }
      .badge-ok { background: #dcfce7; color: var(--success); }
      .badge-warn { background: #fef3c7; color: var(--warning); }
      .badge-fail { background: #fee2e2; color: var(--danger); }
      .btn-primary {
        background: var(--accent);
        border-color: var(--accent);
        border-radius: 8px;
        font-weight: 500;
        color: #fff;
      }
      .btn-primary:hover {
        background: #E09510;
        border-color: #E09510;
      }
      .btn-outline {
        background: #fff;
        border: 1px solid var(--primary);
        border-radius: 8px;
        font-weight: 500;
        color: var(--primary);
      }
      .btn-outline:hover {
        background: var(--primary-light);
      }
      .well {
        background: #fff;
        border: 1px dashed var(--border);
        border-radius: 12px;
      }
      .info-text {
        color: var(--text-muted);
        font-size: 14px;
        line-height: 1.6;
      }
      .table { font-size: 13px; }
      .table thead th {
        background: var(--primary-light);
        color: var(--primary);
        border-bottom: 2px solid var(--primary);
      }
      .shiny-output-error { color: var(--danger); }
      a { color: var(--primary); }
      a:hover { color: var(--accent); }
      hr { border-color: var(--border); }
      .download-group .btn { margin-right: 8px; margin-bottom: 8px; }
    "))
  ),

  navbarPage(
    title = tags$span(
      tags$img(src = "logo.png", alt = "lstparseR"),
      "lstparseR"
    ),
    id = "main_nav",
    windowTitle = "lstparseR",

    # -- Tab: Home / Upload ---------------------------------------------------
    tabPanel(
      "Upload",
      icon = icon("upload"),
      fluidRow(
        column(4,
          div(class = "card",
            h4("Upload .lst Files"),
            fileInput("lst_files", NULL,
                      accept = ".lst",
                      multiple = TRUE,
                      placeholder = "Choose .lst files..."),
            p(class = "info-text",
              "Upload one or more NONMEM listing files (.lst).",
              "Results are parsed immediately and shown in the tabs above."
            ),
            hr(),
            h4("Quick Download"),
            div(class = "download-group",
              downloadButton("dl_all_csv", "All Results (CSV)",
                             class = "btn-primary"),
              downloadButton("dl_all_rds", "All Results (RDS)",
                             class = "btn-outline")
            )
          ),
          div(class = "card",
            h4("About lstparseR"),
            p(class = "info-text",
              "lstparseR reads NONMEM .lst output files and extracts",
              "parameter estimates into tidy data frames for downstream",
              "population PK/PD analysis."
            ),
            tags$ul(class = "info-text",
              tags$li("Parses THETA, OMEGA, SIGMA, OFV, condition number"),
              tags$li("Extracts standard errors, RSE, and ETA shrinkage"),
              tags$li("Handles failed runs gracefully (returns NA)"),
              tags$li("Supports FOCE-I, FOCE, FO, SAEM, IMP, IMPMAP, Bayesian")
            ),
            p(class = "info-text",
              tags$strong("Package: "),
              tags$a(href = "https://github.com/Clinical-Pharmacy-Saarland-University/lstparseR",
                     "github.com/.../lstparseR", target = "_blank")
            ),
            p(class = "info-text",
              tags$strong("License: "), "GPL (>= 3)"
            )
          )
        ),
        column(8,
          div(class = "card",
            h4("Overview"),
            uiOutput("overview_stats"),
            hr(),
            h4("File Summary"),
            tableOutput("file_summary_table")
          )
        )
      )
    ),

    # -- Tab: Thetas ----------------------------------------------------------
    tabPanel(
      "Thetas",
      icon = icon("table"),
      div(class = "card",
        fluidRow(
          column(8, h4("THETA Estimates (Fixed Effects)")),
          column(4, style = "text-align: right;",
            div(class = "download-group",
              downloadButton("dl_thetas_csv", "CSV", class = "btn-outline"),
              downloadButton("dl_thetas_rds", "RDS", class = "btn-outline")
            )
          )
        ),
        tableOutput("thetas_table")
      )
    ),

    # -- Tab: Etas ------------------------------------------------------------
    tabPanel(
      "Etas",
      icon = icon("table"),
      div(class = "card",
        fluidRow(
          column(8, h4("OMEGA Estimates (Random Effects)")),
          column(4, style = "text-align: right;",
            div(class = "download-group",
              downloadButton("dl_etas_csv", "CSV", class = "btn-outline"),
              downloadButton("dl_etas_rds", "RDS", class = "btn-outline")
            )
          )
        ),
        tableOutput("etas_table")
      )
    ),

    # -- Tab: Sigmas ----------------------------------------------------------
    tabPanel(
      "Sigmas",
      icon = icon("table"),
      div(class = "card",
        fluidRow(
          column(8, h4("SIGMA Estimates (Residual Error)")),
          column(4, style = "text-align: right;",
            div(class = "download-group",
              downloadButton("dl_sigmas_csv", "CSV", class = "btn-outline"),
              downloadButton("dl_sigmas_rds", "RDS", class = "btn-outline")
            )
          )
        ),
        tableOutput("sigmas_table")
      )
    ),

    # -- Tab: Scalars ---------------------------------------------------------
    tabPanel(
      "OFV & Condition",
      icon = icon("chart-line"),
      div(class = "card",
        fluidRow(
          column(8, h4("Objective Function Value & Condition Number")),
          column(4, style = "text-align: right;",
            div(class = "download-group",
              downloadButton("dl_scalars_csv", "CSV", class = "btn-outline"),
              downloadButton("dl_scalars_rds", "RDS", class = "btn-outline")
            )
          )
        ),
        tableOutput("scalars_table")
      )
    )
  )
)

# -- Server -------------------------------------------------------------------

server <- function(input, output, session) {

  # Reactive: parse all uploaded files
  parsed <- reactive({
    req(input$lst_files)
    files <- input$lst_files

    results <- lapply(seq_len(nrow(files)), function(i) {
      fname <- files$name[i]
      fpath <- files$datapath[i]

      # Rename temp file to have .lst extension (checkmate requires it)
      lst_path <- paste0(fpath, ".lst")
      file.copy(fpath, lst_path, overwrite = TRUE)

      tryCatch({
        lst <- read_lst_file(lst_path)
        res <- suppressWarnings(fetch_all(lst))
        list(file = fname, result = res, error = NULL)
      }, error = function(e) {
        list(file = fname, result = NULL, error = conditionMessage(e))
      })
    })

    results
  })

  # -- Derived tables ---------------------------------------------------------

  thetas_df <- reactive({
    res <- parsed()
    dfs <- lapply(res, function(r) {
      if (!is.null(r$result) && !is.null(r$result$thetas)) {
        df <- r$result$thetas
        df$file <- r$file
        df
      }
    })
    dfs <- dfs[!vapply(dfs, is.null, logical(1))]
    if (length(dfs) == 0) return(NULL)
    do.call(rbind, dfs)
  })

  etas_df <- reactive({
    res <- parsed()
    dfs <- lapply(res, function(r) {
      if (!is.null(r$result) && !is.null(r$result$etas)) {
        df <- r$result$etas
        df$file <- r$file
        df
      }
    })
    dfs <- dfs[!vapply(dfs, is.null, logical(1))]
    if (length(dfs) == 0) return(NULL)
    do.call(rbind, dfs)
  })

  sigmas_df <- reactive({
    res <- parsed()
    dfs <- lapply(res, function(r) {
      if (!is.null(r$result) && !is.null(r$result$sigmas)) {
        df <- r$result$sigmas
        df$file <- r$file
        df
      }
    })
    dfs <- dfs[!vapply(dfs, is.null, logical(1))]
    if (length(dfs) == 0) return(NULL)
    do.call(rbind, dfs)
  })

  scalars_df <- reactive({
    res <- parsed()
    data.frame(
      file  = vapply(res, function(r) r$file, character(1)),
      ofv   = vapply(res, function(r) {
        if (!is.null(r$result)) r$result$ofv else NA_real_
      }, numeric(1)),
      condn = vapply(res, function(r) {
        if (!is.null(r$result)) {
          val <- r$result$condn
          if (is.null(val)) NA_real_ else val
        } else NA_real_
      }, numeric(1)),
      n_thetas = vapply(res, function(r) {
        if (!is.null(r$result) && !is.null(r$result$thetas))
          nrow(r$result$thetas) else NA_integer_
      }, integer(1)),
      n_etas = vapply(res, function(r) {
        if (!is.null(r$result) && !is.null(r$result$etas))
          nrow(r$result$etas) else NA_integer_
      }, integer(1)),
      n_sigmas = vapply(res, function(r) {
        if (!is.null(r$result) && !is.null(r$result$sigmas))
          nrow(r$result$sigmas) else NA_integer_
      }, integer(1)),
      error = vapply(res, function(r) {
        if (!is.null(r$error)) r$error else ""
      }, character(1)),
      stringsAsFactors = FALSE
    )
  })

  all_results_list <- reactive({
    res <- parsed()
    out <- list()
    for (r in res) {
      out[[r$file]] <- r$result
    }
    out
  })

  # -- Overview stats ---------------------------------------------------------

  output$overview_stats <- renderUI({
    res <- parsed()
    n_files    <- length(res)
    n_ok       <- sum(vapply(res, function(r) is.null(r$error), logical(1)))
    n_fail     <- n_files - n_ok
    n_with_cov <- sum(vapply(res, function(r) {
      !is.null(r$result) && !is.na(r$result$condn)
    }, logical(1)))

    fluidRow(
      column(3, div(class = "stat-box",
        div(class = "value", n_files),
        div(class = "label", "Files Uploaded")
      )),
      column(3, div(class = "stat-box",
        div(class = "value", n_ok),
        div(class = "label", "Parsed OK")
      )),
      column(3, div(class = "stat-box",
        div(class = "value", n_fail),
        div(class = "label", "Errors")
      )),
      column(3, div(class = "stat-box",
        div(class = "value", n_with_cov),
        div(class = "label", "With Cov Step")
      ))
    )
  })

  # -- File summary table -----------------------------------------------------

  output$file_summary_table <- renderTable({
    sc <- scalars_df()
    sc$status <- ifelse(sc$error == "", "OK", "Error")
    sc[, c("file", "status", "ofv", "condn", "n_thetas", "n_etas", "n_sigmas")]
  }, striped = TRUE, hover = TRUE, width = "100%",
     na = "NA", digits = 4)

  # -- Parameter tables -------------------------------------------------------

  output$thetas_table <- renderTable({
    df <- thetas_df()
    if (is.null(df)) return(data.frame(Message = "No THETA data available."))
    df[, c("file", "parameter", "estimate", "se", "rse")]
  }, striped = TRUE, hover = TRUE, width = "100%",
     na = "NA", digits = 6)

  output$etas_table <- renderTable({
    df <- etas_df()
    if (is.null(df)) return(data.frame(Message = "No ETA data available."))
    df[, c("file", "parameter", "estimate", "se", "rse", "shrinkage")]
  }, striped = TRUE, hover = TRUE, width = "100%",
     na = "NA", digits = 6)

  output$sigmas_table <- renderTable({
    df <- sigmas_df()
    if (is.null(df)) return(data.frame(Message = "No SIGMA data available."))
    df[, c("file", "parameter", "estimate", "se", "rse")]
  }, striped = TRUE, hover = TRUE, width = "100%",
     na = "NA", digits = 6)

  output$scalars_table <- renderTable({
    sc <- scalars_df()
    sc[, c("file", "ofv", "condn")]
  }, striped = TRUE, hover = TRUE, width = "100%",
     na = "NA", digits = 6)

  # -- Downloads: individual CSVs ---------------------------------------------

  output$dl_thetas_csv <- downloadHandler(
    filename = function() "lstparseR_thetas.csv",
    content  = function(file) {
      df <- thetas_df()
      if (is.null(df)) df <- data.frame()
      write.csv(df, file, row.names = FALSE)
    }
  )

  output$dl_etas_csv <- downloadHandler(
    filename = function() "lstparseR_etas.csv",
    content  = function(file) {
      df <- etas_df()
      if (is.null(df)) df <- data.frame()
      write.csv(df, file, row.names = FALSE)
    }
  )

  output$dl_sigmas_csv <- downloadHandler(
    filename = function() "lstparseR_sigmas.csv",
    content  = function(file) {
      df <- sigmas_df()
      if (is.null(df)) df <- data.frame()
      write.csv(df, file, row.names = FALSE)
    }
  )

  output$dl_scalars_csv <- downloadHandler(
    filename = function() "lstparseR_scalars.csv",
    content  = function(file) write.csv(scalars_df(), file, row.names = FALSE)
  )

  # -- Downloads: individual RDS ----------------------------------------------

  output$dl_thetas_rds <- downloadHandler(
    filename = function() "lstparseR_thetas.rds",
    content  = function(file) saveRDS(thetas_df(), file)
  )

  output$dl_etas_rds <- downloadHandler(
    filename = function() "lstparseR_etas.rds",
    content  = function(file) saveRDS(etas_df(), file)
  )

  output$dl_sigmas_rds <- downloadHandler(
    filename = function() "lstparseR_sigmas.rds",
    content  = function(file) saveRDS(sigmas_df(), file)
  )

  output$dl_scalars_rds <- downloadHandler(
    filename = function() "lstparseR_scalars.rds",
    content  = function(file) saveRDS(scalars_df(), file)
  )

  # -- Downloads: all-in-one --------------------------------------------------

  output$dl_all_csv <- downloadHandler(
    filename = function() "lstparseR_all.zip",
    content  = function(file) {
      tmpdir <- tempdir()
      csv_files <- character(0)

      df <- thetas_df()
      if (!is.null(df) && nrow(df) > 0) {
        p <- file.path(tmpdir, "thetas.csv")
        write.csv(df, p, row.names = FALSE)
        csv_files <- c(csv_files, p)
      }

      df <- etas_df()
      if (!is.null(df) && nrow(df) > 0) {
        p <- file.path(tmpdir, "etas.csv")
        write.csv(df, p, row.names = FALSE)
        csv_files <- c(csv_files, p)
      }

      df <- sigmas_df()
      if (!is.null(df) && nrow(df) > 0) {
        p <- file.path(tmpdir, "sigmas.csv")
        write.csv(df, p, row.names = FALSE)
        csv_files <- c(csv_files, p)
      }

      p <- file.path(tmpdir, "scalars.csv")
      write.csv(scalars_df(), p, row.names = FALSE)
      csv_files <- c(csv_files, p)

      zip(file, csv_files, flags = "-j")
    },
    contentType = "application/zip"
  )

  output$dl_all_rds <- downloadHandler(
    filename = function() "lstparseR_all.rds",
    content  = function(file) {
      saveRDS(list(
        thetas  = thetas_df(),
        etas    = etas_df(),
        sigmas  = sigmas_df(),
        scalars = scalars_df(),
        raw     = all_results_list()
      ), file)
    }
  )
}

shinyApp(ui, server)
