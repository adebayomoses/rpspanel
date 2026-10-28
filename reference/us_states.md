# US states and the District of Columbia

Returns the 51 geographic units covered by the package with their USPS
abbreviation, name and two-digit FIPS code.

## Usage

``` r
us_states()
```

## Value

A data frame with columns `abbr`, `name` and `fips`.

## Examples

``` r
head(us_states())
#>   abbr       name fips
#> 1   AL    Alabama   01
#> 2   AK     Alaska   02
#> 3   AZ    Arizona   04
#> 4   AR   Arkansas   05
#> 5   CA California   06
#> 6   CO   Colorado   08
```
