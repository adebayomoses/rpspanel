#' Download state data from the Census Bureau API
#'
#' Retrieves a state-level variable from the American Community Survey
#' 1-year estimates (default: total population, `B01003_001E`). This is an
#' optional supplement: [build_panel()] takes population from BEA, which is
#' available for every year. ACS 1-year estimates start in 2005, and the
#' standard 2020 release does not exist, so that year is skipped.
#'
#' @param years Years to download (2005 onward).
#' @param variable ACS variable code.
#' @param api_key Optional Census API key. Defaults to the `CENSUS_API_KEY`
#'   environment variable; small queries work without a key.
#' @inheritParams fetch_eia
#'
#' @return A data frame with columns `state`, `year`, `series`, `value`,
#'   `unit`. Years that fail to download are skipped with a warning.
#' @export
#' @examples
#' \donttest{
#' try(fetch_census(2019, states = c("CA", "TX")))
#' }
fetch_census <- function(years, variable = "B01003_001E", states = NULL,
                         api_key = NULL, cache = TRUE, refresh = FALSE) {
  years <- as_years(years)
  states <- resolve_states(states)
  api_key <- api_key %||% Sys.getenv("CENSUS_API_KEY")
  if (any(years == 2020L)) {
    cli::cli_inform("Skipping 2020: no standard ACS 1-year release.")
    years <- setdiff(years, 2020L)
  }
  if (any(years < 2005L)) {
    cli::cli_inform("Skipping years before 2005: ACS 1-year data start in 2005.")
    years <- years[years >= 2005L]
  }
  pieces <- lapply(years, function(y) {
    key <- cache_key("census_acs1", y, variable)
    tryCatch(
      with_cache(key, "census_acs", cache = cache, refresh = refresh,
                 fetch = function() {
                   body <- perform_json(census_request(y, variable, api_key),
                                        paste("Census ACS", y))
                   census_tidy(body, y, variable)
                 }),
      rpspanel_http_error = function(e) {
        cli::cli_warn("Skipping ACS {y}: {conditionMessage(e)}")
        NULL
      }
    )
  })
  pieces <- Filter(Negate(is.null), pieces)
  if (length(pieces) == 0) {
    return(empty_long())
  }
  out <- do.call(rbind, pieces)
  out <- out[out$state %in% states, , drop = FALSE]
  rownames(out) <- NULL
  attr(out, "rps_source") <- "census_acs"
  attr(out, "rps_retrieved") <- attr(pieces[[1]], "rps_retrieved")
  out
}

census_request <- function(year, variable, api_key = "") {
  q <- list(get = paste0("NAME,", variable), `for` = "state:*")
  if (nzchar(api_key)) q$key <- api_key
  build_request(sprintf("https://api.census.gov/data/%d/acs/acs1", year), q)
}

census_tidy <- function(body, year, variable) {
  m <- as.matrix(body)
  header <- m[1, ]
  m <- m[-1, , drop = FALSE]
  data.frame(
    state = harmonise_states(m[, which(header == "state")], warn = FALSE),
    year = as.integer(year),
    series = variable,
    value = parse_num(m[, which(header == variable)]),
    unit = "persons",
    stringsAsFactors = FALSE
  )
}
