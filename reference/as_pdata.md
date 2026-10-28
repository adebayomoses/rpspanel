# Convert a panel for estimation packages

Prepares a panel for `plm`, `fixest` or `csdm`. The package does not
re-implement estimators; it hands a correctly indexed panel to them.

## Usage

``` r
as_pdata(x, to = c("plm", "fixest", "csdm", "data.frame"))
```

## Arguments

- x:

  An `rps_panel` (or any data frame with `state` and `year`).

- to:

  Target package.

## Value

An object of the requested class.

## Details

- `"plm"`: a `pdata.frame` indexed by `state` and `year`.

- `"fixest"`: a `fixest_panel` (for lag and lead operators) indexed by
  `state` and `year`.

- `"csdm"`: a plain data frame sorted by `state` and `year`, with
  `state` as a factor; pass `id = "state"` and `time = "year"` to
  `csdm`.

- `"data.frame"`: the same sorted plain data frame.

## Examples

``` r
p <- build_panel(states = c("CA", "TX"), years = 2005:2020, groups = "rps",
                 rps_methods = c("adoption", "nominal"))
head(as_pdata(p, "data.frame"))
#>   state state_name fips year rps_adoption rps_nominal
#> 1    CA California   06 2005            1   0.1417857
#> 2    CA California   06 2006            1   0.1534286
#> 3    CA California   06 2007            1   0.1650714
#> 4    CA California   06 2008            1   0.1767143
#> 5    CA California   06 2009            1   0.1883571
#> 6    CA California   06 2010            1   0.2000000
if (requireNamespace("plm", quietly = TRUE)) {
  class(as_pdata(p, "plm"))
}
#> [1] "pdata.frame" "data.frame" 
```
