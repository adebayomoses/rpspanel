#' Convert nominal values to real values
#'
#' Divides by a price index and rescales so that values are expressed in
#' prices of `base_year`.
#'
#' @param x Numeric vector of nominal values.
#' @param price_index Price index for the same observations as `x` (for
#'   example the BEA GDP deflator, 2017 = 100).
#' @param years Optional years of the observations; needed with `base_year`.
#' @param base_year Year whose prices the result is expressed in. If `NULL`,
#'   the index is assumed to equal 100 in the base year and the result is
#'   `x * 100 / price_index`.
#' @param index_years,index_values Optional full index series used to look up
#'   the base-year value when `base_year` is not among `years`.
#'
#' @return Numeric vector of real values.
#' @export
#' @examples
#' # $10 in 2010 and $12 in 2020 with deflator 90 and 110 (2017 = 100)
#' deflate(c(10, 12), c(90, 110))
#' # Expressed in 2020 prices instead
#' deflate(c(10, 12), c(90, 110), years = c(2010, 2020), base_year = 2020)
deflate <- function(x, price_index, years = NULL, base_year = NULL,
                    index_years = years, index_values = price_index) {
  if (length(price_index) != length(x) && length(price_index) != 1L) {
    cli::cli_abort("{.arg price_index} must have length 1 or the length of {.arg x}.")
  }
  if (is.null(base_year)) {
    return(x * 100 / price_index)
  }
  if (is.null(index_years)) {
    cli::cli_abort("Supply {.arg years} (or {.arg index_years}) together with {.arg base_year}.")
  }
  base <- mean(index_values[index_years == base_year], na.rm = TRUE)
  if (is.nan(base)) {
    cli::cli_abort("No price index value for base year {base_year}.")
  }
  x * base / price_index
}

unit_table <- data.frame(
  unit = c(
    # energy, in Btu
    "btu", "thousand btu", "million btu", "mmbtu", "billion btu", "trillion btu",
    "quadrillion btu", "quad", "kwh", "mwh", "gwh", "twh", "thousand mwh",
    "million kwh", "gj", "tj", "pj",
    # mass, in metric tons
    "kg", "metric ton", "tonne", "thousand metric tons", "million metric tons",
    "short ton", "thousand short tons",
    # money, in dollars
    "dollars", "thousand dollars", "million dollars", "billion dollars",
    # population
    "persons", "thousand persons", "million persons"
  ),
  dimension = c(
    rep("energy", 17), rep("mass", 7), rep("money", 4), rep("count", 3)
  ),
  factor = c(
    1, 1e3, 1e6, 1e6, 1e9, 1e12, 1e15, 1e15, 3412.14, 3412.14e3, 3412.14e6,
    3412.14e9, 3412.14e6, 3412.14e6, 947817.12, 947817.12e3, 947817.12e6,
    1e-3, 1, 1, 1e3, 1e6, 0.90718474, 907.18474,
    1, 1e3, 1e6, 1e9,
    1, 1e3, 1e6
  ),
  stringsAsFactors = FALSE
)

#' Convert between units
#'
#' Converts energy, mass, money-scale and population units used by EIA and
#' BEA. Electricity is converted to Btu at the thermal equivalent of 3,412.14
#' Btu per kWh (the convention used in SEDS for electricity consumption).
#'
#' @param x Numeric vector.
#' @param from,to Unit names (case-insensitive), for example
#'   `"billion Btu"`, `"MMBtu"`, `"thousand MWh"`, `"million metric tons"`,
#'   `"short ton"`, `"million dollars"`. See `convert_units_available()`.
#'
#' @return Numeric vector in the `to` unit.
#' @export
#' @examples
#' convert_units(1, "trillion Btu", "billion Btu")
#' convert_units(1000, "thousand MWh", "TWh")
#' convert_units(1, "million metric tons", "short ton")
convert_units <- function(x, from, to) {
  f <- lookup_unit(from)
  t <- lookup_unit(to)
  if (f$dimension != t$dimension) {
    cli::cli_abort("Cannot convert {f$dimension} ({.val {from}}) to {t$dimension} ({.val {to}}).")
  }
  x * f$factor / t$factor
}

#' @rdname convert_units
#' @export
convert_units_available <- function() {
  unit_table[c("unit", "dimension")]
}

lookup_unit <- function(u) {
  key <- tolower(trimws(u))
  key <- sub("s$", "", key) # plural forms
  i <- match(key, sub("s$", "", unit_table$unit))
  if (is.na(i)) {
    cli::cli_abort("Unknown unit {.val {u}}; see {.fn convert_units_available}.")
  }
  unit_table[i, ]
}
