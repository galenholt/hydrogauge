test_that("single variable ts works", {
  s1 <- get_response("https://data.water.vic.gov.au/cgi/webservice.exe?",
                     paramlist = list("function" = 'get_ts_traces',
                                      "version" = "2",
                                      "params" = list("site_list" = '233217',
                                                      "start_time" = 20200101,
                                                      "var_list" = "100",
                                                      "interval" = "day",
                                                      "datasource" = "A",
                                                      "end_time" = 20200105,
                                                      "data_type" = "mean",
                                                      "multiplier" = 1)))
  expect_equal(class(s1), 'list')
  expect_equal(s1[[1]], 0)

  # check there's no internal error- indexing is specific to ts. maybe better to
  # leave to the error catcher
  expect_equal(s1[[2]][[1]][[1]][[1]], 0)


})


test_that("multiple variables work for ts", {
  s2 <- get_response("https://data.water.vic.gov.au/cgi/webservice.exe?",
                     paramlist = list("function" = 'get_ts_traces',
                                      "version" = "2",
                                      "params" = list("site_list" = '233217',
                                                      "start_time" = 20200101,
                                                      "var_list" = "100, 450",
                                                      "interval" = "day",
                                                      "datasource" = "A",
                                                      "end_time" = 20200105,
                                                      "data_type" = "mean",
                                                      "multiplier" = 1)))
  expect_equal(class(s2), 'list')
  expect_equal(s2[[1]], 0)

})

test_that("derived variables work for ts", {
  s3 <- get_response("https://data.water.vic.gov.au/cgi/webservice.exe?",
                     paramlist = list("function" = 'get_ts_traces',
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
  expect_equal(class(s3), 'list')
  expect_equal(s3[[1]], 0)

})

# I could do more with the other functions, but I think it probably makes more
# sense to check them at the wrapper level, rather than rebuild their paramlists
# here
