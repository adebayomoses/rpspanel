# Harmonise state identifiers

Converts state names, USPS abbreviations or FIPS codes (two-digit,
numeric, or five-digit BEA `GeoFips` such as `"06000"`) to a single
representation. Matching ignores case, surrounding white space and
trailing footnote markers such as the asterisks BEA appends to some
state names.

## Usage

``` r
harmonise_states(x, to = c("abbr", "name", "fips"), warn = TRUE)
```

## Arguments

- x:

  A character or numeric vector of state identifiers.

- to:

  Output representation: `"abbr"` (default), `"name"` or `"fips"`.

- warn:

  If `TRUE`, warn about values that could not be matched (for example
  `"US"` or regional aggregates). Unmatched values become `NA`.

## Value

A character vector the same length as `x`.

## Examples

``` r
harmonise_states(c("California", "tx", "06", 36, "11000", "Alaska *"))
#> [1] "CA" "TX" "CA" "NY" "DC" "AK"
harmonise_states(c("CA", "NY"), to = "fips")
#> [1] "06" "36"
```
