test_that("simple works, with time test", {
  bomout <- fetch_kiwis_timeseries(portal = 'bom',
                                   gauge = c('410730', 'A4260505'),
                                start_time = '2020-01-01 01:30:30',
                                end_time = '20200105')
  expect_snapshot(names(bomout))
  expect_equal(nrow(bomout), 13)


})

test_that("multiple of each filter arg", {
  bomout <- fetch_kiwis_timeseries(portal = 'bom',
                                   gauge = c('410730', 'A4260505'),
                                   variable = c('discharge', 'Rainfall'),
                                   units = c('cumec', 'mm'),
                                   timeunit = c('Daily', 'Monthly'),
                                   statistic = c('Mean', 'Total'),
                                   datatype = c('QaQc', 'Harmon'),
                                   start_time = '2020-01-01 01:30:30',
                                   end_time = '20200105')
  expect_snapshot(names(bomout))
  expect_equal(nrow(bomout), 13)


})
