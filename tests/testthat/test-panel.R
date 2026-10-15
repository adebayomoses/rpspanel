test_that("build_panel merges sources, derives variables and adds RPS", {
  local_mocked_bindings(perform_json = fake_perform)
  vars <- c("energy_cons_total", "gen_total", "gen_wind", "re_share_nonhydro",
            "co2_total", "co2_pc", "gdp_real", "elec_price_real", "rps_nominal",
            "rps_incremental")
  p <- build_panel(states = c("CA", "TX"), years = 2019:2020, vars = vars,
                   cache = FALSE, quiet = TRUE)
  expect_s3_class(p, "rps_panel")
  expect_equal(nrow(p), 4)
  expect_equal(names(p), c("state", "state_name", "fips", "year", vars))

  ca19 <- p[p$state == "CA" & p$year == 2019, ]
  expect_equal(ca19$energy_cons_total, 7800000)
  # wind + solar (geothermal/wood/biomass missing -> 0) over total
  expect_equal(ca19$re_share_nonhydro, (14000 + 28000) / 200000)
  expect_equal(ca19$co2_pc, 358 * 1e6 / 39500000)
  # price deflated to 2017 dollars with 2019 deflator 103
  expect_equal(ca19$elec_price_real, 16.6 * 100 / 103)
  # baseline for CA (enacted 2002) is the first year with data, 2019
  ca_cov <- rps_rules("CA")$rules$coverage_share
  expect_equal(ca19$rps_incremental, ca19$rps_nominal * ca_cov - ca19$re_share_nonhydro)

  src <- attr(p, "sources")
  expect_true(all(c("eia_seds", "eia_generation", "eia_co2", "bea_regional",
                    "bea_nipa", "rps_bundled") %in% src$source))
  expect_equal(codebook(p)$variable, vars)
  expect_output(print(p), "rps_panel")
  expect_output(cite_sources(p), "Energy Information Administration")
})

test_that("build_panel keeps going when a source fails", {
  local_mocked_bindings(perform_json = function(req, what) {
    if (grepl("apps.bea.gov", req$url, fixed = TRUE)) {
      cli::cli_abort("BEA down", class = "rpspanel_http_error")
    }
    fake_perform(req, what)
  })
  expect_warning(
    p <- build_panel(states = "CA", years = 2019:2020,
                     vars = c("energy_cons_total", "gdp_real"),
                     cache = FALSE, quiet = TRUE),
    "Skipping"
  )
  expect_true("energy_cons_total" %in% names(p))
  expect_false("gdp_real" %in% names(p))
})

test_that("RPS-only panels need no API keys", {
  withr::local_envvar(EIA_API_KEY = "", BEA_API_KEY = "")
  p <- build_panel(states = c("CA", "WA"), years = 2010:2012, groups = "rps",
                   rps_methods = c("adoption", "nominal", "flexibility"), quiet = TRUE)
  expect_equal(nrow(p), 6)
  expect_true(all(c("rps_adoption", "rps_nominal", "rps_oos_rec") %in% names(p)))
  expect_false("rps_incremental" %in% names(p))
})

test_that("unknown variables are rejected", {
  expect_error(build_panel(vars = "nope"), "Unknown variable")
})

test_that("codebook documents every variable", {
  cb <- codebook()
  expect_false(anyDuplicated(cb$variable) > 0)
  expect_false(any(is.na(cb$label) | is.na(cb$unit) | is.na(cb$source)))
  expect_equal(unique(codebook(group = "rps")$group), "rps")
})

test_that("build_panel converts MW standards and uses hydro baselines where targets count hydro", {
  local_mocked_bindings(perform_json = fake_perform)
  rules <- rps_rules(c("CA", "TX"))
  rules$rules$baseline_includes_hydro[rules$rules$state == "CA"] <- 1L
  p <- build_panel(states = c("CA", "TX"), years = 2019:2020,
                   vars = c("rps_nominal", "rps_incremental", "rps_baseline_share"),
                   rps_rules = rules, cache = FALSE, quiet = TRUE)
  tx19 <- p[p$state == "TX" & p$year == 2019, ]
  tx_mw <- stats::approx(rules$targets$year[rules$targets$state == "TX"],
                         rules$targets$target[rules$targets$state == "TX"], xout = 2019, rule = 2)$y
  tx_cov <- rules$rules$coverage_share[rules$rules$state == "TX"]
  expect_equal(tx19$rps_nominal, tx_mw * 0.33 * 8.76 / (430000 * tx_cov))
  # TX baseline excludes hydro: (wind + solar) / total in the first year with data
  expect_equal(tx19$rps_baseline_share, (84000 + 5000) / 480000)
  # CA flagged to include hydro
  ca19 <- p[p$state == "CA" & p$year == 2019, ]
  expect_equal(ca19$rps_baseline_share, (14000 + 28000 + 34000) / 200000)
})
