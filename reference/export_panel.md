# Export a panel to CSV, Stata or Parquet

Writes the panel and, by default, its codebook next to it
(`<name>_codebook.csv`). Stata files carry variable labels from the
codebook.

## Usage

``` r
export_panel(x, path, format = NULL, codebook = TRUE)
```

## Arguments

- x:

  An `rps_panel`.

- path:

  Output file path.

- format:

  `"csv"`, `"stata"` or `"parquet"`. Guessed from the file extension
  (`.csv`, `.dta`, `.parquet`) when `NULL`.

- codebook:

  Also write the codebook as CSV.

## Value

The path, invisibly.

## Examples

``` r
p <- build_panel(states = "CA", years = 2010:2020, groups = "rps",
                 rps_methods = "nominal")
f <- tempfile(fileext = ".csv")
export_panel(p, f)
head(read.csv(f))
#>   state state_name fips year rps_nominal
#> 1    CA California    6 2010   0.2000000
#> 2    CA California    6 2011   0.2000000
#> 3    CA California    6 2012   0.2000000
#> 4    CA California    6 2013   0.2000000
#> 5    CA California    6 2014   0.2166667
#> 6    CA California    6 2015   0.2333333
```
