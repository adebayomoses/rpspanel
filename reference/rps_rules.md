# Coded Renewable Portfolio Standard rules

Reads the RPS rule coding that feeds
[`rps_stringency()`](https://adebayomoses.github.io/rpspanel/reference/rps_stringency.md).
By default this is the coding bundled with the package in
`inst/extdata/`; you can point to your own files with the same layout to
correct or extend it.

## Usage

``` r
rps_rules(states = NULL, rules_path = NULL, targets_path = NULL)
```

## Arguments

- states:

  Optional states to keep.

- rules_path, targets_path:

  Paths to CSV files with your own coding. Default: the files bundled
  with the package.

## Value

An object of class `rps_rules`: a list with data frames `rules` and
`targets`.

## Details

The coding has two tables:

**rules** (one row per state): `has_rps` (1 = mandatory RPS, 0 = none),
`enacted_year`, `first_compliance_year`, `repeal_year`, `target_type`
(`"share"` of retail sales, or `"capacity_mw"`), `final_target`,
`final_target_year`, `coverage_share` (share of retail sales covered),
`out_of_state_rec`, `carveout`, `acp` (0/1 design indicators),
`carveout_types`, `acp_usd_mwh`, `baseline_re_share` (optional existing
renewable share at enactment; filled from data by
[`build_panel()`](https://adebayomoses.github.io/rpspanel/reference/build_panel.md)),
`source`, `verified` and `notes`. Optional: `baseline_includes_hydro` (1
if the targets count existing hydro, so the incremental baseline should
too; default 0).

**targets** (one row per legal target): `state`, `year`, `target` (share
of sales between 0 and 1, or MW for capacity targets).

States that do not appear in the rules table are treated as *not yet
coded*, and their stringency measures are `NA` rather than zero.

## Status of the bundled coding

The bundled coding covers all 50 states and DC. Rows with
`verified = TRUE` have been hand-checked against the statute, the DSIRE
program page and the LBNL RPS & CES data, as set out in the package's
validation plan; `source` and `notes` give the citations and coding
choices. Please report corrections on the issue tracker.

## Examples

``` r
r <- rps_rules()
r
#> <rps_rules>: 51 coded states (33 with an RPS), 273 legal targets
#>  state enacted_year first_compliance_year target_type final_target
#>     AZ         2006                  2006       share         0.15
#>     CA         2002                  2003       share          0.6
#>     CO         2004                  2007       share          0.3
#>     CT         1998                  2001       share         0.29
#>     DC         2005                  2007       share            1
#>     DE         2005                  2007       share          0.4
#>     HI         2004                  2005       share            1
#>     IA         1983                  1983 capacity_mw          105
#>     IL         2007                  2008       share          0.5
#>     KS         2009                  2011       share       0.0726
#>     MA         1997                  2003       share          0.4
#>     MD         2004                  2006       share          0.5
#>     ME         1997                  2000       share          0.6
#>     MI         2008                  2012       share          0.6
#>     MN         2007                  2010       share         0.55
#>     MO         2008                  2011       share         0.15
#>     MT         2005                  2008       share         0.15
#>     NC         2007                  2012       share        0.125
#>     NH         2007                  2008       share        0.157
#>     NJ         1999                  2002       share          0.5
#>     NM         2004                  2006       share          0.8
#>     NV         1997                  2003       share          0.5
#>     NY         2004                  2006       share          0.7
#>     OH         2008                  2009       share        0.085
#>     OR         2007                  2011       share          0.5
#>     PA         2004                  2007       share         0.08
#>     RI         2004                  2007       share         0.98
#>     TX         1999                  2002 capacity_mw         5880
#>     VA         2020                  2021       share            1
#>     VT         2015                  2017       share            1
#>     WA         2006                  2012       share         0.15
#>     WI         1999                  2006       share          0.1
#>     WV         2009                  2015       share         0.25
#>  final_target_year coverage_share
#>               2025          0.589
#>               2030          0.985
#>               2020          0.990
#>               2030          1.000
#>               2032          1.000
#>               2035          0.918
#>               2045          1.000
#>               1983          0.862
#>               2040          0.929
#>               2014          0.825
#>               2030          0.887
#>               2030          0.980
#>               2040          0.956
#>               2035          1.000
#>               2035          0.999
#>               2021          0.726
#>               2015          0.742
#>               2021          0.998
#>               2025          1.000
#>               2030          0.990
#>               2040          0.902
#>               2030          0.929
#>               2030          0.983
#>               2026          0.734
#>               2040          0.808
#>               2021          0.976
#>               2033          0.991
#>               2015          0.757
#>               2045          0.722
#>               2035          1.000
#>               2020          0.874
#>               2015          1.000
#>               2025          0.994
head(r$targets)
#>   state year target
#> 1    AZ 2006 0.0125
#> 2    AZ 2009 0.0200
#> 3    AZ 2010 0.0250
#> 4    AZ 2015 0.0500
#> 5    AZ 2025 0.1500
#> 6    CA 2003 0.1185
```
