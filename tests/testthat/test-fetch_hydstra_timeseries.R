future::plan('sequential')

test_that("ts simple", {
  # same as the main get_ts_traces test
  simpletrace <- fetch_hydstra_timeseries(portal = 'vic',
                                         gauge = "233217",
                               datasource = 'A',
                               var_list = c('100', '141'),
                               start_time = '20200101',
                               end_time = '20200105',
                               timeunit = 'day',
                               statistic = 'mean',
                               multiplier = 1,
                               returnformat = 'df',
                               request_timezone = 'db_default',
                               return_timezone = 'raw')
  expect_s3_class(simpletrace, 'tbl_df')
  expect_snapshot(simpletrace)

})

test_that("timezones behave", {
  simpletrace_UTC <- fetch_hydstra_timeseries(portal = 'vic',
                                              gauge = "233217",
                                              datasource = 'A',
                                              var_list = c('100', '141'),
                                              start_time = '20200101',
                                              end_time = '20200105',
                                              timeunit = 'day',
                                              statistic = 'mean',
                                              multiplier = 1,
                                              returnformat = 'df',
                                              request_timezone = 'db_default',
                                              return_timezone = 'UTC')
  expect_s3_class(simpletrace_UTC, 'tbl_df')
  expect_snapshot(simpletrace_UTC)

  # now, if we call that with variable and unit we should get the same thing.
})

test_that("variable and unit work", {
  # This should just get 141
  simpletrace_vt <- fetch_hydstra_timeseries(portal = 'vic',
                                              gauge = "233217",
                                              datasource = 'A',
                                              var_list = '141',
                                              start_time = '20200101',
                                              end_time = '20200105',
                                              timeunit = 'day',
                                              statistic = 'mean',
                                              multiplier = 1,
                                              returnformat = 'df',
                                              request_timezone = 'db_default',
                                              return_timezone = 'UTC')

  # as should this
  simpletrace_vu <- fetch_hydstra_timeseries(portal = 'vic',
                                             gauge = "233217",
                                             datasource = 'A',
                                             variable = 'discharge',
                                             unit = 'ML/d',
                                             start_time = '20200101',
                                             end_time = '20200105',
                                             timeunit = 'day',
                                             statistic = 'mean',
                                             multiplier = 1,
                                             returnformat = 'df',
                                             request_timezone = 'db_default',
                                             return_timezone = 'UTC')

  # Those two should match
  expect_equal(simpletrace_vu, simpletrace_vt)
})


test_that("ignore unavailable gauges", {
  # '615026' is in WA
  expect_warning(simpletrace_vt_WA <- fetch_hydstra_timeseries(portal = 'vic',
                                             gauge = c("233217", '615026'),
                                             datasource = 'A',
                                             var_list = '141',
                                             start_time = '20200101',
                                             end_time = '20200105',
                                             timeunit = 'day',
                                             statistic = 'mean',
                                             multiplier = 1,
                                             returnformat = 'df',
                                             request_timezone = 'db_default',
                                             return_timezone = 'UTC'))
})
