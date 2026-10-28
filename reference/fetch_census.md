# Download state data from the Census Bureau API

Retrieves a state-level variable from the American Community Survey
1-year estimates (default: total population, `B01003_001E`). This is an
optional supplement:
[`build_panel()`](https://adebayomoses.github.io/rpspanel/reference/build_panel.md)
takes population from BEA, which is available for every year. ACS 1-year
estimates start in 2005, and the standard 2020 release does not exist,
so that year is skipped.

## Usage

``` r
fetch_census(
  years,
  variable = "B01003_001E",
  states = NULL,
  api_key = NULL,
  cache = TRUE,
  refresh = FALSE
)
```

## Arguments

- years:

  Years to download (2005 onward).

- variable:

  ACS variable code.

- states:

  States to download; any form accepted by
  [`harmonise_states()`](https://adebayomoses.github.io/rpspanel/reference/harmonise_states.md).
  `NULL` means all 50 states and DC.

- api_key:

  Census API key. Defaults to the `CENSUS_API_KEY` environment variable.
  The Census API rejects requests without a key; register for a free one
  at <https://api.census.gov/data/key_signup.html>.

- cache:

  Use the local download cache.

- refresh:

  Ignore any cached copy and download again.

## Value

A data frame with columns `state`, `year`, `series`, `value` and `unit`
("persons" for the default population variable, otherwise `NA`; look up
other ACS variables in the Census documentation). Years that fail to
download are skipped with a warning.

## Examples

``` r
if (FALSE) { # nzchar(Sys.getenv("CENSUS_API_KEY"))
fetch_census(2019, states = c("CA", "TX"))
}
```
