# Convert nominal values to real values

Divides by a price index and rescales so that values are expressed in
prices of `base_year`.

## Usage

``` r
deflate(
  x,
  price_index,
  years = NULL,
  base_year = NULL,
  index_years = years,
  index_values = price_index
)
```

## Arguments

- x:

  Numeric vector of nominal values.

- price_index:

  Price index for the same observations as `x` (for example the BEA GDP
  deflator, 2017 = 100).

- years:

  Optional years of the observations; needed with `base_year`.

- base_year:

  Year whose prices the result is expressed in. If `NULL`, the index is
  assumed to equal 100 in the base year and the result is
  `x * 100 / price_index`.

- index_years, index_values:

  Optional full index series used to look up the base-year value when
  `base_year` is not among `years`.

## Value

Numeric vector of real values.

## Examples

``` r
# $10 in 2010 and $12 in 2020 with deflator 90 and 110 (2017 = 100)
deflate(c(10, 12), c(90, 110))
#> [1] 11.11111 10.90909
# Expressed in 2020 prices instead
deflate(c(10, 12), c(90, 110), years = c(2010, 2020), base_year = 2020)
#> [1] 12.22222 12.00000
```
