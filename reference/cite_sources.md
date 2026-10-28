# Citations for the data sources used

Lists the citation for every source used in a panel, including the
retrieval date (vintage), plus the citation for the package itself.

## Usage

``` r
cite_sources(x = NULL, format = c("text", "bibtex"))
```

## Arguments

- x:

  An `rps_panel`, a character vector of source keys (see `source` in
  [`codebook()`](https://adebayomoses.github.io/rpspanel/reference/codebook.md)),
  or `NULL` for all sources.

- format:

  `"text"` for plain-text references or `"bibtex"`.

## Value

A character vector of references of class `rps_citation`, which prints
one reference per paragraph.

## Examples

``` r
cite_sources(c("eia_seds", "bea_regional"))
#> U.S. Energy Information Administration (2026). State Energy Data System (SEDS). <https://www.eia.gov/state/seds/>.
#> 
#> U.S. Bureau of Economic Analysis (2026). Regional Economic Accounts (SAGDP, SAINC tables). <https://apps.bea.gov/regional/>.
#> 
#> Adebayo, M. (2026). rpspanel: US state energy-economy panels with renewable portfolio standards. R package version 0.1.0.9000.
#> 
p <- build_panel(states = "CA", years = 2010:2020, groups = "rps",
                 rps_methods = "nominal")
cite_sources(p, format = "bibtex")
#> @misc{rps_bundled,
#>   author = {{rpspanel authors}},
#>   title = {rpspanel RPS rule coding (bundled)},
#>   year = {2026},
#>   url = {https://github.com/adebayomoses/rpspanel},
#>   note = {Coding shipped with rpspanel 0.1.0.9000.},
#> }
#> 
#> @Manual{rpspanel,
#>   author = {Moses Adebayo},
#>   title = {rpspanel: US State Energy-Economy Panels with Renewable Portfolio Standards},
#>   note = {R package version 0.1.0.9000},
#>   year = {2026},
#> }
#> 
```
