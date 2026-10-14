# rpspanel 0.0.0.9000

* Initial version following the project plan.
* Fetch layer: `fetch_eia()`, `fetch_bea()`, `fetch_census()` and `fetch_rps()`, with a local download cache and graceful failure when a service is unavailable.
* Harmonise layer: `harmonise_states()`, `deflate()` and `convert_units()`.
* Panel builder: `build_panel()`.
* RPS stringency module: `rps_rules()` and `rps_stringency()` with the `adoption`, `nominal`, `coverage_adjusted`, `incremental` and `flexibility` methods.
* Documentation helpers `codebook()` and `cite_sources()`; output helpers `as_pdata()` and `export_panel()`.
* The bundled RPS rule coding (`inst/extdata/`) is a starter set that has not yet been verified against statutes (column `verified`).
