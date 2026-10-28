# Download state data from the EIA API

Queries version 2 of the US Energy Information Administration API and
returns tidy long data. Results are cached (see
[`rps_cache_dir()`](https://adebayomoses.github.io/rpspanel/reference/cache.md));
the API key is never written to the cache.

## Usage

``` r
fetch_eia(
  dataset = c("seds", "co2", "generation", "retail_sales"),
  series,
  states = NULL,
  years = NULL,
  api_key = NULL,
  cache = TRUE,
  refresh = FALSE
)
```

## Arguments

- dataset:

  One of `"seds"`, `"co2"`, `"generation"`, `"retail_sales"`.

- series:

  Character vector of series identifiers (see Details).

- states:

  States to download; any form accepted by
  [`harmonise_states()`](https://adebayomoses.github.io/rpspanel/reference/harmonise_states.md).
  `NULL` means all 50 states and DC.

- years:

  Integer vector of years. `NULL` downloads all available years.

- api_key:

  EIA API key. Defaults to the `EIA_API_KEY` environment variable.

- cache:

  Use the local download cache.

- refresh:

  Ignore any cached copy and download again.

## Value

A data frame with columns `state`, `year`, `series`, `value` and `unit`,
with attributes `rps_source` and `rps_retrieved` (download time, UTC).

## Details

Supported datasets:

- `"seds"`: State Energy Data System. `series` are SEDS MSN codes, for
  example `"TETCB"` (total energy consumption, billion Btu).

- `"co2"`: energy-related CO2 emissions aggregates for all fuels.
  `series` are EIA sector ids: `"TT"` (total), `"EC"` (electric power),
  `"IC"` (industrial), `"TC"` (transportation), `"RC"` (residential),
  `"CC"` (commercial).

- `"generation"`: net generation, all sectors (forms EIA-923/906/920).
  `series` are fuel type ids such as `"ALL"`, `"COW"`, `"NG"`, `"NUC"`,
  `"HYC"`, `"WND"`, `"SUN"`, `"GEO"`, `"WWW"`, `"WAS"`.

- `"retail_sales"`: electricity retail sales and average price, all
  sectors. `series` are `"sales"` and/or `"price"`.

## Examples

``` r
if (FALSE) { # nzchar(Sys.getenv("EIA_API_KEY"))
fetch_eia("seds", "TETCB", states = c("CA", "TX"), years = 2015:2020)
}
```
