# avoid warnings about plans
# doFuture::registerDoFuture() # Shouldn't be needed anymore
future::plan('sequential')

test_that("ts example", {
  simpletrace <- get_ts_traces(portal = 'vic', site_list = "233217",
                               datasource = 'A',
                               var_list = c('100', '140'),
                               start_time = '20200101',
                               end_time = '20200105',
                               interval = 'day',
                               data_type = 'mean',
                               multiplier = 1,
                               returnformat = 'df',
                               return_timezone = 'raw')
  expect_s3_class(simpletrace, 'tbl_df')
  expect_snapshot(simpletrace)
})

test_that("ts_2 example", {
  # There's a weird API error in here that I can't figure out. It says it's
  # suspended, for 140, but the above works. Must be a date interaction?

  # simpletrace <- get_ts_traces2(portal = 'Vic',
  #                               site_list = "233217",
  #                               datasource = 'A',
  #                               var_list = "all",
  #                               start_time = "all",
  #                               end_time = "all",
  #                               interval = 'year',
  #                               data_type = 'mean',
  #                               multiplier = 1,
  #                               returnformat = 'df')
  # expect_s3_class(simpletrace, 'tbl_df')
})

test_that("errorhandling for a single site, ts2", {

  # gauge 412107 throws an error for this var_list
  pass412107 <- get_ts_traces2(portal = 'NSW',
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
  expect_snapshot(pass412107[[1]])

  expect_error(stop412107 <- get_ts_traces2(portal = 'NSW',
                                            site_list = '412107',
                                            var_list = "141",
                                            start_time = 'all',
                                            end_time = 'all',
                                            interval = 'day',
                                            data_type = 'mean',
                                            returnformat = 'sitelist',
                                            .errorhandling = 'stop'))


  remove412107 <- get_ts_traces2(portal = 'NSW',
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
  pass3 <- get_ts_traces2(portal = 'NSW',
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

  expect_equal(nrow(pass3[[2]]), 1) # The error
  expect_true(nrow(pass3[[1]]) > 1)
  expect_true(nrow(pass3[[3]]) > 1)



  expect_error(stop3 <- get_ts_traces2(portal = 'NSW',
                                       site_list = c('422028', '412107', '410007'),
                                       var_list = "141",
                                       start_time = 'all',
                                       end_time = 'all',
                                       interval = 'day',
                                       data_type = 'mean',
                                       returnformat = 'sitelist',
                                       .errorhandling = 'stop'))


  remove3 <- get_ts_traces2(portal = 'NSW',
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
  expect_error(pass412107 <- get_ts_traces(portal = 'NSW',
                                           site_list = '412107',
                                           var_list = "141",
                                           start_time = '20200101',
                                           end_time = '20201231',
                                           interval = 'day',
                                           data_type = 'mean',
                                           returnformat = 'sitelist'))

  working_ts <- get_ts_traces(portal = 'NSW',
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


# HTTP errors -------------------------------------------------------------

test_that('HTTP errors work correctly for one gauge', {

  skip("The error that previously triggered these tests no longer occurs. Finding another one will be trial and error, skip until that happens, assuming it still works as it did.")
  # This site returns a 504 Gateway timeout for 'CP'
  # This is an idiosyncratic error, so I might have to
  # do something different here like bypass `portal` somehow.

  # I could feed it "http://httpbin.org/404" as in test-get_response, but this
  # needs to ensure the outputs can line up with other sites, so it's harder to
  # set that up

  # Should error with 'stop'
  expect_error(man16_s <- get_ts_traces2(portal = 'NSW',
                          site_list = '412038',
                          var_list = "141",
                          start_time = 'all',
                          end_time = 'all',
                          interval = 'day',
                          data_type = 'mean',
                          datasource = 'CP',
                          returnformat = 'sitelist',
                          .errorhandling = 'stop'))

  # Should return a simple tibble with no info if 'pass'
  man16_p <- get_ts_traces2(portal = 'NSW',
                          site_list = '412038',
                          var_list = "141",
                          start_time = 'all',
                          end_time = 'all',
                          interval = 'day',
                          data_type = 'mean',
                          datasource = 'CP',
                          returnformat = 'sitelist',
                          .errorhandling = 'pass')

  expect_true(inherits(man16_p[[1]], 'tbl_df'))
  expect_equal(man16_p[[1]]$error_msg, 'HTTP error number: 504 Gateway Timeout')

  # should return NULL and leave a message if 'remove'
  expect_message(man16_r <- get_ts_traces2(portal = 'NSW',
                            site_list = '412038',
                            var_list = "141",
                            start_time = 'all',
                            end_time = 'all',
                            interval = 'day',
                            data_type = 'mean',
                            datasource = 'CP',
                            returnformat = 'sitelist',
                            .errorhandling = 'remove'))
  expect_null(man16_r)

})

test_that('HTTP errors work correctly for multiple gauges', {

  # 412038 returns a 504 Gateway timeout for 'CP'. 416072 should work.
  # Make sure they work together

  skip("The error that previously triggered these tests no longer occurs. Finding another one will be trial and error, skip until that happens, assuming it still works as it did.")


  # It's entirely possible this is an idiosyncratic error, so I might have to
  # do something different here like bypass `portal` somehow.

  # I could feed it "http://httpbin.org/404" as in test-get_response, but this
  # needs to ensure the outputs can line up with other sites, so it's harder to
  # set that up

  # Should error with 'stop'
  expect_error(man16_s <- get_ts_traces2(portal = 'NSW',
                                         site_list = c('412038', '416072'),
                                         var_list = "141",
                                         start_time = 'all',
                                         end_time = 'all',
                                         interval = 'day',
                                         data_type = 'mean',
                                         datasource = 'CP',
                                         returnformat = 'sitelist',
                                         .errorhandling = 'stop'))

  # Should return a simple tibble with no info if 'pass', but second should be unaffected
  man16_p <- get_ts_traces2(portal = 'NSW',
                            site_list = c('412038', '416072'),
                            var_list = "141",
                            start_time = 'all',
                            end_time = 'all',
                            interval = 'day',
                            data_type = 'mean',
                            datasource = 'CP',
                            returnformat = 'sitelist',
                            .errorhandling = 'pass')

  expect_true(inherits(man16_p[[1]], 'tbl_df'))
  expect_equal(nrow(man16_p[[1]]), 1)
  expect_equal(man16_p[[1]]$error_msg, 'HTTP error number: 504 Gateway Timeout')
  expect_true(is.na(man16_p[[1]]$variable))

  expect_true(inherits(man16_p[[2]], 'tbl_df'))
  expect_true(is.na(man16_p[[2]]$error_msg[1]))
  expect_gt(nrow(man16_p[[2]]), 4000)

  # should return NULL and leave a message if 'remove'
  man16_r <- get_ts_traces2(portal = 'NSW',
                                           site_list = c('412038', '416072'),
                                           var_list = "141",
                                           start_time = 'all',
                                           end_time = 'all',
                                           interval = 'day',
                                           data_type = 'mean',
                                           datasource = 'CP',
                                           returnformat = 'sitelist',
                                           .errorhandling = 'remove')

  expect_equal(length(man16_r), 1)
  expect_gt(nrow(man16_r[[1]]), 4000)

})

test_that("ts timezone checks", {
  simpletrace <- get_ts_traces(portal = 'vic', site_list = "233217",
                               datasource = 'A',
                               var_list = c('100', '140'),
                               start_time = '20200101000000',
                               end_time = '20200101235900',
                               interval = 'default',
                               data_type = 'point',
                               multiplier = 1,
                               returnformat = 'df',
                               return_timezone = 'char')
  expect_equal(simpletrace$time[1], "2020-01-01T00:00:00+10")

  simpletrace_utc <- get_ts_traces(portal = 'vic', site_list = "233217",
                               datasource = 'A',
                               var_list = c('100', '140'),
                               start_time = '20200101000000', end_time = '20200101235900',
                               interval = 'default', data_type = 'point',
                               multiplier = 1,
                               return_timezone = 'UTC',
                               returnformat = 'df')

  expect_equal(simpletrace_utc$time[1], lubridate::ymd_hms('2019-12-31 14:00:00', tz = "UTC"))

  simpletrace_local <- get_ts_traces(portal = 'vic', site_list = "233217",
                                   datasource = 'A',
                                   var_list = c('100', '140'),
                                   start_time = '20200101000000', end_time = '20200101235900',
                                   interval = 'default', data_type = 'point',
                                   multiplier = 1,
                                   return_timezone = 'db_default',
                                   returnformat = 'df')

  expect_equal(simpletrace_local$time[1], lubridate::ymd_hms('2020-01-01 00:00:00', tz = "Etc/GMT-10"))

  # are we sure this *is* returning data at local and not UTC? Use TELEM, not archive

  # This gauge is 10 hours ahead of UTC, so grab a timeperiod that's in that gap.
    # go three hours back to make sure there's data and less than 10, so this time hasn't happened in UTC yet
  londontime <- lubridate::now(tz = 'UTC')
  starttime <- londontime - lubridate::dhours(3)

  # This bit puts it in +10 and removes tz info
  starttime <- starttime |>
    lubridate::with_tz('Etc/GMT-10') |>
    as.character() |>
    stringr::str_remove_all('\\.[0-9]*') |>
    fix_times()

  endtime <- lubridate::now(tz = 'UTC')|>
    lubridate::with_tz('Etc/GMT-10') |>
    as.character() |>
    stringr::str_remove_all('\\.[0-9]*') |>
    fix_times()

  # get times as char, so there's no internal time zone manipulation
  nowtrace <- get_ts_traces(portal = 'vic',
                            site_list = "233217",
                            datasource = 'TELEM',
                            var_list = c('100', '140'),
                            # at the time of writing this test, it is 4:30 am in London on the 18th, so this start time hasn't happened.
                            start_time = starttime, end_time = endtime,
                            interval = 'default', data_type = 'point',
                            multiplier = 1,
                            return_timezone = 'char',
                            returnformat = 'df')

  # all of them should be after current UTC time if we ignore the tz appended on them and treat as UTC, and so they must be local
  notz <- nowtrace$time |>
    substr(1, 19) |>
    lubridate::ymd_hms(tz = 'UTC')

  expect_true(all(notz > londontime))


})
