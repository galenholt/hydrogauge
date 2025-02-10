test_that("returns expected", {
  with_mock_dir('mocked_responses/get_variable_list/simple',
  v2 <- get_variable_list(portal = 'vic', site_list = "233217, 405328, 405331, 405837",
                          datasource = c('A', 'TELEM'))
  )
  expect_snapshot_value(names(v2), style = 'deparse')
})

test_that("handles missing", {
  # this was thowing an error, so debug and test the fix works
    # Note- the gauge is actually in VIC. It returns info, but return$sites[[1]]$variables is list()
  with_mock_dir('mocked_responses/get_variable_list/missing',
  miss_site <- get_variable_list(portal = 'NSW',
                          site_list = "414209",
                          datasource = c('A'))
  )

  expect_snapshot_value(names(miss_site), style = 'deparse')
  expect_equal(rowSums(is.na(miss_site)), 6)

  # test the fix works with multiple sites including some that do exist
  with_mock_dir('mocked_responses/get_variable_list/missing_and_exist',
  miss_and_exist <- get_variable_list(portal = 'NSW',
                          site_list = "414209, 422028",
                          datasource = c('A', 'TELEM'))
  )
  expect_snapshot_value(names(miss_and_exist), style = 'deparse')
  expect_equal(sum(is.na(miss_and_exist$variable)), 3)
})

test_that("lake level and other", {
  # first is normal, second is a reservoir with levels
  with_mock_dir('mocked_responses/get_variable_list/lake_level',
  lakelist <- get_variable_list(portal = 'nsw',
                                                site_list = c("422028", "412107"),
                                                datasource = 'A')
  )

  # Those two should match
  expect_snapshot(lakelist)
})

