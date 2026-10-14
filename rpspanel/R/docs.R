#' Variable codebook
#'
#' Returns the definition, unit, source, source series identifier and
#' transformation of every variable the package can produce, or of the
#' variables in a panel built with [build_panel()].
#'
#' @param x `NULL` (all variables), a character vector of variable names, or
#'   an `rps_panel`.
#' @param group Optional group filter: `"energy"`, `"electricity"`,
#'   `"emissions"`, `"economy"` or `"rps"`.
#'
#' @return A data frame with columns `variable`, `group`, `label`, `unit`,
#'   `source`, `series` and `transformation`.
#' @export
#' @examples
#' codebook(group = "rps")
#' codebook(c("co2_pc", "gdp_real"))
codebook <- function(x = NULL, group = NULL) {
  cb <- registry
  if (inherits(x, "rps_panel")) {
    cb <- attr(x, "codebook") %||% cb[cb$variable %in% names(x), ]
  } else if (is.character(x)) {
    cb <- cb[match(intersect(x, cb$variable), cb$variable), ]
  }
  if (!is.null(group)) {
    group <- match.arg(group, panel_groups, several.ok = TRUE)
    cb <- cb[cb$group %in% group, ]
  }
  cb <- cb[c("variable", "group", "label", "unit", "source", "series", "transformation")]
  rownames(cb) <- NULL
  cb
}

#' Citations for the data sources used
#'
#' Lists the citation for every source used in a panel, including the
#' retrieval date (vintage), plus the citation for the package itself.
#'
#' @param x An `rps_panel`, a character vector of source keys (see
#'   `source` in [codebook()]), or `NULL` for all sources.
#' @param format `"text"` for plain-text references or `"bibtex"`.
#'
#' @return A character vector of references, printed with [cat()] style
#'   separators, returned invisibly.
#' @export
#' @examples
#' cite_sources(c("eia_seds", "bea_regional"))
#' p <- build_panel(states = "CA", years = 2010:2020, groups = "rps",
#'                  rps_methods = "nominal")
#' cite_sources(p, format = "bibtex")
cite_sources <- function(x = NULL, format = c("text", "bibtex")) {
  format <- match.arg(format)
  if (inherits(x, "rps_panel")) {
    src <- attr(x, "sources")
  } else {
    keys <- x %||% source_info$source
    src <- source_info[source_info$source %in% keys, ]
    src$retrieved <- NA_character_
  }
  year_of <- function(r) if (is.na(r) || !grepl("^[0-9]{4}-", r)) format(Sys.Date(), "%Y") else substr(r, 1, 4)
  refs <- vapply(seq_len(nrow(src)), function(i) {
    s <- src[i, ]
    accessed <- if (is.na(s$retrieved)) {
      ""
    } else if (grepl("^[0-9]{4}-", s$retrieved)) {
      paste0(" Retrieved ", s$retrieved, " UTC.")
    } else {
      paste0(" Coding shipped with rpspanel ", s$retrieved, ".")
    }
    if (format == "text") {
      paste0(s$publisher, " (", year_of(s$retrieved), "). ", s$title, ". ",
             if (!is.na(s$url)) s$url else "", ".", accessed)
    } else {
      paste0("@misc{", s$source, ",\n  author = {{", s$publisher, "}},\n  title = {",
             s$title, "},\n  year = {", year_of(s$retrieved), "},\n",
             if (!is.na(s$url)) paste0("  url = {", s$url, "},\n") else "",
             if (nzchar(accessed)) paste0("  note = {", trimws(accessed), "},\n") else "",
             "}")
    }
  }, character(1))
  pkg <- if (format == "text") {
    paste0("Adebayo, M. (", format(Sys.Date(), "%Y"), "). rpspanel: US state ",
           "energy-economy panels with RPS stringency measures. R package version ",
           utils::packageVersion("rpspanel"), ".")
  } else {
    paste0("@Manual{rpspanel,\n  author = {Moses Adebayo},\n  title = {rpspanel: ",
           "US State Energy-Economy Panels with RPS Stringency Measures},\n  note = {R package version ",
           utils::packageVersion("rpspanel"), "},\n  year = {", format(Sys.Date(), "%Y"), "},\n}")
  }
  refs <- c(refs, pkg)
  cat(refs, sep = "\n\n")
  cat("\n")
  invisible(refs)
}
