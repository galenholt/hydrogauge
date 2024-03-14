test_that("simple works, with time test", {
  bomout <- getTimeseriesValues(portal = 'bom', ts_id = c("208669010", "380185010", "329344010"),
                                start_time = '2020-01-01 01:30:30', end_time = '20200105')
  expect_snapshot(names(bomout))
  expect_equal(nrow(bomout), 13)


})

test_that("returnfields, metareturn, more dates", {
  bomout <- getTimeseriesValues(portal = 'bom',
                                ts_id = c("208669010", "380185010", "329344010"),
                                returnfields = c('Timestamp', 'Value'),
                                meta_returnfields = c('station_name', 'station_no', 'ts_id', 'ts_unitsymbol'),
                                start_time = lubridate::ymd('2020-01-01'), end_time = '2020-01-05')

  expect_snapshot(names(bomout))
  expect_equal(nrow(bomout), 15)


})

test_that("ts_path", {
  bomout_full <- getTimeseriesValues(portal = 'bom',
                                     ts_path = 'w00078-A4260505/A4260505/WaterCourseLevel/Pat3_C_B_1_DailyMean',
                                start_time = '2020-01-01 01:30:30', end_time = '20200105')
  expect_snapshot(names(bomout_full))
  expect_equal(nrow(bomout_full), 4)

  bomout_wild <- getTimeseriesValues(portal = 'bom',
                                     ts_path = '*/A4260505/Water*/*DailyMean',
                                     start_time = '2020-01-01 01:30:30', end_time = '20200105')
  expect_snapshot(names(bomout_wild))
  expect_equal(nrow(bomout_wild), 8)


})


test_that("extra_list", {
  # A bit unclear if this actually works, since there are no gaps.
  bomout <- getTimeseriesValues(portal = 'bom',
                                ts_id = c("208669010", "380185010", "329344010"),
                                extra_list = list(gapdetection = 'fillgaps'),
                                meta_returnfields = c('station_name', 'station_no', 'ts_id', 'ts_unitsymbol'),
                                start_time = lubridate::ymd('2020-01-01'), end_time = '2020-01-05')

  expect_snapshot(names(bomout))
  expect_equal(nrow(bomout), 15)


})

test_that("period", {
  bomout_e <- getTimeseriesValues(portal = 'bom',
                                ts_id = c("208669010", "380185010", "329344010"),
                                meta_returnfields = c('station_name', 'station_no', 'ts_name', 'ts_id', 'ts_unitsymbol'),
                                start_time = NULL,
                                end_time = '2020-01-05',
                                period = 'P2W')

  expect_snapshot(names(bomout_e))
  expect_equal(nrow(bomout_e), 42)

  bomout_s <- getTimeseriesValues(portal = 'bom',
                                ts_id = c("208669010", "380185010", "329344010"),
                                meta_returnfields = c('station_name', 'station_no', 'ts_id', 'ts_unitsymbol'),
                                start_time = '2020-01-01',
                                period = 'P2W')

  expect_snapshot(names(bomout_s))
  expect_equal(nrow(bomout_s), 43)

  bomout_p <- getTimeseriesValues(portal = 'bom',
                                  ts_id = c("208669010", "380185010", "329344010"),
                                  meta_returnfields = c('station_name', 'station_no', 'ts_id', 'ts_unitsymbol'),
                                  period = 'P2W')

  expect_snapshot(names(bomout_p))
  expect_equal(nrow(bomout_p), 38)


})



