test_that("simple works", {
  bomout <- getGroupList(portal = 'bom')
  expect_snapshot_value(names(bomout), style = 'deparse')
  expect_equal(nrow(bomout), 8)

})
