#' Convert a panel for estimation packages
#'
#' Prepares a panel for `plm`, `fixest` or `csdm`. The package does not
#' re-implement estimators; it hands a correctly indexed panel to them.
#'
#' * `"plm"`: a `pdata.frame` indexed by `state` and `year`.
#' * `"fixest"`: a `fixest_panel` (for lag and lead operators) indexed by
#'   `state` and `year`.
#' * `"csdm"`: a plain data frame sorted by `state` and `year`, with `state`
#'   as a factor; pass `id = "state"` and `time = "year"` to `csdm`.
#' * `"data.frame"`: the same sorted plain data frame.
#'
#' @param x An `rps_panel` (or any data frame with `state` and `year`).
#' @param to Target package.
#'
#' @return An object of the requested class.
#' @export
#' @examples
#' p <- build_panel(states = c("CA", "TX"), years = 2005:2020, groups = "rps",
#'                  rps_methods = c("adoption", "nominal"))
#' head(as_pdata(p, "data.frame"))
#' if (requireNamespace("plm", quietly = TRUE)) {
#'   class(as_pdata(p, "plm"))
#' }
as_pdata <- function(x, to = c("plm", "fixest", "csdm", "data.frame")) {
  to <- match.arg(to)
  if (!all(c("state", "year") %in% names(x))) {
    cli::cli_abort("{.arg x} needs {.field state} and {.field year} columns.")
  }
  df <- if (inherits(x, "rps_panel")) unclass_panel(x) else as.data.frame(x)
  df <- df[order(df$state, df$year), , drop = FALSE]
  rownames(df) <- NULL
  switch(to,
    plm = {
      rlang_check("plm")
      plm::pdata.frame(df, index = c("state", "year"))
    },
    fixest = {
      rlang_check("fixest")
      fixest::panel(df, ~ state + year)
    },
    csdm = {
      df$state <- factor(df$state)
      df
    },
    data.frame = df
  )
}

rlang_check <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cli::cli_abort(paste0("Package {.pkg {pkg}} is required; install it ",
                          "with {.code install.packages(\"{pkg}\")}."))
  }
}

#' Export a panel to CSV, Stata or Parquet
#'
#' Writes the panel and, by default, its codebook next to it
#' (`<name>_codebook.csv`). Stata files carry variable labels from the
#' codebook.
#'
#' @param x An `rps_panel`.
#' @param path Output file path.
#' @param format `"csv"`, `"stata"` or `"parquet"`. Guessed from the file
#'   extension (`.csv`, `.dta`, `.parquet`) when `NULL`.
#' @param codebook Also write the codebook as CSV.
#'
#' @return The path, invisibly.
#' @export
#' @examples
#' p <- build_panel(states = "CA", years = 2010:2020, groups = "rps",
#'                  rps_methods = "nominal")
#' f <- tempfile(fileext = ".csv")
#' export_panel(p, f)
#' head(read.csv(f))
export_panel <- function(x, path, format = NULL, codebook = TRUE) {
  format <- format %||% switch(tolower(tools::file_ext(path)),
    csv = "csv", dta = "stata", parquet = "parquet",
    cli::cli_abort(
      "Cannot guess the format of {.path {path}}; set {.arg format}."
    )
  )
  format <- match.arg(format, c("csv", "stata", "parquet"))
  cb <- codebook(x)
  df <- if (inherits(x, "rps_panel")) unclass_panel(x) else as.data.frame(x)
  switch(format,
    csv = utils::write.csv(df, path, row.names = FALSE),
    stata = {
      rlang_check("haven")
      for (v in names(df)) {
        lab <- cb$label[cb$variable == v]
        if (length(lab)) attr(df[[v]], "label") <- substr(lab, 1, 80)
      }
      haven::write_dta(df, path)
    },
    parquet = {
      rlang_check("arrow")
      arrow::write_parquet(df, path)
    }
  )
  if (codebook) {
    cb_path <- file.path(dirname(path),
                         paste0(tools::file_path_sans_ext(basename(path)),
                                "_codebook.csv"))
    utils::write.csv(cb, cb_path, row.names = FALSE)
  }
  invisible(path)
}
