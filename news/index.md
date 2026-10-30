# Changelog

## rpspanel (development version)

- Preparation for rOpenSci software peer review: added a contributing
  guide, a code of conduct, a `CITATION` file with the Zenodo DOI, and a
  pkgdown documentation website.
- Internal refactoring for readability:
  [`build_panel()`](https://adebayomoses.github.io/rpspanel/reference/build_panel.md)
  and
  [`rps_stringency()`](https://adebayomoses.github.io/rpspanel/reference/rps_stringency.md)
  are split into smaller helper functions, and code lines are kept
  within 80 characters. Results are unchanged (checked against version
  0.1.0 on every state and year, and on the full live panel).
- [`cite_sources()`](https://adebayomoses.github.io/rpspanel/reference/cite_sources.md)
  text citations now wrap URLs in angle brackets so the closing full
  stop is not read as part of the link, and sources without a URL no
  longer get a stray extra full stop.
- Addressed the goodpractice findings raised in rOpenSci pre-submission
  review: the internal `%||%` helper is now defined only on R \< 4.4
  (newer R provides it in base), `%in%` comparisons with a single value
  use `==`, the duplicated `cli` bullet name is merged, and functions
  with high cyclomatic complexity (`check_stringency_inputs()`,
  `eia_download()`, `validate_rps_rules()`) are split into smaller
  helpers. Results are unchanged.
- Tests use `expect_identical()` wherever an exact match is expected,
  and no longer assign inside `expect_warning()`.
- Tests no longer use `:::`, and the test for rules files without the
  optional `baseline_includes_hydro` column now checks that such files
  load with the default value.

## rpspanel 0.1.0

CRAN release: 2026-10-27

- Initial version following the project plan.
- Fetch layer:
  [`fetch_eia()`](https://adebayomoses.github.io/rpspanel/reference/fetch_eia.md),
  [`fetch_bea()`](https://adebayomoses.github.io/rpspanel/reference/fetch_bea.md),
  [`fetch_census()`](https://adebayomoses.github.io/rpspanel/reference/fetch_census.md)
  and
  [`fetch_rps()`](https://adebayomoses.github.io/rpspanel/reference/fetch_rps.md),
  with a local download cache and graceful failure when a service is
  unavailable.
- Harmonise layer:
  [`harmonise_states()`](https://adebayomoses.github.io/rpspanel/reference/harmonise_states.md),
  [`deflate()`](https://adebayomoses.github.io/rpspanel/reference/deflate.md)
  and
  [`convert_units()`](https://adebayomoses.github.io/rpspanel/reference/convert_units.md).
- Panel builder:
  [`build_panel()`](https://adebayomoses.github.io/rpspanel/reference/build_panel.md).
- RPS stringency module:
  [`rps_rules()`](https://adebayomoses.github.io/rpspanel/reference/rps_rules.md)
  and
  [`rps_stringency()`](https://adebayomoses.github.io/rpspanel/reference/rps_stringency.md)
  with the `adoption`, `nominal`, `coverage_adjusted`, `incremental` and
  `flexibility` methods.
- Documentation helpers
  [`codebook()`](https://adebayomoses.github.io/rpspanel/reference/codebook.md)
  and
  [`cite_sources()`](https://adebayomoses.github.io/rpspanel/reference/cite_sources.md);
  output helpers
  [`as_pdata()`](https://adebayomoses.github.io/rpspanel/reference/as_pdata.md)
  and
  [`export_panel()`](https://adebayomoses.github.io/rpspanel/reference/export_panel.md).
- The bundled RPS rule coding (`inst/extdata/`) covers all 50 states
  and DC. The 33 RPS states and 6 voluntary-goal states are verified
  against statutes, DSIRE and LBNL data (column `verified`), coverage
  shares are filled in, and repeals are coded (AZ 2026, KS 2015, MT
  2021, OH 2027, TX 2025, WV 2015).
- Tested against the live EIA and BEA APIs: BEA GDP tables now use their
  current names (`SAGDP9`, `SAGDP2`), personal income is labelled in
  millions of dollars, and requests retry on transient HTTP 500 errors
  from the EIA gateway.
- README now shows real output from a live run, with figures in
  `man/figures/`.
- [`fetch_census()`](https://adebayomoses.github.io/rpspanel/reference/fetch_census.md)
  now requires a Census API key (the API rejects keyless requests) and
  was tested live against ACS 1-year data; output is sorted by state and
  year, and `unit` is only set for the default population variable.
- API responses that are web pages instead of data (for example a
  rejected key) now raise a clear `rpspanel_http_error` instead of a
  parse failure.
- API keys are only required when data actually need downloading, so a
  cached panel can be rebuilt offline without keys.
- Parquet export tested with `arrow` (values and column types round-trip
  unchanged).
- The 12 original no-RPS rows (AL, AK, AR, FL, GA, ID, KY, LA, MS, NE,
  TN, WY) are now verified against the LBNL June 2026 data and cite
  their sources, so all 51 rows are verified. Nebraska’s utility-adopted
  clean energy commitments (counted by LBNL as a CES from 2040) are
  documented but not coded as a state RPS.
- [`rps_stringency()`](https://adebayomoses.github.io/rpspanel/reference/rps_stringency.md)
  converts capacity-based (MW) standards (Texas, Iowa) into a share of
  covered sales with new `sales` and `capacity_factor` arguments,
  following Berkeley Lab’s approach;
  [`build_panel()`](https://adebayomoses.github.io/rpspanel/reference/build_panel.md)
  supplies retail sales automatically when an EIA key is available, so
  `rps_nominal` is no longer blank for these states.
- New optional rules column `baseline_includes_hydro`: the incremental
  baseline now includes hydro for New York, whose targets count existing
  hydro (2004 baseline about 19%, matching the 19.3% legal baseline).
- Fixed: a single target in force from enactment (Iowa) no longer breaks
  interpolation.
- Texas is recoded so only the 5,880 MW (2015) schedule is binding; the
  10,000 MW by 2025 figure is a non-binding goal (as in Berkeley Lab’s
  data). Converted Texas shares now match Berkeley Lab’s within about
  0.6 percentage points in every year.
