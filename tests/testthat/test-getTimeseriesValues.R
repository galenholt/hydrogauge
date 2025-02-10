test_that("simple works, with time test", {
  with_mock_dir('mocked_responses/getTimeseriesValues/simple',
  bomout <- getTimeseriesValues(portal = 'bom', ts_id = c("208669010", "380185010", "329344010"),
                                start_time = '2020-01-01 01:30:30', end_time = '20200105')
  )
  expect_snapshot_value(names(bomout), style = 'deparse')
  expect_equal(nrow(bomout), 11)


})

test_that("returnfields, metareturn, more dates", {
  with_mock_dir('mocked_responses/getTimeseriesValues/returns_meta_dates',
  bomout <- getTimeseriesValues(portal = 'bom',
                                ts_id = c("208669010", "380185010", "329344010"),
                                returnfields = c('Timestamp', 'Value'),
                                meta_returnfields = c('station_name', 'station_no', 'ts_id', 'ts_unitsymbol'),
                                start_time = lubridate::ymd('2020-01-01'), end_time = '2020-01-05')
  )

  expect_snapshot_value(names(bomout), style = 'deparse')
  expect_equal(nrow(bomout), 13)


})

test_that("ts_path", {
  with_mock_dir('mocked_responses/getTimeseriesValues/ts_path',
  bomout_full <- getTimeseriesValues(portal = 'bom',
                                     ts_path = 'w00078-A4260505/A4260505/WaterCourseLevel/Pat3_C_B_1_DailyMean',
                                start_time = '2020-01-01 01:30:30', end_time = '20200105')
  )

  expect_snapshot_value(names(bomout_full), style = 'deparse')
  expect_equal(nrow(bomout_full), 3)

  with_mock_dir('mocked_responses/getTimeseriesValues/ts_path_wild',
  bomout_wild <- getTimeseriesValues(portal = 'bom',
                                     ts_path = '*/A4260505/Water*/*DailyMean',
                                     start_time = '2020-01-01 01:30:30', end_time = '20200105')
  )
  expect_snapshot_value(names(bomout_wild), style = 'deparse')
  expect_equal(nrow(bomout_wild), 6)


})


test_that("extra_list", {
  # A bit unclear if this actually works, since there are no gaps.
  with_mock_dir('mocked_responses/getTimeseriesValues/extra_list_gaps',
  bomout <- getTimeseriesValues(portal = 'bom',
                                ts_id = c("208669010", "380185010", "329344010"),
                                extra_list = list(gapdetection = 'fillgaps'),
                                meta_returnfields = c('station_name', 'station_no', 'ts_id', 'ts_unitsymbol'),
                                start_time = lubridate::ymd('2020-01-01'), end_time = '2020-01-05')
  )

  expect_snapshot_value(names(bomout), style = 'deparse')
  expect_equal(nrow(bomout), 13)


})

test_that("period", {
  with_mock_dir('mocked_responses/getTimeseriesValues/period_e',
  bomout_e <- getTimeseriesValues(portal = 'bom',
                                ts_id = c("208669010", "380185010", "329344010"),
                                meta_returnfields = c('station_name', 'station_no', 'ts_name', 'ts_id', 'ts_unitsymbol'),
                                start_time = NULL,
                                end_time = '2020-01-05',
                                period = 'P2W')
  )

  expect_snapshot_value(names(bomout_e), style = 'deparse')
  expect_equal(nrow(bomout_e), 43)

  with_mock_dir('mocked_responses/getTimeseriesValues/period_s',
  bomout_s <- getTimeseriesValues(portal = 'bom',
                                ts_id = c("208669010", "380185010", "329344010"),
                                meta_returnfields = c('station_name', 'station_no', 'ts_id', 'ts_unitsymbol'),
                                start_time = '2020-01-01',
                                period = 'P2W')
  )

  expect_snapshot_value(names(bomout_s), style = 'deparse')
  expect_equal(nrow(bomout_s), 43)

  # This depends on the current date, so the rows fluctuat a bit
  with_mock_dir('mocked_responses/getTimeseriesValues/period_p',
  bomout_p <- getTimeseriesValues(portal = 'bom',
                                  ts_id = c("208669010", "380185010", "329344010"),
                                  meta_returnfields = c('station_name', 'station_no', 'ts_id', 'ts_unitsymbol'),
                                  period = 'P2W')
  )

  expect_snapshot_value(names(bomout_p), style = 'deparse')
  expect_true(nrow(bomout_p) > 34 & nrow(bomout_p) < 40)


})


# checking how things work with dates
test_that("time testing for the period", {
  with_mock_dir('mocked_responses/getTimeseriesValues/range_char',
  ts_list <- getTimeseriesList(portal = 'bom',
                               station_no = c('410730', 'A4260505'),
                               return_timezone = 'UTC')
  )

  # get the range of a single id
  oneid <- ts_list |>
    dplyr::filter(grepl('208669010', ts_id)) |>
    dplyr::select(ts_id, ts_name, from, to)

  # What if we try to get it across the start?
    # This actually doesn't return nonexistent data
  with_mock_dir('mocked_responses/getTimeseriesValues/range_dates',
  preout <- getTimeseriesValues(portal = 'bom',
                                ts_id = oneid$ts_id,
                                start_time = oneid$from - lubridate::dweeks(1),
                                end_time = oneid$from + lubridate::dweeks(1),
                                return_timezone = 'UTC')
  )
  # The first time should be the min time, not the start time that's a week earlier.
  expect_equal(oneid$from, min(preout$time))
  expect_equal(nrow(preout), 7)

  # What if we try to get it across the end
 # Get something from the getTimesereiesList test that uses the river murray wildcard
  with_mock_dir('mocked_responses/getTimeseriesValues/get_range',
  tsrm <- getTimeseriesList(portal = 'bom',
                              extra_list = list(station_name = 'River Murray*',
                                                ts_name = 'DMQaQc.Merged.DailyMean.24HR'),
                              returnfields = c('station_no', 'station_name', 'ts_name', 'ts_id',
                                               'ts_path', 'coverage', 'station_latitude'),
                            return_timezone = 'UTC')
  )
  tsrmold <- tsrm |> dplyr::filter(to < lubridate::ymd('20231230'))

  twoid <- tsrmold |>
    dplyr::slice(1) |>
    dplyr::select(ts_id, ts_name, from, to)

  # Why is there data???
  with_mock_dir('mocked_responses/getTimeseriesValues/past_ends',
  preout <- getTimeseriesValues(portal = 'bom',
                                ts_id = twoid$ts_id,
                                start_time = twoid$to - lubridate::dweeks(1),
                                end_time = twoid$to + lubridate::dweeks(1),
                                return_timezone = 'UTC')
  )
  expect_equal(twoid$to, max(preout$time))
  expect_equal(nrow(preout), 8)

  with_mock_dir('mocked_responses/getTimeseriesValues/complete',
  compout <- getTimeseriesValues(portal = 'bom',
                                ts_id = twoid$ts_id,
                                period = 'complete',
                                return_timezone = 'UTC')
  )

  expect_equal(twoid$to, max(compout$time))
  expect_equal(twoid$from, min(compout$time))
  expect_true(nrow(compout) > 2000)




})

test_that("timezones work right", {

  # BOM states "Time of day is presented in local standard time. Coordinated Universal Timezones (UTC) are:

  # THIS DOCUMENTATION IS NOT TRUE-by API default (here, `timezone = NULL`), we get +10 everywhere.
  # Eastern States (QLD, NSW, ACT, VIC, TAS) - UTC +10:00
  # Central States (NT, SA) - UTC +09:30
  # Western Australia - UTC +08:00.

  # also, "Most data are supplied once a day", so that makes checking differences difficult

  # The API default for each state is +10 These ARE returned at +10, but
  # lubridate automatically does the shift to UTC. So, the values here should
  # match if we just ask for UTC, even though they were returned from the API as
  # +10
  # A4261162 is Murray Bridge, and reports at +9:30 in the web interface but
  # +10 here need as stored that reports continuously
  with_mock_dir('mocked_responses/getTimeseriesValues/tz_default',
  ts_SA <- getTimeseriesList(portal = 'bom',
                            station_no = 'A4261162',
                            extra_list = list(ts_name = 'DMQaQc.Merged.AsStored.1',
                                              stationparameter_name = 'WaterCourseLevel'),
                            returnfields = c('station_no', 'station_name', 'ts_name', 'ts_id', 'ts_path', 'coverage', 'station_latitude'),
                            return_timezone = 'db_default')
  )

  # Checking that the times couldn't be London worked for states, but not for BOM since reporting isn't fast enough.

  # But we can at least see how the tzs behave
  # 412078 is Lachlan in NSW
  with_mock_dir('mocked_responses/getTimeseriesValues/tz_default2',
  ts_NSW <- getTimeseriesList(portal = 'bom',
                            station_no = '412078',
                            extra_list = list(ts_name = 'DMQaQc.Merged.AsStored.1',
                                              stationparameter_name = 'WaterCourseLevel'),
                            returnfields = c('station_no', 'station_name', 'ts_name', 'ts_id', 'ts_path', 'coverage', 'station_latitude'),
                            return_timezone = 'db_default')
  )

  # WA
  with_mock_dir('mocked_responses/getTimeseriesValues/tz_wa',
  ts_WA <- getTimeseriesList(portal = 'bom',
                              station_no = '615026',
                              extra_list = list(ts_name = 'DMQaQc.Merged.AsStored.1',
                                                stationparameter_name = 'WaterCourseLevel'),
                              returnfields = c('station_no', 'station_name', 'ts_name', 'ts_id', 'ts_path', 'coverage', 'station_latitude'),
                             return_timezone = 'db_default')
  )

  expect_equal(ts_SA$from |> lubridate::tz(), 'Etc/GMT-10')
  expect_equal(ts_NSW$from |> lubridate::tz(), 'Etc/GMT-10')
  expect_equal(ts_WA$from |> lubridate::tz(), 'Etc/GMT-10')

  # Does 'timezone = 'individual' directly to the API let us get gauge-specific? Doesn't seem to be supported by BOM
  # ts_SA_i <- getTimeseriesList(portal = 'bom',
  #                            station_no = 'A4261162',
  #                            extra_list = list(ts_name = 'DMQaQc.Merged.AsStored.1',
  #                                              stationparameter_name = 'WaterCourseLevel',
  #                                              timezone = 'individual'),
  #                            returnfields = c('station_no', 'station_name', 'ts_name', 'ts_id', 'ts_path', 'coverage', 'station_latitude'),
  #                            return_timezone = 'db_default')

  # and can we put something arbitrary in and still get the right db_tz?
  with_mock_dir('mocked_responses/getTimeseriesValues/tz_wa_cet',
  ts_WA_CET <- getTimeseriesList(portal = 'bom',
                             station_no = '615026',
                             extra_list = list(ts_name = 'DMQaQc.Merged.AsStored.1',
                                               stationparameter_name = 'WaterCourseLevel'),
                             returnfields = c('station_no', 'station_name', 'ts_name', 'ts_id', 'ts_path', 'coverage', 'station_latitude'),
                             return_timezone = 'CET')
  )
  expect_equal(ts_WA_CET$from |> lubridate::tz(), 'CET')
  expect_equal(ts_WA_CET$database_timezone, 'Etc/GMT-10')

  # Test the time extraction- if we give it a time, does it treat it as a time in the `timezone` we give it?
  # NO- input times are interpreted in the database default timezone.

  # Get something with AsStored
  with_mock_dir('mocked_responses/getTimeseriesValues/asstored',
  storedout <- getTimeseriesValues(portal = 'bom',
                                   ts_id = 208665010,
                                   start_time = '2020-01-01 00:00:00',
                                   end_time = '2020-01-01 23:59:00',
                                   return_timezone = 'db_default')
  )
  # use [2] because 1 is midnight and as.character drops it
  expect_equal(as.character(storedout$time[2]), '2020-01-01 00:05:00')
  expect_equal(storedout$time |> lubridate::tz(), "Etc/GMT-10")

  # check UTC- the input time is *local*, so the returned time in UTC will be off by 10h
  with_mock_dir('mocked_responses/getTimeseriesValues/stored_utc',
  storedout_UTC <- getTimeseriesValues(portal = 'bom',
                                       ts_id = 208665010,
                                       start_time = '2020-01-01 00:00:00',
                                       end_time = '2020-01-01 23:59:00',
                                       return_timezone = 'UTC')
  )
  expect_equal(as.character(storedout_UTC$time[1]), "2019-12-31 14:00:00")
  expect_equal(storedout_UTC$time |> lubridate::tz(), "UTC")

  # and can we still get the characters?
  with_mock_dir('mocked_responses/getTimeseriesValues/tz_char',
  storedout_char <- getTimeseriesValues(portal = 'bom',
                                       ts_id = 208665010,
                                       start_time = '2020-01-01 00:00:00',
                                       end_time = '2020-01-01 23:59:00',
                                       return_timezone = 'char')
  )
  expect_equal(storedout_char$time[1], "2020-01-01T00:00:00.000+10:00")

})



