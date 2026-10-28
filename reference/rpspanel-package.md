# rpspanel: US state energy-economy panels with RPS stringency measures

The package has four layers:

## Details

1.  **Fetch and cache**:
    [`fetch_eia()`](https://adebayomoses.github.io/rpspanel/reference/fetch_eia.md),
    [`fetch_bea()`](https://adebayomoses.github.io/rpspanel/reference/fetch_bea.md),
    [`fetch_census()`](https://adebayomoses.github.io/rpspanel/reference/fetch_census.md),
    [`fetch_rps()`](https://adebayomoses.github.io/rpspanel/reference/fetch_rps.md)
    download each source through its API (or read the bundled RPS
    coding), cache the result locally and fail with clear messages when
    a service is unavailable.

2.  **Harmonise**:
    [`harmonise_states()`](https://adebayomoses.github.io/rpspanel/reference/harmonise_states.md),
    [`deflate()`](https://adebayomoses.github.io/rpspanel/reference/deflate.md),
    [`convert_units()`](https://adebayomoses.github.io/rpspanel/reference/convert_units.md)
    align state codes, units and price bases.

3.  **Panel builder**:
    [`build_panel()`](https://adebayomoses.github.io/rpspanel/reference/build_panel.md)
    merges everything into one tidy state-year table with source and
    vintage attributes.

4.  **RPS stringency**:
    [`rps_rules()`](https://adebayomoses.github.io/rpspanel/reference/rps_rules.md)
    and
    [`rps_stringency()`](https://adebayomoses.github.io/rpspanel/reference/rps_stringency.md)
    turn coded RPS rules into annual stringency indices.

Documentation helpers
([`codebook()`](https://adebayomoses.github.io/rpspanel/reference/codebook.md),
[`cite_sources()`](https://adebayomoses.github.io/rpspanel/reference/cite_sources.md))
and output helpers
([`as_pdata()`](https://adebayomoses.github.io/rpspanel/reference/as_pdata.md),
[`export_panel()`](https://adebayomoses.github.io/rpspanel/reference/export_panel.md))
complete the workflow.

## API keys

EIA and BEA data require free API keys. Store them in your `.Renviron`
file as `EIA_API_KEY` and `BEA_API_KEY`, plus `CENSUS_API_KEY` if you
use
[`fetch_census()`](https://adebayomoses.github.io/rpspanel/reference/fetch_census.md).

## Options

- `rpspanel.cache_dir`: directory used for the download cache (default
  `tools::R_user_dir("rpspanel", "cache")`).

- `rpspanel.cache_max_age`: maximum age of cached downloads in days
  (default `Inf`, so data vintages stay pinned until you refresh them).

## See also

Useful links:

- <https://github.com/adebayomoses/rpspanel>

- <https://adebayomoses.github.io/rpspanel/>

- Report bugs at <https://github.com/adebayomoses/rpspanel/issues>

## Author

**Maintainer**: Moses Adebayo <adebayomoses2021@gmail.com>
([ORCID](https://orcid.org/0009-0000-0768-0801)) \[copyright holder\]

Authors:

- Moses Adebayo <adebayomoses2021@gmail.com>
  ([ORCID](https://orcid.org/0009-0000-0768-0801)) \[copyright holder\]
