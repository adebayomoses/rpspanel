## Submission

This is a new submission.

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Test environments

* Local: Windows 10, R 4.5.1 (`R CMD check --as-cran`, vignettes and PDF
  manual built)
* GitHub Actions: Windows (release), macOS (release), Ubuntu (devel, release,
  oldrel-1)
* win-builder: R-devel (to be run before submission)

## Web services and API keys

The package downloads data from the US Energy Information Administration,
Bureau of Economic Analysis and Census Bureau APIs. Each needs a free API key
supplied by the user through an environment variable (`EIA_API_KEY`,
`BEA_API_KEY`, `CENSUS_API_KEY`).

* Examples that need a key use `@examplesIf` and only run when the key is
  set, so they are skipped on CRAN.
* Tests never touch the network: all API calls are mocked.
* When a service is unavailable or a key is missing, functions fail with an
  informative, classed error, and `build_panel()` returns the remaining
  sources with a warning.
* Downloads are cached in `tools::R_user_dir("rpspanel", "cache")` only when
  the user calls a download function; examples, tests and vignettes do not
  write to the user's home file space.
