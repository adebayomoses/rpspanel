test_that("harmonise_states maps names, codes and FIPS", {
  expect_equal(
    harmonise_states(c("California", "tx", "06", 36, "11000", "Alaska *", " new york ")),
    c("CA", "TX", "CA", "NY", "DC", "AK", "NY")
  )
  expect_equal(harmonise_states(c("CA", "DC"), to = "fips"), c("06", "11"))
  expect_equal(harmonise_states("wa", to = "name"), "Washington")
  expect_equal(harmonise_states("Washington DC"), "DC")
})

test_that("unmatched identifiers become NA with a warning", {
  expect_warning(out <- harmonise_states(c("CA", "US", "Puerto Rico")), "Could not match 2")
  expect_equal(out, c("CA", NA, NA))
  expect_equal(harmonise_states(NA), NA_character_)
  expect_silent(harmonise_states("US", warn = FALSE))
})

test_that("us_states covers 50 states and DC", {
  s <- us_states()
  expect_equal(nrow(s), 51)
  expect_false(anyDuplicated(s$abbr) > 0)
  expect_false(anyDuplicated(s$fips) > 0)
})
