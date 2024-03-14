test_that("simple works", {
  bomout <- getTimeseriesList(portal = 'bom', site_list = c('410730', 'A4260505'))
  expect_snapshot(names(bomout))
  expect_equal(nrow(bomout), 200)

})

test_that("extra_list and returnfields", {
  bomout <- getTimeseriesList(portal = 'bom',
                           extra_list = list(station_name = 'River Murray*',
                                             ts_name = 'DMQaQc.Merged.DailyMean.24HR'),
                           returnfields = c('station_no', 'station_name', 'ts_id', 'ts_path', 'coverage', 'station_latitude'))

  namevec <- c('station_no', 'station_name', 'ts_id', 'from', 'to')
  expect_snapshot(names(bomout))
  expect_equal(nrow(bomout), 199)
})
