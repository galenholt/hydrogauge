test_that("ts example", {
  simpletrace <- get_ts_traces(site_list = "233217",
                               datasource = 'A',
                               var_list = c('100', '140'),
                               start_time = '20200101', end_time = '20200105',
                               interval = 'day', data_type = 'mean',
                               multiplier = 1, returnformat = 'df')
  expect_s3_class(simpletrace, 'tbl_df')
})

test_that("ts_2 example", {
  # There's a weird API error in here that I can't figure out. It says it's
  # suspended, for 140, but the above works. Must be a date interaction?

  # simpletrace <- get_ts_traces2(state
  # = 'Vic', site_list = "233217", datasource = 'A', var_list = "all",
  # start_time = "all", end_time = "all", interval = 'year', data_type = 'mean',
  # multiplier = 1, returnformat = 'df') expect_s3_class(simpletrace, 'tbl_df')
})
