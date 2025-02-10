test_that("simple works", {
  with_mock_dir('mocked_responses/getGroupList/simple',
  bomout <- getGroupList(portal = 'bom')
  )
  expect_snapshot_value(names(bomout), style = 'deparse')
  expect_equal(nrow(bomout), 8)

})
