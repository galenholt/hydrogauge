test_that("returns expected", {
  v2 <- get_variable_list(site_list = "233217, 405328, 405331, 405837",
                          datasource = c('A', 'TELEM'))
  namevec <- c("site", "short_name", "long_name", "variable", "units", "var_name", "period_start", "period_end", "subdesc", "datasource", "timezone")
  expect_equal(names(v2), namevec)
})

test_that("handles missing", {
  # this was thowing an error, so debug and test the fix works
    # Note- the gauge is actually in VIC. It returns info, but return$sites[[1]]$variables is list()
  miss_site <- get_variable_list(state = 'NSW',
                          site_list = "414209",
                          datasource = c('A'))

  namevec <- c("site", "short_name", "long_name", "variable", "units", "var_name", "period_start", "period_end", "subdesc", "datasource", "timezone")
  expect_equal(names(miss_site), namevec)
  expect_equal(rowSums(is.na(miss_site)), 6)

  # test the fix works with multiple sites including some that do exist
  miss_and_exist <- get_variable_list(state = 'NSW',
                          site_list = "414209, 422028",
                          datasource = c('A', 'TELEM'))
  namevec <- c("site", "short_name", "long_name", "variable", "units", "var_name", "period_start", "period_end", "subdesc", "datasource", "timezone")
  expect_equal(names(miss_and_exist), namevec)
  expect_equal(sum(is.na(miss_and_exist$variable)), 3)
  })

