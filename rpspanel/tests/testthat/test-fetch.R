test_that("EIA requests carry facets, years and data columns", {
  spec <- rpspanel:::eia_specs$seds
  req <- rpspanel:::eia_request(spec, c("TETCB", "TETCD"), c("CA", "TX"), 2010:2020, "SECRET")
  url <- utils::URLdecode(req$url)
  expect_match(url, "https://api.eia.gov/v2/seds/data/", fixed = TRUE)
  expect_match(url, "facets[seriesId][]=TETCB", fixed = TRUE)
  expect_match(url, "facets[seriesId][]=TETCD", fixed = TRUE)
  expect_match(url, "facets[stateId][]=TX", fixed = TRUE)
  expect_match(url, "start=2010", fixed = TRUE)
  expect_match(url, "data[0]=value", fixed = TRUE)
})

test_that("fetch_eia tidies responses", {
  local_mocked_bindings(perform_json = fake_perform)
  x <- fetch_eia("seds", "TETCB", states = c("CA", "TX"), years = 2019:2020, cache = FALSE)
  expect_equal(names(x), c("state", "year", "series", "value", "unit"))
  expect_equal(nrow(x), 4)
  expect_equal(x$value[x$state == "CA" & x$year == 2019], 7800000)
  expect_false(is.null(attr(x, "rps_retrieved")))

  r <- fetch_eia("retail_sales", c("sales", "price"), states = "CA", cache = FALSE)
  expect_setequal(unique(r$series), c("sales", "price"))
  expect_equal(r$unit[r$series == "price"][1], "cents per kilowatt-hour")

  co2 <- fetch_eia("co2", "TT", states = "TX", cache = FALSE)
  expect_equal(co2$unit[1], "million metric tons of CO2")
})

test_that("fetch_eia uses the cache and never stores the key", {
  calls <- 0
  local_mocked_bindings(perform_json = function(req, what) {
    calls <<- calls + 1
    fake_perform(req, what)
  })
  withr::local_options(rpspanel.cache_dir = withr::local_tempdir())
  fetch_eia("seds", "TETCB", states = "CA", years = 2019:2020)
  fetch_eia("seds", "TETCB", states = "CA", years = 2019:2020)
  expect_equal(calls, 1)
  expect_equal(nrow(rps_cache_list()), 1)
  cached <- readRDS(list.files(rps_cache_dir(), full.names = TRUE)[1])
  expect_false(any(grepl("test-eia-key", unlist(attributes(cached)), fixed = TRUE)))
  fetch_eia("seds", "TETCB", states = "CA", years = 2019:2020, refresh = TRUE)
  expect_equal(calls, 2)
  expect_message(rps_cache_clear(), "Removed 1")
})

test_that("missing keys and network failures give classed errors", {
  withr::local_envvar(EIA_API_KEY = "")
  expect_error(fetch_eia("seds", "TETCB", cache = FALSE), class = "rpspanel_no_key")
  withr::local_envvar(EIA_API_KEY = "x")
  local_mocked_bindings(perform_json = function(req, what) {
    cli::cli_abort("offline", class = "rpspanel_http_error")
  })
  expect_error(fetch_eia("seds", "TETCB", cache = FALSE), class = "rpspanel_http_error")
})

test_that("fetch_bea parses numbers, footnotes and NIPA lines", {
  local_mocked_bindings(perform_json = fake_perform)
  g <- fetch_bea("SAGDP9N", 1, states = c("CA", "TX"), cache = FALSE)
  expect_equal(nrow(g), 4) # US row dropped
  expect_equal(g$value[g$state == "CA" & g$year == 2019], 2.8e6)
  d <- fetch_bea("T10109", 1, dataset = "NIPA", cache = FALSE)
  expect_equal(d$value, c(100, 103, 104))
  expect_true(all(is.na(d$state)))
})

test_that("BEA errors are reported", {
  body <- list(BEAAPI = list(Results = list(Error = list(APIErrorDescription = "bad key"))))
  expect_error(rpspanel:::bea_tidy(body, "X", 1, "Regional"), "bad key")
})

test_that("census responses are parsed", {
  body <- rbind(c("NAME", "B01003_001E", "state"),
                c("California", "39538223", "06"),
                c("Puerto Rico", "3285874", "72"))
  out <- rpspanel:::census_tidy(body, 2019, "B01003_001E")
  expect_equal(out$state, c("CA", NA))
  expect_equal(out$value[1], 39538223)
})
