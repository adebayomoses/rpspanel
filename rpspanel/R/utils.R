`%||%` <- function(x, y) if (is.null(x)) y else x

# Parse numbers that may contain thousands separators or BEA/EIA footnote
# markers such as "(NA)", "(D)" or "--". Anything non-numeric becomes NA.
parse_num <- function(x) {
  if (is.numeric(x)) {
    return(as.numeric(x))
  }
  x <- gsub(",", "", trimws(as.character(x)), fixed = TRUE)
  x[!grepl("^-?[0-9.]+([eE][-+]?[0-9]+)?$", x)] <- NA_character_
  as.numeric(x)
}

as_years <- function(years) {
  if (is.null(years)) {
    return(NULL)
  }
  if (!is.numeric(years) || anyNA(years) || any(years %% 1 != 0)) {
    cli::cli_abort("{.arg years} must be a vector of whole years.")
  }
  sort(unique(as.integer(years)))
}

# Long (state, year, variable, value) -> wide, one column per variable.
long_to_wide <- function(long, variables) {
  out <- unique(long[c("state", "year")])
  for (v in variables) {
    sub <- long[long$variable == v, c("state", "year", "value")]
    sub <- sub[!duplicated(sub[c("state", "year")]), , drop = FALSE]
    names(sub)[3] <- v
    out <- merge(out, sub, by = c("state", "year"), all.x = TRUE)
  }
  out
}

empty_long <- function() {
  data.frame(
    state = character(), year = integer(), series = character(),
    value = numeric(), unit = character(), stringsAsFactors = FALSE
  )
}

now_utc <- function() {
  format(Sys.time(), "%Y-%m-%d %H:%M:%S", tz = "UTC")
}
