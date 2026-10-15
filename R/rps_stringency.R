rps_method_cols <- list(
  adoption = "rps_adoption",
  nominal = "rps_nominal",
  coverage_adjusted = "rps_coverage_adj",
  incremental = c("rps_incremental", "rps_baseline_share"),
  flexibility = c("rps_oos_rec", "rps_carveout", "rps_acp")
)

#' Annual RPS stringency indices
#'
#' Turns coded RPS rules ([rps_rules()]) into comparable state-year measures,
#' so you can study how strong a policy is, not only whether it exists.
#'
#' Methods:
#'
#' * `adoption`: 1 if an RPS is in force that year (from `adopt_from` until
#'   any repeal), else 0.
#' * `nominal`: required renewable share of retail sales in that year.
#'   Zero before the first compliance year. Between legal targets the
#'   requirement is interpolated linearly (`interpolation = "linear"`) or held
#'   at the last legal target (`"step"`); after the final target year it is
#'   held constant. If the first coded target lies after the enactment year,
#'   linear interpolation starts from zero at enactment. Capacity-based (MW)
#'   standards (Texas, Iowa) are converted to an equivalent share of covered
#'   sales: `MW * capacity_factor * 8.76 / (sales_gwh * coverage_share)`,
#'   the same approach Berkeley Lab uses. This needs `sales`; without it they
#'   are `NA`.
#' * `coverage_adjusted`: nominal requirement times the share of retail sales
#'   covered by the standard.
#' * `incremental`: requirement beyond the renewable share the state already
#'   had at enactment, following Yin and Powers (2010):
#'   `nominal * coverage - baseline_share` while the nominal requirement is
#'   positive, otherwise 0. The baseline is taken from `baseline`, or from
#'   the `baseline_re_share` column of the rules. Also returns the baseline
#'   used (`rps_baseline_share`). [build_panel()] measures the baseline the
#'   same way the target is defined: including hydro for states whose targets
#'   count existing hydro (`baseline_includes_hydro = 1`, New York),
#'   excluding it otherwise.
#' * `flexibility`: indicators for out-of-state renewable credits, carve-outs
#'   and alternative compliance payments, set to 0 when no RPS is in force.
#'
#' States missing from the rule coding get `NA` for every measure.
#'
#' @param years Years to compute.
#' @param states States to include (default: all 50 + DC).
#' @param method One or more of `"adoption"`, `"nominal"`,
#'   `"coverage_adjusted"`, `"incremental"`, `"flexibility"`.
#' @param rules An `rps_rules` object; defaults to the bundled coding.
#' @param baseline Optional data frame with columns `state` and
#'   `baseline_share`, the existing (eligible) renewable share of sales or
#'   generation at enactment. Overrides `baseline_re_share` in the rules.
#' @param interpolation `"linear"` or `"step"`.
#' @param adopt_from Year from which `adoption` is 1: `"enactment"` or
#'   `"first_compliance"`.
#' @param floor_zero If `TRUE`, negative incremental requirements are set to 0.
#' @param sales Optional data frame with columns `state`, `year` and
#'   `sales_gwh` (retail electricity sales, GWh, the same as EIA's million
#'   kWh), used to convert capacity-based standards into shares.
#'   [build_panel()] supplies it from EIA retail sales.
#' @param capacity_factor Assumed capacity factor of the resources that meet
#'   a capacity-based standard. The default 0.33 is typical of wind, which met
#'   most of the Texas and Iowa requirements.
#'
#' @return A data frame with `state`, `year` and the columns for each method:
#'   `rps_adoption`, `rps_nominal`, `rps_coverage_adj`, `rps_incremental`,
#'   `rps_baseline_share`, `rps_oos_rec`, `rps_carveout`, `rps_acp`.
#'
#' @references Yin, H., & Powers, N. (2010). Do state renewable portfolio
#'   standards promote in-state renewable generation? *Energy Policy*,
#'   38(2), 1140-1149.
#' @export
#' @examples
#' s <- rps_stringency(2000:2030, states = c("CA", "WA", "TX", "FL"),
#'                     method = c("adoption", "nominal"))
#' s[s$state == "WA" & s$year %in% 2011:2021, ]
#'
#' # Capacity (MW) standards become shares when sales are supplied
#' tx_sales <- data.frame(state = "TX", year = 2015, sales_gwh = 380000)
#' rps_stringency(2015, "TX", method = "nominal", sales = tx_sales)
#'
#' # Step interpolation follows the legal schedule exactly
#' rps_stringency(2012:2020, states = "WA", method = "nominal",
#'                interpolation = "step")
rps_stringency <- function(years, states = NULL,
                           method = c("adoption", "nominal", "coverage_adjusted",
                                      "incremental", "flexibility"),
                           rules = rps_rules(), baseline = NULL,
                           interpolation = c("linear", "step"),
                           adopt_from = c("enactment", "first_compliance"),
                           floor_zero = FALSE, sales = NULL,
                           capacity_factor = 0.33) {
  years <- as_years(years)
  states <- resolve_states(states)
  method <- match.arg(method, several.ok = TRUE)
  interpolation <- match.arg(interpolation)
  adopt_from <- match.arg(adopt_from)
  if (!inherits(rules, "rps_rules")) {
    cli::cli_abort("{.arg rules} must be an {.cls rps_rules} object; see {.fn rps_rules}.")
  }

  if (!is.numeric(capacity_factor) || length(capacity_factor) != 1 ||
      capacity_factor <= 0 || capacity_factor > 1) {
    cli::cli_abort("{.arg capacity_factor} must be a single number between 0 and 1.")
  }
  if (!is.null(sales) && !all(c("state", "year", "sales_gwh") %in% names(sales))) {
    cli::cli_abort("{.arg sales} needs columns {.field state}, {.field year} and {.field sales_gwh}.")
  }

  r <- rules$rules
  if (!is.null(baseline)) {
    if (!all(c("state", "baseline_share") %in% names(baseline))) {
      cli::cli_abort("{.arg baseline} needs columns {.field state} and {.field baseline_share}.")
    }
    b <- baseline$baseline_share[match(r$state, harmonise_states(baseline$state))]
    r$baseline_re_share[!is.na(b)] <- b[!is.na(b)]
  }

  grid <- expand.grid(year = years, state = states, stringsAsFactors = FALSE)[c("state", "year")]
  rule <- r[match(grid$state, r$state), , drop = FALSE]
  coded <- !is.na(rule$state)
  has <- coded & rule$has_rps %in% 1L

  start <- if (adopt_from == "enactment") rule$enacted_year else rule$first_compliance_year
  in_force <- has & grid$year >= start &
    (is.na(rule$repeal_year) | grid$year < rule$repeal_year)
  in_force[!coded] <- NA

  nominal <- numeric(nrow(grid))
  for (st in unique(grid$state[has])) {
    rows <- which(grid$state == st)
    rs <- r[r$state == st, ]
    req <- required_share(grid$year[rows], rs, rules$targets[rules$targets$state == st, ],
                          interpolation)
    nominal[rows] <- if (rs$target_type == "share") {
      req
    } else {
      capacity_to_share(req, st, grid$year[rows], rs$coverage_share, sales, capacity_factor)
    }
  }
  nominal[has & !in_force] <- 0
  nominal[has & grid$year < rule$first_compliance_year] <- 0
  nominal[!coded] <- NA

  out <- grid
  if ("adoption" %in% method) {
    out$rps_adoption <- as.integer(in_force)
  }
  if ("nominal" %in% method) {
    out$rps_nominal <- nominal
  }
  cov_adj <- nominal * ifelse(has, rule$coverage_share, 1)
  if ("coverage_adjusted" %in% method) {
    out$rps_coverage_adj <- cov_adj
  }
  if ("incremental" %in% method) {
    base <- ifelse(has, rule$baseline_re_share, NA_real_)
    incr <- cov_adj - base
    incr[!is.na(nominal) & nominal == 0] <- 0
    if (floor_zero) incr <- pmax(incr, 0)
    out$rps_incremental <- incr
    out$rps_baseline_share <- base
  }
  if ("flexibility" %in% method) {
    on <- as.integer(in_force)
    out$rps_oos_rec <- on * ifelse(has, rule$out_of_state_rec, 0L)
    out$rps_carveout <- on * ifelse(has, rule$carveout, 0L)
    out$rps_acp <- on * ifelse(has, rule$acp, 0L)
  }
  out <- out[order(out$state, out$year), , drop = FALSE]
  rownames(out) <- NULL
  attr(out, "rps_options") <- list(method = method, interpolation = interpolation,
                                   adopt_from = adopt_from, floor_zero = floor_zero,
                                   capacity_factor = capacity_factor)
  out
}

# Required share in each year for one state, from its legal targets.
required_share <- function(years, rule, targets, interpolation) {
  if (nrow(targets) == 0) {
    return(rep(NA_real_, length(years)))
  }
  ty <- targets$year
  tv <- targets$target
  if (length(ty) == 1 && min(ty) <= rule$enacted_year) {
    # One target in force from enactment (for example Iowa's 105 MW)
    return(ifelse(years >= ty, tv, 0))
  }
  if (interpolation == "linear") {
    if (min(ty) > rule$enacted_year) {
      ty <- c(rule$enacted_year, ty)
      tv <- c(0, tv)
    }
    val <- stats::approx(ty, tv, xout = years, rule = 2, ties = "ordered")$y
  } else {
    idx <- findInterval(years, ty)
    val <- ifelse(idx == 0, 0, tv[pmax(idx, 1)])
  }
  val[years < min(ty) & interpolation == "step"] <- 0
  val
}

# Energy a MW target implies (GWh = MW * capacity factor * 8760 h / 1000) as a
# share of the sales the standard covers.
capacity_to_share <- function(mw, state, years, coverage, sales, capacity_factor) {
  if (is.null(sales)) {
    return(rep(NA_real_, length(mw)))
  }
  st <- harmonise_states(sales$state, warn = FALSE)
  s <- sales$sales_gwh[match(paste(state, years), paste(st, sales$year))]
  covered <- s * (if (is.na(coverage)) 1 else coverage)
  mw * capacity_factor * 8.76 / covered
}
