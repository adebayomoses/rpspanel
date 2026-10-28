# Manage the download cache

Downloads are cached as `.rds` files so that a panel can be rebuilt
offline and so that a data vintage stays pinned until you refresh it.
`rps_cache_dir()` returns the cache directory, `rps_cache_list()` lists
cached downloads and `rps_cache_clear()` deletes them.

## Usage

``` r
rps_cache_dir()

rps_cache_list()

rps_cache_clear()
```

## Value

`rps_cache_dir()`: a path. `rps_cache_list()`: a data frame with `file`,
`source`, `retrieved` and `size_kb`. `rps_cache_clear()`: the number of
files removed, invisibly.

## Details

The cache directory defaults to `tools::R_user_dir("rpspanel", "cache")`
and can be changed with `options(rpspanel.cache_dir = "path")`.

## Examples

``` r
rps_cache_dir()
#> [1] "/home/runner/.cache/R/rpspanel"
```
