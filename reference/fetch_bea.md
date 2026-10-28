# Download data from the BEA API

Retrieves state series from the Bureau of Economic Analysis Regional
accounts, or national series from the NIPA tables (used for price
deflators).

## Usage

``` r
fetch_bea(
  table,
  line_code,
  dataset = c("Regional", "NIPA"),
  states = NULL,
  years = NULL,
  api_key = NULL,
  cache = TRUE,
  refresh = FALSE
)
```

## Arguments

- table:

  BEA table name, for example `"SAGDP9"` or `"T10109"`.

- line_code:

  Line code (Regional) or line number (NIPA).

- dataset:

  `"Regional"` (state data) or `"NIPA"` (national data).

- states:

  States to keep (Regional only); `NULL` keeps all 50 + DC.

- years:

  Years to keep; `NULL` keeps all available years.

- api_key:

  BEA API key. Defaults to the `BEA_API_KEY` environment variable.

- cache:

  Use the local download cache.

- refresh:

  Ignore any cached copy and download again.

## Value

A data frame with columns `state` (`NA` for NIPA data), `year`, `series`
(`"<table>:<line>"`), `value` and `unit`. Values are in the units
reported by BEA (the `UNIT_MULT` scale factor is already applied to the
unit label, not the value).

## Details

Useful Regional tables and line codes:

- `SAGDP9` line 1: real GDP, all industries (millions of chained 2017
  dollars); line 12: manufacturing.

- `SAGDP2` line 1: nominal GDP (millions of current dollars).

- `SAINC1` line 1: personal income (millions of dollars); line 2:
  population (persons); line 3: per capita personal income (dollars).

Useful NIPA table: `T10109` line 1, the implicit price deflator for GDP
(index, 2017 = 100).

## Examples

``` r
if (FALSE) { # nzchar(Sys.getenv("BEA_API_KEY"))
fetch_bea("SAGDP9", 1, states = "CA", years = 2015:2020)
fetch_bea("T10109", 1, dataset = "NIPA")
}
```
