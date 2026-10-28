rps_rule_cols <- c(
  "state", "has_rps", "policy_name", "enacted_year", "first_compliance_year",
  "repeal_year", "target_type", "final_target", "final_target_year",
  "coverage_share", "out_of_state_rec", "carveout", "carveout_types", "acp",
  "acp_usd_mwh", "baseline_re_share", "source", "verified", "notes"
)

# Optional columns and the value used when a user-supplied file lacks them.
rps_optional_cols <- c(baseline_includes_hydro = 0L)

#' Coded Renewable Portfolio Standard rules
#'
#' Reads the RPS rule coding that feeds [rps_stringency()]. By default this is
#' the coding bundled with the package in `inst/extdata/`; you can point to
#' your own files with the same layout to correct or extend it.
#'
#' The coding has two tables:
#'
#' **rules** (one row per state): `has_rps` (1 = mandatory RPS, 0 = none),
#' `enacted_year`, `first_compliance_year`, `repeal_year`, `target_type`
#' (`"share"` of retail sales, or `"capacity_mw"`), `final_target`,
#' `final_target_year`, `coverage_share` (share of retail sales covered),
#' `out_of_state_rec`, `carveout`, `acp` (0/1 design indicators),
#' `carveout_types`, `acp_usd_mwh`, `baseline_re_share` (optional existing
#' renewable share at enactment; filled from data by [build_panel()]),
#' `source`, `verified` and `notes`. Optional: `baseline_includes_hydro`
#' (1 if the targets count existing hydro, so the incremental baseline should
#' too; default 0).
#'
#' **targets** (one row per legal target): `state`, `year`, `target` (share
#' of sales between 0 and 1, or MW for capacity targets).
#'
#' States that do not appear in the rules table are treated as *not yet
#' coded*, and their stringency measures are `NA` rather than zero.
#'
#' @section Status of the bundled coding:
#' The bundled coding covers all 50 states and DC. Rows with
#' `verified = TRUE` have been hand-checked against the statute, the DSIRE
#' program page and the LBNL RPS & CES data, as set out in the package's
#' validation plan; `source` and `notes` give the citations and coding
#' choices. Please report corrections on the issue tracker.
#'
#' @param states Optional states to keep.
#' @param rules_path,targets_path Paths to CSV files with your own coding.
#'   Default: the files bundled with the package.
#'
#' @return An object of class `rps_rules`: a list with data frames `rules`
#'   and `targets`.
#' @export
#' @examples
#' r <- rps_rules()
#' r
#' head(r$targets)
rps_rules <- function(states = NULL, rules_path = NULL, targets_path = NULL) {
  rules_path <- rules_path %||%
    system.file("extdata", "rps_rules.csv", package = "rpspanel")
  targets_path <- targets_path %||%
    system.file("extdata", "rps_targets.csv", package = "rpspanel")
  read <- function(path) {
    utils::read.csv(path, stringsAsFactors = FALSE, na.strings = c("", "NA"))
  }
  rules <- read(rules_path)
  targets <- read(targets_path)
  out <- new_rps_rules(rules, targets)
  if (!is.null(states)) {
    st <- resolve_states(states)
    out$rules <- out$rules[out$rules$state %in% st, , drop = FALSE]
    out$targets <- out$targets[out$targets$state %in% st, , drop = FALSE]
  }
  out
}

new_rps_rules <- function(rules, targets) {
  missing_cols <- setdiff(rps_rule_cols, names(rules))
  if (length(missing_cols)) {
    cli::cli_abort("RPS rules are missing column{?s} {.field {missing_cols}}.")
  }
  if (!all(c("state", "year", "target") %in% names(targets))) {
    cli::cli_abort(paste0("RPS targets need columns {.field state}, ",
                          "{.field year} and {.field target}."))
  }
  for (col in setdiff(names(rps_optional_cols), names(rules))) {
    rules[[col]] <- rps_optional_cols[[col]]
  }
  rules$state <- harmonise_states(rules$state)
  targets$state <- harmonise_states(targets$state)
  int_cols <- c("has_rps", "enacted_year", "first_compliance_year",
                "repeal_year", "final_target_year", "out_of_state_rec",
                "carveout", "acp", "baseline_includes_hydro")
  num_cols <- c("final_target", "coverage_share", "acp_usd_mwh",
                "baseline_re_share")
  for (col in int_cols) rules[[col]] <- as.integer(rules[[col]])
  for (col in num_cols) rules[[col]] <- as.numeric(rules[[col]])
  rules$verified <- as.logical(rules$verified)
  rules$verified[is.na(rules$verified)] <- FALSE
  targets$year <- as.integer(targets$year)
  targets$target <- as.numeric(targets$target)
  targets <- targets[order(targets$state, targets$year),
                     c("state", "year", "target")]
  rownames(targets) <- NULL
  rules$baseline_includes_hydro[is.na(rules$baseline_includes_hydro)] <- 0L
  rules <- rules[order(rules$state), c(rps_rule_cols, names(rps_optional_cols))]
  rownames(rules) <- NULL
  x <- structure(list(rules = rules, targets = targets), class = "rps_rules")
  validate_rps_rules(x)
  x
}

validate_rps_rules <- function(x) {
  r <- x$rules
  problems <- character()
  if (anyDuplicated(r$state)) {
    problems <- c(problems, "duplicated states in rules")
  }
  if (anyNA(r$has_rps) || !all(r$has_rps %in% c(0L, 1L))) {
    problems <- c(problems, "`has_rps` must be 0 or 1")
  }
  act <- r[r$has_rps %in% 1L, , drop = FALSE]
  if (anyNA(act$enacted_year) || anyNA(act$first_compliance_year)) {
    problems <- c(problems,
                  "RPS states need `enacted_year` and `first_compliance_year`")
  }
  if (any(act$first_compliance_year < act$enacted_year, na.rm = TRUE)) {
    problems <- c(problems, "`first_compliance_year` is before `enacted_year`")
  }
  if (!all(act$target_type %in% c("share", "capacity_mw"))) {
    problems <- c(problems,
                  "`target_type` must be \"share\" or \"capacity_mw\"")
  }
  if (any(act$coverage_share < 0 | act$coverage_share > 1, na.rm = TRUE)) {
    problems <- c(problems, "`coverage_share` must be between 0 and 1")
  }
  share_states <- act$state[act$target_type == "share"]
  t <- x$targets
  st <- t[t$state %in% share_states, , drop = FALSE]
  if (any(st$target < 0 | st$target > 1, na.rm = TRUE)) {
    problems <- c(problems, "share targets must be between 0 and 1")
  }
  if (anyDuplicated(t[c("state", "year")])) {
    problems <- c(problems, "duplicated state-year targets")
  }
  orphan <- setdiff(t$state, act$state)
  if (length(orphan)) {
    problems <- c(problems, paste("targets for states without an RPS:",
                                  toString(orphan)))
  }
  no_targets <- setdiff(act$state, t$state)
  if (length(no_targets)) {
    problems <- c(problems, paste("RPS states without targets:",
                                  toString(no_targets)))
  }
  if (length(problems)) {
    bullets <- stats::setNames(problems, rep("x", length(problems)))
    cli::cli_abort(c("Invalid RPS rule coding:", bullets))
  }
  invisible(TRUE)
}

#' @export
print.rps_rules <- function(x, ...) {
  r <- x$rules
  n_rps <- sum(r$has_rps == 1L)
  cat(sprintf(
    "<rps_rules>: %d coded states (%d with an RPS), %d legal targets\n",
    nrow(r), n_rps, nrow(x$targets)
  ))
  uncoded <- setdiff(state_table$abbr, r$state)
  if (length(uncoded)) {
    cat(strwrap(sprintf("Not yet coded (%d): %s", length(uncoded),
                        paste(uncoded, collapse = " "))), sep = "\n")
  }
  n_unver <- sum(!r$verified)
  if (n_unver) {
    cat(sprintf("%d rows not yet verified against statutes.\n", n_unver))
  }
  r <- r[r$has_rps == 1L, c("state", "enacted_year", "first_compliance_year",
                            "target_type", "final_target", "final_target_year",
                            "coverage_share")]
  r$final_target <- format(r$final_target, scientific = FALSE,
                           drop0trailing = TRUE)
  print(r, row.names = FALSE)
  invisible(x)
}

#' Get RPS rule coding from the package or a URL
#'
#' Without arguments, returns the bundled coding (same as [rps_rules()]).
#' With URLs, downloads CSV files that follow the [rps_rules()] layout, for
#' example a shared or corrected version of the coding, and caches them.
#' The package does not redistribute DSIRE, LBNL or PUDL data; if you build
#' your own coding from those sources, check their terms of use.
#'
#' @param rules_url,targets_url URLs (or local paths) of CSV files.
#' @inheritParams fetch_eia
#'
#' @return An `rps_rules` object.
#' @export
#' @examples
#' fetch_rps()
fetch_rps <- function(rules_url = NULL, targets_url = NULL, cache = TRUE,
                      refresh = FALSE) {
  if (is.null(rules_url) && is.null(targets_url)) {
    out <- rps_rules()
    attr(out, "rps_source") <- "rps_bundled"
    attr(out, "rps_retrieved") <-
      as.character(utils::packageVersion("rpspanel"))
    return(out)
  }
  if (is.null(rules_url) || is.null(targets_url)) {
    cli::cli_abort("Supply both {.arg rules_url} and {.arg targets_url}.")
  }
  key <- cache_key("rps", rules_url, targets_url)
  read <- function(u) {
    tryCatch(
      utils::read.csv(u, stringsAsFactors = FALSE, na.strings = c("", "NA")),
      error = function(e) {
        cli::cli_abort(c("Could not read {.url {u}}.", x = conditionMessage(e)),
                       class = "rpspanel_http_error")
      }
    )
  }
  with_cache(key, "rps_url", cache = cache, refresh = refresh,
             fetch = function() new_rps_rules(read(rules_url),
                                              read(targets_url)))
}
