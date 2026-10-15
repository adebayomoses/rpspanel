# rpspanel 0.1.0

* Initial version following the project plan.
* Fetch layer: `fetch_eia()`, `fetch_bea()`, `fetch_census()` and `fetch_rps()`, with a local download cache and graceful failure when a service is unavailable.
* Harmonise layer: `harmonise_states()`, `deflate()` and `convert_units()`.
* Panel builder: `build_panel()`.
* RPS stringency module: `rps_rules()` and `rps_stringency()` with the `adoption`, `nominal`, `coverage_adjusted`, `incremental` and `flexibility` methods.
* Documentation helpers `codebook()` and `cite_sources()`; output helpers `as_pdata()` and `export_panel()`.
* The bundled RPS rule coding (`inst/extdata/`) covers all 50 states and DC. The 33 RPS states and 6 voluntary-goal states are verified against statutes, DSIRE and LBNL data (column `verified`), coverage shares are filled in, and repeals are coded (AZ 2026, KS 2015, MT 2021, OH 2027, TX 2025, WV 2015).
* Tested against the live EIA and BEA APIs: BEA GDP tables now use their current names (`SAGDP9`, `SAGDP2`), personal income is labelled in millions of dollars, and requests retry on transient HTTP 500 errors from the EIA gateway.
* README now shows real output from a live run, with figures in `man/figures/`.
* `fetch_census()` now requires a Census API key (the API rejects keyless requests) and was tested live against ACS 1-year data; output is sorted by state and year, and `unit` is only set for the default population variable.
* API responses that are web pages instead of data (for example a rejected key) now raise a clear `rpspanel_http_error` instead of a parse failure.
* API keys are only required when data actually need downloading, so a cached panel can be rebuilt offline without keys.
* Parquet export tested with `arrow` (values and column types round-trip unchanged).
* The 12 original no-RPS rows (AL, AK, AR, FL, GA, ID, KY, LA, MS, NE, TN, WY) are now verified against the LBNL June 2026 data and cite their sources, so all 51 rows are verified. Nebraska's utility-adopted clean energy commitments (counted by LBNL as a CES from 2040) are documented but not coded as a state RPS.
* `rps_stringency()` converts capacity-based (MW) standards (Texas, Iowa) into a share of covered sales with new `sales` and `capacity_factor` arguments, following Berkeley Lab's approach; `build_panel()` supplies retail sales automatically when an EIA key is available, so `rps_nominal` is no longer blank for these states.
* New optional rules column `baseline_includes_hydro`: the incremental baseline now includes hydro for New York, whose targets count existing hydro (2004 baseline about 19%, matching the 19.3% legal baseline).
* Fixed: a single target in force from enactment (Iowa) no longer breaks interpolation.
* Texas is recoded so only the 5,880 MW (2015) schedule is binding; the 10,000 MW by 2025 figure is a non-binding goal (as in Berkeley Lab's data). Converted Texas shares now match Berkeley Lab's within about 0.6 percentage points in every year.
