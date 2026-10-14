# Small invented RPS coding with known answers (state codes are real only so
# that harmonisation works; the rules are not).
toy_rules <- function(coverage = 0.8, baseline = 0.05) {
  rules <- data.frame(
    state = c("CA", "TX", "FL"), has_rps = c(1, 1, 0),
    policy_name = c("A", "B", NA), enacted_year = c(2005, 2008, NA),
    first_compliance_year = c(2007, 2010, NA), repeal_year = c(NA, 2015, NA),
    target_type = c("share", "share", NA), final_target = c(0.2, 0.1, NA),
    final_target_year = c(2015, 2012, NA), coverage_share = c(coverage, 1, NA),
    out_of_state_rec = c(1, 0, NA), carveout = c(0, 1, NA),
    carveout_types = c(NA, "solar", NA), acp = c(1, 0, NA),
    acp_usd_mwh = c(50, NA, NA), baseline_re_share = c(baseline, NA, NA),
    source = "invented", verified = TRUE, notes = NA
  )
  targets <- data.frame(state = c("CA", "CA", "TX", "TX"),
                        year = c(2007, 2015, 2010, 2012),
                        target = c(0.04, 0.20, 0.05, 0.10))
  rpspanel:::new_rps_rules(rules, targets)
}

# Fake API responses keyed on the request URL.
fake_eia_body <- function(url) {
  if (grepl("/seds/", url, fixed = TRUE)) {
    data <- data.frame(period = c("2019", "2020", "2019", "2020"),
                       seriesId = "TETCB", stateId = c("CA", "CA", "TX", "TX"),
                       value = c("7800000", "7000000", "13000000", "12500000"),
                       unit = "Billion Btu")
  } else if (grepl("co2-emissions", url, fixed = TRUE)) {
    data <- data.frame(period = c("2019", "2020", "2019", "2020"),
                       sectorId = "TT", fuelId = "TO",
                       stateId = c("CA", "CA", "TX", "TX"),
                       value = c(358, 303, 683, 642),
                       `value-units` = "million metric tons of CO2",
                       check.names = FALSE)
  } else if (grepl("operational-data", url, fixed = TRUE)) {
    data <- expand.grid(period = c("2019", "2020"), location = c("CA", "TX"),
                        fueltypeid = c("ALL", "WND", "SUN", "HYC"),
                        stringsAsFactors = FALSE)
    data$sectorid <- "99"
    data$generation <- c(200000, 190000, 480000, 470000,   # ALL
                         14000, 13000, 84000, 92000,       # WND
                         28000, 29000, 5000, 9000,         # SUN
                         34000, 21000, 1000, 900)          # HYC
    data$`generation-units` <- "thousand megawatthours"
  } else if (grepl("retail-sales", url, fixed = TRUE)) {
    data <- data.frame(period = c("2019", "2020", "2019", "2020"),
                       stateid = c("CA", "CA", "TX", "TX"), sectorid = "ALL",
                       sales = c(250000, 247000, 430000, 426000),
                       price = c(16.6, 17.7, 8.5, 8.4),
                       `sales-units` = "million kilowatt hours",
                       `price-units` = "cents per kilowatt-hour",
                       check.names = FALSE)
  } else {
    stop("unexpected url")
  }
  list(response = list(total = as.character(nrow(data)), data = data))
}

fake_bea_body <- function(url) {
  if (grepl("NIPA", url, fixed = TRUE)) {
    data <- data.frame(TableName = "T10109", LineNumber = c("1", "1", "1", "2"),
                       TimePeriod = c("2017", "2019", "2020", "2020"),
                       CL_UNIT = "Fisher Price Index", UNIT_MULT = "0",
                       DataValue = c("100.000", "103.000", "104.000", "99"))
  } else {
    line <- sub(".*LineCode=([0-9]+).*", "\\1", url)
    table <- sub(".*TableName=([A-Z0-9]+).*", "\\1", url)
    val <- switch(paste0(table, ":", line),
      "SAGDP9N:1" = c("2,800,000", "2,700,000", "1,800,000", "1,750,000", "(NA)"),
      "SAINC1:2" = c("39,500,000", "39,400,000", "29,000,000", "29,200,000", "330000000"),
      rep("1", 5))
    data <- data.frame(Code = paste0(table, "-", line),
                       GeoFips = c("06000", "06000", "48000", "48000", "00000"),
                       GeoName = c("California", "California", "Texas", "Texas", "United States"),
                       TimePeriod = c("2019", "2020", "2019", "2020", "2020"),
                       CL_UNIT = "Millions of chained 2017 dollars", UNIT_MULT = "6",
                       DataValue = val)
  }
  list(BEAAPI = list(Results = list(Data = data)))
}

fake_perform <- function(req, what) {
  url <- utils::URLdecode(req$url)
  if (grepl("api.eia.gov", url, fixed = TRUE)) {
    fake_eia_body(url)
  } else if (grepl("apps.bea.gov", url, fixed = TRUE)) {
    fake_bea_body(url)
  } else {
    stop("unexpected request")
  }
}
