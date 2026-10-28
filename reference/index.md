# Package index

## Build a panel

One call returns a documented state-by-year panel.

- [`build_panel()`](https://adebayomoses.github.io/rpspanel/reference/build_panel.md)
  : Build a state-year energy-economy panel

## RPS stringency

Coded Renewable Portfolio Standard rules and annual stringency measures.

- [`rps_rules()`](https://adebayomoses.github.io/rpspanel/reference/rps_rules.md)
  : Coded Renewable Portfolio Standard rules
- [`rps_stringency()`](https://adebayomoses.github.io/rpspanel/reference/rps_stringency.md)
  : Annual RPS stringency indices
- [`fetch_rps()`](https://adebayomoses.github.io/rpspanel/reference/fetch_rps.md)
  : Get RPS rule coding from the package or a URL

## Download data

Fetch and cache data from the EIA, BEA and Census APIs.

- [`fetch_eia()`](https://adebayomoses.github.io/rpspanel/reference/fetch_eia.md)
  : Download state data from the EIA API
- [`fetch_bea()`](https://adebayomoses.github.io/rpspanel/reference/fetch_bea.md)
  : Download data from the BEA API
- [`fetch_census()`](https://adebayomoses.github.io/rpspanel/reference/fetch_census.md)
  : Download state data from the Census Bureau API
- [`rps_cache_dir()`](https://adebayomoses.github.io/rpspanel/reference/cache.md)
  [`rps_cache_list()`](https://adebayomoses.github.io/rpspanel/reference/cache.md)
  [`rps_cache_clear()`](https://adebayomoses.github.io/rpspanel/reference/cache.md)
  : Manage the download cache

## Harmonise

Align state identifiers, units and price bases across sources.

- [`harmonise_states()`](https://adebayomoses.github.io/rpspanel/reference/harmonise_states.md)
  : Harmonise state identifiers
- [`us_states()`](https://adebayomoses.github.io/rpspanel/reference/us_states.md)
  : US states and the District of Columbia
- [`deflate()`](https://adebayomoses.github.io/rpspanel/reference/deflate.md)
  : Convert nominal values to real values
- [`convert_units()`](https://adebayomoses.github.io/rpspanel/reference/convert_units.md)
  [`convert_units_available()`](https://adebayomoses.github.io/rpspanel/reference/convert_units.md)
  : Convert between units

## Document and cite

- [`codebook()`](https://adebayomoses.github.io/rpspanel/reference/codebook.md)
  : Variable codebook
- [`cite_sources()`](https://adebayomoses.github.io/rpspanel/reference/cite_sources.md)
  : Citations for the data sources used

## Estimate and export

- [`as_pdata()`](https://adebayomoses.github.io/rpspanel/reference/as_pdata.md)
  : Convert a panel for estimation packages
- [`export_panel()`](https://adebayomoses.github.io/rpspanel/reference/export_panel.md)
  : Export a panel to CSV, Stata or Parquet
