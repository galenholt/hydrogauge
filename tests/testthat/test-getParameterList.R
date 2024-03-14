test_that("simple works", {
  bomout <- getParameterList(portal = 'bom',
                           station_no = c('410730', 'A4260505'))
  expect_snapshot(names(bomout))
  expect_equal(nrow(bomout), 9)
})
