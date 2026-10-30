eia_base_url <- "https://api.eia.gov/v2"

# How each EIA dataset is queried and reshaped.
#  route        API v2 route
#  data         data column(s) requested
#  state_facet  facet holding the state code
#  series_facet facet holding the series identifier (NULL: series = data column)
#  fixed        facets that are always applied
eia_specs <- list(
  seds = list(
    route = "seds", data = "value", state_facet = "stateId",
    series_facet = "seriesId", fixed = list()
  ),
  co2 = list(
    route = "co2-emissions/co2-emissions-aggregates", data = "value",
    state_facet = "stateId", series_facet = "sectorId",
    fixed = list(fuelId = "TO")
  ),
  generation = list(
    route = "electricity/electric-power-operational-data", data = "generation",
    state_facet = "location", series_facet = "fueltypeid",
    fixed = list(sectorid = "99")
  ),
  retail_sales = list(
    route = "electricity/retail-sales", data = c("sales", "price"),
    state_facet = "stateid", series_facet = NULL,
    fixed = list(sectorid = "ALL")
  )
)

#' Download state data from the EIA API
#'
#' Queries version 2 of the US Energy Information Administration API and
#' returns tidy long data. Results are cached (see [rps_cache_dir()]); the
#' API key is never written to the cache.
#'
#' Supported datasets:
#'
#' * `"seds"`: State Energy Data System. `series` are SEDS MSN codes, for
#'   example `"TETCB"` (total energy consumption, billion Btu).
#' * `"co2"`: energy-related CO2 emissions aggregates for all fuels.
#'   `series` are EIA sector ids: `"TT"` (total), `"EC"` (electric power),
#'   `"IC"` (industrial), `"TC"` (transportation), `"RC"` (residential),
#'   `"CC"` (commercial).
#' * `"generation"`: net generation, all sectors (forms EIA-923/906/920).
#'   `series` are fuel type ids such as `"ALL"`, `"COW"`, `"NG"`, `"NUC"`,
#'   `"HYC"`, `"WND"`, `"SUN"`, `"GEO"`, `"WWW"`, `"WAS"`.
#' * `"retail_sales"`: electricity retail sales and average price, all
#'   sectors. `series` are `"sales"` and/or `"price"`.
#'
#' @param dataset One of `"seds"`, `"co2"`, `"generation"`, `"retail_sales"`.
#' @param series Character vector of series identifiers (see Details).
#' @param states States to download; any form accepted by
#'   [harmonise_states()]. `NULL` means all 50 states and DC.
#' @param years Integer vector of years. `NULL` downloads all available years.
#' @param api_key EIA API key. Defaults to the `EIA_API_KEY` environment
#'   variable.
#' @param cache Use the local download cache.
#' @param refresh Ignore any cached copy and download again.
#'
#' @return A data frame with columns `state`, `year`, `series`, `value` and
#'   `unit`, with attributes `rps_source` and `rps_retrieved` (download time,
#'   UTC).
#' @export
#' @examplesIf nzchar(Sys.getenv("EIA_API_KEY"))
#' fetch_eia("seds", "TETCB", states = c("CA", "TX"), years = 2015:2020)
fetch_eia <- function(dataset = c("seds", "co2", "generation", "retail_sales"),
                      series, states = NULL, years = NULL,
                      api_key = NULL, cache = TRUE, refresh = FALSE) {
  dataset <- match.arg(dataset)
  spec <- eia_specs[[dataset]]
  states <- resolve_states(states)
  years <- as_years(years)
  if (missing(series) || length(series) == 0) {
    cli::cli_abort("{.arg series} must name at least one series.")
  }
  # The key is only needed for a download, so cached data work offline
  get_key <- function() get_api_key(api_key, "EIA_API_KEY", "EIA",
                                    "https://www.eia.gov/opendata/register.php")

  key <- cache_key("eia", dataset, sort(series), states,
                   paste(range(years %||% 0L), collapse = "-"))
  with_cache(key, paste0("eia_", dataset), cache = cache, refresh = refresh,
    fetch = function() {
      raw <- eia_download(spec, series, states, years, get_key())
      eia_tidy(raw, spec, series, states)
    })
}

eia_query <- function(spec, series, states, years, offset = 0, length = 5000) {
  data_cols <- if (is.null(spec$series_facet)) {
    intersect(spec$data, series)
  } else {
    spec$data
  }
  q <- list(frequency = "annual")
  q[sprintf("data[%d]", seq_along(data_cols) - 1L)] <- as.list(data_cols)
  q[[sprintf("facets[%s][]", spec$state_facet)]] <- states
  if (!is.null(spec$series_facet)) {
    q[[sprintf("facets[%s][]", spec$series_facet)]] <- series
  }
  for (f in names(spec$fixed)) {
    q[[sprintf("facets[%s][]", f)]] <- spec$fixed[[f]]
  }
  if (!is.null(years)) {
    q$start <- as.character(min(years))
    q$end <- as.character(max(years))
  }
  q$offset <- offset
  q$length <- length
  q
}

eia_request <- function(spec, series, states, years, api_key, offset = 0) {
  q <- c(list(api_key = api_key),
         eia_query(spec, series, states, years, offset))
  build_request(sprintf("%s/%s/data/", eia_base_url, spec$route), q)
}

# Download every page of an EIA query (the API returns at most 5000 rows per
# request) and bind them into one data frame.
eia_download <- function(spec, series, states, years, api_key) {
  pages <- list()
  offset <- 0
  repeat {
    body <- eia_page(spec, series, states, years, api_key, offset)
    page <- body$response$data
    if (is.null(page) || length(page) == 0 || NROW(page) == 0) {
      break
    }
    pages[[length(pages) + 1L]] <- as.data.frame(page, stringsAsFactors = FALSE)
    offset <- offset + NROW(page)
    total <- parse_num(body$response$total %||% offset)
    if (is.na(total) || offset >= total) {
      break
    }
  }
  bind_pages(pages)
}

# One page of an EIA query; API errors become classed R errors.
eia_page <- function(spec, series, states, years, api_key, offset) {
  req <- eia_request(spec, series, states, years, api_key, offset)
  body <- perform_json(req, paste0("EIA ", spec$route, " data"))
  if (!is.null(body$error)) {
    cli::cli_abort(c("EIA API returned an error.", x = "{body$error}"),
                   class = "rpspanel_http_error")
  }
  body
}

# Row-bind pages that may not all have the same columns.
bind_pages <- function(pages) {
  if (length(pages) == 0) {
    return(data.frame())
  }
  cols <- Reduce(union, lapply(pages, names))
  pages <- lapply(pages, function(p) {
    p[setdiff(cols, names(p))] <- NA
    p[cols]
  })
  do.call(rbind, pages)
}

eia_tidy <- function(raw, spec, series, states) {
  if (NROW(raw) == 0) {
    return(empty_long())
  }
  state <- harmonise_states(raw[[spec$state_facet]], warn = FALSE)
  year <- as.integer(substr(as.character(raw$period), 1, 4))
  if (is.null(spec$series_facet)) {
    pieces <- lapply(intersect(spec$data, series), function(col) {
      data.frame(
        state = state, year = year, series = col,
        value = parse_num(raw[[col]]),
        unit = as.character(raw[[paste0(col, "-units")]] %||% NA_character_),
        stringsAsFactors = FALSE
      )
    })
    out <- do.call(rbind, pieces)
  } else {
    col <- spec$data[1]
    unit_col <- intersect(c("unit", paste0(col, "-units"), "value-units"),
                          names(raw))
    out <- data.frame(
      state = state, year = year,
      series = as.character(raw[[spec$series_facet]]),
      value = parse_num(raw[[col]]),
      unit = if (length(unit_col)) {
        as.character(raw[[unit_col[1]]])
      } else {
        NA_character_
      },
      stringsAsFactors = FALSE
    )
  }
  out <- out[!is.na(out$state) & out$state %in% states, , drop = FALSE]
  out <- out[order(out$series, out$state, out$year), , drop = FALSE]
  rownames(out) <- NULL
  out
}
