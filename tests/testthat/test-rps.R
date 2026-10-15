test_that("bundled rules load and validate", {
  r <- rps_rules()
  expect_s3_class(r, "rps_rules")
  expect_true(all(r$rules$state %in% us_states()$abbr))
  expect_true(all(r$targets$state %in% r$rules$state[r$rules$has_rps == 1]))
  expect_output(print(r), "state")
})

test_that("invalid codings are rejected", {
  r <- toy_rules()
  bad <- r$targets
  bad$target[1] <- 1.5
  expect_error(rpspanel:::new_rps_rules(r$rules, bad), "between 0 and 1")
  bad_rules <- r$rules
  bad_rules$first_compliance_year[1] <- 2000
  expect_error(rpspanel:::new_rps_rules(bad_rules, r$targets), "before")
})

test_that("adoption and nominal requirements have known values", {
  s <- rps_stringency(2004:2017, states = c("CA", "TX", "FL", "OH"), rules = toy_rules())
  ca <- s[s$state == "CA", ]
  expect_equal(ca$rps_adoption, as.integer(2004:2017 >= 2005))
  # 0 before first compliance (2007), linear 0.04 -> 0.20 over 2007-2015, then flat
  expect_equal(ca$rps_nominal[ca$year == 2006], 0)
  expect_equal(ca$rps_nominal[ca$year == 2007], 0.04)
  expect_equal(ca$rps_nominal[ca$year == 2011], 0.12)
  expect_equal(ca$rps_nominal[ca$year == 2017], 0.20)
  # TX repealed in 2015
  tx <- s[s$state == "TX", ]
  expect_equal(tx$rps_adoption[tx$year == 2014], 1L)
  expect_equal(tx$rps_adoption[tx$year == 2015], 0L)
  expect_equal(tx$rps_nominal[tx$year == 2016], 0)
  # FL coded as no RPS: zeros; OH not coded: NA
  expect_true(all(s$rps_nominal[s$state == "FL"] == 0))
  expect_true(all(is.na(s$rps_nominal[s$state == "OH"])))
  expect_true(all(is.na(s$rps_adoption[s$state == "OH"])))
})

test_that("linear interpolation starts from zero at enactment when needed", {
  r <- toy_rules()
  r$targets <- r$targets[r$targets$year != 2007, ]
  s <- rps_stringency(2005:2015, states = "CA", rules = r, method = "nominal")
  expect_equal(s$rps_nominal[s$year == 2006], 0) # before first compliance
  expect_equal(s$rps_nominal[s$year == 2010], 0.2 * 5 / 10)
})

test_that("step interpolation holds the last legal target", {
  s <- rps_stringency(2007:2016, states = "CA", rules = toy_rules(),
                      method = "nominal", interpolation = "step")
  expect_equal(s$rps_nominal, c(rep(0.04, 8), 0.20, 0.20))
})

test_that("coverage-adjusted and incremental measures follow their formulas", {
  s <- rps_stringency(2006:2015, states = "CA", rules = toy_rules(coverage = 0.8, baseline = 0.05))
  expect_equal(s$rps_coverage_adj, s$rps_nominal * 0.8)
  pos <- s$rps_nominal > 0
  expect_equal(s$rps_incremental[pos], s$rps_nominal[pos] * 0.8 - 0.05)
  expect_equal(s$rps_incremental[!pos], 0)
  # floor_zero and baseline override
  s2 <- rps_stringency(2007, states = "CA", rules = toy_rules(),
                       baseline = data.frame(state = "California", baseline_share = 0.5),
                       floor_zero = TRUE)
  expect_equal(s2$rps_baseline_share, 0.5)
  expect_equal(s2$rps_incremental, 0)
})

test_that("flexibility indicators are zero when no RPS is in force", {
  s <- rps_stringency(c(2004, 2010), states = c("CA", "TX"), rules = toy_rules(),
                      method = "flexibility")
  expect_equal(s$rps_oos_rec, c(0, 1, 0, 0))
  expect_equal(s$rps_carveout, c(0, 0, 0, 1))
  expect_equal(s$rps_acp, c(0, 1, 0, 0))
})

test_that("capacity standards need sales to become shares", {
  s <- rps_stringency(2010, states = "TX", method = c("adoption", "nominal"))
  expect_equal(s$rps_adoption, 1L)
  expect_true(is.na(s$rps_nominal))
})

test_that("capacity standards convert MW to a share of covered sales", {
  r <- rps_rules("TX")
  cov <- r$rules$coverage_share
  mw <- r$targets$target[r$targets$year == 2015]
  sales <- data.frame(state = "TX", year = 2015, sales_gwh = 380000)
  s <- rps_stringency(2015, "TX", method = c("nominal", "coverage_adjusted"),
                      rules = r, sales = sales)
  expect_equal(s$rps_nominal, mw * 0.33 * 8.76 / (380000 * cov))
  expect_equal(s$rps_coverage_adj, mw * 0.33 * 8.76 / 380000)
  # close to Berkeley Lab's published equivalent for 2015 (5.9%)
  expect_equal(s$rps_nominal, 0.059, tolerance = 0.05)
  # capacity factor is adjustable and scales the result
  s2 <- rps_stringency(2015, "TX", method = "nominal", rules = r, sales = sales,
                       capacity_factor = 0.4)
  expect_equal(s2$rps_nominal, s$rps_nominal * 0.4 / 0.33)
  # repealed in 2025: no requirement afterwards
  s3 <- rps_stringency(2026, "TX", method = "nominal", rules = r,
                       sales = data.frame(state = "TX", year = 2026, sales_gwh = 1))
  expect_equal(s3$rps_nominal, 0)
  expect_error(rps_stringency(2015, "TX", sales = sales, capacity_factor = 2), "between 0 and 1")
  expect_error(rps_stringency(2015, "TX", sales = data.frame(state = "TX")), "sales_gwh")
})

test_that("a single target in force from enactment is held constant (Iowa)", {
  r <- rps_rules("IA")
  sales <- data.frame(state = "IA", year = c(1982, 2010), sales_gwh = 45000)
  s <- rps_stringency(c(1982, 2010), "IA", method = "nominal", rules = r, sales = sales)
  cov <- r$rules$coverage_share
  expect_equal(s$rps_nominal, c(0, 105 * 0.33 * 8.76 / (45000 * cov)))
  st <- rps_stringency(2010, "IA", method = "nominal", rules = r, sales = sales,
                       interpolation = "step")
  expect_equal(st$rps_nominal, s$rps_nominal[2])
})

test_that("baseline_includes_hydro is optional and set for NY", {
  r <- rps_rules()
  expect_equal(r$rules$state[r$rules$baseline_includes_hydro == 1], "NY")
  old <- toy_rules()$rules
  expect_false("baseline_includes_hydro" %in% names(old[setdiff(names(old), "baseline_includes_hydro")]))
  expect_true(all(toy_rules()$rules$baseline_includes_hydro == 0))
})

test_that("fetch_rps returns bundled coding or reads files", {
  expect_s3_class(fetch_rps(), "rps_rules")
  rf <- system.file("extdata", "rps_rules.csv", package = "rpspanel")
  tf <- system.file("extdata", "rps_targets.csv", package = "rpspanel")
  expect_s3_class(fetch_rps(rf, tf, cache = FALSE), "rps_rules")
  expect_error(fetch_rps(rf), "both")
})
