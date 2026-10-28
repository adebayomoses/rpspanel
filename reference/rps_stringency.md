# Annual RPS stringency indices

Turns coded RPS rules
([`rps_rules()`](https://adebayomoses.github.io/rpspanel/reference/rps_rules.md))
into comparable state-year measures, so you can study how strong a
policy is, not only whether it exists.

## Usage

``` r
rps_stringency(
  years,
  states = NULL,
  method = c("adoption", "nominal", "coverage_adjusted", "incremental", "flexibility"),
  rules = rps_rules(),
  baseline = NULL,
  interpolation = c("linear", "step"),
  adopt_from = c("enactment", "first_compliance"),
  floor_zero = FALSE,
  sales = NULL,
  capacity_factor = 0.33
)
```

## Arguments

- years:

  Years to compute.

- states:

  States to include (default: all 50 + DC).

- method:

  One or more of `"adoption"`, `"nominal"`, `"coverage_adjusted"`,
  `"incremental"`, `"flexibility"`.

- rules:

  An `rps_rules` object; defaults to the bundled coding.

- baseline:

  Optional data frame with columns `state` and `baseline_share`, the
  existing (eligible) renewable share of sales or generation at
  enactment. Overrides `baseline_re_share` in the rules.

- interpolation:

  `"linear"` or `"step"`.

- adopt_from:

  Year from which `adoption` is 1: `"enactment"` or
  `"first_compliance"`.

- floor_zero:

  If `TRUE`, negative incremental requirements are set to 0.

- sales:

  Optional data frame with columns `state`, `year` and `sales_gwh`
  (retail electricity sales, GWh, the same as EIA's million kWh), used
  to convert capacity-based standards into shares.
  [`build_panel()`](https://adebayomoses.github.io/rpspanel/reference/build_panel.md)
  supplies it from EIA retail sales.

- capacity_factor:

  Assumed capacity factor of the resources that meet a capacity-based
  standard. The default 0.33 is typical of wind, which met most of the
  Texas and Iowa requirements.

## Value

A data frame with `state`, `year` and the columns for each method:
`rps_adoption`, `rps_nominal`, `rps_coverage_adj`, `rps_incremental`,
`rps_baseline_share`, `rps_oos_rec`, `rps_carveout`, `rps_acp`.

## Details

Methods:

- `adoption`: 1 if an RPS is in force that year (from `adopt_from` until
  any repeal), else 0.

- `nominal`: required renewable share of retail sales in that year. Zero
  before the first compliance year. Between legal targets the
  requirement is interpolated linearly (`interpolation = "linear"`) or
  held at the last legal target (`"step"`); after the final target year
  it is held constant. If the first coded target lies after the
  enactment year, linear interpolation starts from zero at enactment.
  Capacity-based (MW) standards (Texas, Iowa) are converted to an
  equivalent share of covered sales:
  `MW * capacity_factor * 8.76 / (sales_gwh * coverage_share)`, the same
  approach Berkeley Lab uses. This needs `sales`; without it they are
  `NA`.

- `coverage_adjusted`: nominal requirement times the share of retail
  sales covered by the standard.

- `incremental`: requirement beyond the renewable share the state
  already had at enactment, following Yin and Powers (2010):
  `nominal * coverage - baseline_share` while the nominal requirement is
  positive, otherwise 0. The baseline is taken from `baseline`, or from
  the `baseline_re_share` column of the rules. Also returns the baseline
  used (`rps_baseline_share`).
  [`build_panel()`](https://adebayomoses.github.io/rpspanel/reference/build_panel.md)
  measures the baseline the same way the target is defined: including
  hydro for states whose targets count existing hydro
  (`baseline_includes_hydro = 1`, New York), excluding it otherwise.

- `flexibility`: indicators for out-of-state renewable credits,
  carve-outs and alternative compliance payments, set to 0 when no RPS
  is in force.

States missing from the rule coding get `NA` for every measure.

## References

Yin, H., & Powers, N. (2010). Do state renewable portfolio standards
promote in-state renewable generation? *Energy Policy*, 38(2),
1140-1149.

## Examples

``` r
s <- rps_stringency(2000:2030, states = c("CA", "WA", "TX", "FL"),
                    method = c("adoption", "nominal"))
s[s$state == "WA" & s$year %in% 2011:2021, ]
#>     state year rps_adoption rps_nominal
#> 105    WA 2011            1        0.00
#> 106    WA 2012            1        0.03
#> 107    WA 2013            1        0.03
#> 108    WA 2014            1        0.03
#> 109    WA 2015            1        0.03
#> 110    WA 2016            1        0.09
#> 111    WA 2017            1        0.09
#> 112    WA 2018            1        0.09
#> 113    WA 2019            1        0.09
#> 114    WA 2020            1        0.15
#> 115    WA 2021            1        0.15

# Capacity (MW) standards become shares when sales are supplied
tx_sales <- data.frame(state = "TX", year = 2015, sales_gwh = 380000)
rps_stringency(2015, "TX", method = "nominal", sales = tx_sales)
#>   state year rps_nominal
#> 1    TX 2015  0.05909026

# Step interpolation follows the legal schedule exactly
rps_stringency(2012:2020, states = "WA", method = "nominal",
               interpolation = "step")
#>   state year rps_nominal
#> 1    WA 2012        0.03
#> 2    WA 2013        0.03
#> 3    WA 2014        0.03
#> 4    WA 2015        0.03
#> 5    WA 2016        0.09
#> 6    WA 2017        0.09
#> 7    WA 2018        0.09
#> 8    WA 2019        0.09
#> 9    WA 2020        0.15
```
