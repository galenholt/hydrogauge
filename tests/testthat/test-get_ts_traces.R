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

test_that("errorhandling for a single site, ts2", {

  # gauge 412107 throws an error for this var_list
  pass412107 <- get_ts_traces2(state = 'NSW',
                 site_list = '412107',
                 var_list = "141",
                 start_time = 'all',
                 end_time = 'all',
                 interval = 'day',
                 data_type = 'mean',
                 returnformat = 'sitelist',
                 .errorhandling = 'pass')

  # It's a list of one tibble
  expect_s3_class(pass412107[[1]], 'tbl_df')
  expect_equal(nrow(pass412107[[1]]), 1)

  expect_error(stop412107 <- get_ts_traces2(state = 'NSW',
                               site_list = '412107',
                               var_list = "141",
                               start_time = 'all',
                               end_time = 'all',
                               interval = 'day',
                               data_type = 'mean',
                               returnformat = 'sitelist',
                               .errorhandling = 'stop'))


  remove412107 <- get_ts_traces2(state = 'NSW',
                               site_list = '412107',
                               var_list = "141",
                               start_time = 'all',
                               end_time = 'all',
                               interval = 'day',
                               data_type = 'mean',
                               returnformat = 'sitelist',
                               .errorhandling = 'remove')
  expect_type(remove412107, 'list')
  expect_equal(length(remove412107), 0)

})

test_that("errorhandling appends correctly", {

  # gauge 412107 throws an error for this var_list
  pass3 <- get_ts_traces2(state = 'NSW',
                               site_list = c('422028', '412107', '410007'),
                               var_list = "141",
                               start_time = 'all',
                               end_time = 'all',
                               interval = 'day',
                               data_type = 'mean',
                               returnformat = 'sitelist',
                               .errorhandling = 'pass')

  expect_equal(length(pass3), 3)
  expect_s3_class(pass3[[1]], 'tbl_df')
  # this should be the failure
  expect_s3_class(pass3[[2]], 'tbl_df')

  expect_equal(nrow(pass3[[2]]), 1)
  expect_true(nrow(pass3[[1]]) > 1)
  expect_true(nrow(pass3[[3]]) > 1)



  expect_error(stop3 <- get_ts_traces2(state = 'NSW',
                                            site_list = c('422028', '412107', '410007'),
                                            var_list = "141",
                                            start_time = 'all',
                                            end_time = 'all',
                                            interval = 'day',
                                            data_type = 'mean',
                                            returnformat = 'sitelist',
                                            .errorhandling = 'stop'))


  remove3 <- get_ts_traces2(state = 'NSW',
                                 site_list = c('422028', '412107', '410007'),
                                 var_list = "141",
                                 start_time = 'all',
                                 end_time = 'all',
                                 interval = 'day',
                                 data_type = 'mean',
                                 returnformat = 'sitelist',
                                 .errorhandling = 'remove')
  # the error should be silently dropped
  expect_equal(length(remove3), 2)
  expect_s3_class(remove3[[1]], 'tbl_df')
  expect_s3_class(remove3[[2]], 'tbl_df')

  expect_true(nrow(remove3[[1]]) > 1)
  expect_true(nrow(remove3[[2]]) > 1)


})

test_that("ts either errors or works", {

  # I haven't implemented .errorhandling here.

  # gauge 412107 throws an error for this var_list
  expect_error(pass412107 <- get_ts_traces(state = 'NSW',
                                           site_list = '412107',
                                           var_list = "141",
                                           start_time = '20200101',
                                           end_time = '20201231',
                                           interval = 'day',
                                           data_type = 'mean',
                                           returnformat = 'sitelist'))

  working_ts <- get_ts_traces(state = 'NSW',
                              site_list = c('422028', '410007'),
                              var_list = "141",
                              start_time = '20200101',
                              end_time = '20201231',
                              interval = 'day',
                              data_type = 'mean',
                              returnformat = 'sitelist')

  expect_equal(length(working_ts), 2)
  expect_s3_class(working_ts[[1]], 'tbl_df')
  # this should be the failure
  expect_s3_class(working_ts[[2]], 'tbl_df')

  expect_true(nrow(working_ts[[2]]) > 1)
  expect_true(nrow(working_ts[[1]]) > 1)


})
