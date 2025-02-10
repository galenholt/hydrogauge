test_that("simple works", {
  with_mock_dir('mocked_responses/getParameterList/simple',
  bomout <- getParameterList(portal = 'bom',
                           station_no = c('410730', 'A4260505'))
  )
  expect_snapshot_value(names(bomout), style = 'deparse')
  expect_equal(nrow(bomout), 9)
})
