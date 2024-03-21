future::plan('sequential')

test_that("ts simple", {
  # same as the main get_ts_traces test
  simpletrace <- fetch_hydllp_timeseries(portal = 'vic',
                                         gauge = "233217",
                               datasource = 'A',
                               var_list = c('100', '140'),
                               start_time = '20200101',
                               end_time = '20200105',
                               interval = 'day',
                               data_type = 'mean',
                               multiplier = 1,
                               returnformat = 'df',
                               request_timezone = 'db_default',
                               return_timezone = 'raw')
  expect_s3_class(simpletrace, 'tbl_df')
  expect_snapshot(simpletrace)

  simpletrace_UTC <- fetch_hydllp_timeseries(portal = 'vic',
                                         gauge = "233217",
                                         datasource = 'A',
                                         var_list = c('100', '140'),
                                         start_time = '20200101',
                                         end_time = '20200105',
                                         interval = 'day',
                                         data_type = 'mean',
                                         multiplier = 1,
                                         returnformat = 'df',
                                         request_timezone = 'db_default',
                                         return_timezone = 'UTC')
  expect_s3_class(simpletrace_UTC, 'tbl_df')
  expect_snapshot(simpletrace_UTC)
})
