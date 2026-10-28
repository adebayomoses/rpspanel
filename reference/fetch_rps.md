# Get RPS rule coding from the package or a URL

Without arguments, returns the bundled coding (same as
[`rps_rules()`](https://adebayomoses.github.io/rpspanel/reference/rps_rules.md)).
With URLs, downloads CSV files that follow the
[`rps_rules()`](https://adebayomoses.github.io/rpspanel/reference/rps_rules.md)
layout, for example a shared or corrected version of the coding, and
caches them. The package does not redistribute DSIRE, LBNL or PUDL data;
if you build your own coding from those sources, check their terms of
use.

## Usage

``` r
fetch_rps(rules_url = NULL, targets_url = NULL, cache = TRUE, refresh = FALSE)
```

## Arguments

- rules_url, targets_url:

  URLs (or local paths) of CSV files.

- cache:

  Use the local download cache.

- refresh:

  Ignore any cached copy and download again.

## Value

An `rps_rules` object.

## Examples

``` r
fetch_rps()
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
```
