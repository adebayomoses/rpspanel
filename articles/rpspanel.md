# Getting started with rpspanel

`rpspanel` builds a documented, reproducible state-by-year panel for the
50 US states and DC. It combines EIA energy, electricity and CO2 data,
BEA GDP, income and population, and standardised Renewable Portfolio
Standard (RPS) stringency measures.

``` r

library(rpspanel)
```

## API keys

EIA and BEA data need free API keys:

- EIA: <https://www.eia.gov/opendata/register.php>
- BEA: <https://apps.bea.gov/API/signup/>

Put them in your `.Renviron` file (open it with
`usethis::edit_r_environ()`), then restart R:

    EIA_API_KEY=your-eia-key
    BEA_API_KEY=your-bea-key

## One call, one panel

``` r

panel <- build_panel(years = 2005:2022)
panel
```

Pick variables by group or by name. Derived variables fetch what they
need:

``` r

small <- build_panel(
  states = c("CA", "TX", "NY", "IA"),
  years  = 2010:2022,
  vars   = c("co2_pc", "re_share_nonhydro", "gdp_real_pc", "rps_nominal")
)
head(small)
```

If one source cannot be reached, its variables are left out with a
warning and the rest of the panel is still returned.

## Codebook and citations

Every variable has a definition, unit, source series and transformation:

``` r

head(codebook(), 10)
#>               variable       group
#> 1    energy_cons_total      energy
#> 2      energy_cons_res      energy
#> 3      energy_cons_com      energy
#> 4      energy_cons_ind      energy
#> 5    energy_cons_trans      energy
#> 6    energy_prod_total      energy
#> 7     renew_cons_total      energy
#> 8     energy_price_avg      energy
#> 9  energy_expend_total      energy
#> 10           gen_total electricity
#>                                             label                    unit
#> 1                        Total energy consumption             billion Btu
#> 2           Residential sector energy consumption             billion Btu
#> 3            Commercial sector energy consumption             billion Btu
#> 4            Industrial sector energy consumption             billion Btu
#> 5        Transportation sector energy consumption             billion Btu
#> 6                 Total primary energy production             billion Btu
#> 7              Total renewable energy consumption             billion Btu
#> 8  Average price of energy, all sectors (nominal) dollars per million Btu
#> 9             Total energy expenditures (nominal)         million dollars
#> 10         Net generation, all fuels, all sectors            thousand MWh
#>            source series transformation
#> 1        eia_seds  TETCB   As published
#> 2        eia_seds  TERCB   As published
#> 3        eia_seds  TECCB   As published
#> 4        eia_seds  TEICB   As published
#> 5        eia_seds  TEACB   As published
#> 6        eia_seds  TEPRB   As published
#> 7        eia_seds  RETCB   As published
#> 8        eia_seds  TETCD   As published
#> 9        eia_seds  TETCV   As published
#> 10 eia_generation    ALL   As published
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
```

[`cite_sources()`](https://adebayomoses.github.io/rpspanel/reference/cite_sources.md)
lists the sources used, with the date each was retrieved:

``` r

cite_sources(c("eia_seds", "eia_co2", "bea_regional"))
#> U.S. Energy Information Administration (2026). State Energy Data System (SEDS). <https://www.eia.gov/state/seds/>.
#> 
#> U.S. Energy Information Administration (2026). State Energy-Related Carbon Dioxide Emissions. <https://www.eia.gov/environment/emissions/state/>.
#> 
#> U.S. Bureau of Economic Analysis (2026). Regional Economic Accounts (SAGDP, SAINC tables). <https://apps.bea.gov/regional/>.
#> 
#> Adebayo, M. (2026). rpspanel: US state energy-economy panels with renewable portfolio standards. R package version 0.1.0.9000.
```

## Caching and vintages

Downloads are cached, so a panel can be rebuilt offline with exactly the
same data vintage. Use `refresh = TRUE` to download fresh data,
[`rps_cache_list()`](https://adebayomoses.github.io/rpspanel/reference/cache.md)
to see what is cached and
[`rps_cache_clear()`](https://adebayomoses.github.io/rpspanel/reference/cache.md)
to empty the cache.

``` r

rps_cache_dir()
#> [1] "/tmp/Rtmp7X9FPV/rpspanel-vignette"
```

## RPS measures without API keys

RPS stringency measures come from the coded rules bundled with the
package, so they work offline:

``` r

rps <- build_panel(states = c("CA", "WA", "NC", "TX"), years = 2005:2025,
                   groups = "rps",
                   rps_methods = c("adoption", "nominal", "flexibility"))
rps[rps$year %in% c(2010, 2020), ]
#> <rps_panel>: 4 states x 2010-2020 (8 rows), 5 variables
#> Sources: rps_bundled 
#>    state     state_name fips year rps_adoption rps_nominal rps_oos_rec
#> 6     CA     California   06 2010            1        0.20           1
#> 16    CA     California   06 2020            1        0.33           1
#> 27    NC North Carolina   37 2010            1        0.00           1
#> 37    NC North Carolina   37 2020            1        0.10           1
#> 48    TX          Texas   48 2010            1          NA           0
#> 58    TX          Texas   48 2020            1          NA           0
#>    rps_carveout rps_acp
#> 6             0       0
#> 16            0       0
#> 27            1       0
#> 37            1       0
#> 48            0       1
#> 58            0       1
#> # ... with 2 more rows
```

See
[`vignette("rps-stringency")`](https://adebayomoses.github.io/rpspanel/articles/rps-stringency.md)
for the methods.

## Estimation and export

The panel works directly with `plm`, `fixest` and `csdm`:

``` r

library(fixest)
p <- build_panel(years = 2001:2022,
                 vars = c("co2_pc", "rps_nominal", "gdp_real_pc"))
feols(log(co2_pc) ~ rps_nominal + log(gdp_real_pc) | state + year,
      data = as_pdata(p, "fixest"), cluster = ~state)
```

Export to CSV, Stata or Parquet, with the codebook alongside:

``` r

f <- file.path(tempdir(), "rps_panel.dta")
if (requireNamespace("haven", quietly = TRUE)) export_panel(rps, f)
```
