test_that("simple works, with time test", {
  bomout <- fetch_kiwis_timeseries(portal = 'bom',
                                   gauge = c('410730', 'A4260505'),
                                start_time = '2020-01-01 01:30:30',
                                end_time = '20200105')
  expect_snapshot_value(names(bomout), style = 'deparse')
  expect_equal(nrow(bomout), 8)
  expect_equal(lubridate::tz(bomout$time[1]), 'UTC')
  # The discharge is at 09am at GMT +10, so the value that gets grabbed is the next one after start_time
  expect_equal(bomout$time[1], lubridate::ymd_hms('2020-01-01 09:00:00', tz = 'Etc/GMT-10') |>
                 lubridate::with_tz('UTC'))


})

test_that("multiple of each filter arg", {
  bomout <- fetch_kiwis_timeseries(portal = 'bom',
                                   gauge = c('410730', 'A4260505'),
                                   variable = c('discharge', 'Rainfall'),
                                   units = c('cumec', 'mm'),
                                   timeunit = c('Daily', 'Monthly'),
                                   statistic = c('Mean', 'Total'),
                                   datatype = c('QaQc', 'Harmon'),
                                   # If I want monthly to return, need to cross a month boundary.
                                   start_time = '2019-12-01 01:30:30',
                                   end_time = '20200105')

  expect_snapshot_value(names(bomout), style = 'deparse')
  expect_equal(nrow(bomout), 212)

  # monthly data reports on the first of the month
  expect_equal(bomout$time[212], lubridate::ymd_hms('2020-01-01 00:00:00', tz = 'Etc/GMT-10') |>
                 lubridate::with_tz('UTC'))


})


test_that("I can separate the 09 vs 24 in the QaQc, and it doesn't fail when asking for things that aren't there", {
  bomout <- fetch_kiwis_timeseries(portal = 'bom',
                                   gauge = '410730',
                                   variable = 'Rainfall',
                                   units = c('cumec', 'mm'), # only mm exists for rainfall
                                   timeunit = 'Daily',
                                   statistic = c('Mean', 'Total'), # ditto Total
                                   datatype = 'QaQc.*09', # with just 'QaQc, both 09 and 24 are here.
                                   start_time = '2020-01-01 00:00:00',
                                   end_time = '20200105')

  expect_equal(nrow(bomout), 4)

  # monthly data reports on the first of the month
  expect_true(all(grepl('09', bomout$ts_name)))


})

test_that("Unavailable gauges disappear", {
  # 'B18230938' is made up, this should be the same as the first test.
  bomout <- fetch_kiwis_timeseries(portal = 'bom',
                                   gauge = c('410730', 'A4260505', 'B18230938'),
                                   start_time = '2020-01-01 01:30:30',
                                   end_time = '20200105')
  expect_snapshot_value(names(bomout), style = 'deparse')
  expect_equal(nrow(bomout), 8)
  expect_equal(lubridate::tz(bomout$time[1]), 'UTC')
  # The discharge is at 09am at GMT +10, so the value that gets grabbed is the next one after start_time
  expect_equal(bomout$time[1], lubridate::ymd_hms('2020-01-01 09:00:00', tz = 'Etc/GMT-10') |>
                 lubridate::with_tz('UTC'))


})


