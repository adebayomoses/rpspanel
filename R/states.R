state_table <- data.frame(
  abbr = c(
    "AL", "AK", "AZ", "AR", "CA", "CO", "CT", "DE", "DC", "FL", "GA", "HI",
    "ID", "IL", "IN", "IA", "KS", "KY", "LA", "ME", "MD", "MA", "MI", "MN",
    "MS", "MO", "MT", "NE", "NV", "NH", "NJ", "NM", "NY", "NC", "ND", "OH",
    "OK", "OR", "PA", "RI", "SC", "SD", "TN", "TX", "UT", "VT", "VA", "WA",
    "WV", "WI", "WY"
  ),
  name = c(
    "Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado",
    "Connecticut", "Delaware", "District of Columbia", "Florida", "Georgia",
    "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky",
    "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota",
    "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire",
    "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota",
    "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island",
    "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont",
    "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"
  ),
  fips = c(
    "01", "02", "04", "05", "06", "08", "09", "10", "11", "12", "13", "15",
    "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27",
    "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39",
    "40", "41", "42", "44", "45", "46", "47", "48", "49", "50", "51", "53",
    "54", "55", "56"
  ),
  stringsAsFactors = FALSE
)

#' US states and the District of Columbia
#'
#' Returns the 51 geographic units covered by the package with their USPS
#' abbreviation, name and two-digit FIPS code.
#'
#' @return A data frame with columns `abbr`, `name` and `fips`.
#' @export
#' @examples
#' head(us_states())
us_states <- function() {
  state_table
}

#' Harmonise state identifiers
#'
#' Converts state names, USPS abbreviations or FIPS codes (two-digit, numeric,
#' or five-digit BEA `GeoFips` such as `"06000"`) to a single representation.
#' Matching ignores case, surrounding white space and trailing footnote
#' markers such as the asterisks BEA appends to some state names.
#'
#' @param x A character or numeric vector of state identifiers.
#' @param to Output representation: `"abbr"` (default), `"name"` or `"fips"`.
#' @param warn If `TRUE`, warn about values that could not be matched
#'   (for example `"US"` or regional aggregates). Unmatched values become `NA`.
#'
#' @return A character vector the same length as `x`.
#' @export
#' @examples
#' harmonise_states(c("California", "tx", "06", 36, "11000", "Alaska *"))
#' harmonise_states(c("CA", "NY"), to = "fips")
harmonise_states <- function(x, to = c("abbr", "name", "fips"), warn = TRUE) {
  to <- match.arg(to)
  raw <- as.character(x)
  key <- toupper(trimws(gsub("[*]+$", "", trimws(raw))))
  key <- gsub("\\s+", " ", key)

  idx <- match(key, state_table$abbr)

  names_up <- toupper(state_table$name)
  aliases <- c("WASHINGTON DC" = "DC", "WASHINGTON D.C." = "DC", "D.C." = "DC",
               "DISTRICT OF COLUMBIA" = "DC")
  by_name <- match(key, names_up)
  by_alias <- match(unname(aliases[key]), state_table$abbr)
  idx[is.na(idx)] <- by_name[is.na(idx)]
  idx[is.na(idx)] <- by_alias[is.na(idx)]

  numeric_key <- grepl("^[0-9]+$", key)
  fips_key <- key
  # BEA GeoFips look like "06000"
  fips_key[numeric_key & nchar(key) == 5 & endsWith(key, "000")] <-
    substr(key[numeric_key & nchar(key) == 5 & endsWith(key, "000")], 1, 2)
  fips_num <- suppressWarnings(as.integer(fips_key[numeric_key]))
  fips_key[numeric_key] <- sprintf("%02d", fips_num)
  by_fips <- ifelse(numeric_key, match(fips_key, state_table$fips), NA_integer_)
  idx[is.na(idx)] <- by_fips[is.na(idx)]

  bad <- is.na(idx) & !is.na(x)
  if (warn && any(bad)) {
    cli::cli_warn(c(
      "Could not match {sum(bad)} state identifier{?s} to the 50 states + DC.",
      i = "Unmatched: {.val {unique(raw[bad])}}"
    ))
  }
  state_table[[to]][idx]
}

resolve_states <- function(states) {
  if (is.null(states)) {
    return(state_table$abbr)
  }
  out <- harmonise_states(states, warn = FALSE)
  if (anyNA(out)) {
    cli::cli_abort("Unknown state identifier{?s}: {.val {states[is.na(out)]}}.")
  }
  unique(out)
}
