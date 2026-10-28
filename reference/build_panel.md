# Build a state-year energy-economy panel

The main entry point of the package. Downloads (or reads from the cache)
the requested EIA and BEA series, harmonises state codes and units,
merges them into one tidy state-by-year table, adds derived variables
and RPS stringency measures, and records the source and vintage of every
variable.

## Usage

``` r
build_panel(
  states = NULL,
  years = 2001:2022,
  vars = NULL,
  groups = panel_groups,
  rps_methods = c("adoption", "nominal", "coverage_adjusted", "incremental",
    "flexibility"),
  rps_rules = NULL,
  price_base_year = 2017,
  eia_key = NULL,
  bea_key = NULL,
  cache = TRUE,
  refresh = FALSE,
  quiet = FALSE,
  ...
)
```

## Arguments

- states:

  States to include (any form accepted by
  [`harmonise_states()`](https://adebayomoses.github.io/rpspanel/reference/harmonise_states.md));
  `NULL` for all 50 states and DC.

- years:

  Years to include.

- vars:

  Variable names to include (see
  [`codebook()`](https://adebayomoses.github.io/rpspanel/reference/codebook.md)).
  Derived variables pull in the series they need. Overrides `groups`.

- groups:

  Variable groups to include when `vars` is `NULL`: any of `"energy"`,
  `"electricity"`, `"emissions"`, `"economy"`, `"rps"`.

- rps_methods:

  Methods passed to
  [`rps_stringency()`](https://adebayomoses.github.io/rpspanel/reference/rps_stringency.md).

- rps_rules:

  An `rps_rules` object; defaults to the bundled coding.

- price_base_year:

  Base year for real prices.

- eia_key, bea_key:

  API keys; default to the `EIA_API_KEY` and `BEA_API_KEY` environment
  variables.

- cache, refresh:

  Use the download cache / force a fresh download.

- quiet:

  Suppress progress messages.

- ...:

  Further arguments to
  [`rps_stringency()`](https://adebayomoses.github.io/rpspanel/reference/rps_stringency.md),
  such as `interpolation`.

## Value

A data frame of class `rps_panel` with one row per state and year,
columns `state`, `state_name`, `fips`, `year` and the requested
variables. Attributes: `sources` (source, vintage, URL), `codebook`
(definitions of the included variables) and `call`.

## Details

If one source cannot be reached (no API key, no internet, service down)
its variables are left out with a warning and the rest of the panel is
still returned.

## Examples

``` r
# RPS measures only: no API key needed
p <- build_panel(states = c("CA", "TX", "NY"), years = 2000:2025,
                 groups = "rps",
                 rps_methods = c("adoption", "nominal", "flexibility"))
head(p)
#> <rps_panel>: 1 state x 2000-2005 (6 rows), 5 variables
#> Sources: rps_bundled 
#>   state state_name fips year rps_adoption rps_nominal rps_oos_rec rps_carveout
#> 1    CA California   06 2000            0   0.0000000           0            0
#> 2    CA California   06 2001            0   0.0000000           0            0
#> 3    CA California   06 2002            1   0.0000000           1            0
#> 4    CA California   06 2003            1   0.1185000           1            0
#> 5    CA California   06 2004            1   0.1301429           1            0
#> 6    CA California   06 2005            1   0.1417857           1            0
#>   rps_acp
#> 1       0
#> 2       0
#> 3       0
#> 4       0
#> 5       0
#> 6       0

if (FALSE) { # nzchar(Sys.getenv("EIA_API_KEY")) && nzchar(Sys.getenv("BEA_API_KEY"))
p <- build_panel(years = 2005:2022)
codebook(p)
}
```
