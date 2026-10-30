panel_groups <- c("energy", "electricity", "emissions", "economy", "rps")

#' Build a state-year energy-economy panel
#'
#' The main entry point of the package. Downloads (or reads from the cache)
#' the requested EIA and BEA series, harmonises state codes and units, merges
#' them into one tidy state-by-year table, adds derived variables and RPS
#' stringency measures, and records the source and vintage of every variable.
#'
#' If one source cannot be reached (no API key, no internet, service down)
#' its variables are left out with a warning and the rest of the panel is
#' still returned.
#'
#' @param states States to include (any form accepted by
#'   [harmonise_states()]); `NULL` for all 50 states and DC.
#' @param years Years to include.
#' @param vars Variable names to include (see [codebook()]). Derived
#'   variables pull in the series they need. Overrides `groups`.
#' @param groups Variable groups to include when `vars` is `NULL`: any of
#'   `"energy"`, `"electricity"`, `"emissions"`, `"economy"`, `"rps"`.
#' @param rps_methods Methods passed to [rps_stringency()].
#' @param rps_rules An `rps_rules` object; defaults to the bundled coding.
#' @param price_base_year Base year for real prices.
#' @param eia_key,bea_key API keys; default to the `EIA_API_KEY` and
#'   `BEA_API_KEY` environment variables.
#' @param cache,refresh Use the download cache / force a fresh download.
#' @param quiet Suppress progress messages.
#' @param ... Further arguments to [rps_stringency()], such as
#'   `interpolation`.
#'
#' @return A data frame of class `rps_panel` with one row per state and year,
#'   columns `state`, `state_name`, `fips`, `year` and the requested
#'   variables. Attributes: `sources` (source, vintage, URL), `codebook`
#'   (definitions of the included variables) and `call`.
#' @export
#' @examples
#' # RPS measures only: no API key needed
#' p <- build_panel(states = c("CA", "TX", "NY"), years = 2000:2025,
#'                  groups = "rps",
#'                  rps_methods = c("adoption", "nominal", "flexibility"))
#' head(p)
#'
#' @examplesIf all(nzchar(Sys.getenv(c("EIA_API_KEY", "BEA_API_KEY"))))
#' p <- build_panel(years = 2005:2022)
#' codebook(p)
build_panel <- function(states = NULL, years = 2001:2022, vars = NULL,
                        groups = panel_groups,
                        rps_methods = c("adoption", "nominal",
                                        "coverage_adjusted", "incremental",
                                        "flexibility"),
                        rps_rules = NULL, price_base_year = 2017,
                        eia_key = NULL, bea_key = NULL,
                        cache = TRUE, refresh = FALSE, quiet = FALSE, ...) {
  call <- match.call()
  states <- resolve_states(states)
  years <- as_years(years)
  rps_methods <- match.arg(rps_methods, names(rps_method_cols),
                           several.ok = TRUE)
  wanted <- select_vars(vars, groups, rps_methods)
  needed <- expand_deps(wanted)
  # Capacity-based (MW) standards are converted with retail sales; fetch them
  # when an EIA key is available rather than making RPS-only panels need one.
  rps_req <- c("rps_nominal", "rps_coverage_adj", "rps_incremental")
  if (any(rps_req %in% wanted) && !"elec_sales" %in% needed &&
      nzchar(eia_key %||% Sys.getenv("EIA_API_KEY"))) {
    needed <- c(needed, "elec_sales")
  }

  fetched <- fetch_panel_sources(needed, states, years, eia_key, bea_key,
                                 cache, refresh, quiet)
  sources <- fetched$sources
  panel <- assemble_panel(fetched$long, states, years)
  panel <- add_derived(panel$panel, needed, price_base_year,
                       panel$deflator_series)

  if (any(registry$group[match(wanted, registry$variable)] == "rps")) {
    rules <- rps_rules %||% fetch_rps()
    panel <- add_rps_measures(panel, rules, years, states, rps_methods, ...)
    rps_src <- attr(rules, "rps_source") %||% "rps_bundled"
    sources[[rps_src]] <- source_row(rps_src, rules)
  }

  finish_panel(panel, wanted, sources, price_base_year, call, quiet)
}

# One row of the `sources` attribute: the source key and its vintage.
source_row <- function(src, obj) {
  data.frame(source = src,
             retrieved = attr(obj, "rps_retrieved") %||% NA_character_,
             stringsAsFactors = FALSE)
}

# Download every data source the requested variables need. A source that
# fails is skipped with a warning so the rest of the panel can still be built.
fetch_panel_sources <- function(needed, states, years, eia_key, bea_key,
                                cache, refresh, quiet) {
  sources <- list()
  long <- list()
  data_vars <- registry[registry$variable %in% needed &
                          !registry$source %in% c("derived", "rps"), ]
  for (src in unique(data_vars$source)) {
    rows <- data_vars[data_vars$source == src, ]
    if (!quiet) {
      cli::cli_inform("Fetching {.field {src}} ({nrow(rows)} series)")
    }
    res <- tryCatch(
      fetch_source(src, rows$series, states, years, eia_key, bea_key,
                   cache, refresh),
      rpspanel_http_error = function(e) e,
      rpspanel_no_key = function(e) e
    )
    if (inherits(res, "condition")) {
      cli::cli_warn(c("Skipping {.field {src}}: {conditionMessage(res)}",
                      i = "Variables left out: {.field {rows$variable}}"))
      next
    }
    sources[[src]] <- source_row(src, res)
    res$variable <- rows$variable[match(res$series, rows$series)]
    long[[src]] <- res[!is.na(res$variable),
                       c("state", "year", "variable", "value")]
  }
  list(sources = sources, long = long)
}

# Merge long (state, year, variable, value) data onto the state-year grid.
# National series (state = NA, such as the deflator) are repeated for every
# state; the full deflator series is kept for rebasing real prices.
assemble_panel <- function(long, states, years) {
  panel <- expand.grid(year = years, state = states,
                       stringsAsFactors = FALSE)[c("state", "year")]
  deflator_series <- NULL
  if (length(long)) {
    long_df <- do.call(rbind, long)
    nat <- long_df[is.na(long_df$state), ]
    st <- long_df[!is.na(long_df$state), ]
    present <- unique(st$variable)
    if (length(present)) {
      wide <- long_to_wide(st, present)
      panel <- merge(panel, wide, by = c("state", "year"), all.x = TRUE)
    }
    for (v in unique(nat$variable)) {
      nv <- nat[nat$variable == v, ]
      panel[[v]] <- nv$value[match(panel$year, nv$year)]
      if (v == "gdp_deflator") deflator_series <- nv
    }
  }
  list(panel = panel, deflator_series = deflator_series)
}

# Add RPS stringency measures, using the panel's generation data for the
# incremental baseline and its retail sales to convert MW standards.
add_rps_measures <- function(panel, rules, years, states, rps_methods, ...) {
  baseline <- NULL
  if ("incremental" %in% rps_methods &&
      "re_share_nonhydro" %in% names(panel)) {
    baseline <- baseline_from_panel(panel, rules)
  }
  sales <- if ("elec_sales" %in% names(panel)) {
    data.frame(state = panel$state, year = panel$year,
               sales_gwh = panel$elec_sales)
  }
  s <- rps_stringency(years, states, method = rps_methods, rules = rules,
                      baseline = baseline, sales = sales, ...)
  merge(panel, s, by = c("state", "year"), all.x = TRUE)
}

# Order rows and columns, add state names and FIPS codes, and attach the
# sources, codebook and call attributes.
finish_panel <- function(panel, wanted, sources, price_base_year, call,
                         quiet) {
  keep <- intersect(wanted, names(panel))
  missing_vars <- setdiff(wanted, names(panel))
  if (length(missing_vars) && !quiet) {
    cli::cli_inform("Not available: {.field {missing_vars}}")
  }
  panel$state_name <- state_table$name[match(panel$state, state_table$abbr)]
  panel$fips <- state_table$fips[match(panel$state, state_table$abbr)]
  panel <- panel[order(panel$state, panel$year),
                 c("state", "state_name", "fips", "year", keep)]
  rownames(panel) <- NULL

  src_df <- if (length(sources)) {
    do.call(rbind, sources)
  } else {
    data.frame(source = character(), retrieved = character())
  }
  src_df <- merge(src_df, source_info, by = "source", all.x = TRUE,
                  sort = FALSE)
  rownames(src_df) <- NULL

  structure(panel,
            class = c("rps_panel", "data.frame"),
            sources = src_df,
            codebook = codebook(keep),
            price_base_year = price_base_year,
            call = call)
}

select_vars <- function(vars, groups, rps_methods) {
  if (!is.null(vars)) {
    unknown <- setdiff(vars, registry$variable)
    if (length(unknown)) {
      cli::cli_abort(c("Unknown variable{?s}: {.val {unknown}}.",
                       i = "See {.fn codebook} for available variables."))
    }
    return(vars)
  }
  groups <- match.arg(groups, panel_groups, several.ok = TRUE)
  out <- registry$variable[registry$group %in% groups]
  rps_keep <- unlist(rps_method_cols[rps_methods], use.names = FALSE)
  is_rps <- registry$group[match(out, registry$variable)] == "rps"
  out[!is_rps | out %in% rps_keep]
}

expand_deps <- function(vars) {
  repeat {
    deps <- registry$deps[match(vars, registry$variable)]
    deps <- unique(unlist(strsplit(deps[!is.na(deps)], ",", fixed = TRUE)))
    new <- setdiff(deps, vars)
    if (length(new) == 0) {
      return(vars)
    }
    vars <- c(vars, new)
  }
}

fetch_source <- function(src, series, states, years, eia_key, bea_key,
                         cache, refresh) {
  eia <- function(dataset) {
    fetch_eia(dataset, series, states, years, eia_key, cache, refresh)
  }
  switch(src,
    eia_seds = eia("seds"),
    eia_generation = eia("generation"),
    eia_retail_sales = eia("retail_sales"),
    eia_co2 = eia("co2"),
    bea_regional = ,
    bea_nipa = {
      dataset <- if (src == "bea_nipa") "NIPA" else "Regional"
      # Download whole series (all years) so the deflator base year is
      # available even when it is outside `years`.
      pieces <- lapply(series, function(s) {
        tl <- strsplit(s, ":", fixed = TRUE)[[1]]
        fetch_bea(tl[1], tl[2], dataset = dataset, states = states,
                  years = if (dataset == "NIPA") NULL else years,
                  api_key = bea_key, cache = cache, refresh = refresh)
      })
      out <- do.call(rbind, pieces)
      attr(out, "rps_retrieved") <- attr(pieces[[1]], "rps_retrieved")
      out
    }
  )
}

derived_fns <- list(
  gen_renew_nonhydro = function(p) {
    p$gen_wind + p$gen_solar + p$gen_geothermal + p$gen_wood +
      p$gen_biomass_other
  },
  re_share_nonhydro = function(p) p$gen_renew_nonhydro / p$gen_total,
  re_share_total = function(p) {
    (p$gen_renew_nonhydro + p$gen_hydro) / p$gen_total
  },
  energy_cons_pc = function(p) p$energy_cons_total * 1000 / p$population,
  energy_intensity = function(p) p$energy_cons_total * 1000 / p$gdp_real,
  co2_pc = function(p) p$co2_total * 1e6 / p$population,
  co2_intensity = function(p) p$co2_total * 1e6 / p$gdp_real,
  gdp_real_pc = function(p) p$gdp_real * 1e6 / p$population
)

add_derived <- function(panel, needed, price_base_year, deflator_series) {
  panel <- fill_missing_fuels(panel, needed)
  for (v in names(derived_fns)) {
    deps <- strsplit(registry$deps[registry$variable == v], ",",
                     fixed = TRUE)[[1]]
    if (v %in% needed && all(deps %in% names(panel))) {
      panel[[v]] <- derived_fns[[v]](panel)
    }
  }
  add_real_prices(panel, needed, price_base_year, deflator_series)
}

# EIA returns no rows for fuels a state does not use: record those as 0 when
# the state's total generation is reported.
fill_missing_fuels <- function(panel, needed) {
  if (!"gen_total" %in% names(panel)) {
    return(panel)
  }
  fuels <- registry$variable[registry$source == "eia_generation" &
                               registry$series != "ALL"]
  for (f in setdiff(intersect(fuels, needed), names(panel))) {
    panel[[f]] <- NA_real_
  }
  for (f in intersect(fuels, names(panel))) {
    fill <- is.na(panel[[f]]) & !is.na(panel$gen_total)
    panel[[f]][fill] <- 0
  }
  panel
}

# Real prices in `price_base_year` dollars, using the full deflator series so
# the base year can lie outside the panel years.
add_real_prices <- function(panel, needed, price_base_year, deflator_series) {
  real_prices <- c(elec_price_real = "elec_price",
                   energy_price_real = "energy_price_avg")
  for (v in names(real_prices)) {
    nom <- real_prices[[v]]
    if (v %in% needed && nom %in% names(panel) &&
        "gdp_deflator" %in% names(panel)) {
      panel[[v]] <- deflate(panel[[nom]], panel$gdp_deflator,
                            years = panel$year,
                            base_year = price_base_year,
                            index_years = deflator_series$year,
                            index_values = deflator_series$value)
    }
  }
  panel
}

# Renewable share of generation in the enactment year, or the first later
# year with data. It includes hydro for states whose targets count existing
# hydro (`baseline_includes_hydro = 1`) and excludes it otherwise.
baseline_from_panel <- function(panel, rules) {
  r <- rules$rules[which(rules$rules$has_rps == 1L), ]
  b <- vapply(seq_len(nrow(r)), function(i) {
    # Measure the baseline the way the target is defined
    use_total <- isTRUE(r$baseline_includes_hydro[i] == 1L) &&
      "re_share_total" %in% names(panel)
    col <- if (use_total) {
      "re_share_total"
    } else {
      "re_share_nonhydro"
    }
    d <- panel[panel$state == r$state[i] & !is.na(panel[[col]]) &
                 panel$year >= r$enacted_year[i], c("year", col)]
    if (nrow(d) == 0) NA_real_ else d[[col]][which.min(d$year)]
  }, numeric(1))
  data.frame(state = r$state, baseline_share = b, stringsAsFactors = FALSE)
}

#' @export
print.rps_panel <- function(x, n = 6, ...) {
  if (!all(c("state", "year") %in% names(x)) || nrow(x) == 0) {
    print(as.data.frame(unclass_panel(x)), ...)
    return(invisible(x))
  }
  yrs <- range(x$year)
  vars <- setdiff(names(x), c("state", "state_name", "fips", "year"))
  n_st <- length(unique(x$state))
  cat(sprintf("<rps_panel>: %d state%s x %d-%d (%d rows), %d variable%s\n",
              n_st, if (n_st == 1) "" else "s", yrs[1], yrs[2], nrow(x),
              length(vars), if (length(vars) == 1) "" else "s"))
  src <- attr(x, "sources")
  if (!is.null(src) && nrow(src)) {
    cat("Sources:", toString(src$source), "\n")
  }
  print(utils::head(as.data.frame(unclass_panel(x)), n), ...)
  if (nrow(x) > n) cat(sprintf("# ... with %d more rows\n", nrow(x) - n))
  invisible(x)
}

unclass_panel <- function(x) {
  attr(x, "sources") <- NULL
  attr(x, "codebook") <- NULL
  attr(x, "call") <- NULL
  attr(x, "price_base_year") <- NULL
  class(x) <- "data.frame"
  x
}
