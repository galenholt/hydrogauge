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


# checking how things work with dates
test_that("time testing", {
  ts_list <- getTimeseriesList(portal = 'bom', station_no = c('410730', 'A4260505'))

  # get the range of a single id
  oneid <- ts_list |>
    dplyr::filter(grepl('208669010', ts_id)) |>
    dplyr::select(ts_id, ts_name, from, to)

  # What if we try to get it across the start?
    # This actually doesn't return nonexistent data
  preout <- getTimeseriesValues(portal = 'bom',
                                ts_id = oneid$ts_id,
                                start_time = oneid$from - lubridate::dweeks(1),
                                end_time = oneid$from + lubridate::dweeks(1))
  expect_equal(oneid$from, min(preout$timestamp))
  expect_equal(nrow(bomout), 7)

  # What if we try to get it across the end
 # Get something from the getTimesereiesList test that uses the river murray wildcard
  tsrm <- getTimeseriesList(portal = 'bom',
                              extra_list = list(station_name = 'River Murray*',
                                                ts_name = 'DMQaQc.Merged.DailyMean.24HR'),
                              returnfields = c('station_no', 'station_name', 'ts_name', 'ts_id', 'ts_path', 'coverage', 'station_latitude'))
  tsrmold <- tsrm |> dplyr::filter(to < lubridate::ymd('20231230'))

  twoid <- tsrmold |>
    dplyr::filter(grepl('208797010', ts_id)) |>
    dplyr::select(ts_id, ts_name, from, to)

  # Why is there data???
  preout <- getTimeseriesValues(portal = 'bom',
                                ts_id = twoid$ts_id,
                                start_time = twoid$to - lubridate::dweeks(1),
                                end_time = twoid$to + lubridate::dweeks(1))
  expect_equal(twoid$to, max(preout$timestamp))
  expect_equal(nrow(preout), 8)

  compout <- getTimeseriesValues(portal = 'bom',
                                ts_id = twoid$ts_id,
                                period = 'complete')

  expect_equal(twoid$to, max(compout$timestamp))
  expect_equal(twoid$from, min(compout$timestamp))
  expect_equal(nrow(compout), 7941)

  # Test the time extraction- is it local or UTM? I assume local but need to double check.

  # Get something with AsStored
  storedout <- getTimeseriesValues(portal = 'bom',
                                   ts_id = 208665010,
                                   start_time = '2020-01-01 00:00:00',
                                   end_time = '2020-01-01 23:59:00')
  expect_equal(storedout$time[1], '2020-01-01T00:00:00.000+10:00')

  # check the timeparse
  storedout_UTC <- getTimeseriesValues(portal = 'bom',
                                   ts_id = 208665010,
                                   start_time = '2020-01-01 00:00:00',
                                   end_time = '2020-01-01 23:59:00',
                                   timetype = 'UTC')
  expect_equal(storedout_UTC$time[1], lubridate::ymd_hms('2019-12-31 14:00:00'))

  # check the timeparse
  storedout_local <- getTimeseriesValues(portal = 'bom',
                                       ts_id = 208665010,
                                       start_time = '2020-01-01 00:00:00',
                                       end_time = '2020-01-01 23:59:00',
                                       timetype = 'local')
  expect_equal(storedout_local$time[1], lubridate::ymd_hms('2020-01-01 00:00:00', tz = 'Etc/GMT-10'))


})



