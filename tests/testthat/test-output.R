rps_only <- function() {
  # No keys, so nothing is downloaded
  withr::local_envvar(EIA_API_KEY = "", BEA_API_KEY = "")
  build_panel(states = c("CA", "TX"), years = 2010:2012, groups = "rps",
              rps_methods = c("adoption", "nominal"), quiet = TRUE)
}

test_that("as_pdata converts for estimation packages", {
  p <- rps_only()
  df <- as_pdata(p, "data.frame")
  expect_s3_class(df, "data.frame", exact = TRUE)
  expect_s3_class(as_pdata(p, "csdm")$state, "factor")
  skip_if_not_installed("plm")
  expect_s3_class(as_pdata(p, "plm"), "pdata.frame")
  skip_if_not_installed("fixest")
  expect_s3_class(as_pdata(p, "fixest"), "fixest_panel")
})

test_that("export_panel writes data and codebook", {
  p <- rps_only()
  dir <- withr::local_tempdir()
  f <- file.path(dir, "panel.csv")
  export_panel(p, f)
  expect_equal(nrow(utils::read.csv(f)), 6)
  expect_true(file.exists(file.path(dir, "panel_codebook.csv")))
  expect_error(export_panel(p, file.path(dir, "panel.xyz")), "Cannot guess")
  skip_if_not_installed("haven")
  fd <- file.path(dir, "panel.dta")
  export_panel(p, fd, codebook = FALSE)
  d <- haven::read_dta(fd)
  expect_equal(attr(d$rps_nominal, "label"), "Nominal RPS requirement")
})

test_that("export_panel writes Parquet that reads back unchanged", {
  skip_if_not_installed("arrow")
  p <- rps_only()
  dir <- withr::local_tempdir()
  f <- file.path(dir, "panel.parquet")
  export_panel(p, f)
  back <- as.data.frame(arrow::read_parquet(f))
  expect_equal(back, as_pdata(p, "data.frame"), ignore_attr = TRUE)
  expect_true(file.exists(file.path(dir, "panel_codebook.csv")))
})
