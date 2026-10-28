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
  cb <- cb[c("variable", "group", "label", "unit", "source", "series",
             "transformation")]
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
#' @return A character vector of references of class `rps_citation`, which
#'   prints one reference per paragraph.
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
  refs <- vapply(seq_len(nrow(src)), function(i) {
    source_reference(src[i, ], format)
  }, character(1))
  structure(c(refs, package_reference(format)), class = "rps_citation")
}

# Year of a retrieval timestamp, or the current year when there is none.
citation_year <- function(retrieved) {
  if (is.na(retrieved) || !grepl("^[0-9]{4}-", retrieved)) {
    format(Sys.Date(), "%Y")
  } else {
    substr(retrieved, 1, 4)
  }
}

# One reference for a row of the sources table.
source_reference <- function(s, format) {
  accessed <- if (is.na(s$retrieved)) {
    ""
  } else if (grepl("^[0-9]{4}-", s$retrieved)) {
    paste0(" Retrieved ", s$retrieved, " UTC.")
  } else {
    paste0(" Coding shipped with rpspanel ", s$retrieved, ".")
  }
  if (format == "text") {
    # Angle brackets keep the closing full stop out of the URL
    link <- if (!is.na(s$url)) paste0(" <", s$url, ">.") else ""
    return(paste0(s$publisher, " (", citation_year(s$retrieved), "). ",
                  s$title, ".", link, accessed))
  }
  url <- if (!is.na(s$url)) paste0("  url = {", s$url, "},\n") else ""
  note <- if (nzchar(accessed)) {
    paste0("  note = {", trimws(accessed), "},\n")
  } else {
    ""
  }
  paste0("@misc{", s$source, ",\n",
         "  author = {{", s$publisher, "}},\n",
         "  title = {", s$title, "},\n",
         "  year = {", citation_year(s$retrieved), "},\n",
         url, note, "}")
}

# The reference for the package itself.
package_reference <- function(format) {
  if (format == "text") {
    return(paste0("Adebayo, M. (", format(Sys.Date(), "%Y"), "). rpspanel: ",
                  "US state energy-economy panels with renewable portfolio ",
                  "standards. R package version ",
                  utils::packageVersion("rpspanel"), "."))
  }
  paste0("@Manual{rpspanel,\n",
         "  author = {Moses Adebayo},\n",
         "  title = {rpspanel: US State Energy-Economy Panels with ",
         "Renewable Portfolio Standards},\n",
         "  note = {R package version ",
         utils::packageVersion("rpspanel"), "},\n",
         "  year = {", format(Sys.Date(), "%Y"), "},\n}")
}

#' @export
print.rps_citation <- function(x, ...) {
  cat(unclass(x), sep = "\n\n")
  cat("\n")
  invisible(x)
}
