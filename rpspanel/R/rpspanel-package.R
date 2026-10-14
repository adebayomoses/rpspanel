#' rpspanel: US state energy-economy panels with RPS stringency measures
#'
#' The package has four layers:
#'
#' 1. **Fetch and cache**: [fetch_eia()], [fetch_bea()], [fetch_census()],
#'    [fetch_rps()] download each source through its API (or read the bundled
#'    RPS coding), cache the result locally and fail with clear messages when
#'    a service is unavailable.
#' 2. **Harmonise**: [harmonise_states()], [deflate()], [convert_units()] align
#'    state codes, units and price bases.
#' 3. **Panel builder**: [build_panel()] merges everything into one tidy
#'    state-year table with source and vintage attributes.
#' 4. **RPS stringency**: [rps_rules()] and [rps_stringency()] turn coded RPS
#'    rules into annual stringency indices.
#'
#' Documentation helpers ([codebook()], [cite_sources()]) and output helpers
#' ([as_pdata()], [export_panel()]) complete the workflow.
#'
#' @section API keys:
#' EIA and BEA data require free API keys. Store them in your `.Renviron`
#' file as `EIA_API_KEY` and `BEA_API_KEY` (and optionally `CENSUS_API_KEY`).
#'
#' @section Options:
#' * `rpspanel.cache_dir`: directory used for the download cache (default
#'   `tools::R_user_dir("rpspanel", "cache")`).
#' * `rpspanel.cache_max_age`: maximum age of cached downloads in days
#'   (default `Inf`, so data vintages stay pinned until you refresh them).
#'
#' @keywords internal
"_PACKAGE"
