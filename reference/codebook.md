# Variable codebook

Returns the definition, unit, source, source series identifier and
transformation of every variable the package can produce, or of the
variables in a panel built with
[`build_panel()`](https://adebayomoses.github.io/rpspanel/reference/build_panel.md).

## Usage

``` r
codebook(x = NULL, group = NULL)
```

## Arguments

- x:

  `NULL` (all variables), a character vector of variable names, or an
  `rps_panel`.

- group:

  Optional group filter: `"energy"`, `"electricity"`, `"emissions"`,
  `"economy"` or `"rps"`.

## Value

A data frame with columns `variable`, `group`, `label`, `unit`,
`source`, `series` and `transformation`.

## Examples

``` r
codebook(group = "rps")
#>             variable group                                             label
#> 1       rps_adoption   rps                                      RPS in force
#> 2        rps_nominal   rps                           Nominal RPS requirement
#> 3   rps_coverage_adj   rps                 Coverage-adjusted RPS requirement
#> 4    rps_incremental   rps Incremental RPS requirement (Yin and Powers 2010)
#> 5 rps_baseline_share   rps         Existing renewable share at RPS enactment
#> 6        rps_oos_rec   rps        RPS accepts out-of-state renewable credits
#> 7       rps_carveout   rps                      RPS has a resource carve-out
#> 8            rps_acp   rps         RPS has an alternative compliance payment
#>                          unit source            series
#> 1                         0/1    rps          adoption
#> 2 share of retail sales (0-1)    rps           nominal
#> 3 share of retail sales (0-1)    rps coverage_adjusted
#> 4     share (can be negative)    rps       incremental
#> 5                 share (0-1)    rps       incremental
#> 6                         0/1    rps       flexibility
#> 7                         0/1    rps       flexibility
#> 8                         0/1    rps       flexibility
#>                                                                                                                                                                 transformation
#> 1                                                                                                                                          rps_stringency(method = "adoption")
#> 2 Legal targets interpolated between target years; 0 before first compliance year; MW targets (TX, IA) converted to a share of covered sales (capacity factor 0.33 by default)
#> 3                                                                                                                                                 rps_nominal * coverage_share
#> 4                                                                                                          rps_coverage_adj - rps_baseline_share while rps_nominal > 0, else 0
#> 5                       Renewable share of generation in the enactment year (or the first year with data); includes hydro where the targets count it (NY), otherwise non-hydro
#> 6                                                                                                                                      Coded design feature times rps_adoption
#> 7                                                                                                                                      Coded design feature times rps_adoption
#> 8                                                                                                                                      Coded design feature times rps_adoption
codebook(c("co2_pc", "gdp_real"))
#>   variable     group                    label                             unit
#> 1   co2_pc emissions CO2 emissions per capita       metric tons CO2 per person
#> 2 gdp_real   economy Real GDP, all industries millions of chained 2017 dollars
#>         source   series               transformation
#> 1      derived     <NA> co2_total * 1e6 / population
#> 2 bea_regional SAGDP9:1                 As published
```
