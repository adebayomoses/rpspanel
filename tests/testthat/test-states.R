test_that("harmonise_states maps names, codes and FIPS", {
  expect_identical(
    harmonise_states(c("California", "tx", "06", 36, "11000", "Alaska *",
                       " new york ")),
    c("CA", "TX", "CA", "NY", "DC", "AK", "NY")
  )
  expect_identical(harmonise_states(c("CA", "DC"), to = "fips"), c("06", "11"))
  expect_identical(harmonise_states("wa", to = "name"), "Washington")
  expect_identical(harmonise_states("Washington DC"), "DC")
})

test_that("unmatched identifiers become NA with a warning", {
  ids <- c("CA", "US", "Puerto Rico")
  expect_warning(harmonise_states(ids), "Could not match 2")
  out <- suppressWarnings(harmonise_states(ids))
  expect_identical(out, c("CA", NA, NA))
  expect_identical(harmonise_states(NA), NA_character_)
  expect_silent(harmonise_states("US", warn = FALSE))
})

test_that("us_states covers 50 states and DC", {
  s <- us_states()
  expect_identical(nrow(s), 51L)
  expect_false(anyDuplicated(s$abbr) > 0)
  expect_false(anyDuplicated(s$fips) > 0)
})
