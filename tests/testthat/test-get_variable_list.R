test_that("returns expected", {
  v2 <- get_variable_list(site_list = "233217, 405328, 405331, 405837",
                          datasource = c('A', 'TELEM'))
  namevec <- c("site", "short_name", "long_name", "variable", "units", "var_name", "period_start", "period_end", "subdesc", "datasource", "timezone")
  expect_equal(names(v2), namevec)
})
