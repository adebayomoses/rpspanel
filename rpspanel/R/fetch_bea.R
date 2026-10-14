bea_base_url <- "https://apps.bea.gov/api/data"

#' Download data from the BEA API
#'
#' Retrieves state series from the Bureau of Economic Analysis Regional
#' accounts, or national series from the NIPA tables (used for price
#' deflators).
#'
#' Useful Regional tables and line codes:
#'
#' * `SAGDP9N` line 1: real GDP, all industries (millions of chained 2017
#'   dollars); line 12: manufacturing.
#' * `SAGDP2N` line 1: nominal GDP (millions of current dollars).
#' * `SAINC1` line 1: personal income (thousands of dollars); line 2:
#'   population (persons); line 3: per capita personal income (dollars).
#'
#' Useful NIPA table: `T10109` line 1, the implicit price deflator for GDP
#' (index, 2017 = 100).
#'
#' @param table BEA table name, for example `"SAGDP9N"` or `"T10109"`.
#' @param line_code Line code (Regional) or line number (NIPA).
#' @param dataset `"Regional"` (state data) or `"NIPA"` (national data).
#' @param states States to keep (Regional only); `NULL` keeps all 50 + DC.
#' @param years Years to keep; `NULL` keeps all available years.
#' @param api_key BEA API key. Defaults to the `BEA_API_KEY` environment
#'   variable.
#' @inheritParams fetch_eia
#'
#' @return A data frame with columns `state` (`NA` for NIPA data), `year`,
#'   `series` (`"<table>:<line>"`), `value` and `unit`. Values are in the
#'   units reported by BEA (the `UNIT_MULT` scale factor is already applied
#'   to the unit label, not the value).
#' @export
#' @examplesIf nzchar(Sys.getenv("BEA_API_KEY"))
#' fetch_bea("SAGDP9N", 1, states = "CA", years = 2015:2020)
#' fetch_bea("T10109", 1, dataset = "NIPA")
fetch_bea <- function(table, line_code, dataset = c("Regional", "NIPA"),
                      states = NULL, years = NULL, api_key = NULL,
                      cache = TRUE, refresh = FALSE) {
  dataset <- match.arg(dataset)
  states <- resolve_states(states)
  years <- as_years(years)
  api_key <- get_api_key(api_key, "BEA_API_KEY", "BEA",
                         "https://apps.bea.gov/API/signup/")

  key <- cache_key("bea", dataset, table, line_code)
  out <- with_cache(key, paste0("bea_", tolower(dataset)), cache = cache, refresh = refresh,
    fetch = function() {
      body <- perform_json(bea_request(table, line_code, dataset, api_key),
                           paste("BEA table", table))
      bea_tidy(body, table, line_code, dataset)
    })
  keep <- rep(TRUE, nrow(out))
  if (dataset == "Regional") keep <- keep & out$state %in% states
  if (!is.null(years)) keep <- keep & out$year %in% years
  res <- out[keep, , drop = FALSE]
  rownames(res) <- NULL
  attributes(res)[c("rps_source", "rps_retrieved")] <-
    attributes(out)[c("rps_source", "rps_retrieved")]
  res
}

bea_request <- function(table, line_code, dataset, api_key) {
  q <- list(UserID = api_key, method = "GetData", datasetname = dataset,
            TableName = table, Year = "ALL", ResultFormat = "json")
  if (dataset == "Regional") {
    q$LineCode <- line_code
    q$GeoFips <- "STATE"
  } else {
    q$Frequency <- "A"
  }
  build_request(bea_base_url, q)
}

bea_tidy <- function(body, table, line_code, dataset) {
  res <- body$BEAAPI$Results
  err <- body$BEAAPI$Error %||% res$Error
  if (!is.null(err)) {
    msg <- err$APIErrorDescription %||% err$ErrorDetail$Description %||% "unknown error"
    cli::cli_abort(c("BEA API returned an error.", x = "{msg}"),
                   class = "rpspanel_http_error")
  }
  d <- as.data.frame(res$Data, stringsAsFactors = FALSE)
  if (nrow(d) == 0) {
    return(empty_long())
  }
  if (dataset == "NIPA") {
    d <- d[as.character(d$LineNumber) == as.character(line_code), , drop = FALSE]
    state <- rep(NA_character_, nrow(d))
  } else {
    state <- harmonise_states(d$GeoFips, warn = FALSE)
  }
  unit <- as.character(d$CL_UNIT %||% NA_character_)
  mult <- parse_num(d$UNIT_MULT %||% NA)
  scale_lab <- c("0" = "", "3" = "thousands of ", "6" = "millions of ", "9" = "billions of ")
  prefix <- unname(scale_lab[as.character(mult)])
  prefix[is.na(prefix)] <- ""
  out <- data.frame(
    state = state,
    year = as.integer(substr(as.character(d$TimePeriod), 1, 4)),
    series = paste0(table, ":", line_code),
    value = parse_num(d$DataValue),
    unit = paste0(prefix, unit),
    stringsAsFactors = FALSE
  )
  if (dataset == "Regional") {
    out <- out[!is.na(out$state), , drop = FALSE]
  }
  out <- out[order(out$state, out$year), , drop = FALSE]
  rownames(out) <- NULL
  out
}
