test_that("convert_units handles energy, mass and money", {
  expect_equal(convert_units(1, "trillion Btu", "billion Btu"), 1000)
  expect_equal(convert_units(1000, "thousand MWh", "TWh"), 1)
  expect_equal(convert_units(1, "MWh", "MMBtu"), 3.41214)
  expect_equal(
    convert_units(2, "million metric tons", "thousand metric tons"), 2000
  )
  expect_equal(convert_units(1, "million dollars", "thousand dollars"), 1000)
  expect_equal(convert_units(1, "Billion Btus", "billion btu"), 1)
})

test_that("convert_units refuses impossible conversions", {
  expect_error(convert_units(1, "MWh", "metric ton"), "Cannot convert")
  expect_error(convert_units(1, "furlong", "MWh"), "Unknown unit")
})

test_that("deflate rebases correctly", {
  expect_equal(deflate(c(10, 12), c(90, 110)), c(10 * 100 / 90, 12 * 100 / 110))
  expect_equal(deflate(c(10, 12), c(90, 110), years = c(2010, 2020),
                       base_year = 2020),
               c(10 * 110 / 90, 12))
  # base year looked up in a longer index series
  expect_equal(deflate(12, 110, years = 2020, base_year = 2017,
                       index_years = c(2017, 2020), index_values = c(100, 110)),
               12 * 100 / 110)
  expect_error(deflate(1, 100, years = 2020, base_year = 1900),
               "No price index")
})
