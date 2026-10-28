# Contributing to rpspanel

Thank you for helping to improve rpspanel. Contributions of all sizes
are welcome: bug reports, corrections to the RPS rule coding,
documentation fixes and new features.

Please note that this project is released with a [Contributor Code of
Conduct](https://github.com/adebayomoses/rpspanel/blob/main/CODE_OF_CONDUCT.md).
By participating you agree to abide by its terms.

## Reporting a bug

Open an [issue](https://github.com/adebayomoses/rpspanel/issues) with:

- a minimal reproducible example, ideally made with the
  [reprex](https://reprex.tidyverse.org/) package;
- the output of
  [`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html);
- for download problems, the data source involved (EIA, BEA or Census)
  and the full error message. **Never include your API keys.**

## Correcting the RPS coding

The RPS rules in `inst/extdata/rps_rules.csv` and
`inst/extdata/rps_targets.csv` are hand-coded from statutes, DSIRE
program pages and Berkeley Lab’s RPS & CES data. If you find an error,
please open an issue that gives:

- the state and the field that is wrong (for example a target year,
  target level, coverage share or repeal year);
- the correct value; and
- a citable source: the statute, regulation or official program page.

Coding changes are recorded in the `source` and `notes` columns so every
value stays auditable. After editing the CSV files, run
`source("data-raw/check_rps_rules.R")` from the package root to check
that the coding is still consistent.

## Pull requests

1.  Fork the repository and create a branch for your change.
2.  Install the development dependencies with
    `remotes::install_deps(dependencies = TRUE)`.
3.  Make your change. New functionality needs tests in `tests/testthat/`
    and documentation with [roxygen2](https://roxygen2.r-lib.org/); run
    `devtools::document()` after editing roxygen comments.
4.  Check the package with `devtools::check()`.
5.  Add a bullet to the top of `NEWS.md` describing the change.
6.  Open a pull request that explains what the change does and why.

### Tests and API keys

The tests never access the network: all EIA, BEA and Census responses
are mocked (see `tests/testthat/helper-fixtures.R`), so you do not need
API keys to run them. Please keep it that way, and never commit API keys
or downloaded data.

### Style

The code follows the [tidyverse style
guide](https://style.tidyverse.org/), with lines of at most 80
characters, and has as few dependencies as possible. User-facing
messages and errors use [cli](https://cli.r-lib.org/), and errors from
web services use the classes `rpspanel_http_error` and
`rpspanel_no_key`.

## Questions

For questions about using the package, open an issue on
[GitHub](https://github.com/adebayomoses/rpspanel/issues).
