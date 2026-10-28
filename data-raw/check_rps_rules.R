# Checks the hand-coded RPS rules in inst/extdata/ and reports what still
# needs to be done under the validation plan:
#   * hand-check at least 10 states against statutes or DSIRE pages
#   * code coverage shares for every RPS state
#   * code every state (no NA rows in the panel)
#
# Run from the package root: source("data-raw/check_rps_rules.R")

pkgload::load_all(".")

rules <- rps_rules(
  rules_path = "inst/extdata/rps_rules.csv",
  targets_path = "inst/extdata/rps_targets.csv"
)

r <- rules$rules
act <- r[r$has_rps == 1, ]

cat("Coded states:      ", nrow(r), "of 51\n")
cat("  with an RPS:     ", nrow(act), "\n")
cat("Verified rows:     ", sum(r$verified), "(goal: at least 10 RPS states)\n")
missing_cov <- act$state[is.na(act$coverage_share)]
uncoded <- setdiff(us_states()$abbr, r$state)
cat("Missing coverage:  ", paste(missing_cov, collapse = " "), "\n")
cat("Not yet coded:     ", paste(uncoded, collapse = " "), "\n")

# The final target in the rules table must match the last legal target.
last <- do.call(rbind, lapply(split(rules$targets, rules$targets$state),
                              function(d) d[which.max(d$year), ]))
chk <- merge(act[c("state", "final_target", "final_target_year")], last,
             by = "state")
bad <- chk[abs(chk$final_target - chk$target) > 1e-9 |
             chk$final_target_year != chk$year, ]
if (nrow(bad)) {
  cat("\nFinal target does not match the last coded target:\n")
  print(bad)
} else {
  cat("\nFinal targets are consistent with the target schedules.\n")
}
