# rpspanel 0.0.0.9000

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
