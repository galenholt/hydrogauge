test_that("single variable ts works", {
  with_mock_dir('mocked_responses/get_responses/single',
  s1 <- get_response("https://data.water.vic.gov.au/WMIS/cgi/webservice.exe?",
                     api_body_list = list("function" = 'get_ts_traces',
                                      "version" = "2",
                                      "params" = list("site_list" = '233217',
                                                      "start_time" = 20200101,
                                                      "var_list" = "100",
                                                      "interval" = "day",
                                                      "datasource" = "A",
                                                      "end_time" = 20200105,
                                                      "data_type" = "mean",
                                                      "multiplier" = 1)))
  )
  expect_equal(class(s1), 'list')
  expect_equal(s1[[1]], 0)

  # check there's no internal error- indexing is specific to ts. maybe better to
  # leave to the error catcher
  expect_equal(s1[[2]][[1]][[1]][[1]], 0)


})


test_that("multiple variables work for ts", {
  with_mock_dir('mocked_responses/get_responses/multi',
  s2 <- get_response("https://data.water.vic.gov.au/WMIS/cgi/webservice.exe?",
                     api_body_list = list("function" = 'get_ts_traces',
                                      "version" = "2",
                                      "params" = list("site_list" = '233217',
                                                      "start_time" = 20200101,
                                                      "var_list" = "100, 450",
                                                      "interval" = "day",
                                                      "datasource" = "A",
                                                      "end_time" = 20200105,
                                                      "data_type" = "mean",
                                                      "multiplier" = 1)))
  )
  expect_equal(class(s2), 'list')
  expect_equal(s2[[1]], 0)

})

test_that("derived variables work for ts", {
  with_mock_dir('mocked_responses/get_responses/derived',
  s3 <- get_response("https://data.water.vic.gov.au/WMIS/cgi/webservice.exe?",
                     api_body_list = list("function" = 'get_ts_traces',
                                      "version" = "2",
                                      "params" = list("site_list" = '233217',
                                                      "start_time" = 20200101,
                                                      "varfrom" = "100",
                                                      "varto" = "140",
                                                      "interval" = "day",
                                                      "datasource" = "A",
                                                      "end_time" = 20200105,
                                                      "data_type" = "mean",
                                                      "multiplier" = 1)))
  )
  expect_equal(class(s3), 'list')
  expect_equal(s3[[1]], 0)

})


test_that("HTTP errors handled", {
  with_mock_dir('mocked_responses/get_responses/errors',
  expect_error(s_stop <- get_response("http://httpbin.org/404",
                     api_body_list = list(dummy = 'testlist'),
                     .errorhandling = 'stop'))
  )

  with_mock_dir('mocked_responses/get_responses/pass_error',
  s_pass <- get_response("http://httpbin.org/404",
                         api_body_list = list(dummy = 'testlist'),
                         .errorhandling = 'pass')
  )

  expect_equal(s_pass, 'HTTP error number: 404 Not Found')

})


# I could do more with the other functions, but I think it probably makes more
# sense to check them at the wrapper level, rather than rebuild their api_body_lists
# here

